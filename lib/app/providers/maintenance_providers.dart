import 'package:flutter/painting.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../ui/core/images/tv_image_cache.dart';
import 'repository_providers.dart';

part 'maintenance_providers.g.dart';

typedef CacheCleaner = Future<void> Function();
@Riverpod(keepAlive: true)
CacheCleaner cacheCleaner(Ref ref) {
  final api = ref.watch(bilibiliApiProvider);
  return () async {
    await api.clearCache();
    await TvImageCache.manager.emptyCache();
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
  };
}

@riverpod
Future<String> installedAppVersion(Ref ref) async {
  final info = await PackageInfo.fromPlatform();
  return '${info.version}+${info.buildNumber}';
}
