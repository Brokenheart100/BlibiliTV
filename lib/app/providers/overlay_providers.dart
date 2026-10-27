import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/repositories/bilibili_overlay_repository.dart';
import '../../data/repositories/local_overlay_preferences.dart';
import '../../domain/overlays/overlays.dart';
import '../../domain/overlays/overlay_metrics.dart';
import 'infrastructure_providers.dart';
import 'repository_providers.dart';
part 'overlay_providers.g.dart';

@Riverpod(keepAlive: true)
OverlayMetrics overlayMetrics(Ref ref) => OverlayMetrics();

@Riverpod(keepAlive: true)
BilibiliOverlayRepository overlayRepository(Ref ref) {
  final repository = BilibiliOverlayRepository(ref.watch(bilibiliApiProvider));
  ref.onDispose(repository.close);
  return repository;
}

@Riverpod(keepAlive: true)
SubtitleRepository subtitleRepository(Ref ref) =>
    ref.watch(overlayRepositoryProvider);
@Riverpod(keepAlive: true)
DanmakuRepository danmakuRepository(Ref ref) =>
    ref.watch(overlayRepositoryProvider);
@Riverpod(keepAlive: true)
OverlayPreferencesRepository overlayPreferencesRepository(Ref ref) =>
    LocalOverlayPreferences(ref.watch(preferencesStoreProvider));
