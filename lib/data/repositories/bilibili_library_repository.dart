import 'dart:convert';

import '../../core/result.dart';
import '../../domain/entities/app_models.dart';
import '../../domain/library/library.dart';
import '../services/bilibili/bilibili_api.dart';
import '../services/bilibili/bilibili_dto.dart';

class BilibiliLibraryRepository implements LibraryRepository {
  BilibiliLibraryRepository(this.api);
  final BilibiliApi api;
  final _busy = <int>{};
  final _pending = <String, bool>{};
  void _check(String owner) {
    api.checkOwner(owner);
    if (!api.identity.session.isAuthenticated) {
      throw const AppFailure(FailureKind.authentication, '请先扫码登录后查看账号列表');
    }
  }

  int _int(Object? value, [int fallback = 0]) =>
      value == null ? fallback : jsonInteger(value);
  List<Object?> _rows(Object? value) => value == null ? [] : jsonList(value);
  String? _cover(Object? value) {
    if (value is! String || value.isEmpty) return null;
    final uri = Uri.tryParse(coverUrl(value));
    return uri?.scheme == 'https' && uri!.userInfo.isEmpty
        ? uri.toString()
        : null;
  }

  LibraryEntry _video(Map<String, Object?> row, {bool history = false}) {
    final h = history ? jsonObject(row['history']) : row;
    final id = (h['bvid'] as String?) ?? '';
    final oid = _int(h['oid'] ?? row['id'] ?? row['aid']);
    final owner = row['owner'] is Map
        ? jsonObject(row['owner'])
        : row['upper'] is Map
        ? jsonObject(row['upper'])
        : <String, Object?>{};
    final seconds = _int(row['duration']);
    final position = _int(row['progress']);
    return LibraryEntry(
      key: id.isEmpty ? 'unavailable:$oid' : id,
      video: VideoSummary(
        id: id,
        title: row['title'] as String? ?? '不可用视频',
        creator: (row['author_name'] ?? owner['name'] ?? '') as String,
        creatorAvatarUrl: avatarUrl(row['author_face'] ?? owner['face']),
        durationSeconds: seconds,
        viewCount: 0,
        coverUrl: _cover(row['cover'] ?? row['pic']),
      ),
      partId: h['cid'] == null || _int(h['cid']) <= 0 ? null : '${h['cid']}',
      position: Duration(
        seconds: position < 0 ? seconds : position.clamp(0, seconds),
      ),
      updatedAt: row['view_at'] == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(_int(row['view_at']) * 1000),
      unavailableReason:
          !id.startsWith('BV') || (history && h['business'] != 'archive')
          ? '此内容暂不支持播放'
          : null,
    );
  }

  @override
  Future<Result<PageSlice<LibraryEntry>>> list({
    required String ownerKey,
    required LibrarySection section,
    String? folderId,
    String? cursor,
    required CancellationSignal cancellation,
  }) async {
    try {
      _check(ownerKey);
      final page = section == LibrarySection.remote
          ? 1
          : int.parse(cursor ?? '1');
      if (page < 1 || page > 100000) throw const FormatException('Page');
      late Map<String, Object?> data;
      late List<Object?> rows;
      String? next;
      if (section == LibrarySection.remote) {
        final c = cursor == null
            ? <String, Object?>{}
            : jsonObject(jsonDecode(cursor));
        data = await api.get(
          '/x/web-interface/history/cursor',
          cancellation,
          query: {
            'type': 'archive',
            'ps': 24,
            'max': _int(c['max']),
            'view_at': _int(c['view_at']),
            if (c['business'] is String) 'business': c['business']! as String,
          },
        );
        rows = _rows(data['list']);
        if (rows.isNotEmpty) {
          final last = jsonObject(rows.last),
              h = jsonObject(jsonObject(rows.last)['history']);
          next = jsonEncode({
            'max': _int(h['oid']),
            'view_at': _int(last['view_at']),
            'business': h['business'] ?? 'archive',
          });
          if (next == cursor) next = null;
        }
      } else if (section == LibrarySection.folders) {
        data = await api.get(
          '/x/v3/fav/folder/created/list',
          cancellation,
          query: {
            'up_mid': int.parse(ownerKey.substring(5)),
            'pn': page,
            'ps': 24,
          },
        );
        rows = _rows(data['list']);
        if (data['has_more'] == true) next = '${page + 1}';
        _check(ownerKey);
        return Success(
          PageSlice(
            items: [
              for (final item in rows)
                LibraryEntry(
                  key: 'folder:${_int(jsonObject(item)['id'])}',
                  folderId: '${_int(jsonObject(item)['id'])}',
                  count: _int(jsonObject(item)['media_count']),
                  video: VideoSummary(
                    id: '',
                    title: jsonObject(item)['title'] as String? ?? '收藏夹',
                    creator: '收藏夹',
                    durationSeconds: 0,
                    viewCount: 0,
                    coverUrl: _cover(jsonObject(item)['cover']),
                  ),
                ),
            ],
            nextCursor: next,
          ),
        );
      } else if (section == LibrarySection.folder) {
        data = await api.get(
          '/x/v3/fav/resource/list',
          cancellation,
          query: {
            'media_id': int.parse(folderId!),
            'pn': page,
            'ps': 24,
            'order': 'mtime',
            'type': 0,
            'tid': 0,
            'platform': 'web',
          },
        );
        rows = _rows(data['medias']);
        if (data['has_more'] == true) next = '${page + 1}';
      } else if (section == LibrarySection.watchLater) {
        data = await api.get(
          '/x/v2/history/toview/web',
          cancellation,
          signed: true,
          query: {
            'pn': page,
            'ps': 24,
            'viewed': 0,
            'key': '',
            'asc': false,
            'need_split': true,
            'web_location': '333.881',
          },
        );
        rows = _rows(data['list']);
        if (rows.isNotEmpty && _int(data['count']) > page * 24) {
          next = '${page + 1}';
        }
      } else {
        throw const FormatException('Section');
      }
      _check(ownerKey);
      return Success(
        PageSlice(
          items: rows
              .map(
                (v) => _video(
                  jsonObject(v),
                  history: section == LibrarySection.remote,
                ),
              )
              .toList(),
          nextCursor: next,
        ),
      );
    } catch (error) {
      return ResultFailure(safeApiFailure(error));
    }
  }

  @override
  Future<Result<LibraryMembership>> membership({
    required String ownerKey,
    required String videoId,
    required int aid,
    required CancellationSignal cancellation,
  }) async {
    try {
      _check(ownerKey);
      if (aid <= 0) {
        final view = await api.get(
          '/x/web-interface/wbi/view',
          cancellation,
          signed: true,
          query: {'bvid': videoId},
        );
        aid = jsonInteger(view['aid']);
      }
      final folders = await api.get(
        '/x/v3/fav/folder/created/list-all',
        cancellation,
        query: {
          'up_mid': int.parse(ownerKey.substring(5)),
          'rid': aid,
          'type': 2,
        },
      );
      final later = await api.get('/x/v2/history/toview', cancellation);
      final folderRows = _rows(folders['list']);
      final laterRows = _rows(later['list']);
      final selected = laterRows.any(
        (v) =>
            jsonObject(v)['bvid'] == videoId ||
            _int(jsonObject(v)['aid']) == aid,
      );
      if (_int(folders['count']) > folderRows.length ||
          (!selected && _int(later['count']) > laterRows.length)) {
        throw const AppFailure(FailureKind.contract, '账号列表不完整，暂时无法确认操作状态');
      }
      _check(ownerKey);
      return Success(
        LibraryMembership(
          aid: aid,
          watchLater: selected,
          folders: [
            for (final value in folderRows)
              FavouriteFolder(
                '${jsonObject(value)['id']}',
                jsonObject(value)['title'] as String? ?? '收藏夹',
                selected: _int(jsonObject(value)['fav_state']) == 1,
              ),
          ],
        ),
      );
    } catch (error) {
      return ResultFailure(safeApiFailure(error));
    }
  }

  bool _selected(LibraryMembership value, String? folderId) => folderId == null
      ? value.watchLater
      : value.folders.any((f) => f.id == folderId && f.selected);
  @override
  Future<Result<LibraryWriteResult>> change({
    required String ownerKey,
    required String videoId,
    required int aid,
    String? folderId,
    required bool desired,
    required CancellationSignal cancellation,
  }) async {
    if (!_busy.add(aid)) {
      return const ResultFailure(
        AppFailure(FailureKind.unavailable, '操作正在处理中，请等待'),
      );
    }
    final key = '$aid:${folderId ?? 'later'}';
    try {
      _check(ownerKey);
      if (const bool.fromEnvironment('MAMBA_READ_ONLY_VALIDATION')) {
        throw const AppFailure(FailureKind.permission, '本次只读验收不执行账号变更');
      }
      final before = (await membership(
        ownerKey: ownerKey,
        videoId: videoId,
        aid: aid,
        cancellation: cancellation,
      )).valueOrThrow;
      if (_pending.containsKey(key)) {
        if (_selected(before, folderId) != _pending[key]) {
          return Success(
            LibraryWriteResult(
              WriteStatus.uncertain,
              '上次结果仍待确认，请稍后重新检查',
              pendingDesired: _pending[key],
              pendingFolder: folderId,
            ),
          );
        }
        _pending.remove(key);
      }
      if (folderId != null && !before.folders.any((f) => f.id == folderId)) {
        throw const AppFailure(FailureKind.permission, '收藏夹已不可用，请刷新列表');
      }
      if (_selected(before, folderId) == desired) {
        return const Success(
          LibraryWriteResult(WriteStatus.confirmed, '已确认当前状态'),
        );
      }
      _pending[key] = desired;
      try {
        if (folderId == null) {
          await api.postForm(
            desired
                ? '/x/v2/history/toview/add'
                : '/x/v2/history/toview/v2/dels',
            desired ? {'bvid': videoId} : {'resources': '$aid'},
            cancellation,
          );
        } else {
          await api.postForm('/x/v3/fav/resource/batch-deal', {
            'resources': '$aid:2',
            'add_media_ids': desired ? folderId : '',
            'del_media_ids': desired ? '' : folderId,
          }, cancellation);
        }
      } on AppFailure catch (failure) {
        if ({
          FailureKind.authentication,
          FailureKind.permission,
          FailureKind.rateLimited,
        }.contains(failure.kind)) {
          _pending.remove(key);
          return ResultFailure(failure);
        }
      } catch (_) {
        /* A lost response does not authorize replaying this POST. */
      }
      final after = await membership(
        ownerKey: ownerKey,
        videoId: videoId,
        aid: aid,
        cancellation: cancellation,
      );
      if (after is Success<LibraryMembership> &&
          _selected(after.value, folderId) == desired) {
        _pending.remove(key);
        return const Success(
          LibraryWriteResult(WriteStatus.confirmed, '已读取并确认最新状态'),
        );
      }
      return Success(
        LibraryWriteResult(
          WriteStatus.uncertain,
          '操作结果尚未确认，请稍后重新检查；不会重复提交',
          pendingDesired: desired,
          pendingFolder: folderId,
        ),
      );
    } catch (error) {
      return ResultFailure(safeApiFailure(error));
    } finally {
      _busy.remove(aid);
    }
  }

  @override
  Future<Result<void>> heartbeat({
    required String ownerKey,
    required String videoId,
    required String partId,
    required int seconds,
    required CancellationSignal cancellation,
  }) async {
    try {
      _check(ownerKey);
      await api.postForm('/x/click-interface/web/heartbeat', {
        'bvid': videoId,
        'cid': int.parse(partId),
        'played_time': seconds,
        'type': 3,
      }, cancellation);
      return const Success(null);
    } catch (error) {
      return ResultFailure(safeApiFailure(error));
    }
  }
}
