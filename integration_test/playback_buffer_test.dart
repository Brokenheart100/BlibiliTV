import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mambatv/app/app.dart';
import 'package:mambatv/app/bootstrap.dart';
import 'package:mambatv/app/providers/infrastructure_providers.dart';
import 'package:mambatv/app/providers/playback_providers.dart';
import 'package:mambatv/app/providers/repository_providers.dart';
import 'package:mambatv/app/router.dart';
import 'package:mambatv/data/repositories/memory_session_repository.dart';
import 'package:mambatv/data/services/local/app_database.dart';
import 'package:mambatv/data/services/playback/better_player_engine.dart';
import 'package:mambatv/ui/features/player/view_models/player_view_model.dart';
import 'package:mambatv/ui/features/player/views/player_page.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;
  testWidgets(
    'TV buffer bar follows native DASH cache before and after seeks',
    (tester) async {
      expect(const bool.fromEnvironment('MAMBA_VALIDATION_APP'), isTrue);
      expect(const bool.fromEnvironment('MAMBA_READ_ONLY_VALIDATION'), isTrue);
      final database = AppDatabase(
        driftDatabase(name: 'mambatv_buffer_validation'),
      );
      final sessions = MemorySessionRepository();
      BetterPlayerEngine? engine;
      PlayerViewModel? activeVm;
      final container = ProviderContainer(
        retry: (_, _) => null,
        overrides: [
          sessionRepositoryProvider.overrideWithValue(sessions),
          appDatabaseProvider.overrideWithValue(database),
          playbackAdapterProvider.overrideWithValue(
            PlaybackAdapter(
              create: () => engine = BetterPlayerEngine(),
              surface: (engine) =>
                  BetterPlayerSurface(engine as BetterPlayerEngine),
            ),
          ),
        ],
      );
      final samples = <Map<String, Object?>>[];
      final observations = <Map<String, Object?>>[];
      binding.reportData = {
        'status': 'running',
        'readOnly': true,
        'bufferSource': 'Better Player native buffered duration ranges containing current position',
        'samples': samples,
        'observations': observations,
      };
      addTearDown(() async {
        if (binding.reportData?['status'] == 'running') {
          binding.reportData!['status'] = 'failed';
        }
        await tester.runAsync(() async => activeVm?.close());
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.runAsync(() async {
          container.dispose();
          await engine?.dispose();
          await database.close();
          await sessions.close();
        });
      });
      Future<void> until(bool Function() predicate) async {
        final clock = Stopwatch()..start();
        var lastObservation = -5;
        while (!predicate() && clock.elapsed < const Duration(seconds: 60)) {
          await tester.pump(const Duration(milliseconds: 100));
          if (engine != null &&
              clock.elapsed.inSeconds >= lastObservation + 5) {
            lastObservation = clock.elapsed.inSeconds;
            final value = {
              'elapsedSeconds': clock.elapsed.inSeconds,
              'bufferSeconds':
                  engine!.snapshot.bufferedPosition.inMilliseconds / 1000,
              'positionSeconds':
                  engine!.snapshot.position.inMilliseconds / 1000,
              'nativeBufferedRanges': [
                for (final range in engine!.controller.value.buffered)
                  {
                    'startMs': range.start.inMilliseconds,
                    'endMs': range.end.inMilliseconds,
                  },
              ],
              'playing': engine!.snapshot.playing,
              'durationSeconds':
                  engine!.snapshot.duration.inMilliseconds / 1000,
            };
            observations.add(value);
            debugPrint('BUFFER_OBSERVATION $value');
          }
        }
        expect(
          predicate(),
          isTrue,
          reason: 'Native buffer condition timed out',
        );
      }

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MambaApp(),
        ),
      );
      await tester.runAsync(() => container.read(appStartupProvider.future));
      await tester.runAsync(
        () => database.delete(database.watchProgressRows).go(),
      );
      container.read(appRouterProvider).go('/player/BV1wR4Xz6EqG');
      await until(() => find.byType(PlayerPage).evaluate().isNotEmpty);
      final page = tester.widget<PlayerPage>(find.byType(PlayerPage));
      final provider = playerViewModelProvider(
        pageId: page.pageId,
        ownerKey: 'guest',
      );
      PlayerState state() => container.read(provider);
      final vm = container.read(provider.notifier);
      activeVm = vm;
      await until(
        () =>
            state().phase == PlayerPhase.playing &&
            state().snapshot.bufferedPosition > state().snapshot.position,
      );
      await tester.runAsync(vm.togglePause);
      await until(() => state().phase == PlayerPhase.paused);

      Future<void> sample(String stage) async {
        await until(
          () => state().snapshot.bufferedPosition > state().snapshot.position,
        );
        await tester.pump();
        final snapshot = state().snapshot;
        final bar = tester.widget<LinearProgressIndicator>(
          find.byKey(const Key('player-buffer-progress')),
        );
        final played = tester.widget<LinearProgressIndicator>(
          find.byKey(const Key('player-played-progress')),
        );
        final ranges = engine!.controller.value.buffered;
        final currentRanges = ranges.where(
          (range) =>
              range.start <= snapshot.position &&
              snapshot.position <= range.end,
        );
        expect(currentRanges, isNotEmpty);
        final nativeSeconds = currentRanges
            .map((range) => range.end.inMicroseconds / 1000000)
            .reduce((a, b) => a > b ? a : b);
        final duration = snapshot.duration.inMilliseconds / 1000;
        final buffer = snapshot.bufferedPosition.inMicroseconds / 1000000;
        expect(bar.value, closeTo((buffer / duration).clamp(0, 1), .0001));
        expect(buffer, closeTo(nativeSeconds, 2));
        expect(bar.value!, greaterThan(played.value!));
        samples.add({
          'stage': stage,
          'positionSeconds': snapshot.position.inMilliseconds / 1000,
          'bufferSeconds': buffer,
          'nativeBufferSeconds': nativeSeconds,
          'nativeRanges': [
            for (final range in ranges)
              {
                'startMs': range.start.inMilliseconds,
                'endMs': range.end.inMilliseconds,
              },
          ],
          'durationSeconds': duration,
          'bufferFraction': bar.value,
          'playedFraction': played.value,
        });
      }

      await sample('initial');
      var resets = 0;
      final subscription = engine!.snapshots.listen((snapshot) {
        if (snapshot.bufferedPosition == Duration.zero) resets++;
      });
      try {
        await tester.runAsync(() => vm.seekBy(const Duration(seconds: 60)));
        expect(state().phase, PlayerPhase.paused);
        expect(state().seekTarget, isNull);
        await sample('forward');
        await tester.runAsync(() => vm.seekBy(const Duration(seconds: -45)));
        await sample('backward');
        expect(resets, greaterThanOrEqualTo(2));
        binding.reportData!['bufferResets'] = resets;
      } finally {
        await subscription.cancel();
      }
      expect(tester.takeException(), isNull);
      await tester.runAsync(vm.close);
      binding.reportData!['status'] = 'passed';
    },
    timeout: const Timeout(Duration(minutes: 5)),
  );
}
