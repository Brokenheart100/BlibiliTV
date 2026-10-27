"""Generate the small Web protobuf schema using pinned upstream tools."""
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import urllib.request
import zipfile
from urllib.parse import urlparse, unquote

ROOT = Path(__file__).resolve().parents[2]
CONFIG = json.loads((ROOT / 'tool/ci/toolchain.json').read_text())
VERSION = CONFIG['protoc']
if VERSION != '36.2':
    raise RuntimeError('Update compiler checksums before changing the protoc version')
ASSETS = {
    'nt': ('win64', 'f0c128dc0d8492eceece83bb459a4c0e316764b929ffbf1aa416357fd644edd3'),
    'posix': ('linux-x86_64', '121f6c7afe1d4d0e3ea6aab9432038599250134cbf4474cb1167d2c7decd4278'),
}

def main():
    suffix, expected = ASSETS[os.name]
    cache = ROOT / '.dart_tool' / f'protoc-{VERSION}'
    cache.mkdir(parents=True, exist_ok=True)
    archive = cache / 'archive.zip'
    if not archive.exists():
        urllib.request.urlretrieve(f'https://github.com/protocolbuffers/protobuf/releases/download/v{VERSION}/protoc-{VERSION}-{suffix}.zip', archive)
    if hashlib.sha256(archive.read_bytes()).hexdigest() != expected:
        raise ValueError('protoc archive checksum mismatch')
    binary = 'protoc.exe' if os.name == 'nt' else 'protoc'
    executable = cache / binary
    with zipfile.ZipFile(archive) as source:
        executable.write_bytes(source.read('bin/' + binary))
    executable.chmod(0o755)
    dart = shutil.which('dart')
    if not dart and os.environ.get('FLUTTER_ROOT'):
        dart = str(Path(os.environ['FLUTTER_ROOT']) / 'bin/dart.bat')
    if not dart:
        raise RuntimeError('Put the pinned Dart SDK on PATH or set FLUTTER_ROOT')
    # A native executable avoids cmd.exe consuming protoc's binary stdin on Windows.
    configuration = json.loads((ROOT / '.dart_tool/package_config.json').read_text())
    package = next(p for p in configuration['packages'] if p['name'] == 'protoc_plugin')
    parsed = urlparse(package['rootUri'])
    location = unquote(parsed.path)
    if os.name == 'nt' and location.startswith('/'):
        location = location[1:]
    # The pub archive retains a workspace pubspec; compile its unchanged entry
    # inside our project so Dart uses our actual locked package configuration.
    plugin_spec = (Path(location) / 'pubspec.yaml').read_text(encoding='utf-8')
    if f"version: {CONFIG['protoc_plugin']}" not in plugin_spec.splitlines():
        raise ValueError('protoc_plugin does not match the pinned toolchain')
    source = cache / 'protoc_plugin.dart'
    source.write_bytes((Path(location) / 'bin/protoc_plugin.dart').read_bytes())
    plugin = cache / ('protoc-gen-dart.exe' if os.name == 'nt' else 'protoc-gen-dart')
    subprocess.run([dart, 'compile', 'exe', '--packages=' + str(ROOT / '.dart_tool/package_config.json'), str(source), '-o', str(plugin)], cwd=ROOT, check=True, timeout=120)
    output = ROOT / 'lib/data/services/danmaku/generated'
    output.mkdir(parents=True, exist_ok=True)
    generated = cache / 'generated.zip'
    subprocess.run([str(executable), '--plugin=protoc-gen-dart=' + str(plugin), '--dart_out=' + str(generated), '--proto_path=' + str(ROOT / 'tool/proto'), str(ROOT / 'tool/proto/danmaku.proto')], cwd=ROOT, check=True, timeout=60)
    # protoc supports zip output; use it consistently across Windows and Linux.
    with zipfile.ZipFile(generated) as files:
        for name in files.namelist():
            if name not in ('danmaku.pb.dart', 'danmaku.pbenum.dart', 'danmaku.pbjson.dart'):
                raise ValueError('Unexpected generated path')
            (output / name).write_bytes(files.read(name))
    print('Generated Web protobuf schema: protoc 36.2, locked protoc_plugin')

if __name__ == '__main__':
    main()
