import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:mambatv/core/result.dart';
import 'package:mambatv/data/repositories/bilibili_playback_repository.dart';
import 'package:mambatv/data/services/bilibili/bilibili_api.dart';
import 'package:mambatv/data/services/playback/media_kit_engine.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;
  MediaKit.ensureInitialized();
  testWidgets('Android emulator audio backend comparison', (tester) async {
    expect(const bool.fromEnvironment('MAMBA_VALIDATION_APP'), isTrue);
    expect(const bool.fromEnvironment('MAMBA_READ_ONLY_VALIDATION'), isTrue);
    final client = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 20),
      ),
    );
    final api = BilibiliApi(client);
    final signal = CancellationSignal();
    const videoId = 'BV1wR4Xz6EqG';
    final view = (await tester.runAsync(
      () => api.get('/x/web-interface/view', signal, query: {'bvid': videoId}),
    ))!;
    final part = ((view['pages']! as List).first as Map)['cid'].toString();
    final source = (await tester.runAsync(
      () =>
          BilibiliPlaybackRepository(api)
              .resolve(videoId: videoId, partId: part, cancellation: signal),
    ))!.valueOrThrow;
    final records = <Map<String, Object?>>[];
    binding.reportData = {
      'status': 'running',
      'platform': 'Android',
      'readOnly': true,
      'variants': records,
      'manualNoiseFreeVerified': false,
    };
    addTearDown(() {
      if (binding.reportData?['status'] == 'running') {
        binding.reportData!['status'] = 'failed';
      }
    });
    addTearDown(() {
      api.close();
      client.close(force: true);
    });
    final variants = const bool.fromEnvironment('AUDIO_SINGLE_BACKEND')
        ? ['opensles']
        : ['opensles', 'opensles-pcm16', 'audiotrack', 'audiotrack-pcm16'];
    for (final variant in variants) {
      final backend = variant.startsWith('opensles')
          ? 'opensles'
          : 'audiotrack';
      final engine = MediaKitEngine();
      final native = engine.player.platform! as NativePlayer;
      final errors = <String>[];
      final subscription = engine.player.stream.error.listen(
        (message) =>
            errors.add(classifyNativePlaybackFailure(message).kind.name),
      );
      try {
        await tester.pumpWidget(
          MaterialApp(
            home: Stack(
              fit: StackFit.expand,
              children: [
                Video(controller: engine.controller, controls: null),
                Positioned(
                  top: 20,
                  left: 20,
                  child: ColoredBox(
                    color: Colors.black87,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        '声音对照：$variant · 同一音质 · 音量 60%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
        await tester.runAsync(() async {
          await native.setProperty('ao', backend);
          if (variant.endsWith('pcm16')) {
            await native.setProperty('audio-format', 's16');
            await native.setProperty('audio-samplerate', '48000');
            await native.setProperty('audio-channels', 'stereo');
            if (backend == 'audiotrack') {
              await native.setProperty('audiotrack-pcm-float', 'no');
            }
          }
          await engine.setVolume(60);
          await engine.open(source, startAt: const Duration(seconds: 35));
        });
        Future<String> property(String name) async {
          try {
            return await native.getProperty(name);
          } catch (_) {
            return 'unavailable';
          }
        }

        final initial = await tester.runAsync(
          () async => <String, Object?>{
            'variant': variant,
            'requestedBackend': backend,
            'actualBackend': await property('current-ao'),
            'inputFormat': await property('audio-params/format'),
            'inputSampleRate': await property('audio-params/samplerate'),
            'inputChannels': await property('audio-params/channels'),
            'outputFormat': await property('audio-out-params/format'),
            'outputSampleRate': await property('audio-out-params/samplerate'),
            'outputChannels': await property('audio-out-params/channels'),
          },
        );
        records.add(initial!);
        expect(initial['actualBackend'], backend);
        final clock = Stopwatch()..start();
        var maximumSync = 0.0;
        const seconds = int.fromEnvironment(
          'AUDIO_LISTEN_SECONDS',
          defaultValue: 20,
        );
        debugPrint('AUDIO_LISTEN_BEGIN $variant $seconds');
        while (clock.elapsed < const Duration(seconds: seconds)) {
          await tester.pump(const Duration(milliseconds: 250));
          final value = (await tester.runAsync(() => property('avsync')))!;
          final sync = double.parse(value).abs();
          if (sync > maximumSync) maximumSync = sync;
        }
        records.last['maximumAvsyncSeconds'] = maximumSync;
        records.last['errors'] = errors;
      } finally {
        await subscription.cancel();
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.runAsync(engine.dispose);
      }
    }
    binding.reportData!['status'] = 'diagnostic';
  }, timeout: const Timeout(Duration(minutes: 5)));
}
