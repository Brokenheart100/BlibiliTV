import '../../core/result.dart';
import '../../domain/entities/app_models.dart';
import '../../domain/library/library.dart';
import '../../domain/library/personal_home.dart';
import '../../domain/repositories/repositories.dart';
import '../services/bilibili/bilibili_api.dart';
import '../services/bilibili/bilibili_dto.dart';
import 'bilibili_catalog_repository.dart' show plainTitle;

class BilibiliPersonalHomeRepository implements PersonalHomeRepository {
  BilibiliPersonalHomeRepository(this.api, this.catalog, this.library);
  final BilibiliApi api;
  final CatalogRepository catalog;
  final LibraryRepository library;
  int _owner(String owner) {
    api.checkOwner(owner);
    if (!api.identity.session.isAuthenticated) {
      throw const AppFailure(FailureKind.authentication, '登录后查看你的内容');
    }
    final mid = int.tryParse(
      owner.startsWith('user:') ? owner.substring(5) : '',
    );
    if (mid == null || mid <= 0) throw const FormatException('Account');
    return mid;
  }

  String? _image(Object? raw) {
    if (raw is! String || raw.isEmpty) return null;
    final uri = Uri.tryParse(coverUrl(raw));
    return uri?.scheme == 'https' &&
            uri!.host.isNotEmpty &&
            uri.userInfo.isEmpty
        ? uri.toString()
        : null;
  }

  @override
  Future<Result<PersonalProfile>> profile(
    String ownerKey,
    CancellationSignal cancellation,
  ) async {
    try {
      final mid = _owner(ownerKey);
      final data = await api.get('/x/web-interface/nav', cancellation);
      if (data['isLogin'] != true) {
        throw const AppFailure(FailureKind.authentication, '登录已失效，请重新扫码');
      }
      if (jsonInteger(data['mid']) != mid) {
        throw const AppFailure(FailureKind.cancelled, '账号状态已变化');
      }
      _owner(ownerKey);
      return Success(
        PersonalProfile(
          mid: mid,
          name: plainTitle(data['uname'] as String? ?? '我的账号'),
          avatarUrl: _image(data['face']),
        ),
      );
    } catch (error) {
      return ResultFailure(safeApiFailure(error));
    }
  }

  @override
  Future<Result<PageSlice<PersonalItem>>> list({
    required String ownerKey,
    required PersonalSection section,
    String? folderId,
    String? cursor,
    required CancellationSignal cancellation,
  }) async {
    try {
      final mid = _owner(ownerKey);
      if (section == PersonalSection.submissions) {
        final page = (await catalog.fetchVideos(
          section: 'creator',
          ownerKey: ownerKey,
          options: CatalogOptions(creatorId: mid, order: VideoOrder.newest),
          cursor: cursor,
          cancellation: cancellation,
        )).valueOrThrow;
        _owner(ownerKey);
        return Success(
          PageSlice(
            items: page.items.map(PersonalVideo.new).toList(),
            nextCursor: page.nextCursor,
            notice: page.notice,
          ),
        );
      }
      if (section == PersonalSection.folders ||
          section == PersonalSection.watchLater) {
        final page = (await library.list(
          ownerKey: ownerKey,
          section: section == PersonalSection.watchLater
              ? LibrarySection.watchLater
              : folderId == null
              ? LibrarySection.folders
              : LibrarySection.folder,
          folderId: folderId,
          cursor: cursor,
          cancellation: cancellation,
        )).valueOrThrow;
        _owner(ownerKey);
        return Success(
          PageSlice(
            items: [
              for (final item in page.items)
                if (item.folderId != null)
                  PersonalFolder(
                    id: item.folderId!,
                    title: item.video.title,
                    count: item.count,
                    coverUrl: item.video.coverUrl,
                  )
                else
                  PersonalVideo(
                    item.video,
                    unavailableReason: item.unavailableReason,
                  ),
            ],
            nextCursor: page.nextCursor,
            notice: page.notice,
          ),
        );
      }
      var page = 1, seen = 0;
      if (cursor != null) {
        final parts = cursor.split(':');
        if (parts.length != 3 || parts.first != section.name) {
          throw const FormatException('Collection cursor');
        }
        page = int.parse(parts[1]);
        seen = int.parse(parts[2]);
        if (page < 1 || page > 100000 || seen < 0) {
          throw const FormatException('Collection cursor');
        }
      }
      final data = await api.get(
        '/x/space/bangumi/follow/list',
        cancellation,
        query: {
          'vmid': mid,
          'type': section == PersonalSection.bangumi ? 1 : 2,
          'pn': page,
        },
      );
      _owner(ownerKey);
      final rows = data['list'] == null ? <Object?>[] : jsonList(data['list']);
      final items = <PersonalItem>[];
      for (final raw in rows) {
        final row = jsonObject(raw);
        final id = jsonInteger(row['season_id']);
        if (id <= 0) continue;
        final episode = row['new_ep'] is Map
            ? jsonObject(row['new_ep'])
            : <String, Object?>{};
        items.add(
          PersonalSeason(
            id: id,
            title: plainTitle(row['title'] as String? ?? '未命名剧集'),
            subtitle: plainTitle(
              (episode['index_show'] ?? row['renewal_time'] ?? '') as String,
            ),
            coverUrl: _image(row['cover']),
            progress: plainTitle(row['progress'] as String? ?? ''),
            badge: plainTitle(row['badge'] as String? ?? ''),
          ),
        );
      }
      final consumed = seen + rows.length;
      final total = data['total'] == null ? null : jsonInteger(data['total']);
      return Success(
        PageSlice(
          items: items,
          nextCursor: rows.isNotEmpty && (total == null || consumed < total)
              ? '${section.name}:${page + 1}:$consumed'
              : null,
        ),
      );
    } catch (error) {
      return ResultFailure(safeApiFailure(error));
    }
  }
}
