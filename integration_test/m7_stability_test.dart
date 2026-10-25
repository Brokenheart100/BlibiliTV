import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:media_kit/media_kit.dart' hide PlayerState;
import 'package:media_kit_video/media_kit_video.dart';
import 'package:mambatv/app/app.dart';
import 'package:mambatv/app/bootstrap.dart';
import 'package:mambatv/app/providers/infrastructure_providers.dart';
import 'package:mambatv/app/providers/repository_providers.dart';
import 'package:mambatv/app/providers/playback_providers.dart';
import 'package:mambatv/app/router.dart';
import 'package:mambatv/core/result.dart';
import 'package:mambatv/data/repositories/local_settings_repository.dart';
import 'package:mambatv/data/repositories/memory_session_repository.dart';
import 'package:mambatv/data/services/local/app_database.dart';
import 'package:mambatv/data/services/playback/media_kit_engine.dart';
import 'package:mambatv/domain/entities/app_models.dart';
import 'package:mambatv/ui/core/images/tv_image_cache.dart';
import 'package:mambatv/ui/features/player/views/player_page.dart';
import 'package:mambatv/ui/features/player/view_models/player_view_model.dart';

import '../test/support/memory_preferences.dart';
import 'm5_playback_flow_test.dart' show M5Tracker, M5Engine;

class M7Tracker extends M5Tracker {
  final errors = <Map<String, Object?>>[];
  @override
  PlaybackAdapter get adapter => PlaybackAdapter(
    focus: focus,
    create: () => M7Engine(this),
    surface: (engine) => Video(
      controller: (engine as MediaKitEngine).controller,
      controls: null,
      pauseUponEnteringBackgroundMode: false,
      resumeUponEnteringForegroundMode: false,
    ),
  );
}

class M7Engine extends M5Engine {
  M7Engine(M7Tracker tracker) : super(tracker) {
    subscription = player.stream.error.listen((message) {
      final lower = message.toLowerCase();
      const phrases = [
        'partial file',
        'input/output error',
        'i/o error',
        'error reading',
        'invalid data',
        'error while decoding',
        'audio device',
        'underrun',
        'failed to open',
        'error opening',
        'connection',
        'timed out',
        'end of file',
        'http',
        '403',
        '404',
        '410',
        '500',
        '502',
        '503',
        '504',
        'demux',
        'ffmpeg',
        'tls',
        'read error',
        'stream',
        'avcodec',
        'could not',
        'seek failed',
        'reconnect',
        'failed',
        'network',
      ];
      final item = <String, Object?>{
        'kind': classifyNativePlaybackFailure(message).kind.name,
        'tokens': [
          for (final phrase in phrases)
            if (lower.contains(phrase)) phrase,
        ],
      };
      if (tracker.errors.length < 100) tracker.errors.add(item);
      debugPrint('M7_NATIVE_ERROR ${jsonEncode(item)}');
    });
  }
  late final StreamSubscription<String> subscription;
  @override
  Future<void> dispose() async {
    await subscription.cancel();
    await super.dispose();
  }
}

const soakSeconds = int.fromEnvironment('M7_SOAK_SECONDS', defaultValue: 900);
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  TvImageCache.configure();
  testWidgets('M7 profile resource cycles and continuous UGC playlist', (
    tester,
  ) async {
    expect(const bool.fromEnvironment('MAMBA_VALIDATION_APP'), true);
    expect(const bool.fromEnvironment('MAMBA_READ_ONLY_VALIDATION'), true);
    expect(kProfileMode, true);
    final tracker = M7Tracker();
    final database = AppDatabase(driftDatabase(name: 'mambatv_m7_soak'));
    final sessions = MemorySessionRepository();
    final preferences = LocalSettingsRepository(MemoryPreferencesStore());
    await preferences.save(const AppSettings(autoNext: true));
    final container = ProviderContainer(
      retry: (_, _) => null,
      overrides: [
        sessionRepositoryProvider.overrideWithValue(sessions),
        appDatabaseProvider.overrideWithValue(database),
        settingsRepositoryProvider.overrideWithValue(preferences),
        playbackAdapterProvider.overrideWithValue(tracker.adapter),
      ],
    );
    PlayerViewModel? activeVm;
    final builds = <double>[], rasters = <double>[];
    var frameCount = 0;
    void timings(List<FrameTiming> values) {
      for (final f in values) {
        final index = frameCount++ % 4096;
        if (builds.length < 4096) {
          builds.add(f.buildDuration.inMicroseconds / 1000);
          rasters.add(f.rasterDuration.inMicroseconds / 1000);
        } else {
          builds[index] = f.buildDuration.inMicroseconds / 1000;
          rasters[index] = f.rasterDuration.inMicroseconds / 1000;
        }
      }
    }

    WidgetsBinding.instance.addTimingsCallback(timings);
    addTearDown(() async {
      WidgetsBinding.instance.removeTimingsCallback(timings);
      await activeVm?.close();
      await tester.pumpWidget(const SizedBox.shrink());
      container.dispose();
      await tracker.focus.dispose();
      await database.close();
      await sessions.close();
    });
    Future<void> until(bool Function() test, {int seconds = 90}) async {
      final clock = Stopwatch()..start();
      while (!test() && clock.elapsed < Duration(seconds: seconds)) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(test(), true, reason: 'M7 native condition timed out');
    }

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const MambaApp()),
    );
    await tester.runAsync(() => container.read(appStartupProvider.future));
    await tester.runAsync(() async {
      await database.delete(database.watchProgressRows).go();
      await database.delete(database.historyVideos).go();
    });
    const videoId = 'BV1wR4Xz6EqG';
    const startPart = int.fromEnvironment('M7_START_PART', defaultValue: 0);
    const cycleCount = int.fromEnvironment(
      'M7_RESOURCE_CYCLES',
      defaultValue: 20,
    );
    final detail = (await tester.runAsync(
      () => container
          .read(catalogRepositoryProvider)
          .getVideo(
            videoId,
            ownerKey: 'guest',
            cancellation: CancellationSignal(),
          ),
    ))!.valueOrThrow;
    expect(detail.parts.length, greaterThan(2));
    expect(
      detail.parts.fold<int>(0, (n, p) => n + p.durationSeconds),
      greaterThan(soakSeconds),
    );
    final router = container.read(appRouterProvider);
    late PlayerViewModelProvider provider;
    PlayerState state() => container.read(provider);
    PlayerViewModel vm() => container.read(provider.notifier);
    Future<void> enter() async {
      router.push<void>('/player/$videoId?part=${detail.parts[startPart].id}');
      await until(() => find.byType(PlayerPage).evaluate().isNotEmpty);
      provider = playerViewModelProvider(
        pageId: tester.widget<PlayerPage>(find.byType(PlayerPage)).pageId,
        ownerKey: 'guest',
      );
      activeVm = vm();
      await until(
        () =>
            state().phase == PlayerPhase.playing &&
            state().snapshot.position.inSeconds >= 1,
      );
    }

    final cycles = <Map<String, Object?>>[];
    for (var i = 0; i < cycleCount; i++) {
      await enter();
      await tester.runAsync(() => vm().close());
      activeVm = null;
      router.pop();
      await tester.pump(const Duration(seconds: 1));
      expect(tracker.active, 0);
      expect(tracker.maximum, 1);
      final sample = {
        'cycle': i + 1,
        'rssBytes': ProcessInfo.currentRss,
        'liveEngines': tracker.active,
      };
      cycles.add(sample);
      debugPrint('M7_CYCLE ${jsonEncode(sample)}');
    }
    await tester.runAsync(
      () => database.delete(database.watchProgressRows).go(),
    );
    await enter();
    expect(state().autoNext, true);
    expect(state().snapshot.rate, 1);
    final clock = Stopwatch()..start();
    final samples = <Map<String, Object?>>[],
        transitions = <Map<String, Object?>>[];
    var previousPart = state().partId;
    var previousPosition = state().snapshot.position;
    var advanced = Duration.zero;
    var nextSample = 0;
    debugPrint('M7_SOAK_STARTED');
    while (clock.elapsed < const Duration(seconds: soakSeconds)) {
      await tester.pump(const Duration(milliseconds: 500));
      if (state().phase == PlayerPhase.failed) {
        debugPrint(
          'M7_FAILED_STATE ${jsonEncode({'kind': state().failure?.kind.name, 'recoveryAttempts': state().recoveryAttempts, 'elapsedSeconds': clock.elapsed.inSeconds})}',
        );
        await until(() => state().phase == PlayerPhase.playing, seconds: 20);
      }
      expect(tracker.maximum, 1);
      if (state().phase == PlayerPhase.playing) {
        final position = state().snapshot.position;
        if (state().partId != previousPart) {
          advanced += previousPosition;
          transitions.add({
            'atSeconds': clock.elapsed.inSeconds,
            'fromPart': previousPart,
            'toPart': state().partId,
          });
          final index = detail.parts.indexWhere((p) => p.id == previousPart);
          expect(state().partId, detail.parts[index + 1].id);
          previousPart = state().partId;
        }
        previousPosition = position;
      }
      if (clock.elapsed.inSeconds >= nextSample &&
          state().phase == PlayerPhase.playing &&
          vm().engine != null) {
        final timeline = advanced + previousPosition;
        final engine = vm().engine! as MediaKitEngine;
        final native = engine.player.platform! as NativePlayer;
        final sample = {
          'elapsedSeconds': clock.elapsed.inSeconds,
          'partId': state().partId,
          'positionMs': state().snapshot.position.inMilliseconds,
          'cumulativeMediaMs': timeline.inMilliseconds,
          'rate': state().snapshot.rate,
          'durationMs': state().snapshot.duration.inMilliseconds,
          'nativeSpeed': await tester.runAsync(
            () => native.getProperty('speed'),
          ),
          'nativePosition': await tester.runAsync(
            () => native.getProperty('time-pos'),
          ),
          'audioOutput': await tester.runAsync(
            () => native.getProperty('current-ao'),
          ),
          'audioSpeedCorrection': await tester.runAsync(
            () => native.getProperty('audio-speed-correction'),
          ),
          'phase': state().phase.name,
          'audioSampleRate': state().snapshot.audioSampleRate,
          'rssBytes': ProcessInfo.currentRss,
          'imageCacheBytes':
              PaintingBinding.instance.imageCache.currentSizeBytes,
          'liveEngines': tracker.active,
          'avSyncSeconds': double.tryParse(
            await tester.runAsync(() => native.getProperty('avsync')) ?? '',
          ),
        };
        expect(state().snapshot.audioSampleRate, greaterThan(0));
        samples.add(sample);
        debugPrint('M7_SAMPLE ${jsonEncode(sample)}');
        expect(
          (timeline - clock.elapsed).abs(),
          lessThan(const Duration(seconds: 30)),
          reason: 'Media timeline must advance at 1x across natural part boundaries',
        );

        nextSample += 60;
      }
    }
    if (soakSeconds > detail.parts[startPart].durationSeconds + 30) {
      expect(transitions, isNotEmpty);
    }
    expect(
      ((advanced + previousPosition) - clock.elapsed).abs(),
      lessThan(const Duration(seconds: 30)),
    );
    final cumulativeAtEndMs = (advanced + previousPosition).inMilliseconds;
    await tester.runAsync(() => vm().close());
    activeVm = null;
    router.pop();
    await tester.pump(const Duration(seconds: 2));
    expect(tracker.active, 0);
    expect(tracker.created, tracker.released);
    double p95(List<double> values) {
      final sorted = [...values]..sort();
      return sorted.isEmpty ? 0 : sorted[((sorted.length - 1) * .95).round()];
    }

    binding.reportData = {
      'status': 'passed',
      'recordedAtUtc': DateTime.now().toUtc().toIso8601String(),
      'mode': 'profile',
      'isolatedPackage': true,
      'owner': 'guest',
      'remoteWrites': container
          .read(bilibiliApiProvider)
          .remoteWriteRequestsSent,
      'requestedSeconds': soakSeconds,
      'cumulativeMediaAtEndMs': cumulativeAtEndMs,
      'elapsedSeconds': clock.elapsed.inSeconds,
      'requestedDurationMet': clock.elapsed.inSeconds >= soakSeconds,
      'fifteenMinuteThresholdMet': clock.elapsed.inSeconds >= 900,
      'twoHourThresholdMet': clock.elapsed.inSeconds >= 7200,
      'videoId': videoId,
      'cycles': cycles,
      'nativeErrorEvents': tracker.errors,
      'samples': samples,
      'naturalAutoNextTransitions': transitions,
      'maximumEngines': tracker.maximum,
      'created': tracker.created,
      'released': tracker.released,
      'liveAfterReturn': tracker.active,
      'finalRssBytes': ProcessInfo.currentRss,
      'frameSamplesTotal': frameCount,
      'frameWindowSize': builds.length,
      'buildWindowP95Ms': p95(builds),
      'rasterWindowP95Ms': p95(rasters),
      'manualLipSyncVerified': false,
      'physicalTv': false,
    };
  }, timeout: const Timeout(Duration(seconds: soakSeconds + 1200)));
}
