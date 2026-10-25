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
    int? quality,
    int? audioId,
    Duration? position,
    Duration? fallbackPosition,
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
    final preferences = (await settings.load()).valueOrThrow;
    final preferred =
        quality ??
        (preferences.defaultQuality == 0 ? null : preferences.defaultQuality);
    var resolved = await playback.resolve(
      videoId: videoId,
      partId: part.id,
      cancellation: cancellation,
      quality: preferred,
      audioId: audioId,
    );
    String? preferenceNotice;
    if (quality == null &&
        preferred != null &&
        resolved is ResultFailure<PlaybackSource> &&
        {
          FailureKind.permission,
          FailureKind.unsupported,
        }.contains(resolved.failure.kind)) {
      _check(cancellation);
      resolved = await playback.resolve(
        videoId: videoId,
        partId: part.id,
        cancellation: cancellation,
        audioId: audioId,
      );
      preferenceNotice = '首选清晰度暂不可用，已使用当前可用档位';
    }
    final source = resolved.valueOrThrow;
    _check(cancellation);
    final saved = preferences.resumePlayback
        ? (await progress.load(ownerKey, videoId, part.id)).valueOrThrow
        : null;
    _check(cancellation);
    final start = position != null
        ? Duration(
            milliseconds: position.inMilliseconds.clamp(
              0,
              (source.duration.inMilliseconds - 1000).clamp(0, 1 << 53),
            ),
          )
        : saved != null &&
              saved.isValid &&
              saved.position < source.duration - const Duration(seconds: 10)
        ? saved.position
        : (saved == null || !saved.isValid) &&
              preferences.resumePlayback &&
              fallbackPosition != null &&
              fallbackPosition > Duration.zero &&
              fallbackPosition < source.duration - const Duration(seconds: 10)
        ? fallbackPosition
        : Duration.zero;
    if (preferences.resumePlayback) {
      await progress.rememberVideo(ownerKey, detail.video);
    }
    _check(cancellation);
    return PlaybackPlan(
      source: source,
      videoId: videoId,
      partId: part.id,
      title: detail.video.title,
      partTitle: part.title,
      startAt: start,
      rememberProgress: preferences.resumePlayback,
      parts: detail.parts,
      initialRate: preferences.defaultRate,
      autoNext: preferences.autoNext,
      syncHistory: preferences.syncHistory,
      preferenceNotice: preferenceNotice,
    );
  }

  void _check(CancellationSignal cancellation) {
    if (cancellation.isCancelled) {
      throw const AppFailure(FailureKind.cancelled, '已取消播放');
    }
  }
}
