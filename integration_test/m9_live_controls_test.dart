import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mambatv/app/app.dart';
import 'package:mambatv/app/bootstrap.dart';
import 'package:mambatv/app/logging/app_container.dart';
import 'package:mambatv/app/providers/playback_providers.dart';
import 'package:mambatv/app/providers/repository_providers.dart';
import 'package:mambatv/app/router.dart';
import 'package:mambatv/data/repositories/memory_session_repository.dart';
import 'package:mambatv/ui/features/player/view_models/player_view_model.dart';
import 'package:mambatv/ui/features/player/views/player_page.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'm8_stability_test.dart' show M8Tracker;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;
  testWidgets('M9 real live quality and lifecycle release', (tester) async {
    expect(const bool.fromEnvironment('MAMBA_VALIDATION_APP'), isTrue);
    expect(const bool.fromEnvironment('MAMBA_READ_ONLY_VALIDATION'), isTrue);
    final sessions = MemorySessionRepository(), tracker = M8Tracker();
    final container = createAppContainer(
      overrides: [
        sessionRepositoryProvider.overrideWithValue(sessions),
        playbackAdapterProvider.overrideWithValue(tracker.adapter),
      ],
    );
    binding.reportData = {'status': 'running', 'readOnly': true};
    PlayerViewModel? active;
    addTearDown(() async {
      if (binding.reportData?['status'] == 'running') {
        binding.reportData!['status'] = 'failed';
      }
      await tester.runAsync(() async => active?.close());
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.runAsync(() async {
        container.dispose();
        await tracker.focus.dispose();
        await sessions.close();
      });
    });
    Future<void> until(bool Function() check) async {
      final clock = Stopwatch()..start();
      while (!check() && clock.elapsed < const Duration(seconds: 90)) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(check(), isTrue, reason: 'Native live controls timed out');
    }

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const MambaApp()),
    );
    await tester.runAsync(() => container.read(appStartupProvider.future));
    final router = container.read(appRouterProvider);
    router.push<void>('/watch/live/6');
    await until(() => find.byType(PlayerPage).evaluate().isNotEmpty);
    final page = tester.widget<PlayerPage>(find.byType(PlayerPage));
    final provider = playerViewModelProvider(
      pageId: page.pageId,
      ownerKey: 'guest',
    );
    final vm = container.read(provider.notifier);
    active = vm;
    PlayerState state() => container.read(provider);
    await until(
      () => state().phase == PlayerPhase.playing && state().snapshot.width > 0,
    );
    final before = state().quality;
    final choices = state().qualities
        .where((q) => q.available && q.id != before)
        .toList();
    expect(
      choices,
      isNotEmpty,
      reason: 'Need a real second quality to accept switching',
    );
    final requested =
        choices.where((q) => q.id == 250).firstOrNull ?? choices.last;
    await tester.runAsync(() => vm.selectQuality(requested.id));
    await until(
      () => state().phase == PlayerPhase.playing && state().snapshot.width > 0,
    );
    final fallback = state().quality != requested.id;
    if (fallback) {
      expect(state().notice, contains('服务端实际返回'));
    }
    expect(tracker.maximum, 1);
    final switched = state().quality;
    binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await until(
      () => tracker.active == 0 && state().phase == PlayerPhase.paused,
    );
    final releasedInBackground = tracker.active;
    binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump(const Duration(milliseconds: 300));
    expect(tracker.active, 0, reason: 'Foreground needs explicit confirmation');
    await tester.runAsync(vm.togglePause);
    await until(
      () => state().phase == PlayerPhase.playing && state().snapshot.width > 0,
    );
    await tester.pump(const Duration(seconds: 2));
    expect(state().snapshot.buffering, isFalse);
    await tester.runAsync(vm.close);
    active = null;
    router.pop();
    await tester.pump(const Duration(milliseconds: 300));
    expect(tracker.active, 0);
    expect(tracker.created, tracker.released);
    expect(container.read(bilibiliApiProvider).remoteWriteRequestsSent, 0);
    binding.reportData = {
      'status': 'passed',
      'recordedAtUtc': DateTime.now().toUtc().toIso8601String(),
      'backend': 'Better Player / Media3',
      'readOnly': true,
      'physicalTv': false,
      'initialQuality': before,
      'requestedQuality': requested.id,
      'actualQuality': switched,
      'serverFallback': fallback,
      'distinctQualityVerified': !fallback && switched != before,
      'liveAfterBackground': releasedInBackground,
      'explicitResume': true,
      'created': tracker.created,
      'released': tracker.released,
      'maximumEngines': tracker.maximum,
      'liveAfterReturn': tracker.active,
      'nativeErrors': tracker.errors,
      'remoteWrites': 0,
      'lifecycleMethod':
          'Flutter binding inactive/paused/resumed with real native engine',
    };
    debugPrint('M9_LIVE_CONTROLS ${jsonEncode(binding.reportData)}');
  }, timeout: const Timeout(Duration(minutes: 8)));
}
