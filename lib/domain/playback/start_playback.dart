import '../../core/result.dart';
import '../repositories/repositories.dart';
import 'playback.dart';
import 'playback_target.dart';
import 'content_playback.dart';
import '../entities/app_models.dart';

/// Resolves an actual part, fresh resources and the user's local resume point.
class StartPlayback {
  StartPlayback(
    this.catalog,
    this.playback,
    this.progress,
    this.settings, {
    this.pgc,
    this.live,
    this.contentProgress,
  });
  final PgcRepository Function()? pgc;
  final LiveRepository Function()? live;
  final ContentProgressRepository Function()? contentProgress;
  final CatalogRepository catalog;
  final PlaybackRepository playback;
  final ProgressRepository progress;
  final SettingsRepository settings;

  Future<PlaybackPlan> call({
    String? videoId,
    PlaybackTarget? target,
    String? partId,
    required String ownerKey,
    required CancellationSignal cancellation,
    int? quality,
    int? audioId,
    Duration? position,
    Duration? fallbackPosition,
  }) async {
    final actual =
        target ??
        (videoId == null
            ? null
            : PlaybackTarget.ugc(bvid: videoId, cid: partId));
    if (actual == null) throw const AppFailure(FailureKind.contract, '播放目标无效');
    if (actual is! UgcTarget) {
      return _content(
        actual,
        ownerKey,
        cancellation,
        quality: quality,
        audioId: audioId,
        position: position,
      );
    }
    videoId = actual.bvid;
    partId = actual.cid;
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

  Future<PlaybackPlan> _content(
    PlaybackTarget target,
    String ownerKey,
    CancellationSignal signal, {
    int? quality,
    int? audioId,
    Duration? position,
  }) async {
    final preferences = (await settings.load()).valueOrThrow;
    _check(signal);
    if (target is LiveTarget) {
      final repository = live?.call();
      if (repository == null) {
        throw const AppFailure(FailureKind.unsupported, '直播暂不可用');
      }
      final room = (await repository.room(target.roomId, signal)).valueOrThrow;
      if (!room.live || room.locked) {
        throw const AppFailure(FailureKind.unavailable, '直播间未开播或暂不可访问');
      }
      final source = (await repository.resolve(
        room.id,
        signal,
        quality: quality,
      )).valueOrThrow;
      _check(signal);
      final resolved = PlaybackTarget.live(roomId: room.id);
      await contentProgress?.call().rememberTarget(
        ownerKey,
        resolved,
        VideoSummary(
          id: room.id,
          title: room.title,
          creator: room.creator,
          coverUrl: room.coverUrl,
          durationSeconds: 0,
          viewCount: 0,
        ),
      );
      _check(signal);
      return PlaybackPlan(
        source: source,
        videoId: room.id,
        partId: '',
        title: room.title,
        partTitle: room.creator,
        startAt: Duration.zero,
        rememberProgress: false,
        playbackTarget: resolved,
        capabilities: PlaybackCapabilities.live,
        preferenceNotice: quality != null && quality != source.quality
            ? '请求的直播清晰度暂不可用，已使用服务端实际返回的档位'
            : null,
      );
    }
    final pgcTarget = target as PgcTarget;
    final repository = pgc?.call();
    if (repository == null) {
      throw const AppFailure(FailureKind.unsupported, '番剧暂不可用');
    }
    final season = (await repository.season(
      pgcTarget.seasonId,
      signal,
    )).valueOrThrow;
    _check(signal);
    final all = [...season.episodes, ...season.groups.values.expand((e) => e)];
    final episode = all.where((e) => e.id == pgcTarget.episodeId).firstOrNull;
    if (episode == null) {
      throw const AppFailure(FailureKind.unavailable, '当前剧集不在这个季中');
    }
    final resolvedTarget = PlaybackTarget.pgc(
      seasonId: season.id,
      episodeId: episode.id,
    );
    final preferred =
        quality ??
        (preferences.defaultQuality == 0 ? null : preferences.defaultQuality);
    var response = await repository.resolve(
      resolvedTarget as PgcTarget,
      signal,
      quality: preferred,
      audioId: audioId,
    );
    if (quality == null &&
        preferred != null &&
        response is ResultFailure<PlaybackSource> &&
        {
          FailureKind.permission,
          FailureKind.unsupported,
        }.contains(response.failure.kind)) {
      _check(signal);
      response = await repository.resolve(
        resolvedTarget,
        signal,
        audioId: audioId,
      );
    }
    final source = response.valueOrThrow;
    _check(signal);
    final saved = preferences.resumePlayback
        ? (await contentProgress?.call().loadTarget(
            ownerKey,
            resolvedTarget,
          ))?.valueOrThrow
        : null;
    _check(signal);
    final resume =
        position ??
        (saved != null &&
                saved.isValid &&
                saved.position < source.duration - const Duration(seconds: 10)
            ? saved.position
            : Duration.zero);
    if (preferences.resumePlayback) {
      await contentProgress?.call().rememberTarget(
        ownerKey,
        resolvedTarget,
        VideoSummary(
          id: season.id,
          title: season.title,
          creator: '番剧／影视',
          coverUrl: season.coverUrl,
          durationSeconds: source.duration.inSeconds,
          viewCount: 0,
        ),
      );
    }
    _check(signal);
    final sequence = season.episodes.any((e) => e.id == episode.id)
        ? season.episodes
        : season.groups.values.firstWhere(
            (e) => e.any((e) => e.id == episode.id),
          );
    return PlaybackPlan(
      source: source,
      videoId: season.id,
      partId: episode.id,
      title: season.title,
      partTitle: episode.title,
      startAt: Duration(
        milliseconds: resume.inMilliseconds.clamp(
          0,
          (source.duration.inMilliseconds - 1000).clamp(0, 1 << 53),
        ),
      ),
      rememberProgress: preferences.resumePlayback,
      parts: sequence.map((e) => VideoPart(id: e.id, title: e.title)).toList(),
      initialRate: preferences.defaultRate,
      autoNext: preferences.autoNext,
      playbackTarget: resolvedTarget,
      capabilities: PlaybackCapabilities.pgc,
      overlayVideoId: episode.bvid,
      overlayPartId: episode.cid,
    );
  }

  void _check(CancellationSignal cancellation) {
    if (cancellation.isCancelled) {
      throw const AppFailure(FailureKind.cancelled, '已取消播放');
    }
  }
}
