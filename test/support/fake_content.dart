import 'package:mambatv/core/result.dart';
import 'package:mambatv/domain/entities/app_models.dart';
import 'package:mambatv/domain/playback/content_playback.dart';
import 'package:mambatv/domain/playback/playback.dart';
import 'package:mambatv/domain/playback/playback_target.dart';

import 'dash_source.dart';
import 'fake_playback.dart';

class FakePgcRepository implements PgcRepository {
  final requested = <PgcTarget>[];
  int episodeCount = 30;
  @override
  Future<Result<ContentSeason>> season(
    String id,
    CancellationSignal signal,
  ) async => Success(
    ContentSeason(
      id: id,
      title: '合成番剧 $id',
      description: '用于验证选集与遥控器操作',
      episodes: List.generate(
        episodeCount,
        (i) => ContentEpisode(
          id: '${i + 1}',
          title: '第 ${i + 1} 话',
          cid: '${i + 100}',
          bvid: 'BVfixture$i',
          restricted: i == 2,
          badge: i == 2 ? '会员' : '',
        ),
      ),
    ),
  );
  @override
  Future<Result<PageSlice<VideoSummary>>> browse(
    CancellationSignal signal, {
    int page = 1,
    String keyword = '',
  }) async => Success(
    PageSlice(
      items: [
        const VideoSummary(
          id: '10',
          title: '合成番剧 10',
          creator: '更新至第 30 话',
          durationSeconds: 0,
          viewCount: 0,
        ),
      ],
    ),
  );
  @override
  Future<Result<PlaybackSource>> resolve(
    PgcTarget target,
    CancellationSignal signal, {
    int? quality,
    int? audioId,
  }) async {
    requested.add(target);
    if (target.episodeId == '3') {
      return const ResultFailure(
        AppFailure(FailureKind.permission, '当前仅提供试看，暂不播放'),
      );
    }
    return const Success(dashSource);
  }
}

class FakeLiveRepository implements LiveRepository {
  bool active = true;
  int resolutions = 0;
  @override
  Future<Result<LiveRoom>> room(String id, CancellationSignal signal) async =>
      Success(LiveRoom(id: '100', title: '合成直播', creator: '主播', live: active));
  @override
  Future<Result<PlaybackSource>> resolve(
    String id,
    CancellationSignal signal, {
    int? quality,
  }) async {
    resolutions++;
    return const Success(
      PlaybackSource(
        videoUrl: 'https://fake.bilivideo.com/live.m3u8',
        audioUrl: '',
        duration: Duration.zero,
        quality: 250,
        codec: 'avc',
        transport: PlaybackTransport.hls,
        qualities: [PlaybackOption(250, '高清')],
      ),
    );
  }

  @override
  Future<Result<PageSlice<LiveRoom>>> browse(
    CancellationSignal signal, {
    int page = 1,
    String keyword = '',
  }) async =>
      const ResultFailure(AppFailure(FailureKind.rateLimited, '请求暂时受限，请稍后重试'));
}

class MemoryContentProgress extends MemoryProgressRepository
    implements ContentProgressRepository {
  final typed = <String, WatchProgress>{};
  final visits = <PlaybackTarget>[];
  String _key(String owner, ContentKind kind, String id, String part) =>
      '$owner:${kind.name}:$id:$part';
  @override
  Future<Result<void>> save(WatchProgress progress) async {
    if (progress.isValid) {
      typed[_key(
            progress.ownerKey,
            progress.kind,
            progress.videoId,
            progress.partId,
          )] =
          progress;
    }
    if (progress.kind == ContentKind.ugc) return super.save(progress);
    if (progress.isValid) writes.add(progress);
    return const Success(null);
  }

  @override
  Future<Result<WatchProgress?>> loadTarget(
    String ownerKey,
    PlaybackTarget target,
  ) async => Success(
    typed[_key(ownerKey, target.kind, target.contentId, target.partId ?? '')],
  );
  @override
  Future<Result<void>> rememberTarget(
    String ownerKey,
    PlaybackTarget target,
    VideoSummary metadata,
  ) async {
    visits.add(target);
    return const Success(null);
  }
}
