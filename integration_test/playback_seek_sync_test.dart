import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
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

  testWidgets('native DASH seeks recover audio and video together', (
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
    final signal = CancellationSignal();
    const videoId = 'BV1wR4Xz6EqG';
    final metadata = (await tester.runAsync(
      () => api.get('/x/web-interface/view', signal, query: {'bvid': videoId}),
    ))!;
    final part = ((metadata['pages']! as List).first as Map)['cid'].toString();
    final source = (await tester.runAsync(
      () =>
          BilibiliPlaybackRepository(api)
              .resolve(videoId: videoId, partId: part, cancellation: signal),
    ))!.valueOrThrow;
    final experiments = const bool.fromEnvironment('SEEK_EXPERIMENTS');
    final reports = <Map<String, Object?>>[];
    binding.reportData = {
      'status': 'running',
      'experiments': experiments,
      'variants': reports,
    };
    addTearDown(() {
      if (binding.reportData?['status'] == 'running') {
        binding.reportData!['status'] = 'failed';
      }
    });
    addTearDown(() {
      api.close();
      dio.close(force: true);
    });

    for (final variant
        in experiments ? ['baseline', 'framedrop', 'edl'] : ['production']) {
      final engine = MediaKitEngine();
      final native = engine.player.platform! as NativePlayer;
      final steps = <Map<String, Object?>>[];
      final report = <String, Object?>{'variant': variant, 'steps': steps};
      reports.add(report);
      final errors = <String>[];
      final subscription = engine.player.stream.error.listen((message) {
        // Preserve only categories, never native text containing signed URLs.
        errors.add(classifyNativePlaybackFailure(message).kind.name);
      });
      try {
        await tester.pumpWidget(
          MaterialApp(
            home: Video(controller: engine.controller, controls: null),
          ),
        );
        if (experiments) {
          await tester.runAsync(() async {
            await native.setProperty(
              'hr-seek-framedrop',
              variant == 'baseline' ? 'no' : 'yes',
            );
            if (variant == 'edl') {
              final video = source.videoUrl, audio = source.audioUrl;
              final edl =
                  'edl://!no_chapters;%${utf8.encode(video).length}%$video;!new_stream;!no_chapters;%${utf8.encode(audio).length}%$audio';
              await engine.player.open(
                Media(edl, httpHeaders: bilibiliMediaHeaders),
              );
            } else {
              await engine.open(source, startAt: Duration.zero);
              // Keep the historical comparison reproducible even after the
              // production adapter starts enabling pre-target frame discard.
              await native.setProperty(
                'hr-seek-framedrop',
                variant == 'baseline' ? 'no' : 'yes',
              );
            }
          });
        } else {
          await tester.runAsync(
            () => engine.open(source, startAt: Duration.zero),
          );
        }
        Future<String?> property(String name) async {
          try {
            return await native.getProperty(name);
          } catch (_) {
            return null;
          }
        }

        Future<Map<String, Object?>> sample() async => {
          'position': double.tryParse(await property('time-pos') ?? ''),
          'audioPts': double.tryParse(await property('audio-pts') ?? ''),
          'avsync': double.tryParse(await property('avsync') ?? ''),
          'seeking': await property('seeking'),
          'cachePaused': await property('paused-for-cache'),
          'vo': await property('current-vo'),
          'hwdec': await property('hwdec-current'),
          'videoConfigured': await property('vo-configured'),
        };
        report['initialState'] = (await tester.runAsync(sample))!;
        await tester.pump(const Duration(seconds: 4));
        for (final target in [
          35,
          85,
          25,
          120,
          15,
          180,
          40,
          210,
          10,
          source.duration.inSeconds - 3,
          0,
        ]) {
          final clock = Stopwatch()..start();
          final samples = <Map<String, Object?>>[];
          String? failure;
          try {
            await tester.runAsync(
              () => engine
                  .seek(Duration(seconds: target))
                  .timeout(const Duration(seconds: 15)),
            );
          } catch (_) {
            failure = 'seek-timeout-or-failure';
          }
          final returnedMs = clock.elapsedMilliseconds;
          final atReturn = (await tester.runAsync(sample))!;
          if (!experiments) {
            expect(atReturn['seeking'], 'no');
            expect(atReturn['audioPts'], isNotNull);
          }
          var stable = 0;
          while (clock.elapsed < const Duration(seconds: 15)) {
            await tester.pump(const Duration(milliseconds: 250));
            final current = (await tester.runAsync(sample))!;
            samples.add(current);
            final sync = current['avsync'] as double?;
            final position = current['position'] as double?;
            stable =
                current['seeking'] == 'no' &&
                    current['cachePaused'] == 'no' &&
                    current['videoConfigured'] == 'yes' &&
                    sync != null &&
                    sync.abs() <= .25 &&
                    position != null &&
                    position >= target - 1 &&
                    position <= target + clock.elapsedMilliseconds / 1000 + 2
                ? stable + 1
                : 0;
            if (stable >= 4) break;
          }
          final step = <String, Object?>{
            'target': target,
            'seekReturnedMs': returnedMs,
            'stableAfterMs': clock.elapsedMilliseconds,
            'recovered': stable >= 4,
            'failure': failure,
            'atReturn': atReturn,
            'samples': samples,
          };
          steps.add(step);
          debugPrint(
            'SEEK_SYNC ${jsonEncode({'variant': variant, ...step, 'samples': samples.take(2).toList()})}',
          );
          if (!experiments) {
            expect(
              stable,
              greaterThanOrEqualTo(4),
              reason: 'Audio and video must settle after seek to $target',
            );
          }
        }
        report['errors'] = errors;
        report['videoSync'] = await tester.runAsync(
          () async => await property('video-sync') ?? 'unavailable',
        );
        report['audioOutput'] = await tester.runAsync(
          () async => await property('current-ao') ?? 'unavailable',
        );
        if (!experiments) {
          await tester.runAsync(engine.pause);
          final paused = <Map<String, Object?>>[];
          for (final target in [60, 10]) {
            await tester.runAsync(() => engine.seek(Duration(seconds: target)));
            await tester.pump(const Duration(seconds: 1));
            final value = (await tester.runAsync(sample))!;
            paused.add({'target': target, ...value});
            expect(engine.snapshot.playing, isFalse);
            expect(
              (value['position'] as double) - target,
              inInclusiveRange(-1, 1),
            );
            expect(value['seeking'], 'no');
          }
          report['pausedSeeks'] = paused;
          await tester.runAsync(engine.play);
          final rates = <Map<String, Object?>>[];
          for (final rate in [.5, 1.5, 2.0, 1.0]) {
            await tester.runAsync(() => engine.setRate(rate));
            await tester.runAsync(
              () => engine.seek(const Duration(seconds: 35)),
            );
            final value = (await tester.runAsync(sample))!;
            rates.add({'rate': rate, ...value});
            expect((value['avsync'] as double).abs(), lessThanOrEqualTo(.25));
          }
          report['rateSeeks'] = rates;
          const soakSeconds = int.fromEnvironment(
            'SEEK_SOAK_SECONDS',
            defaultValue: 900,
          );
          final clock = Stopwatch()..start();
          final samples = <Map<String, Object?>>[];
          report['soakSamples'] = samples;
          var nextSeek = 20, nextSample = 0, seekIndex = 0;
          final targets = [85, 25, 180, 10, 210, 40];
          debugPrint('SEEK_SOAK_STARTED');
          while (clock.elapsed.inSeconds < soakSeconds) {
            if (clock.elapsed.inSeconds >= nextSeek) {
              final target = targets[seekIndex++ % targets.length];
              await tester.runAsync(
                () => engine.seek(Duration(seconds: target)),
              );
              debugPrint(
                'SEEK_SOAK_SEEK ${jsonEncode({'elapsedSeconds': clock.elapsed.inSeconds, 'target': target})}',
              );
              nextSeek += 20;
            }
            await tester.pump(const Duration(milliseconds: 250));
            final value = (await tester.runAsync(sample))!;
            expect(value['seeking'], 'no');
            expect(value['audioPts'], isNotNull);
            expect((value['avsync'] as double).abs(), lessThanOrEqualTo(.25));
            if (clock.elapsed.inSeconds >= nextSample) {
              samples.add({
                'elapsedSeconds': clock.elapsed.inSeconds,
                ...value,
              });
              if (clock.elapsed.inSeconds % 60 < 5) {
                debugPrint('SEEK_SOAK_SAMPLE ${jsonEncode(samples.last)}');
              }
              nextSample += 5;
            }
          }
          report['soakSeconds'] = clock.elapsed.inSeconds;
          report['soakSeeks'] = seekIndex;
          report['soakSamples'] = samples;
          expect(errors, isEmpty);
        }
      } finally {
        await subscription.cancel();
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.runAsync(engine.dispose);
      }
    }
    binding.reportData!['status'] = experiments ? 'diagnostic' : 'passed';
    binding.reportData!['mode'] = kProfileMode ? 'profile' : 'debug';
  }, timeout: const Timeout(Duration(minutes: 20)));
}
