import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mambatv/core/result.dart';
import 'package:mambatv/data/repositories/bilibili_library_repository.dart';
import 'package:mambatv/data/services/auth/request_identity.dart';
import 'package:mambatv/data/services/bilibili/bilibili_api.dart';
import 'package:mambatv/domain/entities/app_models.dart';
import 'package:mambatv/domain/library/library.dart';

void main() {
  late Dio dio;
  late BilibiliApi api;
  late BilibiliLibraryRepository repo;
  final calls = <RequestOptions>[];
  var later = false, favorite = false, count = 0;
  var loseResponse = false, commitWrite = true;
  Map<String, Object?> Function(RequestOptions)? custom;
  setUp(() {
    calls.clear();
    later = false;
    favorite = false;
    count = 0;
    loseResponse = false;
    commitWrite = true;
    custom = null;
    dio = Dio();
    api = BilibiliApi(
      dio,
      identity: const RequestIdentity(
        Session(ownerKey: 'user:101', status: SessionStatus.authenticated),
        'SESSDATA=synthetic; bili_jct=synthetic-csrf',
      ),
    );
    repo = BilibiliLibraryRepository(api);
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (o, h) {
          calls.add(o);
          if (o.method == 'POST') {
            if (commitWrite) {
              final data = o.data as Map;
              if (o.path.endsWith('/add')) later = true;
              if (o.path.endsWith('/dels')) later = false;
              if (o.path.endsWith('/batch-deal')) {
                favorite = data['add_media_ids'] != '';
              }
            }
            if (loseResponse) {
              h.reject(
                DioException(
                  requestOptions: o,
                  type: DioExceptionType.receiveTimeout,
                ),
              );
              return;
            }
          }
          final Map<String, Object?> data;
          if (o.path.endsWith('/nav')) {
            data = {
              'wbi_img': {
                'img_url': 'https://example.invalid/${'a' * 32}.png',
                'sub_url': 'https://example.invalid/${'b' * 32}.png',
              },
            };
          } else if (o.path.endsWith('/list-all')) {
            data = {
              'count': 1,
              'list': [
                {'id': 9, 'title': '合成收藏夹', 'fav_state': favorite ? 1 : 0},
              ],
            };
          } else if (o.path.endsWith('/toview')) {
            data = {
              'count': count > 0
                  ? count
                  : later
                  ? 1
                  : 0,
              'list': [
                if (later) {'aid': 7, 'bvid': 'BVtest'},
              ],
            };
          } else {
            data = custom?.call(o) ?? {};
          }
          h.resolve(
            Response<Object?>(
              requestOptions: o,
              statusCode: 200,
              data: {'code': 0, 'data': data},
            ),
          );
        },
      ),
    );
    addTearDown(() {
      api.close();
      dio.close(force: true);
    });
  });
  Future<LibraryWriteResult> change(bool desired, {String? folder}) async =>
      (await repo.change(
        ownerKey: 'user:101',
        videoId: 'BVtest',
        aid: 7,
        folderId: folder,
        desired: desired,
        cancellation: CancellationSignal(),
      )).valueOrThrow;
  Future<PageSlice<LibraryEntry>> list(
    LibrarySection section, {
    String? cursor,
    String? folder,
  }) async => (await repo.list(
    ownerKey: 'user:101',
    section: section,
    cursor: cursor,
    folderId: folder,
    cancellation: CancellationSignal(),
  )).valueOrThrow;
  test('history keeps unsupported rows visible and advances using the last raw history cursor', () async {
    custom = (_) => {
      'list': [
        {
          'title': '合成视频',
          'duration': 90,
          'progress': 20,
          'view_at': 100,
          'history': {
            'bvid': 'BVtest',
            'oid': 7,
            'cid': 11,
            'business': 'archive',
          },
        },
        {
          'title': '暂不支持',
          'duration': 30,
          'progress': -1,
          'view_at': 99,
          'history': {'oid': 8, 'business': 'pgc'},
        },
      ],
    };
    final first = await list(LibrarySection.remote);
    expect(first.items.first.position.inSeconds, 20);
    expect(first.items.last.unavailableReason, isNotNull);
    final second = await list(LibrarySection.remote, cursor: first.nextCursor);
    expect(calls.last.queryParameters['max'], 8);
    expect(calls.last.queryParameters['business'], 'pgc');
    expect(second.nextCursor, isNull);
    expect(api.remoteWriteRequestsSent, 0);
  });
  test(
    'folders, folder media and watchlater use independent pagination contracts',
    () async {
      custom = (o) {
        if (o.path.endsWith('/created/list')) {
          return {
            'has_more': true,
            'list': [
              {'id': 9, 'title': '合成收藏夹', 'media_count': 3},
            ],
          };
        }
        if (o.path.endsWith('/resource/list')) {
          return {
            'has_more': false,
            'medias': [
              {'bvid': 'BVtest', 'title': '视频', 'duration': 10},
            ],
          };
        }
        return {
          'count': 25,
          'list': [
            {'bvid': 'BVtest', 'title': '稍后', 'duration': 10},
          ],
        };
      };
      expect((await list(LibrarySection.folders)).items.single.folderId, '9');
      expect(calls.last.queryParameters['up_mid'], 101);
      expect(
        (await list(LibrarySection.folder, folder: '9')).nextCursor,
        isNull,
      );
      expect(calls.last.queryParameters['media_id'], 9);
      expect((await list(LibrarySection.watchLater)).nextCursor, '2');
      expect(calls.last.queryParameters['w_rid'], isNotNull);
      expect(calls.last.queryParameters['ps'], '24');
    },
  );
  test(
    'watchlater and favorite writes send one CSRF form then reconcile by reads',
    () async {
      expect((await change(true)).status, WriteStatus.confirmed);
      var post = calls.singleWhere((o) => o.method == 'POST');
      expect(post.data, {'bvid': 'BVtest', 'csrf': 'synthetic-csrf'});
      expect(post.contentType, Headers.formUrlEncodedContentType);
      await change(true);
      expect(
        api.remoteWriteRequestsSent,
        1,
        reason: 'Already selected is read-only',
      );
      await change(false);
      post = calls.lastWhere((o) => o.method == 'POST');
      expect((post.data as Map)['resources'], '7');
      await change(true, folder: '9');
      post = calls.lastWhere((o) => o.method == 'POST');
      expect(post.data, {
        'resources': '7:2',
        'add_media_ids': '9',
        'del_media_ids': '',
        'csrf': 'synthetic-csrf',
      });
      await change(false, folder: '9');
      expect(
        (calls.lastWhere((o) => o.method == 'POST').data
            as Map)['del_media_ids'],
        '9',
      );
      expect(api.remoteWriteRequestsSent, 4);
    },
  );
  test(
    'a lost response with confirmed server state never replays the POST',
    () async {
      loseResponse = true;
      expect((await change(true)).status, WriteStatus.confirmed);
      expect(api.remoteWriteRequestsSent, 1);
      expect(calls.where((o) => o.path.endsWith('/toview')).length, 2);
    },
  );
  test(
    'uncertain write retains its original intention across new dialog commands',
    () async {
      loseResponse = true;
      commitWrite = false;
      expect((await change(true)).status, WriteStatus.uncertain);
      final opposite = await change(false);
      expect(opposite.status, WriteStatus.uncertain);
      expect(opposite.pendingDesired, true);
      expect(api.remoteWriteRequestsSent, 1);
      later = true;
      expect((await change(true)).status, WriteStatus.confirmed);
      expect(api.remoteWriteRequestsSent, 1);
    },
  );
  test(
    'incomplete membership cannot authorize a write based on assumed absence',
    () async {
      count = 2;
      final result = await repo.change(
        ownerKey: 'user:101',
        videoId: 'BVtest',
        aid: 7,
        desired: true,
        cancellation: CancellationSignal(),
      );
      expect((result as ResultFailure).failure.kind, FailureKind.contract);
      expect(api.remoteWriteRequestsSent, 0);
    },
  );
  test(
    'owner mismatch and cancelled scope cannot read or mutate another account',
    () async {
      final result = await repo.list(
        ownerKey: 'user:202',
        section: LibrarySection.remote,
        cancellation: CancellationSignal(),
      );
      expect((result as ResultFailure).failure.kind, FailureKind.cancelled);
      api.close();
      final changeResult = await repo.change(
        ownerKey: 'user:101',
        videoId: 'BVtest',
        aid: 7,
        desired: true,
        cancellation: CancellationSignal(),
      );
      expect(changeResult, isA<ResultFailure<LibraryWriteResult>>());
      expect(calls, isEmpty);
    },
  );
  test(
    'heartbeat sends the validated part and elapsed media seconds once',
    () async {
      await repo.heartbeat(
        ownerKey: 'user:101',
        videoId: 'BVtest',
        partId: '11',
        seconds: 42,
        cancellation: CancellationSignal(),
      );
      expect(calls.single.data, {
        'bvid': 'BVtest',
        'cid': 11,
        'played_time': 42,
        'type': 3,
        'csrf': 'synthetic-csrf',
      });
      expect(api.remoteWriteRequestsSent, 1);
    },
  );
}
