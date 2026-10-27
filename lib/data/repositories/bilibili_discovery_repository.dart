import '../../core/result.dart';
import '../../domain/entities/app_models.dart';
import '../../domain/discovery/discovery.dart';
import '../services/bilibili/bilibili_api.dart';
import '../services/bilibili/bilibili_dto.dart';

class BilibiliDiscoveryRepository
    implements CreatorRepository, FollowingFeedRepository {
  BilibiliDiscoveryRepository(this.api);
  final BilibiliApi api;
  @override
  Future<Result<PageSlice<VideoSummary>>> creatorVideos({
    required int mid,
    required String ownerKey,
    required VideoOrder order,
    String? cursor,
    required CancellationSignal cancellation,
  }) async {
    try {
      api.checkOwner(ownerKey);
      if (mid <= 0) throw const FormatException('Creator ID');
      final page = int.tryParse(cursor ?? '1');
      if (page == null || page < 1) throw const FormatException('Page');
      final data = await api.get(
        '/x/space/wbi/arc/search',
        cancellation,
        signed: true,
        query: {
          'mid': mid,
          'pn': page,
          'ps': 30,
          'tid': 0,
          'order': order == VideoOrder.mostViewed ? 'click' : 'pubdate',
          'platform': 'web',
          'web_location': 1550101,
          'order_avoided': true,
        },
      );
      final rows = (data['list'] as Map?)?['vlist'] as List? ?? [];
      final videos = <VideoSummary>[];
      for (final value in rows) {
        final row = jsonObject(value);
        final video = _video(row, row['author'] as String? ?? 'UP 主');
        if (video != null) videos.add(video);
      }
      final count = (data['page'] as Map?)?['count'];
      return Success(
        PageSlice(
          items: videos,
          nextCursor: rows.isEmpty || count is num && page * 30 >= count
              ? null
              : '${page + 1}',
        ),
      );
    } catch (e) {
      return ResultFailure(safeApiFailure(e));
    }
  }

  @override
  Future<Result<PageSlice<VideoSummary>>> followingVideos({
    required String ownerKey,
    String? cursor,
    required CancellationSignal cancellation,
  }) async {
    try {
      api.checkOwner(ownerKey);
      if (!api.identity.session.isAuthenticated) {
        throw const AppFailure(FailureKind.authentication, '登录后查看关注视频');
      }
      final data = await api.get(
        '/x/polymer/web-dynamic/v1/feed/all',
        cancellation,
        query: {'type': 'video', 'offset': ?cursor},
      );
      final rows = data['items'] as List? ?? [];
      final videos = <VideoSummary>[];
      var filtered = 0;
      for (final value in rows) {
        final row = jsonObject(value);
        final modules = row['modules'] as Map?;
        final major = (modules?['module_dynamic'] as Map?)?['major'] as Map?;
        final archive = major?['archive'];
        if (archive is! Map<String, Object?> ||
            major?['type'] != 'MAJOR_TYPE_ARCHIVE') {
          filtered++;
          continue;
        }
        final mapped = <String, Object?>{
          ...archive,
          'pic': archive['cover'],
          'length': archive['duration_text'],
          'play': (archive['stat'] as Map?)?['play'],
          'author_face': (modules?['module_author'] as Map?)?['face'],
        };
        final video = _video(
          mapped,
          (modules?['module_author'] as Map?)?['name'] as String? ?? 'UP 主',
        );
        if (video == null) {
          filtered++;
        } else {
          videos.add(video);
        }
      }
      final next = data['offset'] as String?;
      return Success(
        PageSlice(
          items: videos,
          nextCursor:
              (data['has_more'] == true || data['has_more'] == 1) &&
                  next != null &&
                  next.isNotEmpty &&
                  next != cursor
              ? next
              : null,
          notice: filtered > 0 ? '已过滤 $filtered 条非普通视频内容' : null,
        ),
      );
    } catch (e) {
      return ResultFailure(safeApiFailure(e));
    }
  }

  VideoSummary? _video(Map<String, Object?> row, String author) {
    final id = row['bvid'], title = row['title'];
    if (id is! String || !id.startsWith('BV') || title is! String) return null;
    final rawViews = '${row['play'] ?? 0}';
    final number =
        num.tryParse(rawViews.replaceAll(RegExp('[^0-9.]'), '')) ?? 0;
    return VideoSummary(
      id: id,
      title: title.replaceAll(RegExp('<[^>]*>'), ''),
      creator: author,
      creatorAvatarUrl: avatarUrl(row['author_face']),
      durationSeconds: durationSeconds(row['length'] ?? 0),
      viewCount:
          (number *
                  (rawViews.contains('亿')
                      ? 100000000
                      : rawViews.contains('万')
                      ? 10000
                      : 1))
              .round(),
      coverUrl: coverUrl(row['pic'] as String? ?? ''),
    );
  }
}
