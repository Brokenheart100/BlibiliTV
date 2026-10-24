import '../../core/result.dart';
import '../repositories/repositories.dart';
import 'playback.dart';

/// Resolves an actual part, fresh resources and the user's local resume point.
class StartPlayback {
  StartPlayback(this.catalog, this.playback, this.progress, this.settings);
  final CatalogRepository catalog;
  final PlaybackRepository playback;
  final ProgressRepository progress;
  final SettingsRepository settings;

  Future<PlaybackPlan> call({
    required String videoId,
    String? partId,
    required String ownerKey,
    required CancellationSignal cancellation,
  }) async {
    final detail = (await catalog.getVideo(
      videoId,
      ownerKey: ownerKey,
      cancellation: cancellation,
    )).valueOrThrow;
    _check(cancellation);
    final parts = detail.parts.where(
      (part) => partId == null || part.id == partId,
    );
    if (parts.isEmpty) {
      throw const AppFailure(FailureKind.unavailable, '这个分集暂不可用，请返回重新选择');
    }
    final part = parts.first;
    final source = (await playback.resolve(
      videoId: videoId,
      partId: part.id,
      cancellation: cancellation,
    )).valueOrThrow;
    _check(cancellation);
    final preferences = (await settings.load()).valueOrThrow;
    final saved = preferences.resumePlayback
        ? (await progress.load(ownerKey, videoId, part.id)).valueOrThrow
        : null;
    _check(cancellation);
    final start =
        saved != null &&
            saved.isValid &&
            saved.position < source.duration - const Duration(seconds: 10)
        ? saved.position
        : Duration.zero;
    return PlaybackPlan(
      source: source,
      videoId: videoId,
      partId: part.id,
      title: detail.video.title,
      partTitle: part.title,
      startAt: start,
      rememberProgress: preferences.resumePlayback,
    );
  }

  void _check(CancellationSignal cancellation) {
    if (cancellation.isCancelled) {
      throw const AppFailure(FailureKind.cancelled, '已取消播放');
    }
  }
}
