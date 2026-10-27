import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mambatv/core/result.dart';
import 'package:mambatv/data/repositories/bilibili_overlay_repository.dart';
import 'package:mambatv/data/repositories/bilibili_catalog_repository.dart';
import 'package:mambatv/data/repositories/bilibili_discovery_repository.dart';
import 'package:mambatv/data/services/auth/request_identity.dart';
import 'package:mambatv/data/services/bilibili/bilibili_api.dart';
import 'package:mambatv/domain/entities/app_models.dart';
import 'package:mambatv/domain/overlays/overlays.dart';

void main() {
  late Dio dio;
  late BilibiliApi api;
  late BilibiliOverlayRepository overlays;
  late BilibiliCatalogRepository catalog;
  final calls = <RequestOptions>[];
  Object? Function(RequestOptions) reply = (_) => <String, Object?>{};
  setUp(() {
    calls.clear();
    dio = Dio();
    api = BilibiliApi(
      dio,
      identity: const RequestIdentity(
        Session(ownerKey: 'user:101', status: SessionStatus.authenticated),
        'SESSDATA=synthetic; bili_jct=synthetic',
      ),
    );
    overlays = BilibiliOverlayRepository(api);
    catalog = BilibiliCatalogRepository(api);
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (o, h) {
          calls.add(o);
          if (o.uri.path.endsWith('/nav')) {
            h.resolve(
              Response(
                requestOptions: o,
                data: {
                  'code': 0,
                  'data': {
                    'wbi_img': {
                      'img_url': 'https://example.invalid/${'a' * 32}.png',
                      'sub_url': 'https://example.invalid/${'b' * 32}.png',
                    },
                  },
                },
              ),
            );
          } else if (o.responseType == ResponseType.stream) {
            final data = reply(o);
            h.resolve(
              Response<ResponseBody>(
                requestOptions: o,
                statusCode: 200,
                headers: data is ResponseBody
                    ? Headers.fromMap(data.headers)
                    : null,
                data: data is ResponseBody
                    ? data
                    : ResponseBody.fromBytes(data! as List<int>, 200),
              ),
            );
          } else {
            h.resolve(
              Response(
                requestOptions: o,
                statusCode: 200,
                data: {'code': 0, 'data': reply(o)},
              ),
            );
          }
        },
      ),
    );
    addTearDown(() {
      overlays.close();
      api.close();
      dio.close(force: true);
    });
  });
  test(
    'subtitle CDN receives no account cookie and isolate decodes only bytes',
    () async {
      reply = (o) => o.uri.path.endsWith('/v2')
          ? {
              'subtitle': {
                'subtitles': [
                  {
                    'id_str': '1',
                    'lan': 'ai-zh',
                    'lan_doc': '中文',
                    'subtitle_url': 'https://aisubtitle.hdslb.com/synthetic.json?auth_key=synthetic-sensitive',
                  },
                ],
              },
            }
          : utf8.encode('{"body":[{"from":1,"to":2,"content":"synthetic"}]}');
      final tracks = (await overlays.tracks(
        'BVsynthetic',
        '42',
        CancellationSignal(),
      )).valueOrThrow;
      expect(tracks.single.ai, true);
      expect(tracks.toString(), isNot(contains('auth_key')));
      final cues = (await overlays.cues(
        tracks.single.id,
        CancellationSignal(),
      )).valueOrThrow;
      expect(cues.single.text, 'synthetic');
      expect(calls.last.headers['Cookie'], isNull);
      expect(
        calls
            .where((o) => o.uri.host == 'api.bilibili.com')
            .last
            .headers['Cookie'],
        isNotNull,
      );
      expect(api.remoteWriteRequestsSent, 0);
    },
  );
  test(
    'subtitle resource rejects hostile hosts, userinfo and cleartext',
    () async {
      reply = (_) => {
        'subtitle': {
          'subtitles': [
            for (final url in [
              'https://hdslb.com.evil.invalid/sub.json',
              'https://user@aisubtitle.hdslb.com/sub.json',
              'http://aisubtitle.hdslb.com/sub.json',
            ])
              {'id': url, 'subtitle_url': url},
          ],
        },
      };
      final tracks = await overlays.tracks(
        'BVsynthetic',
        '42',
        CancellationSignal(),
      );
      expect(tracks.valueOrThrow, isEmpty);
      expect(calls.every((o) => o.uri.host == 'api.bilibili.com'), true);
    },
  );
  test('declared oversized resources fail before consumption and malformed protobuf is safe', () async {
    reply = (_) => ResponseBody.fromBytes(
      [],
      200,
      headers: {
        'content-length': ['9000000'],
      },
    );
    final oversized = await overlays.segment('42', 1, CancellationSignal());
    expect(oversized, isA<ResultFailure<List<DanmakuItem>>>());
    reply = (_) => <int>[0x0a, 0xff];
    final broken = await overlays.segment('42', 1, CancellationSignal());
    expect(broken, isA<ResultFailure<List<DanmakuItem>>>());
    expect((broken as ResultFailure).failure.message, isNot(contains('hdslb')));
  });
  test('creator pagination preserves mid and sort without pretending IDs are video IDs', () async {
    reply = (_) => {
      'list': {
        'vlist': [
          {
            'bvid': 'BVsynthetic',
            'title': 'title',
            'author': 'UP',
            'length': '01:02',
            'play': 7,
            'pic': '//i.hdslb.com/synthetic.png',
          },
        ],
      },
      'page': {'count': 31},
    };
    final repo = BilibiliDiscoveryRepository(api);
    final page = (await repo.creatorVideos(
      mid: 42,
      ownerKey: 'user:101',
      order: VideoOrder.mostViewed,
      cancellation: CancellationSignal(),
    )).valueOrThrow;
    expect(page.items.single.durationSeconds, 62);
    expect(page.nextCursor, '2');
    final request = calls.last;
    expect(request.queryParameters['mid'], '42');
    expect(request.queryParameters['order'], 'click');
    expect(request.queryParameters['w_rid'], isNotNull);
    final second = (await repo.creatorVideos(
      mid: 42,
      ownerKey: 'user:101',
      order: VideoOrder.mostViewed,
      cursor: page.nextCursor,
      cancellation: CancellationSignal(),
    )).valueOrThrow;
    expect(second.nextCursor, null);
    expect(calls.last.queryParameters['pn'], '2');
  });
  test('following filters non-UGC and ends repeated cursors; private reads bypass cache', () async {
    reply = (_) => {
      'items': [
        {
          'modules': {
            'module_author': {'name': 'UP'},
            'module_dynamic': {
              'major': {
                'type': 'MAJOR_TYPE_ARCHIVE',
                'archive': {
                  'bvid': 'BVsynthetic',
                  'title': 'title',
                  'cover': '//i.hdslb.com/synthetic.png',
                  'duration_text': '02:03',
                  'stat': {'play': '1.2万'},
                },
              },
            },
          },
        },
        {
          'modules': {
            'module_dynamic': {
              'major': {'type': 'MAJOR_TYPE_LIVE_RCMD'},
            },
          },
        },
      ],
      'offset': 'cursor-a',
      'has_more': true,
    };
    final page = (await catalog.fetchVideos(
      section: 'following',
      ownerKey: 'user:101',
      cancellation: CancellationSignal(),
    )).valueOrThrow;
    expect(page.items.single.viewCount, 12000);
    expect(page.items.single.durationSeconds, 123);
    expect(page.notice, contains('1'));
    expect(calls.last.extra, isEmpty);
    final next = (await catalog.fetchVideos(
      section: 'following',
      ownerKey: 'user:101',
      cursor: page.nextCursor,
      cancellation: CancellationSignal(),
    )).valueOrThrow;
    expect(next.nextCursor, null);
    expect(calls.last.queryParameters['offset'], 'cursor-a');
  });
  test('filtered search forwards only selected public filter values', () async {
    reply = (_) => {'result': <Object?>[], 'numPages': 1};
    await catalog.fetchVideos(
      section: 'search',
      ownerKey: 'user:101',
      query: 'Flutter',
      options: const CatalogOptions(order: VideoOrder.newest, duration: 1),
      cancellation: CancellationSignal(),
    );
    expect(calls.last.queryParameters['order'], 'pubdate');
    expect(calls.last.queryParameters['duration'], '1');
    expect(calls.last.queryParameters['keyword'], 'Flutter');
  });
}
