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
import 'package:media_kit/media_kit.dart' hide PlayerState, SubtitleTrack;
import 'package:media_kit_video/media_kit_video.dart';
import 'package:mambatv/app/app.dart';
import 'package:mambatv/app/bootstrap.dart';
import 'package:mambatv/app/providers/infrastructure_providers.dart';
import 'package:mambatv/app/providers/repository_providers.dart';
import 'package:mambatv/app/providers/playback_providers.dart';
import 'package:mambatv/app/providers/overlay_providers.dart';
import 'package:mambatv/domain/overlays/overlays.dart';
import 'package:mambatv/ui/features/player/view_models/overlay_view_models.dart';
import 'package:mambatv/app/router.dart';
import 'package:mambatv/core/result.dart';
import 'package:mambatv/data/repositories/local_settings_repository.dart';
import 'package:mambatv/data/repositories/memory_session_repository.dart';
import 'package:mambatv/data/services/local/app_database.dart';
import 'package:mambatv/data/services/playback/media_kit_engine.dart';
import 'package:mambatv/domain/entities/app_models.dart';
import 'package:mambatv/ui/core/images/tv_image_cache.dart';
import 'package:mambatv/ui/features/player/views/player_page.dart';
import 'package:mambatv/ui/features/player/views/playback_overlays.dart';
import 'package:mambatv/ui/features/player/view_models/player_view_model.dart';

import '../test/support/memory_preferences.dart';
import '../test/support/fake_overlays.dart';
import 'm5_playback_flow_test.dart' show M5Tracker, M5Engine;

class M8Tracker extends M5Tracker {
  final errors = <Map<String, Object?>>[];
  @override
  PlaybackAdapter get adapter => PlaybackAdapter(
    focus: focus,
    create: () => M8Engine(this),
    surface: (engine) => Video(
      controller: (engine as MediaKitEngine).controller,
      controls: null,
      pauseUponEnteringBackgroundMode: false,
      resumeUponEnteringForegroundMode: false,
    ),
  );
}

class M8Engine extends M5Engine {
  M8Engine(M8Tracker tracker) : super(tracker) {
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
      debugPrint('M8_NATIVE_ERROR ${jsonEncode(item)}');
    });
  }
  late final StreamSubscription<String> subscription;
  @override
  Future<void> dispose() async {
    await subscription.cancel();
    await super.dispose();
  }
}

const soakSeconds = int.fromEnvironment('M8_SOAK_SECONDS', defaultValue: 900);
const danmakuOnly = bool.fromEnvironment('M8_DANMAKU_ONLY');
const syntheticDanmakuPerSecond = int.fromEnvironment(
  'M8_SYNTHETIC_PER_SECOND',
  defaultValue: 20,
);
const pressureDensity = int.fromEnvironment(
  'M8_PRESSURE_DENSITY',
  defaultValue: 40,
);

class M8Subtitles extends FakeOverlays {
  M8Subtitles() {
    available = const [
      SubtitleTrack(id: 'synthetic-zh', language: 'zh', title: '合成时间轴验证'),
      SubtitleTrack(
        id: 'synthetic-en',
        language: 'en',
        title: 'Synthetic track',
      ),
    ];
    contents = {
      for (final track in available)
        track.id: List.generate(
          1200,
          (i) => SubtitleCue(
            startMs: i * 2000,
            endMs: i * 2000 + 1800,
            text: '${track.id} #$i',
          ),
        ),
    };
  }
}

class M8PressureDanmaku implements DanmakuRepository {
  M8PressureDanmaku(this.real);
  final DanmakuRepository real;
  int realCount = 0, syntheticCount = 0;
  @override
  Future<Result<DanmakuManifest>> manifest(
    String videoId,
    String partId,
    CancellationSignal signal,
  ) => real.manifest(videoId, partId, signal);
  @override
  Future<Result<List<DanmakuItem>>> segment(
    String partId,
    int index,
    CancellationSignal signal,
  ) async {
    final response = await real.segment(partId, index, signal);
    if (response is! Success<List<DanmakuItem>>) return response;
    realCount += response.value.length;
    final pressure = List.generate(
      syntheticDanmakuPerSecond * 360,
      (i) => DanmakuItem(
        id: 'pressure-$partId-$index-$i',
        timeMs: (index - 1) * 360000 + i * 1000 ~/ syntheticDanmakuPerSecond,
        mode: i % 8 == 0
            ? 5
            : i % 9 == 0
            ? 4
            : 1,
        color: 0xffffff,
        text: 'M8 synthetic pressure ${i % 20}',
      ),
    );
    syntheticCount += pressure.length;
    return Success(
      [...response.value, ...pressure]
        ..sort((a, b) => a.timeMs.compareTo(b.timeMs)),
    );
  }
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;
  MediaKit.ensureInitialized();
  TvImageCache.configure();
  testWidgets('M8 profile resource cycles and continuous UGC playlist', (
    tester,
  ) async {
    expect(const bool.fromEnvironment('MAMBA_VALIDATION_APP'), true);
    expect(const bool.fromEnvironment('MAMBA_READ_ONLY_VALIDATION'), true);
    expect(kProfileMode, true);
    final tracker = M8Tracker();
    final database = AppDatabase(driftDatabase(name: 'mambatv_m8_soak'));
    final sessions = MemorySessionRepository();
    final preferences = LocalSettingsRepository(MemoryPreferencesStore());
    final overlayPreferences = MemoryOverlayPreferences()
      ..preferences = const OverlayPreferences(
        subtitles: !danmakuOnly,
        danmaku: true,
        density: pressureDensity,
        subtitleBottom: 100,
      );
    late M8PressureDanmaku pressure;
    await preferences.save(const AppSettings(autoNext: true));
    final container = ProviderContainer(
      retry: (_, _) => null,
      overrides: [
        sessionRepositoryProvider.overrideWithValue(sessions),
        appDatabaseProvider.overrideWithValue(database),
        settingsRepositoryProvider.overrideWithValue(preferences),
        playbackAdapterProvider.overrideWithValue(tracker.adapter),
        subtitleRepositoryProvider.overrideWithValue(M8Subtitles()),
        overlayPreferencesRepositoryProvider.overrideWithValue(
          overlayPreferences,
        ),
        danmakuRepositoryProvider.overrideWith(
          (ref) => pressure = M8PressureDanmaku(
            ref.watch(overlayRepositoryProvider),
          ),
        ),
      ],
    );
    binding.reportData = {
      'status': 'running',
      'requestedSeconds': soakSeconds,
      'physicalTv': false,
      'manualLipSyncVerified': false,
      'danmakuOnly': danmakuOnly,
      'syntheticDanmakuPerSecond': syntheticDanmakuPerSecond,
    };
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
      if (binding.reportData?['status'] == 'running') {
        binding.reportData!['status'] = 'failed';
        binding.reportData!['overlayMetrics'] = container
            .read(overlayMetricsProvider)
            .snapshot();
      }
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
      expect(test(), true, reason: 'M8 native condition timed out');
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
    const startPart = int.fromEnvironment('M8_START_PART', defaultValue: 0);
    const cycleCount = int.fromEnvironment(
      'M8_RESOURCE_CYCLES',
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
      expect(container.read(overlayMetricsProvider).active, 0);
      expect(container.read(overlayMetricsProvider).activeSchedulers, 0);
      expect(tracker.maximum, 1);
      final sample = {
        'cycle': i + 1,
        'rssBytes': ProcessInfo.currentRss,
        'liveEngines': tracker.active,
      };
      cycles.add(sample);
      debugPrint('M8_CYCLE ${jsonEncode(sample)}');
    }
    await tester.runAsync(
      () => database.delete(database.watchProgressRows).go(),
    );
    final comparisons = <Map<String, Object?>>[];
    final subtitleSamples = <Map<String, Object?>>[];
    binding.reportData!['comparisonWindows'] = comparisons;
    binding.reportData!['subtitleTimingSamples'] = subtitleSamples;
    await enter();
    final preferencesVm = container.read(
      overlaySettingsViewModelProvider.notifier,
    );
    for (final mode
        in danmakuOnly ? ['off', 'danmaku'] : ['off', 'subtitles', 'both']) {
      await tester.runAsync(
        () => vm().seekBy(
          const Duration(seconds: 35) - state().snapshot.position,
        ),
      );
      await preferencesVm.savePreferences(
        OverlayPreferences(
          subtitles: !danmakuOnly && mode != 'off',
          danmaku: mode == 'both' || mode == 'danmaku',
          density: pressureDensity,
          subtitleBottom: 100,
        ),
      );
      if (mode == 'both' || mode == 'danmaku') {
        final overlay = tester.widget<PlaybackOverlays>(
          find.byType(PlaybackOverlays),
        );
        final overlayData = danmakuViewModelProvider(
          videoId: videoId,
          partId: state().partId,
          scopeKey: overlay.scopeKey,
        );
        await until(
          () =>
              container.read(overlayData).value?.loading == false &&
              (container.read(overlayData).value?.items.isNotEmpty ?? false),
        );
      }
      await tester.pump(const Duration(seconds: 18));
      expect(
        find.byKey(const Key('player-toggle')),
        findsNothing,
        reason: 'A/B windows must measure the same playback view with chrome hidden',
      );
      builds.clear();
      rasters.clear();
      frameCount = 0;
      final beforeTicks = container.read(overlayMetricsProvider).clockSamples;
      final beforePaint = container
          .read(overlayMetricsProvider)
          .canvasDrawTickMs;
      final window = Stopwatch()..start();
      while (window.elapsed < const Duration(seconds: 10)) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      double percentile(List<double> values, double p) {
        final sorted = [...values]..sort();
        return sorted.isEmpty ? 0 : sorted[((sorted.length - 1) * p).round()];
      }

      comparisons.add({
        'mode': mode,
        'elapsedMs': window.elapsedMilliseconds,
        'frameCount': frameCount,
        'buildP95Ms': percentile(builds, .95),
        'rasterP95Ms': percentile(rasters, .95),
        'rasterP99Ms': percentile(rasters, .99),
        'overBudgetRatio': rasters.isEmpty
            ? 0
            : rasters.where((v) => v > 16.7).length / rasters.length,
        'clockSamples':
            container.read(overlayMetricsProvider).clockSamples - beforeTicks,
        'disabledTransitions': container
            .read(overlayMetricsProvider)
            .disabledTransitions,
        'canvasFps': container.read(overlayMetricsProvider).canvasFps,
        'density': container.read(overlayMetricsProvider).density,
      });
      if (mode == 'off') {
        expect(
          container.read(overlayMetricsProvider).clockSamples,
          beforeTicks,
        );
      }
      expect(
        frameCount,
        greaterThan(200),
        reason: 'The native frame window must be populated',
      );
      debugPrint('M8_COMPARISON ${jsonEncode(comparisons.last)}');
      expect(
        container.read(overlayMetricsProvider).disabledTransitions,
        0,
        reason: 'A/B windows cannot benchmark a disabled canvas',
      );
      if (mode == 'both' || mode == 'danmaku') {
        expect(
          container.read(overlayMetricsProvider).canvasDrawTickMs - beforePaint,
          greaterThan(5000),
          reason: 'The measured canvas must actually animate',
        );
      }
    }
    for (final result in comparisons) {
      expect(result['buildP95Ms'] as double, lessThanOrEqualTo(16.7));
      expect(
        result['rasterP95Ms'] as double,
        lessThanOrEqualTo(16.7),
        reason: 'Sustained playback must meet the original 60Hz budget',
      );
    }
    expect(
      (comparisons.last['rasterP95Ms'] as double) -
          (comparisons.first['rasterP95Ms'] as double),
      lessThanOrEqualTo(3),
      reason: 'Danmaku raster P95 incremental budget',
    );
    for (final rate in danmakuOnly ? <double>[] : [.5, 1.0, 2.0]) {
      await tester.runAsync(() => vm().setRate(rate));
      await tester.runAsync(
        () => vm().seekBy(
          const Duration(seconds: 35) - state().snapshot.position,
        ),
      );
      await until(
        () =>
            state().phase == PlayerPhase.playing && !state().snapshot.buffering,
      );
      await tester.pump(const Duration(milliseconds: 100));
      await until(
        () =>
            find.byKey(const Key('player-subtitle-text')).evaluate().isNotEmpty,
      );
      final text = tester
          .widget<Text>(find.byKey(const Key('player-subtitle-text')))
          .data!;
      final cue = int.parse(text.split('#').last);
      final native =
          (vm().engine! as MediaKitEngine).player.platform! as NativePlayer;
      final nativePosition =
          double.parse(
            (await tester.runAsync(() => native.getProperty('time-pos')))!,
          ) *
          1000;
      final error = nativePosition < cue * 2000
          ? cue * 2000 - nativePosition
          : nativePosition > cue * 2000 + 1800
          ? nativePosition - (cue * 2000 + 1800)
          : 0.0;
      subtitleSamples.add({
        'rate': rate,
        'nativePositionMs': nativePosition,
        'cueStartMs': cue * 2000,
        'cueEndMs': cue * 2000 + 1800,
        'outsideCueMs': error,
      });
      expect(error, lessThanOrEqualTo(250));
    }
    await tester.runAsync(() => vm().setRate(1));
    await tester.runAsync(() => vm().close());
    activeVm = null;
    router.pop();
    await tester.pump(const Duration(seconds: 1));
    await tester.runAsync(
      () => database.delete(database.watchProgressRows).go(),
    );
    builds.clear();
    rasters.clear();
    frameCount = 0;
    await enter();
    expect(state().autoNext, true);
    expect(state().snapshot.rate, 1);
    final clock = Stopwatch()..start();
    final samples = <Map<String, Object?>>[],
        transitions = <Map<String, Object?>>[];
    binding.reportData!['samples'] = samples;
    var previousPart = state().partId;
    var previousPosition = state().snapshot.position;
    var advanced = Duration.zero;
    var nextSample = 0;
    var lastAdmitted = container.read(overlayMetricsProvider).admittedDanmaku;
    var lastCanvasTick = 0;
    var sampledPart = state().partId;
    final initialDisabled = container
        .read(overlayMetricsProvider)
        .disabledTransitions;
    debugPrint('M8_SOAK_STARTED');
    while (clock.elapsed < const Duration(seconds: soakSeconds)) {
      await tester.pump(const Duration(milliseconds: 500));
      if (state().phase == PlayerPhase.failed) {
        debugPrint(
          'M8_FAILED_STATE ${jsonEncode({'kind': state().failure?.kind.name, 'recoveryAttempts': state().recoveryAttempts, 'elapsedSeconds': clock.elapsed.inSeconds})}',
        );
        await until(() => state().phase == PlayerPhase.playing, seconds: 20);
      }
      expect(tracker.maximum, 1);
      expect(
        container.read(overlayMetricsProvider).disabledTransitions,
        initialDisabled,
        reason: 'A disabled canvas cannot count as continuous danmaku stress',
      );
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
          'audioPtsSeconds': double.tryParse(
            await tester.runAsync(() => native.getProperty('audio-pts')) ?? '',
          ),
          'overlayMetrics': container.read(overlayMetricsProvider).snapshot(),
        };
        expect(state().snapshot.audioSampleRate, greaterThan(0));
        samples.add(sample);
        final admitted = container.read(overlayMetricsProvider).admittedDanmaku;
        if (clock.elapsed.inSeconds >= 60) {
          expect(
            admitted,
            greaterThan(lastAdmitted),
            reason:
                'Dense overlay must remain active during this sampling window',
          );
          if (sampledPart == state().partId) {
            expect(
              container.read(overlayMetricsProvider).canvasDrawTickMs,
              greaterThan(lastCanvasTick),
              reason: 'The canvas paint clock must advance',
            );
          }
        }
        lastAdmitted = admitted;
        lastCanvasTick = container
            .read(overlayMetricsProvider)
            .canvasDrawTickMs;
        sampledPart = state().partId;
        debugPrint('M8_SAMPLE ${jsonEncode(sample)}');
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
    final overlayMetrics = container.read(overlayMetricsProvider);
    expect(overlayMetrics.active, 0);
    expect(overlayMetrics.activeSchedulers, 0);
    expect(overlayMetrics.created, overlayMetrics.disposed);
    expect(overlayMetrics.maximum, 1);
    expect(overlayMetrics.maximumDanmaku, lessThanOrEqualTo(40));
    expect(overlayMetrics.maximumRenderedDanmaku, inInclusiveRange(1, 40));
    expect(pressure.realCount, greaterThan(0));
    if (syntheticDanmakuPerSecond > 0) {
      expect(pressure.syntheticCount, greaterThan(0));
    }
    expect(overlayMetrics.admittedDanmaku, greaterThan(0));
    expect(
      tracker.errors,
      isEmpty,
      reason: 'Native errors must not be silently accepted',
    );
    expect(container.read(bilibiliApiProvider).remoteWriteRequestsSent, 0);
    double p95(List<double> values) {
      final sorted = [...values]..sort();
      return sorted.isEmpty ? 0 : sorted[((sorted.length - 1) * .95).round()];
    }

    binding.reportData = {
      'status': 'passed',
      'recordedAtUtc': DateTime.now().toUtc().toIso8601String(),
      'mode': 'profile',
      'danmakuOnly': danmakuOnly,
      'syntheticDanmakuPerSecond': syntheticDanmakuPerSecond,
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
      'comparisonWindows': comparisons,
      'subtitleTimingSamples': subtitleSamples,
      'subtitleSource': 'synthetic multi-track fixture; real authenticated body read verified separately',
      'danmakuSource': syntheticDanmakuPerSecond == 0
          ? 'real public segments only'
          : 'real public segments plus $syntheticDanmakuPerSecond synthetic entries per media second',
      'realDanmakuDecoded': pressure.realCount,
      'syntheticDanmakuGenerated': pressure.syntheticCount,
      'overlayMetrics': container.read(overlayMetricsProvider).snapshot(),
    };
  }, timeout: const Timeout(Duration(seconds: soakSeconds + 1200)));
}
