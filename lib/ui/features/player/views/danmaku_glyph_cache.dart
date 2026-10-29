import 'dart:ui';

/// A route-owned LRU of the official canvas's rasterized plain-text glyphs.
/// Each borrower owns an Image clone, so canvas eviction and cache eviction
/// release independent handles. Unique comments never grow the cache unbounded.
class DanmakuGlyphCache {
  DanmakuGlyphCache({
    this.maximumBytes = 4 * 1024 * 1024,
    this.maximumEntries = 64,
  });
  final int maximumBytes, maximumEntries;
  final _images = <Object, Image>{};
  int bytes = 0, hits = 0, misses = 0;
  int get length => _images.length;

  Image reuse(Object key, Image image) {
    final cached = _images.remove(key);
    if (cached != null) {
      hits++;
      _images[key] = cached;
      image.dispose();
      return cached.clone();
    }
    misses++;
    final cost = image.width * image.height * 4;
    if (cost > maximumBytes || maximumEntries <= 0) return image;
    while (_images.isNotEmpty &&
        (_images.length >= maximumEntries || bytes + cost > maximumBytes)) {
      final oldest = _images.remove(_images.keys.first)!;
      bytes -= oldest.width * oldest.height * 4;
      oldest.dispose();
    }
    _images[key] = image.clone();
    bytes += cost;
    return image;
  }

  void clear() {
    for (final image in _images.values) {
      image.dispose();
    }
    _images.clear();
    bytes = 0;
  }
}
