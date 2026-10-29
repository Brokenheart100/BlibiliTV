import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mambatv/app/app.dart';
import 'package:mambatv/app/bootstrap.dart';
import 'package:mambatv/app/providers/infrastructure_providers.dart';
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
  testWidgets('Better Player native DASH, buffer, seek and disposal', (
    tester,
  ) async {
    expect(const bool.fromEnvironment('MAMBA_VALIDATION_APP'), isTrue);
    expect(const bool.fromEnvironment('MAMBA_READ_ONLY_VALIDATION'), isTrue);
    final database = AppDatabase(
      driftDatabase(name: 'mambatv_better_validation'),
    );
    final sessions = MemorySessionRepository();
    final container = ProviderContainer(
      retry: (_, _) => null,
      overrides: [
        sessionRepositoryProvider.overrideWithValue(sessions),
        appDatabaseProvider.overrideWithValue(database),
      ],
    );
    PlayerViewModel? activeVm;
    final samples = <Map<String, Object?>>[];
    binding.reportData = {
      'status': 'running',
      'backend': 'Better Player / Media3',
      'readOnly': true,
      'samples': samples,
    };
    addTearDown(() async {
      if (binding.reportData?['status'] == 'running') {
        binding.reportData!['status'] = 'failed';
      }
      await tester.runAsync(() async => activeVm?.close());
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.runAsync(() async {
        container.dispose();
        await database.close();
        await sessions.close();
      });
    });
    Future<void> until(bool Function() predicate) async {
      final clock = Stopwatch()..start();
      while (!predicate() && clock.elapsed < const Duration(seconds: 60)) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(predicate(), isTrue, reason: 'Native playback timed out');
    }

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const MambaApp()),
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
          state().snapshot.position > const Duration(seconds: 2),
    );
    expect(vm.engine, isA<BetterPlayerEngine>());
    Future<void> sample(String stage) async {
      await until(
        () => state().snapshot.bufferedPosition > state().snapshot.position,
      );
      await tester.pump();
      final value = state().snapshot;
      expect(value.width, greaterThan(0));
      expect(value.failure, isNull);
      final bar = tester.widget<LinearProgressIndicator>(
        find.byKey(const Key('player-buffer-progress')),
      );
      expect(
        bar.value,
        closeTo(
          value.bufferedPosition.inMilliseconds / value.duration.inMilliseconds,
          .001,
        ),
      );
      samples.add({
        'stage': stage,
        'positionMs': value.position.inMilliseconds,
        'bufferMs': value.bufferedPosition.inMilliseconds,
        'playing': value.playing,
        'width': value.width,
        'height': value.height,
      });
      debugPrint('BETTER_PLAYER_SAMPLE ${samples.last}');
    }

    await sample('initial');
    await tester.runAsync(vm.togglePause);
    await until(() => state().phase == PlayerPhase.paused);
    await tester.runAsync(() => vm.seekBy(const Duration(seconds: 60)));
    expect(state().phase, PlayerPhase.paused);
    expect(state().seekTarget, isNull);
    await sample('paused-forward');
    await tester.runAsync(() => vm.seekBy(const Duration(seconds: -45)));
    expect(state().phase, PlayerPhase.paused);
    await sample('paused-backward');
    await tester.runAsync(() => vm.setRate(1.5));
    await tester.runAsync(() => vm.setVolume(70));
    await tester.runAsync(vm.togglePause);
    await until(() => state().phase == PlayerPhase.playing);
    for (final seconds in [240, -180, 60, -30, 120, -90]) {
      await tester.runAsync(() => vm.seekBy(Duration(seconds: seconds)));
      expect(state().seekTarget, isNull);
      expect(state().snapshot.failure, isNull);
      await sample('playing-seek-$seconds');
      final before = state().snapshot.position;
      await until(
        () => state().snapshot.position > before + const Duration(seconds: 1),
      );
    }
    await tester.runAsync(() => vm.setRate(1));
    expect(tester.takeException(), isNull);
    await tester.runAsync(vm.close);
    expect(vm.engine, isNull);
    binding.reportData!['status'] = 'passed';
    binding.reportData!['hearingAcceptance'] = 'pending';
  }, timeout: const Timeout(Duration(minutes: 6)));
}
