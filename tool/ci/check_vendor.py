"""Check the reviewed local canvas patch without mutating package sources."""
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


def verify():
    root = ROOT / 'third_party/canvas_danmaku'
    manifest = json.loads((root / 'UPSTREAM.json').read_text(encoding='utf-8'))
    if manifest['version'] != '0.3.3' or manifest['sha256'] != '1ff071d027b1cf3320d4b58ff1aee6811de51ce39b5b5773c2e0d7693e02d401':
        raise ValueError('Unexpected upstream canvas archive')
    actual = {p.relative_to(root).as_posix() for p in (root / 'lib').rglob('*') if p.is_file()}
    actual.update(['pubspec.yaml', 'LICENSE', 'README.md', 'CHANGELOG.md'])
    if actual != set(manifest['files']):
        raise ValueError('Canvas package file inventory changed')
    changed = []
    for name, entry in manifest['files'].items():
        target = (root / name).resolve()
        if not target.is_relative_to(root.resolve()) or target.is_symlink():
            raise ValueError('Unexpected vendor path')
        canonical = target.read_text(encoding='utf-8').encode('utf-8')
        if hashlib.sha256(canonical).hexdigest() != entry['sha256']:
            raise ValueError('Unreviewed canvas change: ' + name)
        if entry['sha256'] != entry['upstreamSha256']:
            changed.append(name)
    if set(changed) != {'pubspec.yaml', 'lib/danmaku_screen.dart', 'lib/models/danmaku_option.dart'}:
        raise ValueError('Canvas patch exceeded its reviewed scope')
    print('Verified canvas upstream provenance and bounded cadence patch')


if __name__ == '__main__':
    verify()
