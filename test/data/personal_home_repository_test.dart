import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mambatv/core/result.dart';
import 'package:mambatv/data/repositories/bilibili_personal_home_repository.dart';
import 'package:mambatv/data/repositories/fake_catalog_repository.dart';
import 'package:mambatv/data/services/auth/request_identity.dart';
import 'package:mambatv/data/services/bilibili/bilibili_api.dart';
import 'package:mambatv/domain/entities/app_models.dart';
import 'package:mambatv/domain/library/library.dart';
import 'package:mambatv/domain/library/personal_home.dart';

import '../support/fake_library.dart';

class OwnCatalog extends FakeCatalogRepository {
  int? requestedMid;
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
    requestedMid = options.creatorId;
    return Success(PageSlice(items: [libraryVideo('BVown')], nextCursor: '2'));
  }
}

void main() {
  late Dio dio;
  late BilibiliApi api;
  late BilibiliPersonalHomeRepository repository;
  late OwnCatalog catalog;
  late FakeLibraryRepository library;
  final calls = <RequestOptions>[];
  Map<String, Object?> data = {};
  setUp(() {
    calls.clear();
    dio = Dio();
    api = BilibiliApi(
      dio,
      identity: const RequestIdentity(
        Session(ownerKey: 'user:7', status: SessionStatus.authenticated),
      ),
    );
    catalog = OwnCatalog();
    library = FakeLibraryRepository();
    repository = BilibiliPersonalHomeRepository(api, catalog, library);
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (request, handler) {
          calls.add(request);
          handler.resolve(
            Response<Object?>(
              requestOptions: request,
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
  test(
    'own profile validates identity and upgrades the avatar to HTTPS',
    () async {
      data = {
        'isLogin': true,
        'mid': 7,
        'uname': '测试账号',
        'face': 'http://i0.hdslb.com/face.jpg',
      };
      final profile = (await repository.profile(
        'user:7',
        CancellationSignal(),
      )).valueOrThrow;
      expect(profile.avatarUrl, 'https://i0.hdslb.com/face.jpg');
      expect(profile.name, '测试账号');
      expect(calls.single.path, endsWith('/nav'));
      data['mid'] = 8;
      expect(
        await repository.profile('user:7', CancellationSignal()),
        isA<ResultFailure<PersonalProfile>>(),
      );
      final count = calls.length;
      expect(
        await repository.profile('user:8', CancellationSignal()),
        isA<ResultFailure<PersonalProfile>>(),
      );
      expect(calls, hasLength(count));
    },
  );
  test('submissions and folders reuse account-scoped repositories', () async {
    final videos = (await repository.list(
      ownerKey: 'user:7',
      section: PersonalSection.submissions,
      cancellation: CancellationSignal(),
    )).valueOrThrow;
    expect(catalog.requestedMid, 7);
    expect(videos.items.single, isA<PersonalVideo>());
    library.pages['first'] = PageSlice(
      items: [
        LibraryEntry(
          key: 'folder:9',
          folderId: '9',
          count: 3,
          video: libraryVideo(''),
        ),
      ],
    );
    final folders = (await repository.list(
      ownerKey: 'user:7',
      section: PersonalSection.folders,
      cancellation: CancellationSignal(),
    )).valueOrThrow;
    expect((folders.items.single as PersonalFolder).count, 3);
    expect(library.calls.last.$2, LibrarySection.folders);
    expect(calls, isEmpty);
    expect(library.writes, 0);
  });
  test(
    'followed anime and drama retain season types and separate pagination',
    () async {
      data = {
        'total': 3,
        'list': [
          {
            'season_id': 101,
            'title': '测试番剧',
            'cover': '//i0.hdslb.com/poster.jpg',
            'badge': '会员',
            'progress': '看到第 2 话',
            'new_ep': {'index_show': '更新至第 5 话'},
          },
          {'season_id': 102, 'title': '另一个番剧', 'new_ep': null},
        ],
      };
      final anime = (await repository.list(
        ownerKey: 'user:7',
        section: PersonalSection.bangumi,
        cancellation: CancellationSignal(),
      )).valueOrThrow;
      expect(calls.last.queryParameters['vmid'], 7);
      expect(calls.last.queryParameters['type'], 1);
      expect(anime.nextCursor, 'bangumi:2:2');
      final item = anime.items.first as PersonalSeason;
      expect(item.progress, '看到第 2 话');
      expect(item.subtitle, '更新至第 5 话');
      expect(item.coverUrl, startsWith('https:'));
      final count = calls.length;
      expect(
        await repository.list(
          ownerKey: 'user:7',
          section: PersonalSection.drama,
          cursor: anime.nextCursor,
          cancellation: CancellationSignal(),
        ),
        isA<ResultFailure<PageSlice<PersonalItem>>>(),
      );
      expect(calls, hasLength(count));
      data = {
        'total': 3,
        'list': [
          {'season_id': 103, 'title': '最后一个番剧'},
        ],
      };
      final second = (await repository.list(
        ownerKey: 'user:7',
        section: PersonalSection.bangumi,
        cursor: anime.nextCursor,
        cancellation: CancellationSignal(),
      )).valueOrThrow;
      expect(second.nextCursor, isNull);
      expect(calls.last.queryParameters['pn'], 2);
      await repository.list(
        ownerKey: 'user:7',
        section: PersonalSection.drama,
        cancellation: CancellationSignal(),
      );
      expect(calls.last.queryParameters['type'], 2);
      expect(api.remoteWriteRequestsSent, 0);
    },
  );
}
