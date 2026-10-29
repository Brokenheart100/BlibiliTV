import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mambatv/core/result.dart';
import 'package:mambatv/data/repositories/bilibili_pgc_repository.dart';
import 'package:mambatv/data/repositories/bilibili_live_repository.dart';
import 'package:mambatv/data/services/bilibili/bilibili_api.dart';
import 'package:mambatv/domain/playback/playback.dart';
import 'package:mambatv/domain/playback/playback_target.dart';

void main() {
  late Dio dio;
  late BilibiliApi api;
  late Map<String, Object?> response;
  final calls = <RequestOptions>[];
  setUp(() {
    calls.clear();
    dio = Dio();
    api = BilibiliApi(dio);
    response = {'code': 0, 'data': <String, Object?>{}};
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (request, handler) {
          calls.add(request);
          handler.resolve(
            Response<Object?>(
              requestOptions: request,
              statusCode: 200,
              data: response,
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
  Map<String, Object?> dash() => {
    'timelength': 120000,
    'dash': {
      'video': [
        {
          'id': 32,
          'codecs': 'avc1.test',
          'bandwidth': 300000,
          'baseUrl': 'https://cdn.invalid/video',
        },
      ],
      'audio': [
        {
          'id': 30216,
          'codecs': 'mp4a.40.2',
          'bandwidth': 64000,
          'baseUrl': 'https://cdn.invalid/audio',
        },
      ],
    },
  };
  test(
    'PGC unwraps result/video_info while rejecting preview and DRM',
    () async {
      final repository = BilibiliPgcRepository(api);
      const target = PlaybackTarget.pgc(seasonId: '10', episodeId: '20');
      response = {
        'code': 0,
        'result': {
          'video_info': dash(),
          'play_check': {'play_detail': 'PLAY_WHOLE'},
        },
      };
      final source = (await repository.resolve(
        target as PgcTarget,
        CancellationSignal(),
      )).valueOrThrow;
      expect(source.duration.inSeconds, 120);
      expect(calls.single.uri.host, 'api.bilibili.com');
      expect(calls.single.uri.path, '/pgc/player/web/v2/playurl');
      expect(calls.single.queryParameters['ep_id'], 20);
      response = {
        'code': 0,
        'result': {
          'video_info': {...dash(), 'is_preview': 1},
        },
      };
      expect(
        (await repository.resolve(
          target,
          CancellationSignal(),
        ) as ResultFailure<PlaybackSource>).failure.kind,
        FailureKind.permission,
      );
      response = {
        'code': 0,
        'result': {
          'video_info': {...dash(), 'is_drm': true},
        },
      };
      expect(
        (await repository.resolve(
          target,
          CancellationSignal(),
        ) as ResultFailure<PlaybackSource>).failure.kind,
        FailureKind.unsupported,
      );
    },
  );
  Map<String, Object?> liveData({
    String host = 'https://example.bilivideo.com',
  }) => {
    'live_status': 1,
    'room_id': 100,
    'playurl_info': {
      'playurl': {
        'g_qn_desc': [
          {'qn': 250, 'desc': '高清'},
        ],
        'stream': [
          {
            'protocol_name': 'http_hls',
            'format': [
              {
                'format_name': 'ts',
                'codec': [
                  {
                    'codec_name': 'avc',
                    'current_qn': 250,
                    'accept_qn': [250],
                    'base_url': '/live/test.m3u8',
                    'url_info': [
                      {'host': host, 'extra': '?token=synthetic'},
                    ],
                  },
                ],
              },
            ],
          },
        ],
      },
    },
  };
  test('live chooses verified HTTPS HLS/AVC and does not expose signed URLs in diagnostics', () async {
    response = {'code': 0, 'data': liveData()};
    final repository = BilibiliLiveRepository(api);
    final source = (await repository.resolve(
      '6',
      CancellationSignal(),
    )).valueOrThrow;
    expect(source.transport, PlaybackTransport.hls);
    expect(source.audioUrl, isEmpty);
    expect(source.headers['Referer'], 'https://live.bilibili.com/6');
    expect(source.toString(), isNot(contains('synthetic')));
    expect(calls.single.uri.host, 'api.live.bilibili.com');
    expect(calls.single.method, 'GET');
    expect(api.remoteWriteRequestsSent, 0);
    response = {
      'code': 0,
      'data': liveData(host: 'http://example.bilivideo.com'),
    };
    expect(
      await repository.resolve('6', CancellationSignal()),
      isA<ResultFailure<PlaybackSource>>(),
    );
    response = {'code': 0, 'data': liveData(host: 'https://evil.invalid')};
    expect(
      await repository.resolve('6', CancellationSignal()),
      isA<ResultFailure<PlaybackSource>>(),
    );
  });
  test(
    'offline, locked and rate-limited live sources are explicit failures',
    () async {
      final repository = BilibiliLiveRepository(api);
      response = {
        'code': 0,
        'data': {...liveData(), 'live_status': 0},
      };
      expect(
        (await repository.resolve(
          '6',
          CancellationSignal(),
        ) as ResultFailure<PlaybackSource>).failure.kind,
        FailureKind.unavailable,
      );
      response = {
        'code': 0,
        'data': {...liveData(), 'is_locked': true},
      };
      expect(
        (await repository.resolve(
          '6',
          CancellationSignal(),
        ) as ResultFailure<PlaybackSource>).failure.kind,
        FailureKind.permission,
      );
      response = {'code': -352};
      expect(
        (await repository.browse(
          CancellationSignal(),
        ) as ResultFailure).failure.kind,
        FailureKind.rateLimited,
      );
    },
  );
}
