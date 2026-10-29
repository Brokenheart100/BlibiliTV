import 'dart:convert';

import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:media_kit/media_kit.dart' hide PlayerState;
import 'package:mambatv/app/app.dart';
import 'package:mambatv/app/bootstrap.dart';
import 'package:mambatv/app/logging/app_container.dart';
import 'package:mambatv/app/providers/infrastructure_providers.dart';
import 'package:mambatv/app/providers/repository_providers.dart';
import 'package:mambatv/app/providers/playback_providers.dart';
import 'package:mambatv/app/providers/overlay_providers.dart';
import 'package:mambatv/app/router.dart';
import 'package:mambatv/core/result.dart';
import 'package:mambatv/data/repositories/local_settings_repository.dart';
import 'package:mambatv/data/repositories/memory_session_repository.dart';
import 'package:mambatv/data/services/local/app_database.dart';
import 'package:mambatv/data/services/playback/better_player_engine.dart';
import 'package:mambatv/domain/entities/app_models.dart';
import 'package:mambatv/domain/overlays/overlays.dart';
import 'package:mambatv/domain/playback/playback_target.dart';
import 'package:mambatv/ui/features/player/view_models/player_view_model.dart';
import 'package:mambatv/ui/features/player/views/player_page.dart';

import '../test/support/fake_overlays.dart';
import '../test/support/memory_preferences.dart';
import 'm8_stability_test.dart' show M8Tracker;

const liveSeconds = int.fromEnvironment('M9_LIVE_SECONDS', defaultValue: 900);

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;
  MediaKit.ensureInitialized();
  testWidgets('M9 typed PGC and live real read-only native playback', (
    tester,
  ) async {
    expect(const bool.fromEnvironment('MAMBA_VALIDATION_APP'), isTrue);
    expect(const bool.fromEnvironment('MAMBA_READ_ONLY_VALIDATION'), isTrue);
    final tracker = M8Tracker();
    final db = AppDatabase(driftDatabase(name: 'mambatv_m9_validation'));
    final sessions = MemorySessionRepository();
    final settings = LocalSettingsRepository(MemoryPreferencesStore());
    await settings.save(const AppSettings(autoNext: true));
    final overlays = MemoryOverlayPreferences()
      ..preferences = const OverlayPreferences(
        subtitles: false,
        danmaku: false,
      );
    final container = createAppContainer(
      overrides: [
        sessionRepositoryProvider.overrideWithValue(sessions),
        appDatabaseProvider.overrideWithValue(db),
        settingsRepositoryProvider.overrideWithValue(settings),
        overlayPreferencesRepositoryProvider.overrideWithValue(overlays),
        playbackAdapterProvider.overrideWithValue(tracker.adapter),
      ],
    );
    PlayerViewModel? active;
    binding.reportData = {
      'status': 'running',
      'backend': 'Better Player / Media3',
      'readOnly': true,
      'liveRequestedSeconds': liveSeconds,
      'physicalTv': false,
      'manualHearingVerified': false,
    };
    addTearDown(() async {
      if (binding.reportData?['status'] == 'running') {
        binding.reportData!['status'] = 'failed';
      }
      await tester.runAsync(() async => active?.close());
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.runAsync(() async {
        container.dispose();
        await tracker.focus.dispose();
        await db.close();
        await sessions.close();
      });
    });
    Future<void> until(bool Function() check, {int seconds = 90}) async {
      final clock = Stopwatch()..start();
      while (!check() && clock.elapsed < Duration(seconds: seconds)) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(check(), isTrue, reason: 'Native M9 state timed out');
    }

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const MambaApp()),
    );
    await tester.runAsync(() => container.read(appStartupProvider.future));
    await tester.runAsync(() async {
      await db.delete(db.watchProgressRows).go();
      await db.delete(db.historyVideos).go();
    });
    final router = container.read(appRouterProvider);
    late PlayerViewModelProvider provider;
    PlayerState state() => container.read(provider);
    PlayerViewModel vm() => container.read(provider.notifier);
    Future<void> enter(String route, {bool restricted = false}) async {
      router.push<void>(route);
      await until(() => find.byType(PlayerPage).evaluate().isNotEmpty);
      final page = tester.widget<PlayerPage>(find.byType(PlayerPage));
      provider = playerViewModelProvider(
        pageId: page.pageId,
        ownerKey: 'guest',
      );
      active = vm();
      await until(
        () => restricted
            ? state().phase == PlayerPhase.failed
            : state().phase == PlayerPhase.playing &&
                  state().snapshot.width > 0 &&
                  state().snapshot.position > Duration.zero,
      );
      if (!restricted) expect(vm().engine, isA<BetterPlayerEngine>());
    }

    Future<void> leave() async {
      await tester.runAsync(() => vm().close());
      active = null;
      router.pop();
      await tester.pump(const Duration(milliseconds: 500));
      expect(tracker.active, 0);
    }

    final cycles = <Map<String, Object?>>[];
    binding.reportData!['cycles'] = cycles;
    for (var i = 0; i < 20; i++) {
      final route = [
        '/player/BV1wR4Xz6EqG',
        '/watch/pgc/28320/280924',
        '/watch/live/6',
      ][i % 3];
      await enter(route);
      final kind = state().target!.kind.name;
      await leave();
      expect(tracker.maximum, 1);
      cycles.add({
        'cycle': i + 1,
        'kind': kind,
        'liveAfterReturn': tracker.active,
      });
      debugPrint('M9_CYCLE ${jsonEncode(cycles.last)}');
    }
    await tester.runAsync(() => db.delete(db.watchProgressRows).go());
    await enter('/watch/pgc/28320/280924');
    expect(state().target!.kind, ContentKind.pgc);
    expect(state().overlayPartId, '122607639');
    expect(state().capabilities.remoteHistory, isFalse);
    await tester.runAsync(() => vm().togglePause());
    await tester.runAsync(() => vm().seekBy(const Duration(seconds: 60)));
    expect(state().phase, PlayerPhase.paused);
    final saved = state().snapshot.position;
    await leave();
    await enter('/watch/pgc/28320/280924');
    final resumeError = (state().resumedFrom - saved).abs().inMilliseconds;
    expect(resumeError, lessThanOrEqualTo(2000));
    await tester.runAsync(
      () => vm().seekBy(
        state().snapshot.duration -
            const Duration(seconds: 3) -
            state().snapshot.position,
      ),
    );
    await until(
      () => state().partId == '285888' && state().phase == PlayerPhase.playing,
    );
    expect(
      state().target,
      const PlaybackTarget.pgc(seasonId: '28320', episodeId: '285888'),
    );
    await leave();
    final beforeRestriction = tracker.created;
    await enter('/watch/pgc/28320/285889', restricted: true);
    expect(state().failure!.kind, FailureKind.permission);
    expect(tracker.created, beforeRestriction);
    await leave();
    binding.reportData!['pgc'] = {
      'freeEpisode': '280924',
      'resumeErrorMs': resumeError,
      'autoNextEpisode': '285888',
      'restrictedSourceWithheld': true,
    };
    await enter('/watch/live/6');
    expect(state().target, const PlaybackTarget.live(roomId: '7734200'));
    expect(state().capabilities, PlaybackCapabilities.live);
    for (final key in [
      'player-forward',
      'player-rewind',
      'player-rate',
      'player-next',
      'player-played-progress',
    ]) {
      expect(find.byKey(Key(key)), findsNothing);
    }
    await tester.runAsync(() => vm().togglePause());
    expect(tracker.active, 0);
    await tester.runAsync(() => vm().togglePause());
    await until(
      () => state().phase == PlayerPhase.playing && state().snapshot.width > 0,
    );
    final samples = <Map<String, Object?>>[];
    binding.reportData!['samples'] = samples;
    final clock = Stopwatch()..start();
    var previous = state().snapshot.position, changes = 0, nextSample = 0;
    var lastChange = 0, maximumStallMs = 0;
    debugPrint('M9_LIVE_SOAK_STARTED');
    while (clock.elapsed.inSeconds < liveSeconds) {
      await tester.pump(const Duration(milliseconds: 500));
      expect(state().phase, isNot(PlayerPhase.failed));
      expect(tracker.active, 1);
      expect(tracker.maximum, 1);
      final position = state().snapshot.position;
      if ((position - previous).abs().inMilliseconds >= 50) {
        changes++;
        previous = position;
        lastChange = clock.elapsedMilliseconds;
      }
      final stalled = clock.elapsedMilliseconds - lastChange;
      if (stalled > maximumStallMs) maximumStallMs = stalled;
      expect(
        stalled,
        lessThan(20000),
        reason:
            'Live native position must remain active; no VOD clock is assumed',
      );
      if (clock.elapsed.inSeconds >= nextSample) {
        final native = await tester.runAsync(
          () => (vm().engine! as BetterPlayerEngine).controller.position,
        );
        final sample = {
          'elapsedSeconds': clock.elapsed.inSeconds,
          'nativePositionMs': native?.inMilliseconds,
          'width': state().snapshot.width,
          'height': state().snapshot.height,
          'phase': state().phase.name,
          'buffering': state().snapshot.buffering,
          'activeEngines': tracker.active,
          'positionChanges': changes,
        };
        samples.add(sample);
        debugPrint('M9_SAMPLE ${jsonEncode(sample)}');
        nextSample += 60;
      }
    }
    expect(changes, greaterThan(liveSeconds ~/ 4));
    await leave();
    expect(tracker.created, tracker.released);
    // A CDN error may be recovered by the bounded live reconnect policy.
    // Every enter and the soak still require real playback and an active clock;
    // preserve the sanitized native errors in the report instead of hiding them.
    expect(
      tracker.errors.where(
        (e) => !{
          FailureKind.cdn.name,
          FailureKind.network.name,
          FailureKind.timeout.name,
          FailureKind.resourceExpired.name,
        }.contains(e['kind']),
      ),
      isEmpty,
      reason:
          'Decoder, permission or contract failures are not recovered passes',
    );
    expect(container.read(bilibiliApiProvider).remoteWriteRequestsSent, 0);
    binding.reportData = {
      ...binding.reportData!,
      'status': 'passed',
      'recordedAtUtc': DateTime.now().toUtc().toIso8601String(),
      'liveElapsedSecondsIncludingCleanup': clock.elapsed.inSeconds,
      'liveRequestedDurationMet': clock.elapsed.inSeconds >= liveSeconds,
      'livePositionChanges': changes,
      'maximumNativePositionStallMs': maximumStallMs,
      'created': tracker.created,
      'released': tracker.released,
      'maximumEngines': tracker.maximum,
      'liveAfterReturn': tracker.active,
      'nativeErrors': tracker.errors,
      'remoteWrites': container
          .read(bilibiliApiProvider)
          .remoteWriteRequestsSent,
      'databaseSchema': db.schemaVersion,
    };
  }, timeout: const Timeout(Duration(minutes: 35)));
}
