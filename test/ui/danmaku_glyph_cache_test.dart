import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:mambatv/ui/features/player/views/danmaku_glyph_cache.dart';

Image glyph(int width, int height) {
  final recorder = PictureRecorder();
  Canvas(recorder).drawRect(
    Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
    Paint()..color = const Color(0xffffffff),
  );
  final picture = recorder.endRecording();
  final image = picture.toImageSync(width, height);
  picture.dispose();
  return image;
}

void main() {
  testWidgets('cached glyph handles outlive canvas and cache eviction', (
    tester,
  ) async {
    final cache = DanmakuGlyphCache(maximumBytes: 400, maximumEntries: 2);
    final first = cache.reuse(('same', 1), glyph(10, 10));
    first.dispose(); // The canvas releases its own handle.
    final reused = cache.reuse(('same', 1), glyph(10, 10));
    expect(cache.hits, 1);
    expect(cache.misses, 1);
    cache.clear();
    expect(cache.bytes, 0);
    expect(cache.length, 0);
    final pixels = await tester.runAsync(() => reused.toByteData());
    expect(pixels!.lengthInBytes, 400);
    reused.dispose();
  });

  test('LRU evicts cold styles and enforces byte and entry limits', () {
    final cache = DanmakuGlyphCache(maximumBytes: 1200, maximumEntries: 2);
    for (final key in ['a', 'b', 'a', 'c', 'a', 'b']) {
      cache.reuse(key, glyph(10, 10)).dispose();
      expect(cache.length, lessThanOrEqualTo(2));
      expect(cache.bytes, lessThanOrEqualTo(1200));
    }
    expect(cache.hits, 2);
    expect(cache.misses, 4);
    cache.reuse('large', glyph(20, 20)).dispose();
    expect(cache.bytes, 800); // Oversized images are never retained.
    cache.clear();
  });
}
