import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mambatv/core/result.dart';
import 'package:mambatv/data/repositories/bilibili_catalog_repository.dart';
import 'package:mambatv/data/repositories/bilibili_playback_repository.dart';
import 'package:mambatv/data/services/bilibili/bilibili_api.dart';

void main() {
  final video = <String, Object?>{
    'bvid': 'BVsynthetic',
    'title': '<em>Flutter</em> &amp; TV',
    'pic': '//example.invalid/image.jpg',
    'author': '作者',
    'duration': '10:20',
    'play': 123,
  };
  final track = <String, Object?>{
    'id': 32,
    'base_url': 'https://example.invalid/v?token=synthetic',
    'codecs': 'avc1.test',
    'bandwidth': 100,
  };
  late Dio dio;
  late BilibiliApi api;
  setUp(() {
    dio = Dio();
    api = BilibiliApi(dio);
    addTearDown(() => dio.close(force: true));
  });
  void respond(Map<String, Object?> body) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final data = options.path.endsWith('/nav')
              ? <String, Object?>{
                  'code': -101,
                  'data': {
                    'wbi_img': {
                      'img_url': 'https://example.invalid/${'a' * 32}.png',
                      'sub_url': 'https://example.invalid/${'b' * 32}.png',
                    },
                  },
                }
              : body;
          handler.resolve(
            Response<Object?>(
              requestOptions: options,
              statusCode: 200,
              data: data,
            ),
          );
        },
      ),
    );
  }

  test(
    'search filters paid-course promotions before decoding UGC fields',
    () async {
      respond({
        'code': 0,
        'data': {
          'numPages': 2,
          'result': [
            {'type': 'ketang', 'bvid': '', 'duration': ''},
            {...video, 'type': 'video'},
          ],
        },
      });
      final page = (await BilibiliCatalogRepository(api).fetchVideos(
        section: 'search',
        ownerKey: 'guest',
        query: 'Flutter',
        cancellation: CancellationSignal(),
      )).valueOrThrow;
      expect(page.items.single.title, 'Flutter & TV');
      expect(page.items.single.durationSeconds, 620);
      expect(page.items.single.coverUrl, startsWith('https://'));
      expect(page.nextCursor, '2');
    },
  );

  test(
    'DASH aliases map to separate AVC and AAC resources without logging URLs',
    () async {
      respond({
        'code': 0,
        'data': {
          'timelength': 120000,
          'dash': {
            'video': [
              {...track, 'codecs': 'hev1.test'},
              track,
            ],
            'audio': [
              {...track, 'id': 30216, 'codecs': 'mp4a.40.2'},
            ],
          },
        },
      });
      final source = (await BilibiliPlaybackRepository(api).resolve(
        videoId: 'BVsynthetic',
        partId: '123',
        cancellation: CancellationSignal(),
      )).valueOrThrow;
      expect(source.codec, 'avc1.test');
      expect(source.duration.inSeconds, 120);
      expect(source.toString(), isNot(contains('synthetic')));
    },
  );

  test(
    'permission and unsupported codecs remain actionable failures',
    () async {
      respond({'code': -403});
      final denied = await BilibiliPlaybackRepository(api).resolve(
        videoId: 'BVsynthetic',
        partId: '1',
        cancellation: CancellationSignal(),
      );
      expect(
        (denied as ResultFailure<Object?>).failure.kind,
        FailureKind.permission,
      );
      dio.interceptors.clear();
      respond({
        'code': 0,
        'data': {
          'dash': {
            'video': [
              {...track, 'codecs': 'av01.test'},
            ],
            'audio': [
              {...track, 'codecs': 'mp4a.40.2'},
            ],
          },
        },
      });
      final unsupported = await BilibiliPlaybackRepository(api).resolve(
        videoId: 'BVsynthetic',
        partId: '1',
        cancellation: CancellationSignal(),
      );
      expect(
        (unsupported as ResultFailure<Object?>).failure.kind,
        FailureKind.unsupported,
      );
    },
  );

  test('cancellation reaches the in-flight Dio request', () async {
    final entered = Completer<CancelToken>();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          entered.complete(options.cancelToken);
          options.cancelToken!.whenCancel.then(
            (error) => handler.reject(error),
          );
        },
      ),
    );
    final signal = CancellationSignal();
    final request = BilibiliCatalogRepository(api)
        .fetchVideos(section: 'home', ownerKey: 'guest', cancellation: signal);
    final token = await entered.future;
    signal.cancel();
    expect(token.isCancelled, isTrue);
    final result = await request;
    expect(
      (result as ResultFailure<Object?>).failure.kind,
      FailureKind.cancelled,
    );
  });
}
