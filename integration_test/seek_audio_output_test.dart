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
  testWidgets('compare audible output across forward and backward seeks', (
    tester,
  ) async {
    expect(const bool.fromEnvironment('MAMBA_VALIDATION_APP'), isTrue);
    expect(const bool.fromEnvironment('MAMBA_READ_ONLY_VALIDATION'), isTrue);
    final dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 20),
      ),
    );
    final api = BilibiliApi(dio);
    addTearDown(() {
      api.close();
      dio.close(force: true);
    });
    final signal = CancellationSignal();
    const video = 'BV1wR4Xz6EqG';
    final detail = (await tester.runAsync(
      () => api.get('/x/web-interface/view', signal, query: {'bvid': video}),
    ))!;
    final part = ((detail['pages'] as List).first as Map)['cid'].toString();
    final source = (await tester.runAsync(
      () =>
          BilibiliPlaybackRepository(api)
              .resolve(videoId: video, partId: part, cancellation: signal),
    ))!.valueOrThrow;
    final records = <Map<String, Object?>>[];
    binding.reportData = {
      'status': 'running',
      'variants': records,
      'manualNoiseFreeVerified': false,
      'readOnly': true,
    };
    addTearDown(() {
      if (binding.reportData?['status'] == 'running') {
        binding.reportData!['status'] = 'failed';
      }
    });
    const single = String.fromEnvironment('SEEK_AUDIO_SINGLE');
    final variants = single.isNotEmpty
        ? [single]
        : const bool.fromEnvironment('SEEK_AUDIO_QUEUE')
        ? ['continuous', 'audiotrack-pcm16', 'larger-queue']
        : ['baseline', 'pcm16', 'guarded'];
    for (final variant in variants) {
      final title = switch (variant) {
        'baseline' => 'A · 原有跳转',
        'pcm16' => 'B · 16 位 PCM 跳转',
        'guarded' => 'C · 跳转静音保护',
        'continuous' => 'D · 连续音频输出',
        'audiotrack-pcm16' => 'E · AudioTrack 整数输出',
        _ => 'F · 较大音频队列',
      };
      final engine = MediaKitEngine();
      final native = engine.player.platform! as NativePlayer;
      final errors = <String>[];
      final subscription = engine.player.stream.error.listen((error) {
        errors.add(classifyNativePlaybackFailure(error).kind.name);
      });
      final caption = ValueNotifier(title);
      final steps = <Map<String, Object?>>[];
      records.add({'variant': variant, 'steps': steps, 'errors': errors});
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
                      child: ValueListenableBuilder(
                        valueListenable: caption,
                        builder: (context, value, _) => Text(
                          value,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            decoration: TextDecoration.none,
                          ),
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
          await native.setProperty(
            'ao',
            variant == 'audiotrack-pcm16' ? 'audiotrack' : 'opensles',
          );
          if (variant == 'pcm16' || variant == 'audiotrack-pcm16') {
            await native.setProperty('audio-format', 's16');
            await native.setProperty('audio-samplerate', '48000');
          }
          if (variant == 'audiotrack-pcm16') {
            await native.setProperty('audiotrack-pcm-float', 'no');
            await native.setProperty('audio-channels', 'stereo');
          }
          if (variant == 'continuous') {
            await native.setProperty('audio-stream-silence', 'yes');
          }
          if (variant == 'larger-queue') {
            await native.setProperty('opensles-buffer-size-in-ms', '500');
          }
          await engine.setVolume(60);
          await engine.open(source, startAt: const Duration(seconds: 35));
        });
        debugPrint('SEEK_AUDIO_BEGIN $variant');
        await tester.pump(const Duration(seconds: 3));
        for (final target in [55, 35, 65, 45, 75, 35]) {
          caption.value = '$title · 跳转至 $target 秒';
          await tester.pump();
          final clock = Stopwatch()..start();
          await tester.runAsync(() async {
            if (variant == 'guarded') await native.setProperty('mute', 'yes');
            try {
              await engine.seek(Duration(seconds: target));
              if (variant == 'guarded') {
                await Future<void>.delayed(const Duration(milliseconds: 350));
              }
            } finally {
              if (variant == 'guarded') await native.setProperty('mute', 'no');
            }
          });
          final sample = (await tester.runAsync(
            () async => {
              'target': target,
              'seekMs': clock.elapsedMilliseconds,
              'avsync': double.tryParse(await native.getProperty('avsync')),
              'mute': await native.getProperty('mute'),
              'format': await native.getProperty('audio-out-params/format'),
              'rate': await native.getProperty('audio-out-params/samplerate'),
            },
          ))!;
          steps.add(sample);
          expect(sample['mute'], 'no');
          sample['syncHealthy'] = (sample['avsync'] as double).abs() <= .25;
          await tester.pump(const Duration(seconds: 4));
        }
        // Keep every variant available for listening; native error categories
        // are evidence for rejecting a variant, not a reason to skip the rest.
      } on AppFailure catch (failure) {
        records.last['failure'] = failure.kind.name;
      } finally {
        await subscription.cancel();
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.runAsync(engine.dispose);
        caption.dispose();
      }
    }
    binding.reportData!['status'] = 'diagnostic';
  }, timeout: const Timeout(Duration(minutes: 5)));
}
