import '../../core/result.dart';
import '../../domain/discovery/content_search.dart';
import '../services/bilibili/bilibili_api.dart';
import '../services/bilibili/bilibili_dto.dart';
import 'bilibili_catalog_repository.dart' show plainTitle;

class BilibiliContentSearchRepository implements ContentSearchRepository {
  BilibiliContentSearchRepository(this.api);
  final BilibiliApi api;

  @override
  Future<Result<PageSlice<ContentSearchItem>>> search({
    required SearchCategory category,
    required String query,
    required String ownerKey,
    required CancellationSignal cancellation,
    String? cursor,
    bool forceRefresh = false,
  }) async {
    try {
      api.checkOwner(ownerKey);
      final wireType = switch (category) {
        SearchCategory.bangumi => 'media_bangumi',
        SearchCategory.cinema => 'media_ft',
        SearchCategory.live => 'live_room',
        SearchCategory.video => throw const FormatException(
          'Use video catalog',
        ),
      };
      final keyword = query.trim();
      if (keyword.isEmpty) return Success(PageSlice(items: const []));
      if (keyword.length > 100) throw const FormatException('Search keyword');
      var page = 1;
      if (cursor != null) {
        final parts = cursor.split(':');
        if (parts.length != 2 || parts.first != category.name) {
          throw const FormatException('Search cursor category');
        }
        page = int.parse(parts.last);
        if (page < 1 || page > 1000) throw const FormatException('Search page');
      }
      final data = await api.get(
        '/x/web-interface/wbi/search/type',
        cancellation,
        signed: true,
        forceRefresh: forceRefresh,
        query: {
          'search_type': wireType,
          'keyword': keyword,
          'page': page,
          'page_size': 20,
          'platform': 'pc',
        },
      );
      if (data['v_voucher'] != null) throw businessFailure(-352);
      final total = jsonInteger(data['numResults']);
      final pages = jsonInteger(data['numPages']);
      final raw = data['result'];
      if (total < 0 || pages < 0 || (raw == null && total != 0)) {
        throw const FormatException('Search result envelope');
      }
      final items = <ContentSearchItem>[];
      for (final row in jsonList(raw ?? const []).map(jsonObject)) {
        if (row['type'] != wireType) {
          throw const FormatException('Search result type');
        }
        String text(Object? value) =>
            value is String ? plainTitle(value).trim() : '';
        String id(Object? value) {
          final number = jsonInteger(value);
          if (number <= 0) throw const FormatException('Search target ID');
          return '$number';
        }

        final title = text(row['title']);
        if (title.isEmpty) throw const FormatException('Search title');
        if (category == SearchCategory.live) {
          items.add(
            ContentSearchItem.live(
              roomId: id(row['roomid']),
              title: title,
              subtitle: text(row['uname']),
              broadcasting: jsonInteger(row['live_status']) == 1,
              coverUrl: avatarUrl(
                row['user_cover'] ?? row['cover'] ?? row['pic'],
              ),
              avatarUrl: avatarUrl(row['uface']),
            ),
          );
        } else {
          final index = text(row['index_show']);
          final kind = text(row['season_type_name']);
          items.add(
            ContentSearchItem.season(
              seasonId: id(row['season_id']),
              title: title,
              subtitle: index.isNotEmpty
                  ? index
                  : kind.isNotEmpty
                  ? kind
                  : category.label,
              coverUrl: avatarUrl(row['cover']),
            ),
          );
        }
      }
      api.checkOwner(ownerKey);
      return Success(
        PageSlice(
          items: items,
          nextCursor: page < pages ? '${category.name}:${page + 1}' : null,
        ),
      );
    } catch (error) {
      return ResultFailure(safeApiFailure(error));
    }
  }
}
