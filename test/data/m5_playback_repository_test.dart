import 'package:dio/dio.dart';
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mambatv/core/result.dart';
import 'package:mambatv/data/repositories/bilibili_playback_repository.dart';
import 'package:mambatv/data/services/bilibili/bilibili_api.dart';
import 'package:mambatv/data/services/playback/media_kit_engine.dart';
import 'package:mambatv/domain/playback/playback.dart';

void main() {
  late Dio dio;
  late BilibiliApi api;
  late BilibiliPlaybackRepository repository;
  late Map<String, Object?> payload;
  final calls = <RequestOptions>[];
  setUp(() {
    calls.clear();
    dio = Dio();
    api = BilibiliApi(dio);
    repository = BilibiliPlaybackRepository(api);
    payload = {
      'timelength': 120000,
      'support_formats': [
        {'quality': 16},
        {'quality': 32},
        {'quality': 80},
      ],
      'dash': {
        'video': [
          {
            'id': 32,
            'baseUrl': 'https://cdn.invalid/480?secret=synthetic',
            'backupUrl': [
              'http://unsafe.invalid/video',
              'https://backup.invalid/video',
            ],
            'codecs': 'avc1.640033',
            'bandwidth': 500000,
          },
          {
            'id': 16,
            'base_url': 'https://cdn.invalid/360',
            'backup_url': ['https://backup.invalid/video'],
            'codecs': 'avc1.64001e',
            'bandwidth': 200000,
          },
          {
            'id': 80,
            'baseUrl': 'https://cdn.invalid/hevc',
            'codecs': 'hev1.test',
            'bandwidth': 1000000,
          },
        ],
        'audio': [
          {
            'id': 30216,
            'baseUrl': 'https://cdn.invalid/audio64',
            'backupUrl': ['https://backup.invalid/audio'],
            'codecs': 'mp4a.40.2',
            'bandwidth': 64000,
          },
          {
            'id': 30280,
            'baseUrl': 'https://cdn.invalid/audio192',
            'backupUrl': ['https://backup.invalid/audio'],
            'codecs': 'mp4a.40.2',
            'bandwidth': 192000,
          },
        ],
      },
    };
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (request, handler) {
          calls.add(request);
          handler.resolve(
            Response<Object?>(
              requestOptions: request,
              statusCode: 200,
              data: {
                'code': 0,
                'data': request.uri.path.endsWith('/nav')
                    ? {
                        'wbi_img': {
                          'img_url': 'https://example.invalid/${'a' * 32}.png',
                          'sub_url': 'https://example.invalid/${'b' * 32}.png',
                        },
                      }
                    : payload,
              },
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
  Future<Result<PlaybackSource>> resolve({int? quality, int? audio}) =>
      repository.resolve(
        videoId: 'BVsynthetic',
        partId: '123',
        cancellation: CancellationSignal(),
        quality: quality,
        audioId: audio,
      );
  test('menus reflect actual AVC and AAC resources, keeping unavailable quality explanatory', () async {
    final source = (await resolve()).valueOrThrow;
    expect(source.quality, 16);
    expect(source.audioId, 30216);
    expect(
      source.qualities.where((q) => q.available).map((q) => q.id).toSet(),
      {16, 32},
    );
    expect(source.qualities.singleWhere((q) => q.id == 80).reason, isNotEmpty);
    expect(source.audioTracks.map((a) => a.id).toSet(), {30216, 30280});
    expect(source.alternate!.videoUrl, 'https://backup.invalid/video');
    expect(source.alternate!.alternate, isNull);
  });
  test('explicit quality and audio are selected exactly with fresh signed playurl requests', () async {
    final source = (await resolve(quality: 32, audio: 30280)).valueOrThrow;
    expect(source.quality, 32);
    expect(source.audioId, 30280);
    expect(calls.last.queryParameters['qn'], '32');
    expect(calls.last.queryParameters.containsKey('w_rid'), isTrue);
    expect(calls.last.getCacheOptions(), isNull);
    await resolve(quality: 32);
    expect(calls.where((r) => r.uri.path.endsWith('/playurl')).length, 2);
  });
  test(
    'DASH metadata accepts video camelCase and audio snake_case ranges',
    () async {
      final dash = payload['dash']! as Map<String, Object?>;
      final video = (dash['video']! as List).first as Map<String, Object?>;
      video.addAll(<String, Object>{
        'mimeType': 'video/mp4',
        'width': 854,
        'height': 480,
        'SegmentBase': {'Initialization': '0-999', 'indexRange': '1000-1499'},
      });
      final audio = (dash['audio']! as List).first as Map<String, Object?>;
      audio.addAll(<String, Object>{
        'mime_type': 'audio/mp4',
        'audioSamplingRate': 48000,
        'segment_base': {'initialization': '0-599', 'index_range': '600-999'},
      });
      final source = (await resolve(quality: 32)).valueOrThrow;
      expect(source.videoDash!.initializationRange, '0-999');
      expect(source.videoDash!.indexRange, '1000-1499');
      expect(source.videoDash!.width, 854);
      expect(source.audioDash!.indexRange, '600-999');
      expect(source.audioDash!.audioSamplingRate, 48000);
      expect(source.alternate!.audioDash, same(source.audioDash));
    },
  );
  test(
    'missing requested quality is an error rather than silent downgrade',
    () async {
      final result = await resolve(quality: 80);
      expect((result as ResultFailure).failure.kind, FailureKind.permission);
    },
  );
  test('unavailable audio and DRM remain unsupported without retry', () async {
    expect(
      ((await resolve(audio: 999)) as ResultFailure).failure.kind,
      FailureKind.unsupported,
    );
    payload['is_drm'] = true;
    expect(
      ((await resolve()) as ResultFailure).failure.kind,
      FailureKind.unsupported,
    );
  });
  test(
    'insecure primary and backup resources cannot escape validation',
    () async {
      final dash = payload['dash']! as Map<String, Object?>;
      dash['audio'] = [
        {
          'id': 30216,
          'baseUrl': 'http://unsafe.invalid/audio',
          'backupUrl': ['https://user:pass@unsafe.invalid/audio'],
          'codecs': 'mp4a.40.2',
          'bandwidth': 1,
        },
      ];
      expect(
        ((await resolve()) as ResultFailure).failure.kind,
        FailureKind.contract,
      );
    },
  );
  test('source diagnostics never print signed resource URLs', () async {
    final source = (await resolve(quality: 32)).valueOrThrow;
    expect(source.toString(), isNot(contains('synthetic')));
    expect(source.toString(), isNot(contains('cdn.invalid')));
  });
  test('native failure classification distinguishes expiry, CDN and unsupported without exposing messages', () {
    for (final (message, kind) in [
      ('HTTP 403 at https://cdn.invalid/private', FailureKind.resourceExpired),
      ('HTTP 503', FailureKind.cdn),
      ('Failed to open https://cdn.invalid/private', FailureKind.cdn),
      ('Decoder codec not supported', FailureKind.unsupported),
    ]) {
      final failure = classifyNativePlaybackFailure(message);
      expect(failure.kind, kind);
      expect(failure.toString(), isNot(contains('cdn.invalid')));
    }
  });
}
