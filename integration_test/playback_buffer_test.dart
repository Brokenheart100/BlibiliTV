import 'dart:convert';

import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:media_kit/media_kit.dart' hide PlayerState;
import 'package:media_kit_video/media_kit_video.dart';
import 'package:mambatv/app/app.dart';
import 'package:mambatv/app/bootstrap.dart';
import 'package:mambatv/app/providers/infrastructure_providers.dart';
import 'package:mambatv/app/providers/playback_providers.dart';
import 'package:mambatv/app/providers/repository_providers.dart';
import 'package:mambatv/app/router.dart';
import 'package:mambatv/data/repositories/memory_session_repository.dart';
import 'package:mambatv/data/services/local/app_database.dart';
import 'package:mambatv/data/services/playback/media_kit_engine.dart';
import 'package:mambatv/ui/features/player/view_models/player_view_model.dart';
import 'package:mambatv/ui/features/player/views/player_page.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;
  MediaKit.ensureInitialized();
  testWidgets(
    'TV buffer bar follows native DASH cache before and after seeks',
    (tester) async {
      expect(const bool.fromEnvironment('MAMBA_VALIDATION_APP'), isTrue);
      expect(const bool.fromEnvironment('MAMBA_READ_ONLY_VALIDATION'), isTrue);
      final database = AppDatabase(
        driftDatabase(name: 'mambatv_buffer_validation'),
      );
      final sessions = MemorySessionRepository();
      MediaKitEngine? engine;
      PlayerViewModel? activeVm;
      final container = ProviderContainer(
        retry: (_, _) => null,
        overrides: [
          sessionRepositoryProvider.overrideWithValue(sessions),
          appDatabaseProvider.overrideWithValue(database),
          playbackAdapterProvider.overrideWithValue(
            PlaybackAdapter(
              create: () => engine = MediaKitEngine(
                onOpenStage: (stage) => debugPrint('BUFFER_OPEN $stage'),
              ),
              surface: (engine) => Video(
                controller: (engine as MediaKitEngine).controller,
                controls: null,
                pauseUponEnteringBackgroundMode: false,
                resumeUponEnteringForegroundMode: false,
              ),
            ),
          ),
        ],
      );
      final samples = <Map<String, Object?>>[];
      final observations = <Map<String, Object?>>[];
      binding.reportData = {
        'status': 'running',
        'readOnly': true,
        'bufferSource':
            'mpv demuxer-cache-state seekable-ranges at current position',
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
            final native = engine!.player.platform! as NativePlayer;
            final nativeBuffer = await tester.runAsync(() async {
              try {
                return await native.getProperty('demuxer-cache-time');
              } catch (_) {
                return 'unavailable';
              }
            });
            final value = {
              'elapsedSeconds': clock.elapsed.inSeconds,
              'bufferSeconds':
                  engine!.snapshot.bufferedPosition.inMilliseconds / 1000,
              'positionSeconds':
                  engine!.snapshot.position.inMilliseconds / 1000,
              'nativeBuffer': nativeBuffer,
              'playing': engine!.snapshot.playing,
              'durationSeconds':
                  engine!.snapshot.duration.inMilliseconds / 1000,
            };
            value['nativeCacheState'] = await tester.runAsync(
              () => native.getProperty('demuxer-cache-state'),
            );
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
        final native = engine!.player.platform! as NativePlayer;
        final nativeState = jsonDecode(
          (await tester.runAsync(
            () => native.getProperty('demuxer-cache-state'),
          ))!,
        ) as Map<String, dynamic>;
        final ranges = nativeState['seekable-ranges'] as List<dynamic>;
        final position = snapshot.position.inMicroseconds / 1000000;
        final currentRanges = ranges.cast<Map<String, dynamic>>().where(
          (range) =>
              (range['start'] as num) <= position &&
              position <= (range['end'] as num),
        );
        expect(currentRanges, isNotEmpty);
        final nativeSeconds = currentRanges
            .map((range) => (range['end'] as num).toDouble())
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
          'nativeRanges': ranges,
          'legacyCacheTime': nativeState['cache-end'],
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
