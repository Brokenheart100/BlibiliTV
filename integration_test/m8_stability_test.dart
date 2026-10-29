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
import 'package:mambatv/app/app.dart';
import 'package:mambatv/app/logging/app_container.dart';
import 'package:mambatv/app/bootstrap.dart';
import 'package:mambatv/app/providers/infrastructure_providers.dart';
import 'package:mambatv/app/providers/repository_providers.dart';
import 'package:mambatv/app/providers/playback_providers.dart';
import 'package:mambatv/app/providers/overlay_providers.dart';
import 'package:mambatv/app/providers/ui_providers.dart';
import 'package:mambatv/domain/overlays/overlays.dart';
import 'package:mambatv/ui/features/player/view_models/overlay_view_models.dart';
import 'package:mambatv/app/router.dart';
import 'package:mambatv/core/result.dart';
import 'package:mambatv/data/repositories/local_settings_repository.dart';
import 'package:mambatv/data/repositories/memory_session_repository.dart';
import 'package:mambatv/data/services/local/app_database.dart';
import 'package:mambatv/data/services/playback/better_player_engine.dart';
import 'package:mambatv/data/services/playback/audio_session_focus.dart';
import 'package:mambatv/domain/playback/playback.dart';
import 'package:mambatv/domain/entities/app_models.dart';
import 'package:mambatv/ui/core/images/tv_image_cache.dart';
import 'package:mambatv/ui/features/player/views/player_page.dart';
import 'package:mambatv/ui/features/player/views/playback_overlays.dart';
import 'package:mambatv/ui/features/player/view_models/player_view_model.dart';

import '../test/support/memory_preferences.dart';
import '../test/support/fake_overlays.dart';

class M8Tracker {
  int active = 0, maximum = 0, created = 0, released = 0;
  final focus = AudioSessionFocus();
  final errors = <Map<String, Object?>>[];
  PlaybackAdapter get adapter => PlaybackAdapter(
    focus: focus,
    create: () => M8Engine(this),
    surface: (engine) => BetterPlayerSurface(engine as BetterPlayerEngine),
  );
}

class M8Engine extends BetterPlayerEngine {
  M8Engine(this.tracker) {
    tracker.created++;
    tracker.active++;
    if (tracker.active > tracker.maximum) tracker.maximum = tracker.active;
    subscription = snapshots.listen((value) {
      final failure = value.failure;
      if (failure != null && failure.kind != previousFailure) {
        previousFailure = failure.kind;
        if (tracker.errors.length < 100) {
          tracker.errors.add({'kind': failure.kind.name});
        }
      }
    });
  }
  final M8Tracker tracker;
  late final StreamSubscription<EngineSnapshot> subscription;
  FailureKind? previousFailure;
  bool closing = false;
  @override
  Future<void> dispose() async {
    if (closing) return;
    closing = true;
    await subscription.cancel();
    try {
      await super.dispose();
    } finally {
      tracker.active--;
      tracker.released++;
    }
  }
}

const soakSeconds = int.fromEnvironment('M8_SOAK_SECONDS', defaultValue: 900);
const danmakuOnly = bool.fromEnvironment('M8_DANMAKU_ONLY');
const fixedMaximumDanmaku = bool.fromEnvironment('M8_FIXED_MAX_DANMAKU');
const syntheticDanmakuPerSecond = int.fromEnvironment(
  'M8_SYNTHETIC_PER_SECOND',
  defaultValue: 20,
);
const pressureDensity = int.fromEnvironment(
  'M8_PRESSURE_DENSITY',
  defaultValue: 40,
);

double _p95(List<double> values) {
  final sorted = [...values]..sort();
  return sorted.isEmpty ? 0 : sorted[((sorted.length - 1) * .95).round()];
}

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
    if (fixedMaximumDanmaku) {
      expect(danmakuOnly, isTrue);
      expect(pressureDensity, 40);
    }
    final tracker = M8Tracker();
    final database = AppDatabase(driftDatabase(name: 'mambatv_m8_soak'));
    final sessions = MemorySessionRepository();
    final preferences = LocalSettingsRepository(MemoryPreferencesStore());
    final subtitles = danmakuOnly ? FakeOverlays() : M8Subtitles();
    final overlayPreferences = MemoryOverlayPreferences()
      ..preferences = const OverlayPreferences(
        subtitles: !danmakuOnly,
        danmaku: true,
        density: pressureDensity,
        area: fixedMaximumDanmaku ? 1 : .5,
        subtitleBottom: 100,
      );
    late M8PressureDanmaku pressure;
    await preferences.save(const AppSettings(autoNext: true));
    final container = createAppContainer(
      overrides: [
        sessionRepositoryProvider.overrideWithValue(sessions),
        appDatabaseProvider.overrideWithValue(database),
        settingsRepositoryProvider.overrideWithValue(preferences),
        playbackAdapterProvider.overrideWithValue(tracker.adapter),
        subtitleRepositoryProvider.overrideWithValue(subtitles),
        if (fixedMaximumDanmaku)
          danmakuAdaptiveLoadProvider.overrideWithValue(false),
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
      'backend': 'Better Player / Media3',
      'requestedSeconds': soakSeconds,
      'physicalTv': false,
      'manualLipSyncVerified': false,
      'danmakuOnly': danmakuOnly,
      'fixedMaximumDanmaku': fixedMaximumDanmaku,
      'pressureDensity': pressureDensity,
      'pressureArea': fixedMaximumDanmaku ? 1 : .5,
      'adaptiveDensity': !fixedMaximumDanmaku,
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
      await tester.runAsync(() async => activeVm?.close());
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
    Future<double> nativePositionMs() async {
      final position = await tester.runAsync(
        () => (vm().engine! as BetterPlayerEngine).controller.position,
      );
      expect(position, isNotNull);
      return position!.inMicroseconds / 1000;
    }

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
      expect(vm().engine, isA<BetterPlayerEngine>());
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
    final controlSamples = <Map<String, Object?>>[];
    final originalQuality = state().quality, originalAudio = state().audioId;
    binding.reportData!['controlSamples'] = controlSamples;
    Future<void> controlSample(String stage) async {
      await until(
        () => state().snapshot.bufferedPosition > state().snapshot.position,
      );
      final native = await nativePositionMs();
      expect(
        (native - state().snapshot.position.inMilliseconds).abs(),
        lessThan(2000),
      );
      expect(state().seekTarget, isNull);
      expect(state().snapshot.failure, isNull);
      controlSamples.add({
        'stage': stage,
        'nativePositionMs': native,
        'positionMs': state().snapshot.position.inMilliseconds,
        'bufferedPositionMs': state().snapshot.bufferedPosition.inMilliseconds,
        'playing': state().snapshot.playing,
      });
    }

    if (!danmakuOnly) {
      await tester.runAsync(() => vm().togglePause());
      await until(() => state().phase == PlayerPhase.paused);
      for (final seconds in [60, -45]) {
        await tester.runAsync(() => vm().seekBy(Duration(seconds: seconds)));
        expect(state().snapshot.playing, isFalse);
        await controlSample('paused-seek-$seconds');
      }
      await tester.runAsync(() => vm().setRate(1.25));
      await tester.runAsync(() => vm().setVolume(75));
      final otherQualities = state().qualities.where(
        (q) => q.available && q.id != state().quality,
      );
      if (otherQualities.isNotEmpty) {
        final target = otherQualities.first.id;
        final saved = state().snapshot.position;
        unawaited(vm().selectQuality(target));
        await until(
          () =>
              state().quality == target && state().phase == PlayerPhase.paused,
        );
        expect(
          (state().snapshot.position - saved).abs(),
          lessThan(const Duration(seconds: 2)),
        );
        expect(state().snapshot.rate, 1.25);
        expect(state().snapshot.volume, 75);
        await controlSample('paused-quality');
      }
      final otherAudio = state().audioTracks.where(
        (a) => a.available && a.id != state().audioId,
      );
      if (otherAudio.isNotEmpty) {
        final target = otherAudio.first.id;
        final saved = state().snapshot.position;
        unawaited(vm().selectAudio(target));
        await until(
          () =>
              state().audioId == target && state().phase == PlayerPhase.paused,
        );
        expect(
          (state().snapshot.position - saved).abs(),
          lessThan(const Duration(seconds: 2)),
        );
        await controlSample('paused-audio');
      }
      if (state().quality != originalQuality) {
        unawaited(vm().selectQuality(originalQuality));
        await until(
          () =>
              state().quality == originalQuality &&
              state().phase == PlayerPhase.paused,
        );
      }
      if (state().audioId != originalAudio) {
        unawaited(vm().selectAudio(originalAudio));
        await until(
          () =>
              state().audioId == originalAudio &&
              state().phase == PlayerPhase.paused,
        );
      }
      await tester.runAsync(() => vm().setRate(1));
      await tester.runAsync(() => vm().setVolume(100));
      await tester.runAsync(() => vm().togglePause());
      for (final seconds in [120, -90, 60, -30]) {
        await tester.runAsync(() => vm().seekBy(Duration(seconds: seconds)));
        await controlSample('playing-seek-$seconds');
        final before = state().snapshot.position;
        await until(
          () => state().snapshot.position > before + const Duration(seconds: 1),
        );
      }
    }
    final lifecycle = <Map<String, Object?>>[];
    binding.reportData!['lifecycle'] = lifecycle;
    if (const bool.fromEnvironment('M8_HOST_CYCLES')) {
      var backgrounds = 0;
      final listener = container.listen(appForegroundProvider, (_, active) {
        if (!active) backgrounds++;
      });
      addTearDown(listener.close);
      for (var i = 0; i < 10; i++) {
        final before = backgrounds;
        debugPrint('M8_HOME_WAIT_$i');
        await until(
          () => backgrounds > before && container.read(appForegroundProvider),
        );
        await until(() => tracker.active == 0);
        expect(state().snapshot.playing, isFalse);
        expect(container.read(overlayMetricsProvider).activeSchedulers, 0);
        final saved = state().snapshot.position;
        await tester.runAsync(() => vm().togglePause());
        await until(() => state().phase == PlayerPhase.playing);
        final error = (state().snapshot.position - saved).abs().inMilliseconds;
        expect(error, lessThanOrEqualTo(2000));
        lifecycle.add({
          'cycle': i + 1,
          'resumeErrorMs': error,
          'releasedInBackground': true,
        });
        debugPrint('M8_HOME_DONE_$i');
      }
    }
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
          area: fixedMaximumDanmaku ? 1 : .5,
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
      final beforeEvaluations = container
          .read(overlayMetricsProvider)
          .frameEvaluations;
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
        'frameEvaluations':
            container.read(overlayMetricsProvider).frameEvaluations -
            beforeEvaluations,
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
        if (fixedMaximumDanmaku) {
          expect(container.read(overlayMetricsProvider).density, 40);
          expect(container.read(overlayMetricsProvider).lowLoadTransitions, 0);
          expect(subtitles.signals, isEmpty);
        }
        expect(
          container.read(overlayMetricsProvider).canvasDrawTickMs - beforePaint,
          greaterThan(5000),
          reason: 'The measured canvas must actually animate',
        );
      }
    }
    // Preserve the original gates, but finish the stability run even if an A/B
    // gate fails. The final test still fails and reports both kinds of evidence.
    final performanceFailures = <String>[
      for (final result in comparisons)
        if ((result['buildP95Ms'] as double) > 16.7 ||
            (result['rasterP95Ms'] as double) > 16.7)
          '${result['mode']}: frame P95 exceeds 16.7 ms',
      if ((comparisons.last['rasterP95Ms'] as double) -
              (comparisons.first['rasterP95Ms'] as double) >
          3)
        'Danmaku raster P95 incremental budget exceeds 3 ms',
    ];
    binding.reportData!['performanceFailures'] = performanceFailures;
    void checkContinuousFrameBudget(double buildP95, double rasterP95) {
      for (final failure in [
        if (buildP95 > 16.7) 'Continuous build P95 exceeds 16.7 ms',
        if (rasterP95 > 16.7) 'Continuous raster P95 exceeds 16.7 ms',
      ]) {
        if (!performanceFailures.contains(failure)) {
          performanceFailures.add(failure);
        }
      }
    }

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
      final nativePosition = await nativePositionMs();
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
    var fixedDensityChecks = 0, renderedSum = 0, maximumRenderedDuringSoak = 0;
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
      final currentOverlay = container.read(overlayMetricsProvider);
      if (fixedMaximumDanmaku && currentOverlay.activeSchedulers > 0) {
        expect(
          currentOverlay.density,
          40,
          reason: 'Maximum-density pressure cannot silently become a lower-density test',
        );
        expect(currentOverlay.lowLoadTransitions, 0);
        expect(subtitles.signals, isEmpty);
        fixedDensityChecks++;
        renderedSum += currentOverlay.renderedDanmaku;
        if (currentOverlay.renderedDanmaku > maximumRenderedDuringSoak) {
          maximumRenderedDuringSoak = currentOverlay.renderedDanmaku;
        }
      }
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
        final buildP95 = _p95(builds), rasterP95 = _p95(rasters);
        if (clock.elapsed.inSeconds >= 60) {
          checkContinuousFrameBudget(buildP95, rasterP95);
        }
        final sample = {
          'elapsedSeconds': clock.elapsed.inSeconds,
          'partId': state().partId,
          'positionMs': state().snapshot.position.inMilliseconds,
          'cumulativeMediaMs': timeline.inMilliseconds,
          'rate': state().snapshot.rate,
          'durationMs': state().snapshot.duration.inMilliseconds,
          'nativePositionMs': await nativePositionMs(),
          'bufferedPositionMs':
              state().snapshot.bufferedPosition.inMilliseconds,
          'videoWidth': state().snapshot.width,
          'videoHeight': state().snapshot.height,
          'phase': state().phase.name,
          'rssBytes': ProcessInfo.currentRss,
          'imageCacheBytes':
              PaintingBinding.instance.imageCache.currentSizeBytes,
          'liveEngines': tracker.active,
          'frameWindowSize': builds.length,
          'buildWindowP95Ms': buildP95,
          'rasterWindowP95Ms': rasterP95,
          'overlayMetrics': container.read(overlayMetricsProvider).snapshot(),
        };
        expect(state().snapshot.width, greaterThan(0));
        expect(state().snapshot.failure, isNull);
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
    // Freeze playback timings before release/pop/home animations add frames.
    final continuousBuildP95 = _p95(builds);
    final continuousRasterP95 = _p95(rasters);
    final continuousFrameCount = frameCount;
    final continuousWindowSize = builds.length;
    checkContinuousFrameBudget(continuousBuildP95, continuousRasterP95);
    if (danmakuOnly) {
      expect(subtitles.signals, isEmpty);
      expect(find.byKey(const Key('player-subtitle-text')), findsNothing);
    }
    if (fixedMaximumDanmaku) {
      expect(fixedDensityChecks, greaterThan(soakSeconds));
      expect(maximumRenderedDuringSoak, 40);
    }
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
    binding.reportData = {
      'status': performanceFailures.isEmpty ? 'passed' : 'failed',
      'playbackRegressionStatus': 'passed',
      'performanceFailures': performanceFailures,
      'controlSamples': controlSamples,
      'lifecycle': lifecycle,
      'recordedAtUtc': DateTime.now().toUtc().toIso8601String(),
      'mode': 'profile',
      'danmakuOnly': danmakuOnly,
      'fixedMaximumDanmaku': fixedMaximumDanmaku,
      'pressureDensity': pressureDensity,
      'pressureArea': fixedMaximumDanmaku ? 1 : .5,
      'adaptiveDensity': !fixedMaximumDanmaku,
      'fixedDensityChecks': fixedDensityChecks,
      'maximumRenderedDuringSoak': maximumRenderedDuringSoak,
      'meanRenderedDuringSoak': fixedDensityChecks == 0
          ? null
          : renderedSum / fixedDensityChecks,
      'subtitleRequests': subtitles.signals.length,
      'syntheticDanmakuPerSecond': syntheticDanmakuPerSecond,
      'isolatedPackage': true,
      'owner': 'guest',
      'remoteWrites': container
          .read(bilibiliApiProvider)
          .remoteWriteRequestsSent,
      'backend': 'Better Player / Media3',
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
      'frameSamplesTotal': continuousFrameCount,
      'frameWindowSize': continuousWindowSize,
      'buildWindowP95Ms': continuousBuildP95,
      'rasterWindowP95Ms': continuousRasterP95,
      'frameWindowIncludesExit': false,
      'manualLipSyncVerified': false,
      'physicalTv': false,
      'comparisonWindows': comparisons,
      'subtitleTimingSamples': subtitleSamples,
      'subtitleSource': danmakuOnly ? 'disabled; no tracks or cues requested' : 'synthetic multi-track fixture; real authenticated body read verified separately',
      'danmakuSource': syntheticDanmakuPerSecond == 0
          ? 'real public segments only'
          : 'real public segments plus $syntheticDanmakuPerSecond synthetic entries per media second',
      'realDanmakuDecoded': pressure.realCount,
      'syntheticDanmakuGenerated': pressure.syntheticCount,
      'overlayMetrics': container.read(overlayMetricsProvider).snapshot(),
    };
    expect(
      performanceFailures,
      isEmpty,
      reason: 'Original performance gates remain mandatory',
    );
  }, timeout: const Timeout(Duration(seconds: soakSeconds + 1200)));
}
