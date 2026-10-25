"""Inventory locked Dart packages and their actual license files. No network access."""
import hashlib
import json
from pathlib import Path
import re
import subprocess
from urllib.parse import unquote, urlparse

ROOT = Path(__file__).resolve().parents[2]
def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

def generate(deps):
    packages = {p['name']: p for p in deps['packages']}
    configs = json.loads((ROOT / '.dart_tool/package_config.json').read_text())
    locations = {}
    for p in configs['packages']:
        uri = urlparse(p['rootUri'])
        path = unquote(uri.path)
        if uri.scheme == 'file' and re.match(r'^/[A-Za-z]:/', path):
            path = path[1:]
        locations[p['name']] = Path(path) if uri.scheme == 'file' else (ROOT / '.dart_tool' / path).resolve()
    runtime = set()
    def visit(name):
        if name in runtime: return
        runtime.add(name)
        for child in packages[name]['dependencies']: visit(child)
    for p in packages.values():
        if p['kind'] == 'direct': visit(p['name'])
    records, notices = [], []
    for name, p in sorted(packages.items()):
        if p['kind'] == 'root': continue
        location = locations.get(name)
        license_file = next((location / n for n in ['LICENSE', 'LICENSE.md', 'LICENSE.txt', 'COPYING'] if location and (location / n).is_file()), None)
        if license_file is None and p['source'] == 'sdk':
            sdk_license = locations['flutter'] / 'LICENSE'
            if sdk_license.is_file(): license_file = sdk_license
        spec = (location / 'pubspec.yaml').read_text(encoding='utf-8') if location and (location / 'pubspec.yaml').is_file() else ''
        source = re.search(r'(?m)^(?:repository|homepage):\s*[\'\"]?([^\s\'\"]+)', spec)
        record = {'package': name, 'version': p['version'], 'kind': p['kind'], 'runtimeGraph': name in runtime, 'source': source[1] if source else p['source'], 'licenseFile': license_file.name if license_file else None, 'licenseSha256': digest(license_file) if license_file else None}
        records.append(record)
        if name in runtime and license_file:
            notices.append(f'===== {name} {p["version"]} =====\nSource: {record["source"]}\n\n{license_file.read_text(encoding="utf-8-sig").strip()}\n')
    report = {'pubspecLockSha256': digest(ROOT / 'pubspec.lock'), 'lockCanonicalSha256': hashlib.sha256((ROOT / 'pubspec.lock').read_text(encoding='utf-8-sig').encode()).hexdigest(), 'nativeNoticesSha256': hashlib.sha256((ROOT / 'assets/licenses/native-notices.json').read_text(encoding='utf-8').encode()).hexdigest(), 'runtimePackageCount': len(runtime), 'allDependencyCount': len(records), 'packages': records, 'scope': 'Dart/Flutter package license files; native transitive components require separate review'}
    (ROOT / 'docs/release/dependencies.json').write_text(json.dumps(report, ensure_ascii=False, indent=2)+'\n', encoding='utf-8')
    (ROOT / 'docs/release/THIRD_PARTY_NOTICES.txt').write_text('\n'.join(notices), encoding='utf-8')
    native = json.loads((ROOT / 'assets/licenses/native-notices.json').read_text(encoding='utf-8'))
    (ROOT / 'docs/release/NATIVE_NOTICES.txt').write_text('\n\n'.join(f"===== {v['package']} =====\nSource: {v['source']}\n\n{v['text']}" for v in native),encoding='utf-8')
    print(f'Inventoried {len(records)} packages, {len(runtime)} in runtime graph')

def check():
    report = json.loads((ROOT / 'docs/release/dependencies.json').read_text(encoding='utf-8'))
    canonical = hashlib.sha256((ROOT / 'pubspec.lock').read_text(encoding='utf-8-sig').encode()).hexdigest()
    if canonical != report['lockCanonicalSha256'] or hashlib.sha256((ROOT / 'assets/licenses/native-notices.json').read_text(encoding='utf-8').encode()).hexdigest() != report['nativeNoticesSha256']:
        raise ValueError('Notice inventory is stale; regenerate from locked dependencies')
    if any(p['runtimeGraph'] and p['licenseFile'] is None for p in report['packages']):
        raise ValueError('A runtime dependency has no collected license')
    print('Locked dependency and native-notice inventory is current')

if __name__ == '__main__':
    import argparse
    parser = argparse.ArgumentParser()
    parser.add_argument('--deps-json', type=Path)
    parser.add_argument('--check', action='store_true')
    args=parser.parse_args()
    if args.check: check()
    elif args.deps_json: generate(json.loads(args.deps_json.read_text(encoding='utf-8-sig')))
    else: parser.error('Choose --check or --deps-json')
