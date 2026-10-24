import 'package:flutter/painting.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

abstract final class TvImageCache {
  static final BaseCacheManager manager = _ArtworkCacheManager();
  static void configure() {
    PaintingBinding.instance.imageCache.maximumSize = 120;
    PaintingBinding.instance.imageCache.maximumSizeBytes = 48 * 1024 * 1024;
  }
}

class _ArtworkCacheManager extends CacheManager with ImageCacheManager {
  _ArtworkCacheManager()
    : super(
        Config(
          'mambatv-artwork-v1',
          stalePeriod: const Duration(days: 7),
          maxNrOfCacheObjects: 120,
        ),
      );
}
