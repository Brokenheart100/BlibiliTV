import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mambatv/core/result.dart';
import 'package:mambatv/data/repositories/bilibili_catalog_repository.dart';
import 'package:mambatv/data/services/bilibili/bilibili_api.dart';
import 'package:mambatv/data/services/bilibili/bilibili_dto.dart';

void main() {
  test('creator images support search rows and reject malformed images', () {
    expect(
      avatarUrl('http://example.invalid/avatar.jpg'),
      'https://example.invalid/avatar.jpg',
    );
    for (final raw in [
      null,
      '',
      5,
      'file:///avatar',
      'https://name:secret@example.invalid/a.jpg',
      'invalid',
    ]) {
      expect(avatarUrl(raw), isNull);
    }
    final dto = BiliVideoDto.fromJson({
      'bvid': 'BVtest',
      'title': '标题',
      'pic': '',
      'author': '作者',
      'upic': '//example.invalid/search.jpg',
      'duration': 10,
      'play': 1,
    });
    expect(dto.creatorAvatarUrl, 'https://example.invalid/search.jpg');
  });
  test('recommendation HTTP covers are upgraded without enabling cleartext traffic', () {
    expect(
      coverUrl('http://i0.hdslb.com/synthetic.jpg'),
      'https://i0.hdslb.com/synthetic.jpg',
    );
    expect(
      coverUrl('//i0.hdslb.com/synthetic.jpg'),
      'https://i0.hdslb.com/synthetic.jpg',
    );
  });
  late Dio dio;
  late BilibiliCatalogRepository repository;
  final calls = <RequestOptions>[];
  final video = <String, Object?>{
    'bvid': 'BVsynthetic',
    'title': '中文 &amp; TV',
    'pic': '//example.invalid/a.jpg',
    'owner': {'name': '作者', 'mid': 1, 'face': '//example.invalid/author.jpg'},
    'duration': 60,
    'stat': {'view': 10},
  };
  setUp(() {
    calls.clear();
    dio = Dio();
    repository = BilibiliCatalogRepository(BilibiliApi(dio));
    addTearDown(() => dio.close(force: true));
  });
  void reply(Object? Function(RequestOptions) response) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          calls.add(options);
          final body = options.path.endsWith('/nav')
              ? {
                  'code': -101,
                  'data': {
                    'wbi_img': {
                      'img_url': 'https://example.invalid/${'a' * 32}.png',
                      'sub_url': 'https://example.invalid/${'b' * 32}.png',
                    },
                  },
                }
              : response(options);
          handler.resolve(
            Response<Object?>(
              requestOptions: options,
              statusCode: 200,
              data: body,
            ),
          );
        },
      ),
    );
  }

  test(
    'recommendation filters mixed cards, deduplicates and signs its own cursor',
    () async {
      reply(
        (_) => {
          'code': 0,
          'data': {
            'item': [
              {...video, 'goto': 'av'},
              {...video, 'goto': 'av'},
              {'goto': 'live', 'bvid': 'BVbad'},
            ],
          },
        },
      );
      final page = (await repository.fetchVideos(
        section: 'home',
        ownerKey: 'guest',
        cancellation: CancellationSignal(),
      )).valueOrThrow;
      expect(page.items.single.title, '中文 & TV');
      expect(
        page.items.single.creatorAvatarUrl,
        'https://example.invalid/author.jpg',
      );
      expect(page.nextCursor, 'recommend:2');
      expect(calls.last.queryParameters['fresh_idx'], '1');
      expect(calls.last.queryParameters.containsKey('w_rid'), isTrue);
      expect(calls.last.headers.containsKey('Cookie'), isFalse);
    },
  );
  test(
    'weekly pagination pins its issue and signs the reference API parameters',
    () async {
      reply(
        (options) => {
          'code': 0,
          'data': {
            'list': options.path.endsWith('/series/list')
                ? [
                    {'number': 7},
                    {'number': 9},
                    {'number': 8},
                  ]
                : [
                    for (var i = 0; i < 18; i++)
                      {...video, 'bvid': 'BVsynthetic$i'},
                  ],
          },
        },
      );
      final first = (await repository.fetchVideos(
        section: 'weekly',
        ownerKey: 'guest',
        cancellation: CancellationSignal(),
      )).valueOrThrow;
      expect(first.items, hasLength(12));
      expect(first.nextCursor, 'weekly:9:12');
      expect(calls.last.queryParameters['number'], '9');
      expect(calls.last.queryParameters.containsKey('w_rid'), isTrue);
      final next = (await repository.fetchVideos(
        section: 'weekly',
        ownerKey: 'guest',
        cursor: first.nextCursor,
        cancellation: CancellationSignal(),
      )).valueOrThrow;
      expect(next.items, hasLength(6));
      expect(next.nextCursor, isNull);
      expect(
        next.items.any((item) => first.items.any((old) => old.id == item.id)),
        isFalse,
      );
      expect(
        calls.where((call) => call.path.endsWith('/series/list')),
        hasLength(1),
      );
      expect(calls.last.queryParameters['number'], '9');
    },
  );
  test(
    'ranking uses the whole-site API and rejects cross-feed cursors',
    () async {
      reply(
        (_) => {
          'code': 0,
          'data': {
            'list': [video],
          },
        },
      );
      final page = (await repository.fetchVideos(
        section: 'ranking',
        ownerKey: 'guest',
        cancellation: CancellationSignal(),
      )).valueOrThrow;
      expect(page.items.single.id, 'BVsynthetic');
      expect(page.nextCursor, isNull);
      expect(calls.last.path, endsWith('/ranking/v2'));
      expect(calls.last.queryParameters['rid'], '0');
      expect(calls.last.queryParameters['type'], 'all');
      final before = calls.length;
      expect(
        await repository.fetchVideos(
          section: 'ranking',
          ownerKey: 'guest',
          cursor: 'weekly:9:12',
          cancellation: CancellationSignal(),
        ),
        isA<ResultFailure<Object?>>(),
      );
      expect(
        await repository.fetchVideos(
          section: 'live',
          ownerKey: 'guest',
          cancellation: CancellationSignal(),
        ),
        isA<ResultFailure<Object?>>(),
      );
      expect(calls, hasLength(before));
    },
  );
  test(
    'first-page permission fallback remains on popular pagination',
    () async {
      reply(
        (o) => o.path.endsWith('/rcmd')
            ? {'code': -101, 'data': null}
            : {
                'code': 0,
                'data': {
                  'list': [video],
                  'no_more': false,
                },
              },
      );
      final first = (await repository.fetchVideos(
        section: 'home',
        ownerKey: 'guest',
        cancellation: CancellationSignal(),
      )).valueOrThrow;
      expect(first.notice, isNotNull);
      expect(first.nextCursor, 'popular:2');
      await repository.fetchVideos(
        section: 'home',
        ownerKey: 'guest',
        cursor: first.nextCursor,
        cancellation: CancellationSignal(),
      );
      expect(calls.where((o) => o.path.endsWith('/rcmd')), hasLength(1));
      expect(calls.last.queryParameters['pn'], 2);
    },
  );
  test(
    'a mid-feed permission error cannot silently merge another feed',
    () async {
      reply((_) => {'code': -101, 'data': null});
      final result = await repository.fetchVideos(
        section: 'home',
        ownerKey: 'guest',
        cursor: 'recommend:2',
        cancellation: CancellationSignal(),
      );
      expect(result, isA<ResultFailure<Object?>>());
      expect(calls.any((o) => o.path.endsWith('/popular')), isFalse);
    },
  );
  test(
    'rate limits remain errors and never trigger hidden fallback requests',
    () async {
      reply((_) => {'code': -352, 'data': null});
      final result = await repository.fetchVideos(
        section: 'home',
        ownerKey: 'guest',
        cancellation: CancellationSignal(),
      );
      expect((result as ResultFailure).failure.kind, FailureKind.rateLimited);
      expect(calls.any((o) => o.path.endsWith('/popular')), isFalse);
    },
  );
  test('related list envelope is decoded separately and excludes the current video', () async {
    reply(
      (_) => {
        'code': 0,
        'data': [
          video,
          {...video, 'bvid': 'BVother'},
          {...video, 'bvid': 'BVother'},
        ],
      },
    );
    final result = (await repository.getRelated(
      'BVsynthetic',
      ownerKey: 'guest',
      cancellation: CancellationSignal(),
    )).valueOrThrow;
    expect(result.single.id, 'BVother');
  });
  test(
    'numeric popular end marker stops; invalid pagination never performs I/O',
    () async {
      reply(
        (_) => {
          'code': 0,
          'data': {
            'list': [video],
            'no_more': 1,
          },
        },
      );
      final result = (await repository.fetchVideos(
        section: 'popular',
        ownerKey: 'guest',
        cancellation: CancellationSignal(),
      )).valueOrThrow;
      expect(result.nextCursor, isNull);
      final count = calls.length;
      expect(
        await repository.fetchVideos(
          section: 'popular',
          ownerKey: 'guest',
          cursor: '-1',
          cancellation: CancellationSignal(),
        ),
        isA<ResultFailure<Object?>>(),
      );
      expect(calls, hasLength(count));
    },
  );
  test(
    'detail rejects an empty part list and keeps owner metadata optional',
    () async {
      var empty = true;
      reply(
        (_) => {
          'code': 0,
          'data': {
            ...video,
            'desc': '',
            'owner': {'name': '作者', 'mid': 1},
            'pages': empty
                ? <Object?>[]
                : [
                    {'cid': 1, 'part': '第一集', 'duration': 60},
                  ],
          },
        },
      );
      expect(
        await repository.getVideo(
          'BVsynthetic',
          ownerKey: 'guest',
          cancellation: CancellationSignal(),
        ),
        isA<ResultFailure<Object?>>(),
      );
      empty = false;
      final detail = (await repository.getVideo(
        'BVsynthetic',
        ownerKey: 'guest',
        cancellation: CancellationSignal(),
      )).valueOrThrow;
      expect(detail.creatorId, 1);
      expect(detail.creatorAvatarUrl, isNull);
    },
  );
}
