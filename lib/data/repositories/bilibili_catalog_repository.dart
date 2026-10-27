import '../../core/result.dart';
import '../../domain/entities/app_models.dart';
import '../../domain/repositories/repositories.dart';
import '../services/bilibili/bilibili_api.dart';
import '../services/bilibili/bilibili_dto.dart';
import 'bilibili_discovery_repository.dart';

class BilibiliCatalogRepository implements CatalogRepository {
  BilibiliCatalogRepository(this.api);
  final BilibiliApi api;
  VideoSummary mapVideo(BiliVideoDto dto) => VideoSummary(
    id: dto.bvid,
    title: plainTitle(dto.title),
    creator: dto.creator,
    durationSeconds: dto.duration,
    viewCount: dto.views,
    coverUrl: dto.pic,
    creatorAvatarUrl: dto.creatorAvatarUrl,
  );

  List<VideoSummary> _videos(
    List<Object?> entries, {
    bool search = false,
    bool recommend = false,
  }) {
    final unique = <String, VideoSummary>{};
    for (final value in entries) {
      final row = jsonObject(value);
      if (recommend && row['goto'] != 'av') continue;
      if (search && row['type'] != null && row['type'] != 'video') continue;
      if (row['bvid'] is! String ||
          !(row['bvid']! as String).startsWith('BV')) {
        continue;
      }
      final video = mapVideo(BiliVideoDto.fromJson(row));
      unique[video.id] = video;
    }
    return unique.values.toList();
  }

  @override
  Future<Result<PageSlice<VideoSummary>>> fetchVideos({
    required String section,
    required String ownerKey,
    String query = '',
    CatalogOptions options = const CatalogOptions(),
    String? cursor,
    int limit = 12,
    bool forceRefresh = false,
    required CancellationSignal cancellation,
  }) async {
    try {
      api.checkOwner(ownerKey);
      if (section == 'weekly' || section == 'ranking') {
        return await _curatedFeed(
          section,
          cursor,
          limit,
          forceRefresh,
          cancellation,
        );
      }
      if (section == 'live') {
        return const ResultFailure(
          AppFailure(FailureKind.unsupported, '直播还在准备中'),
        );
      }
      if (section == 'creator') {
        return await BilibiliDiscoveryRepository(api).creatorVideos(
          mid: options.creatorId,
          ownerKey: ownerKey,
          order: options.order,
          cursor: cursor,
          cancellation: cancellation,
        );
      }
      if (section == 'following') {
        return await BilibiliDiscoveryRepository(api).followingVideos(
          ownerKey: ownerKey,
          cursor: cursor,
          cancellation: cancellation,
        );
      }
      if (cancellation.isCancelled) {
        throw const AppFailure(FailureKind.cancelled, '请求已取消');
      }
      if (section == 'library' ||
          (section == 'search' && query.trim().isEmpty)) {
        return Success(PageSlice(items: const []));
      }
      final page = int.parse(cursor?.split(':').last ?? '1');
      if (page < 1 || limit < 1 || limit > 30) {
        throw const FormatException('Pagination');
      }
      final search = section == 'search';
      final recommend =
          section == 'home' && cursor?.startsWith('popular:') != true;
      if (recommend) {
        try {
          final data = await api.get(
            '/x/web-interface/wbi/index/top/feed/rcmd',
            cancellation,
            signed: true,
            query: {
              'version': 1,
              'feed_version': 'V8',
              'homepage_ver': 1,
              'ps': limit,
              'fresh_idx': page,
              'brush': page,
              'fresh_type': 4,
            },
          );
          final rows = jsonList(data['item']);
          return Success(
            PageSlice(
              items: _videos(rows, recommend: true),
              nextCursor: data['has_more'] == false || rows.isEmpty
                  ? null
                  : 'recommend:${page + 1}',
            ),
          );
        } on AppFailure catch (failure) {
          if (failure.kind != FailureKind.authentication &&
              failure.kind != FailureKind.permission) {
            rethrow;
          }
          // A fallback starts its own pagination chain; never mix feeds halfway.
          if (page != 1) rethrow;
        }
      }
      final data = await api.get(
        search
            ? '/x/web-interface/wbi/search/type'
            : '/x/web-interface/popular',
        cancellation,
        signed: search,
        forceRefresh: forceRefresh,
        query: search
            ? {
                'search_type': 'video',
                'keyword': query.trim(),
                'page': page,
                if (options.order != VideoOrder.relevance)
                  'order': options.order == VideoOrder.newest
                      ? 'pubdate'
                      : 'click',
                if (options.duration > 0 && options.duration <= 4)
                  'duration': options.duration,
              }
            : {'pn': page, 'ps': limit},
      );
      final raw = data[search ? 'result' : 'list'];
      final rows = raw == null && search ? <Object?>[] : jsonList(raw);
      final more = search
          ? page < jsonInteger(data['numPages'] ?? page)
          : data['no_more'] != true && data['no_more'] != 1 && rows.isNotEmpty;
      return Success(
        PageSlice(
          items: _videos(rows, search: search),
          nextCursor: more
              ? '${section == 'home' ? 'popular:' : ''}${page + 1}'
              : null,
          notice: section == 'home' ? '推荐暂不可用，正在显示热门内容' : null,
        ),
      );
    } catch (error) {
      return ResultFailure(safeApiFailure(error));
    }
  }

  Future<Result<PageSlice<VideoSummary>>> _curatedFeed(
    String section,
    String? cursor,
    int limit,
    bool refresh,
    CancellationSignal cancellation,
  ) async {
    if (limit < 1 || limit > 30) throw const FormatException('Page size');
    var number = 0, offset = 0;
    if (cursor != null) {
      final parts = cursor.split(':');
      if (parts.first != section ||
          parts.length != (section == 'weekly' ? 3 : 2)) {
        throw const FormatException('Feed cursor');
      }
      offset = int.parse(parts.last);
      if (section == 'weekly') number = int.parse(parts[1]);
      if (offset < 0 || (section == 'weekly' && number < 1)) {
        throw const FormatException('Feed cursor');
      }
    }
    if (section == 'weekly' && number == 0) {
      final series = await api.get(
        '/x/web-interface/popular/series/list',
        cancellation,
        signed: true,
        forceRefresh: refresh,
        query: {'web_location': 333.934},
      );
      for (final value in jsonList(series['list'])) {
        final candidate = jsonInteger(jsonObject(value)['number']);
        if (candidate > number) number = candidate;
      }
      if (number == 0) {
        return Success(PageSlice(items: const [], notice: '每周必看暂未更新'));
      }
    }
    final data = await api.get(
      section == 'weekly'
          ? '/x/web-interface/popular/series/one'
          : '/x/web-interface/ranking/v2',
      cancellation,
      signed: true,
      forceRefresh: refresh,
      query: section == 'weekly'
          ? {'number': number, 'web_location': 333.934}
          : {'rid': 0, 'type': 'all'},
    );
    final videos = _videos(jsonList(data['list']));
    final start = offset.clamp(0, videos.length);
    final end = (start + limit).clamp(0, videos.length);
    return Success(
      PageSlice(
        items: videos.sublist(start, end),
        nextCursor: end < videos.length
            ? section == 'weekly'
                  ? 'weekly:$number:$end'
                  : 'ranking:$end'
            : null,
        notice: section == 'weekly' ? '第 $number 期 · 每周必看' : '全站排行榜',
      ),
    );
  }

  @override
  Future<Result<VideoDetail>> getVideo(
    String id, {
    required String ownerKey,
    required CancellationSignal cancellation,
  }) async {
    try {
      if (cancellation.isCancelled) {
        throw const AppFailure(FailureKind.cancelled, '请求已取消');
      }
      api.checkOwner(ownerKey);
      final data = await api.get(
        '/x/web-interface/wbi/view',
        cancellation,
        signed: true,
        query: {'bvid': id},
      );
      final owner = jsonObject(data['owner']);
      final parts = jsonList(data['pages']).map((row) {
        final dto = BiliPartDto.fromJson(jsonObject(row));
        return VideoPart(
          id: '${dto.cid}',
          title: dto.part,
          durationSeconds: dto.duration,
        );
      }).toList();
      if (parts.isEmpty) {
        throw const AppFailure(FailureKind.unavailable, '此视频没有可播放的分集');
      }
      final detail = VideoDetail(
        video: mapVideo(BiliVideoDto.fromJson(data)),
        description: (data['desc'] as String?) ?? '',
        parts: parts,
        creatorId: owner['mid'] == null ? 0 : jsonInteger(owner['mid']),
        creatorAvatarUrl: owner['face'] is String
            ? coverUrl(owner['face']! as String)
            : null,
      );
      api.checkOwner(ownerKey);
      return Success(detail);
    } catch (error) {
      return ResultFailure(safeApiFailure(error));
    }
  }

  @override
  Future<Result<List<VideoSummary>>> getRelated(
    String id, {
    required String ownerKey,
    required CancellationSignal cancellation,
  }) async {
    try {
      api.checkOwner(ownerKey);
      final rows = await api.getList(
        '/x/web-interface/archive/related',
        cancellation,
        query: {'bvid': id},
      );
      return Success(_videos(rows).where((v) => v.id != id).take(20).toList());
    } catch (error) {
      return ResultFailure(safeApiFailure(error));
    }
  }
}

String plainTitle(String value) => value
    .replaceAll(RegExp('<[^>]*>'), '')
    .replaceAll('&amp;', '&')
    .replaceAll('&lt;', '<')
    .replaceAll('&gt;', '>')
    .replaceAll('&quot;', '"')
    .replaceAll('&#39;', "'")
    .replaceAll('&nbsp;', ' ');
