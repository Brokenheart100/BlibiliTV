import 'package:mambatv/core/result.dart';
import 'package:mambatv/domain/discovery/content_search.dart';

class FakeContentSearchRepository implements ContentSearchRepository {
  final calls =
      <
        ({
          SearchCategory category,
          String query,
          String? cursor,
          bool refresh,
          CancellationSignal signal,
        })
      >[];
  @override
  Future<Result<PageSlice<ContentSearchItem>>> search({
    required SearchCategory category,
    required String query,
    required String ownerKey,
    required CancellationSignal cancellation,
    String? cursor,
    bool forceRefresh = false,
  }) async {
    calls.add((
      category: category,
      query: query,
      cursor: cursor,
      refresh: forceRefresh,
      signal: cancellation,
    ));
    final offset = cursor == null ? 0 : 20;
    return Success(
      PageSlice(
        items: List.generate(20, (index) {
          final id = '${10 + offset + index}';
          return category == SearchCategory.live
              ? ContentSearchItem.live(
                  roomId: id,
                  title: '$query 直播 $id',
                  subtitle: '合成主播',
                  broadcasting: index != 1,
                )
              : ContentSearchItem.season(
                  seasonId: id,
                  title: '$query ${category.label} $id',
                  subtitle: '全12集',
                );
        }),
        nextCursor: cursor == null ? '${category.name}:2' : null,
      ),
    );
  }
}
