import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mambatv/core/result.dart';
import 'package:mambatv/data/repositories/bilibili_content_search_repository.dart';
import 'package:mambatv/data/services/bilibili/bilibili_api.dart';
import 'package:mambatv/domain/discovery/content_search.dart';

void main() {
  late Dio dio;
  late BilibiliApi api;
  late BilibiliContentSearchRepository repository;
  late Map<String, Object?> data;
  final requests = <RequestOptions>[];
  setUp(() {
    requests.clear();
    dio = Dio();
    api = BilibiliApi(dio);
    repository = BilibiliContentSearchRepository(api);
    data = {'numPages': 2, 'numResults': 21, 'result': <Object?>[]};
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (request, handler) {
          requests.add(request);
          handler.resolve(
            Response<Object?>(
              requestOptions: request,
              statusCode: 200,
              data: {
                'code': 0,
                'data': request.path.endsWith('/nav')
                    ? {
                        'wbi_img': {
                          'img_url': 'https://i0.hdslb.com/bfs/wbi/7cd084941338484aae1ad9425b84077c.png',
                          'sub_url': 'https://i0.hdslb.com/bfs/wbi/4932caff0ff746eab6f01bf08b70ac45.png',
                        },
                      }
                    : data,
              },
            ),
          );
        },
      ),
    );
  });
  tearDown(() {
    api.close();
    dio.close(force: true);
  });
  Future<Result<PageSlice<ContentSearchItem>>> search(
    SearchCategory category, {
    String? cursor,
    String owner = 'guest',
    String query = '测试',
  }) => repository.search(
    category: category,
    query: query,
    ownerKey: owner,
    cancellation: CancellationSignal(),
    cursor: cursor,
  );
  for (final pair in {
    SearchCategory.bangumi: 'media_bangumi',
    SearchCategory.cinema: 'media_ft',
  }.entries) {
    test(
      '${pair.key.name} preserves season identity, HTML text and pagination',
      () async {
        data['result'] = [
          {
            'type': pair.value,
            'media_id': 999,
            'season_id': 10,
            'title': '<em class="keyword">测试</em> &amp; 正片',
            'index_show': '全12话',
            'cover': '//i0.hdslb.com/test.png',
          },
        ];
        final page = (await search(pair.key)).valueOrThrow;
        expect(
          page.items.single,
          const ContentSearchItem.season(
            seasonId: '10',
            title: '测试 & 正片',
            subtitle: '全12话',
            coverUrl: 'https://i0.hdslb.com/test.png',
          ),
        );
        expect(page.nextCursor, '${pair.key.name}:2');
        final request = requests.last;
        expect(request.queryParameters['search_type'], pair.value);
        expect(request.queryParameters['w_rid'], isNotEmpty);
        expect(request.queryParameters.containsKey('duration'), false);
        expect(request.queryParameters.containsKey('order'), false);
        await search(pair.key, cursor: page.nextCursor);
        expect(requests.last.queryParameters['page'], '2');
      },
    );
  }
  test(
    'live uses roomid rather than unrelated id, status and anchor avatar',
    () async {
      data['result'] = [
        {
          'type': 'live_room',
          'id': 999,
          'roomid': 42,
          'title': '<em>房间</em>',
          'uname': '主播',
          'live_status': 0,
          'uface': '//i0.hdslb.com/face.png',
          'cover': '//i0.hdslb.com/room.png',
        },
      ];
      final item =
          (await search(SearchCategory.live)).valueOrThrow.items.single
              as LiveSearchItem;
      expect(item.roomId, '42');
      expect(item.broadcasting, false);
      expect(item.avatarUrl, 'https://i0.hdslb.com/face.png');
      expect(requests.last.uri.host, 'api.bilibili.com');
      expect(requests.last.queryParameters['search_type'], 'live_room');
    },
  );
  test(
    'missing results is a genuine empty only when the envelope reports zero',
    () async {
      data = {'numPages': 0, 'numResults': 0};
      expect((await search(SearchCategory.cinema)).valueOrThrow.items, isEmpty);
      data = {'numPages': 1, 'numResults': 1};
      expect(
        await search(SearchCategory.cinema),
        isA<ResultFailure<PageSlice<ContentSearchItem>>>(),
      );
    },
  );
  test(
    'code-zero risk challenge is a failure rather than an empty result',
    () async {
      data = {'v_voucher': 'synthetic-challenge'};
      final result = await search(SearchCategory.live) as ResultFailure;
      expect(result.failure.kind, FailureKind.rateLimited);
    },
  );
  test(
    'foreign cursor, wrong owner, empty query and video issue no searches',
    () async {
      expect(
        await search(SearchCategory.bangumi, cursor: 'cinema:2'),
        isA<ResultFailure<PageSlice<ContentSearchItem>>>(),
      );
      expect(
        await search(SearchCategory.live, owner: 'other'),
        isA<ResultFailure<PageSlice<ContentSearchItem>>>(),
      );
      expect(
        (await search(SearchCategory.live, query: ' ')).valueOrThrow.items,
        isEmpty,
      );
      expect(
        await search(SearchCategory.video),
        isA<ResultFailure<PageSlice<ContentSearchItem>>>(),
      );
      expect(requests, isEmpty);
    },
  );
  test(
    'malformed identity or unexpected content kind cannot become a route',
    () async {
      for (final row in [
        {'type': 'media_ft', 'season_id': 0, 'title': 'bad'},
        {'type': 'video', 'season_id': 10, 'title': 'wrong type'},
      ]) {
        data['result'] = [row];
        expect(
          await search(SearchCategory.cinema),
          isA<ResultFailure<PageSlice<ContentSearchItem>>>(),
        );
      }
    },
  );
}
