import '../../core/result.dart';
import '../../domain/entities/app_models.dart';
import '../../domain/repositories/repositories.dart';

/// Explicit M1 demo data. No Bilibili or playback capabilities are simulated.
class FakeCatalogRepository implements CatalogRepository {
  FakeCatalogRepository({this.latency = const Duration(milliseconds: 220)});
  final Duration latency;
  @override
  Future<Result<List<VideoSummary>>> getRelated(
    String id, {
    required String ownerKey,
    required CancellationSignal cancellation,
  }) async => Success(videos.where((v) => v.id != id).take(6).toList());
  static const titles = [
    '山海之间 · 航拍旅行',
    '一碗热汤面的周末',
    '城市散步计划',
    'Flutter 从第一帧开始',
    '星空下的露营夜',
    '记录生活的光',
    '书房里的慢时光',
    '认识一座博物馆',
  ];
  static const creators = [
    '山海记录',
    '厨房小记',
    '步行的人',
    '代码放映室',
    '野外日记',
    '生活观察员',
    '读书时间',
    '文化漫游',
  ];
  static final videos = List<VideoSummary>.unmodifiable(
    List.generate(
      72,
      (i) => VideoSummary(
        id: 'demo-${i.toString().padLeft(3, '0')}',
        title: '${titles[i % titles.length]} ${i ~/ titles.length + 1}',
        creator: creators[i % creators.length],
        durationSeconds: 180 + i * 37,
        viewCount: 18000 + i * 9531,
      ),
    ),
  );

  @override
  Future<Result<PageSlice<VideoSummary>>> fetchVideos({
    required String section,
    required String ownerKey,
    String query = '',
    String? cursor,
    int limit = 12,
    required CancellationSignal cancellation,
  }) async {
    if (latency > Duration.zero) await Future<void>.delayed(latency);
    if (cancellation.isCancelled) {
      return const ResultFailure(AppFailure(FailureKind.cancelled, '请求已取消'));
    }
    final source = section == 'library' && ownerKey == 'guest'
        ? <VideoSummary>[]
        : videos;
    final filtered = source
        .where(
          (v) =>
              query.isEmpty ||
              '${v.title} ${v.creator}'.toLowerCase().contains(
                query.trim().toLowerCase(),
              ),
        )
        .toList();
    final offset = int.tryParse(cursor ?? '0');
    if (offset == null || offset < 0 || limit < 1) {
      return const ResultFailure(AppFailure(FailureKind.unknown, '分页参数无效'));
    }
    final end = (offset + limit).clamp(0, filtered.length);
    return Success(
      PageSlice(
        items: offset >= filtered.length ? [] : filtered.sublist(offset, end),
        nextCursor: end < filtered.length ? '$end' : null,
      ),
    );
  }

  @override
  Future<Result<VideoDetail>> getVideo(
    String id, {
    required String ownerKey,
    required CancellationSignal cancellation,
  }) async {
    if (latency > Duration.zero) await Future<void>.delayed(latency);
    if (cancellation.isCancelled) {
      return const ResultFailure(AppFailure(FailureKind.cancelled, '请求已取消'));
    }
    final matches = videos.where((v) => v.id == id);
    if (matches.isEmpty) {
      return const ResultFailure(
        AppFailure(FailureKind.unavailable, '未找到这个演示视频'),
      );
    }
    return Success(
      VideoDetail(
        video: matches.first,
        parts: [
          VideoPart(id: '$id-p1', title: '第一集 · 出发'),
          VideoPart(id: '$id-p2', title: '第二集 · 继续探索'),
        ],
        description: '这是一条演示内容，用于预览电视上的浏览、选集与返回体验。当前没有连接真实播放源。',
      ),
    );
  }
}
