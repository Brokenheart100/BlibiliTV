import '../../core/result.dart';
import '../../domain/entities/app_models.dart';
import '../../domain/playback/content_playback.dart';
import '../../domain/playback/playback.dart';
import '../../domain/playback/playback_target.dart';
import '../services/bilibili/bilibili_api.dart';
import '../services/bilibili/bilibili_dto.dart';
import 'bilibili_playback_repository.dart';

class BilibiliPgcRepository implements PgcRepository {
  BilibiliPgcRepository(this.api);
  final BilibiliApi api;
  @override
  Future<Result<PageSlice<VideoSummary>>> browse(
    CancellationSignal cancellation, {
    int page = 1,
    String keyword = '',
  }) async {
    try {
      final data = await api.get(
        '/pgc/season/index/result',
        cancellation,
        query: {
          'season_type': 1,
          'type': 1,
          'order': 3,
          'sort': 0,
          'page': page,
          'pagesize': 24,
        },
      );
      final items = jsonList(data['list'])
          .map(jsonObject)
          .map(
            (row) => VideoSummary(
              id: '${jsonInteger(row['season_id'])}',
              title: (row['title'] ?? '') as String,
              creator:
                  (row['index_show'] ?? row['subTitle'] ?? '番剧／影视') as String,
              coverUrl: avatarUrl(row['cover']),
              durationSeconds: 0,
              viewCount: 0,
            ),
          )
          .toList();
      return Success(
        PageSlice(
          items: items,
          nextCursor: data['has_next'] == 1 || data['has_next'] == true
              ? '${page + 1}'
              : null,
        ),
      );
    } catch (e) {
      return ResultFailure(safeApiFailure(e));
    }
  }

  @override
  Future<Result<ContentSeason>> season(
    String id,
    CancellationSignal cancellation,
  ) async {
    try {
      final data = await api.getPgc(
        '/pgc/view/web/season',
        cancellation,
        query: {'season_id': int.parse(id)},
      );
      List<ContentEpisode> episodes(Object? raw) => jsonList(raw ?? const [])
          .map(jsonObject)
          .map(
            (e) => ContentEpisode(
              id: '${jsonInteger(e['id'])}',
              cid: '${jsonInteger(e['cid'])}',
              bvid: (e['bvid'] ?? '') as String,
              title: '${e['title'] ?? ''} ${(e['long_title'] ?? '')}'.trim(),
              badge: (e['badge'] ?? '') as String,
              restricted: !{1, 2}.contains(jsonInteger(e['status'] ?? 0)),
              coverUrl: avatarUrl(e['cover']),
            ),
          )
          .toList();
      final groups = <String, List<ContentEpisode>>{};
      final stat = data['stat'] is Map
          ? jsonObject(data['stat'])
          : const <String, Object?>{};
      final rating = data['rating'] is Map
          ? jsonObject(data['rating'])
          : const <String, Object?>{};
      final publish = data['publish'] is Map
          ? jsonObject(data['publish'])
          : const <String, Object?>{};
      final latest = data['new_ep'] is Map
          ? jsonObject(data['new_ep'])
          : const <String, Object?>{};
      int? number(Object? value) {
        if (value == null) return null;
        final count = jsonInteger(value);
        return count >= 0 ? count : null;
      }

      final score = rating['score'] is num
          ? (rating['score']! as num).toDouble()
          : double.tryParse('${rating['score']}');
      for (final section in jsonList(
        data['section'] ?? const [],
      ).map(jsonObject)) {
        groups[(section['title'] ?? '附加内容') as String] = episodes(
          section['episodes'],
        );
      }
      return Success(
        ContentSeason(
          id: '${jsonInteger(data['season_id'])}',
          title: (data['title'] ?? '') as String,
          description: (data['evaluate'] ?? '') as String,
          coverUrl: avatarUrl(data['cover']),
          episodes: episodes(data['episodes']),
          groups: groups,
          facts: SeasonFacts(
            tags: List.unmodifiable(
              (data['styles'] is List
                      ? jsonList(data['styles'])
                      : const <Object?>[])
                  .whereType<String>(),
            ),
            views: number(stat['views']),
            danmaku: number(stat['danmakus']),
            followText: stat['follow_text'] as String? ?? '',
            score: score != null && score >= 0 && score <= 10 ? score : null,
            ratingCount: number(rating['count']),
            published: publish['pub_time_show'] as String? ?? '',
            status: latest['desc'] as String? ?? '',
            actors: data['actors'] as String? ?? '',
            staff: data['staff'] as String? ?? '',
          ),
        ),
      );
    } catch (e) {
      return ResultFailure(safeApiFailure(e));
    }
  }

  @override
  Future<Result<PlaybackSource>> resolve(
    PgcTarget target,
    CancellationSignal cancellation, {
    int? quality,
    int? audioId,
  }) async {
    try {
      final body = await api.getPgc(
        '/pgc/player/web/v2/playurl',
        cancellation,
        query: {
          'ep_id': int.parse(target.episodeId),
          'qn': quality ?? 32,
          'fnval': 4048,
          'fnver': 0,
          'fourk': 1,
        },
      );
      final data = body['video_info'] == null
          ? body
          : jsonObject(body['video_info']);
      if (data['is_preview'] == 1 ||
          data['is_preview'] == true ||
          (body['play_check'] is Map &&
              jsonObject(body['play_check'])['play_detail'] ==
                  'PLAY_PREVIEW')) {
        throw const AppFailure(
          FailureKind.permission,
          '此剧集需要相应权限，当前仅提供试看，暂不播放',
        );
      }
      if (data['code'] != null && jsonInteger(data['code']) != 0) {
        throw businessFailure(jsonInteger(data['code']));
      }
      return Success(
        decodeDashPlayback(data, quality: quality, audioId: audioId),
      );
    } catch (e) {
      return ResultFailure(safeApiFailure(e));
    }
  }
}
