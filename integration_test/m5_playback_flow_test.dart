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
import 'package:mambatv/app/router.dart';
import 'package:mambatv/app/providers/infrastructure_providers.dart';
import 'package:mambatv/app/providers/playback_providers.dart';
import 'package:mambatv/app/providers/repository_providers.dart';
import 'package:mambatv/app/providers/ui_providers.dart';
import 'package:mambatv/core/result.dart';
import 'package:mambatv/data/repositories/memory_session_repository.dart';
import 'package:mambatv/data/repositories/bilibili_playback_repository.dart';
import 'package:mambatv/data/services/local/app_database.dart';
import 'package:mambatv/data/services/playback/audio_session_focus.dart';
import 'package:mambatv/data/services/playback/media_kit_engine.dart';
import 'package:mambatv/domain/playback/playback.dart';
import 'package:mambatv/ui/features/player/view_models/player_view_model.dart';
import 'package:mambatv/ui/features/player/views/player_page.dart';

class M5Tracker {
  int active = 0, maximum = 0, created = 0, released = 0;
  final focus = AudioSessionFocus();
  PlaybackAdapter get adapter => PlaybackAdapter(
    focus: focus,
    create: () => M5Engine(this),
    surface: (engine) => Video(
      controller: (engine as MediaKitEngine).controller,
      controls: null,
      pauseUponEnteringBackgroundMode: false,
      resumeUponEnteringForegroundMode: false,
    ),
  );
}

class M5Engine extends MediaKitEngine {
  M5Engine(this.tracker)
    : super(onOpenStage: (stage) => debugPrint('M5_OPEN_$stage')) {
    tracker.created++;
    tracker.active++;
    if (tracker.active > tracker.maximum) tracker.maximum = tracker.active;
  }
  final M5Tracker tracker;
  bool closing = false;
  @override
  Future<void> dispose() async {
    if (closing) return;
    closing = true;
    try {
      await super.dispose();
    } finally {
      tracker.active--;
      tracker.released++;
    }
  }
}

class ExpiryProbe implements PlaybackRepository {
  ExpiryProbe(this.inner);
  final PlaybackRepository inner;
  String? expiredUrl;
  int calls = 0;
  @override
  Future<Result<PlaybackSource>> resolve({
    required String videoId,
    required String partId,
    required CancellationSignal cancellation,
    int? quality,
    int? audioId,
  }) async {
    calls++;
    final result = await inner.resolve(
      videoId: videoId,
      partId: partId,
      cancellation: cancellation,
      quality: quality,
      audioId: audioId,
    );
    if (result case Success<PlaybackSource>(:final value)) {
      final invalid = expiredUrl;
      expiredUrl = null;
      if (invalid != null) {
        return Success(
          PlaybackSource(
            videoUrl: invalid,
            audioUrl: value.audioUrl,
            duration: value.duration,
            quality: value.quality,
            codec: value.codec,
            qualities: value.qualities,
            audioTracks: value.audioTracks,
            audioId: value.audioId,
            videoBackups: const bool.fromEnvironment('M5_TEST_BACKUP')
                ? value.videoBackups
                : const [],
            audioBackups: const bool.fromEnvironment('M5_TEST_BACKUP')
                ? value.audioBackups
                : const [],
          ),
        );
      }
    }
    return result;
  }
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  testWidgets(
    'M5 native controls, recovery, lifecycle and continuous profile playback',
    (tester) async {
      final tracker = M5Tracker();
      final database = AppDatabase(
        driftDatabase(name: 'mambatv_m5_validation'),
      );
      final sessions = MemorySessionRepository();
      final container = ProviderContainer(
        retry: (_, _) => null,
        overrides: [
          sessionRepositoryProvider.overrideWithValue(sessions),
          appDatabaseProvider.overrideWithValue(database),
          playbackAdapterProvider.overrideWithValue(tracker.adapter),
          playbackRepositoryProvider.overrideWith(
            (ref) => ExpiryProbe(
              BilibiliPlaybackRepository(ref.watch(bilibiliApiProvider)),
            ),
          ),
        ],
      );
      final frames = <FrameTiming>[];
      void timings(List<FrameTiming> timings) => frames.addAll(timings);
      WidgetsBinding.instance.addTimingsCallback(timings);
      addTearDown(() async {
        WidgetsBinding.instance.removeTimingsCallback(timings);
        container.dispose();
        await tracker.focus.dispose();
        await database.close();
        await sessions.close();
      });
      Future<void> until(bool Function() predicate, {int seconds = 90}) async {
        final end = DateTime.now().add(Duration(seconds: seconds));
        while (!predicate() && DateTime.now().isBefore(end)) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(predicate(), isTrue, reason: 'Native M5 condition timed out');
      }

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MambaApp(),
        ),
      );
      await tester.runAsync(() => container.read(appStartupProvider.future));
      final expiry = container.read(playbackRepositoryProvider) as ExpiryProbe;
      await tester.runAsync(
        () => database.delete(database.watchProgressRows).go(),
      );
      const videoId = String.fromEnvironment(
        'M5_VIDEO',
        defaultValue: 'BV1hQHW63EMc',
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
      final part = detail.parts.firstWhere((p) => p.durationSeconds > 2000);
      container
          .read(appRouterProvider)
          .push<void>('/player/$videoId?part=${part.id}');
      await until(() => find.byType(PlayerPage).evaluate().isNotEmpty);
      final page = tester.widget<PlayerPage>(find.byType(PlayerPage));
      final provider = playerViewModelProvider(
        pageId: page.pageId,
        ownerKey: 'guest',
      );
      PlayerState state() => container.read(provider);
      PlayerViewModel vm() => container.read(provider.notifier);
      await until(
        () =>
            state().phase == PlayerPhase.playing &&
            state().snapshot.position.inSeconds >= 3,
      );
      expect(state().snapshot.audioSampleRate, greaterThan(0));
      await tester.runAsync(() => vm().togglePause());
      await tester.runAsync(() => vm().seekBy(const Duration(seconds: 12)));
      await tester.runAsync(() => vm().setRate(1.25));
      await tester.runAsync(() => vm().setVolume(75));
      final beforeQuality = state().snapshot.position;
      final otherQuality = state().qualities
          .firstWhere((q) => q.available && q.id != state().quality)
          .id;
      unawaited(vm().selectQuality(otherQuality));
      await until(
        () =>
            state().phase == PlayerPhase.paused &&
            state().quality == otherQuality,
      );
      final qualityErrorMs = (state().snapshot.position - beforeQuality)
          .abs()
          .inMilliseconds;
      expect(qualityErrorMs, lessThanOrEqualTo(2000));
      expect(state().snapshot.playing, isFalse);
      expect(state().snapshot.rate, 1.25);
      expect(state().snapshot.volume, 75);
      final otherAudio = state().audioTracks
          .firstWhere((a) => a.id != state().audioId)
          .id;
      final beforeAudio = state().snapshot.position;
      unawaited(vm().selectAudio(otherAudio));
      await until(
        () =>
            state().phase == PlayerPhase.paused &&
            state().audioId == otherAudio,
      );
      final audioErrorMs = (state().snapshot.position - beforeAudio)
          .abs()
          .inMilliseconds;
      expect(audioErrorMs, lessThanOrEqualTo(2000));
      await tester.runAsync(() => vm().setRate(1));
      await tester.runAsync(() => vm().setVolume(100));
      final normalSaved = state().snapshot.position;
      await tester.runAsync(() => vm().close());
      unawaited(vm().start(videoId, partId: part.id));
      await until(() => state().phase == PlayerPhase.playing);
      final normalResumeErrorMs = (state().snapshot.position - normalSaved)
          .abs()
          .inMilliseconds;
      expect(normalResumeErrorMs, lessThanOrEqualTo(2000));
      // A real HTTP 403 resource supplied by a test-local server, not a fake frame event.
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final serverSubscription = server.listen((request) async {
        request.response.statusCode =
            const bool.fromEnvironment('M5_TEST_BACKUP') ? 503 : 403;
        await request.response.close();
      });
      expiry.expiredUrl = 'http://127.0.0.1:${server.port}/expired';
      final callsBeforeExpiry = expiry.calls;
      final beforeRecovery = state().snapshot.position;
      unawaited(vm().start(videoId, partId: part.id));
      await until(
        () =>
            state().phase == PlayerPhase.playing &&
            state().recoveryAttempts > 0,
      );
      final expiryReparses = expiry.calls - callsBeforeExpiry;
      final recoveryAttempts = state().recoveryAttempts;
      final recoveryResumeErrorMs = (state().snapshot.position - beforeRecovery)
          .abs()
          .inMilliseconds;
      expect(recoveryResumeErrorMs, lessThanOrEqualTo(2000));
      expect(expiryReparses, lessThanOrEqualTo(2));
      await server.close(force: true);
      await serverSubscription.cancel();
      const hostCycles = bool.fromEnvironment('M5_HOST_CYCLES');
      final lifecycle = <Map<String, Object?>>[];
      var backgroundEvents = 0;
      final foregroundSubscription = container.listen(appForegroundProvider, (
        _,
        active,
      ) {
        if (!active) backgroundEvents++;
      });
      addTearDown(foregroundSubscription.close);
      if (hostCycles) {
        for (final mode in ['HOME', 'SLEEP']) {
          for (var i = 0; i < 10; i++) {
            final beforeBackground = backgroundEvents;
            debugPrint('M5_${mode}_WAIT_$i');
            // Screen-off can stop vsync. Retain the transition even when this
            // test pump returns only after the host wakes the display.
            await until(() => backgroundEvents > beforeBackground);
            await until(() => tracker.active == 0);
            expect(state().snapshot.playing, isFalse);
            final saved = state().snapshot.position;
            debugPrint('M5_${mode}_PAUSED_$i');
            await until(() => container.read(appForegroundProvider));
            expect(tracker.active, 0, reason: 'Foreground must never autoplay');
            unawaited(vm().togglePause());
            await until(() => state().phase == PlayerPhase.playing);
            final errorMs = (state().snapshot.position - saved)
                .abs()
                .inMilliseconds;
            expect(errorMs, lessThanOrEqualTo(2000));
            lifecycle.add({
              'mode': mode,
              'cycle': i + 1,
              'resumeErrorMs': errorMs,
              'liveAfterBackground': 0,
            });
            debugPrint('M5_${mode}_DONE_$i');
          }
        }
      }
      const soakMinutes = int.fromEnvironment(
        'M5_SOAK_MINUTES',
        defaultValue: 30,
      );
      // Return to a fresh zero timeline for the uninterrupted sample.
      unawaited(vm().start(videoId, partId: part.id));
      await until(() => state().phase == PlayerPhase.playing);
      await tester.runAsync(() => vm().togglePause());
      await tester.runAsync(() => vm().seekBy(-state().snapshot.position));
      await until(() => state().snapshot.position < const Duration(seconds: 1));
      await tester.runAsync(() => vm().setRate(1));
      await tester.runAsync(() => vm().togglePause());
      await until(() => state().phase == PlayerPhase.playing);
      final clock = Stopwatch()..start();
      final sampleStart = state().snapshot.position;
      final samples = <Map<String, Object?>>[];
      debugPrint('M5_SOAK_STARTED');
      var nextSample = 0;
      while (clock.elapsed < Duration(minutes: soakMinutes)) {
        await tester.pump(const Duration(milliseconds: 500));
        expect(state().phase, PlayerPhase.playing);
        if (clock.elapsed.inSeconds >= nextSample) {
          final engine = vm().engine! as MediaKitEngine;
          final native = engine.player.platform! as NativePlayer;
          String? avSync;
          try {
            avSync = await tester.runAsync(() => native.getProperty('avsync'));
          } catch (_) {}
          final sample = <String, Object?>{
            'elapsedSeconds': clock.elapsed.inSeconds,
            'positionMs': state().snapshot.position.inMilliseconds,
            'durationMs': state().snapshot.duration.inMilliseconds,
            'rate': state().snapshot.rate,
            'nativeSpeed': await tester.runAsync(
              () => native.getProperty('speed'),
            ),
            'audioOutput': await tester.runAsync(
              () => native.getProperty('current-ao'),
            ),
            'audioSpeedCorrection': await tester.runAsync(
              () => native.getProperty('audio-speed-correction'),
            ),
            'videoSync': await tester.runAsync(
              () => native.getProperty('video-sync'),
            ),
            'audioSampleRate': state().snapshot.audioSampleRate,
            'width': state().snapshot.width,
            'height': state().snapshot.height,
            'avSyncSeconds': double.tryParse(avSync ?? ''),
          };
          samples.add(sample);
          debugPrint('M5_SAMPLE ${jsonEncode(sample)}');
          expect(
            ((state().snapshot.position - sampleStart) - clock.elapsed).abs(),
            lessThan(const Duration(seconds: 10)),
            reason: 'At 1x the media timeline must follow the monotonic clock',
          );
          debugPrint('M5_SOAK_MINUTE_${clock.elapsed.inMinutes}');
          nextSample += 60;
        }
      }
      final endPosition = state().snapshot.position;
      expect(
        endPosition - sampleStart,
        greaterThan(
          Duration(minutes: soakMinutes) - const Duration(seconds: 10),
        ),
      );
      await tester.runAsync(() => vm().close());
      expect(tracker.active, 0);
      double? p95(Iterable<Duration> values) {
        final sorted = values.map((v) => v.inMicroseconds / 1000).toList()
          ..sort();
        return sorted.isEmpty
            ? null
            : sorted[((sorted.length - 1) * .95).round()];
      }

      binding.reportData = {
        'status': 'passed',
        'applicationId': const bool.fromEnvironment('MAMBA_VALIDATION_APP')
            ? 'app.mamba.mambatv.validation'
            : 'app.mamba.mambatv',
        'recordedAtUtc': DateTime.now().toUtc().toIso8601String(),
        'mode': kProfileMode ? 'profile' : 'debug',
        'videoId': videoId,
        'partId': part.id,
        'qualitySwitchTarget': otherQuality,
        'audioSwitchTarget': otherAudio,
        'qualitySwitchErrorMs': qualityErrorMs,
        'audioSwitchErrorMs': audioErrorMs,
        'pausedIntentRetained': true,
        'normalResumeErrorMs': normalResumeErrorMs,
        'injectedResource': const bool.fromEnvironment('M5_TEST_BACKUP')
            ? 'test-local HTTP 503 with real paired backups'
            : 'test-local HTTP 403',
        'recoveryAttempts': recoveryAttempts,
        'recoveryResumeErrorMs': recoveryResumeErrorMs,
        'resolveCallsIncludingInjectedResource': expiryReparses,
        'lifecycle': lifecycle,
        'soakSeconds': clock.elapsed.inSeconds,
        'soakStartMs': sampleStart.inMilliseconds,
        'soakEndMs': endPosition.inMilliseconds,
        'samples': samples,
        'maximumEngines': tracker.maximum,
        'created': tracker.created,
        'released': tracker.released,
        'liveAfterReturn': tracker.active,
        'flutterFrameSamples': frames.length,
        'buildP95Ms': p95(frames.map((f) => f.buildDuration)),
        'rasterP95Ms': p95(frames.map((f) => f.rasterDuration)),
        'manualLipSyncVerified': false,
      };
    },
    timeout: const Timeout(Duration(minutes: 45)),
  );
}
