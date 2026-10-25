import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mambatv/core/result.dart';
import 'package:mambatv/app/router.dart';
import 'package:mambatv/data/repositories/memory_session_repository.dart';
import 'package:mambatv/domain/entities/app_models.dart';

import '../support/app_harness.dart';
import '../support/fake_playback.dart';
import 'tv_shell_test.dart' show press;

Future<void> playerBack(WidgetTester tester) async {
  await tester.runAsync(() async {
    await tester.binding.handlePopRoute();
    await Future<void>.delayed(Duration.zero);
  });
  for (
    var i = 0;
    i < 30 && find.byKey(const Key('detail-play')).evaluate().isEmpty;
    i++
  ) {
    // Stream cancellation and queued repository writes can complete in the
    // real async zone; alternate it with frames instead of advancing only time.
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump(const Duration(milliseconds: 100));
  }
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'account change closes a hidden player without popping the login route',
    (tester) async {
      final engines = FakeEngineFactory();
      final sessions = MemorySessionRepository();
      final container = await pumpMamba(
        tester,
        engines: engines,
        sessions: sessions,
      );
      await press(tester, LogicalKeyboardKey.arrowRight);
      await press(tester, LogicalKeyboardKey.select);
      await press(tester, LogicalKeyboardKey.select);
      expect(engines.active, 1);
      container
          .read(appRouterProvider)
          .push<void>('/login?returnTo=%2Flibrary');
      await tester.pumpAndSettle();
      sessions.replace(
        const Session(
          ownerKey: 'user:101',
          status: SessionStatus.authenticated,
          generation: 1,
        ),
      );
      for (var i = 0; i < 5; i++) {
        await tester.runAsync(() => Future<void>.delayed(Duration.zero));
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(engines.active, 0);
      expect(container.read(appRouterProvider).state.uri.path, '/login');
      expect(find.byKey(const Key('qr-refresh')), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.byKey(const Key('qr-back')));
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'TV route binds one engine surface and returns through detail to its card',
    (tester) async {
      final engines = FakeEngineFactory();
      await pumpMamba(tester, engines: engines);
      await press(tester, LogicalKeyboardKey.arrowRight);
      await press(tester, LogicalKeyboardKey.select);
      await press(tester, LogicalKeyboardKey.select);
      expect(find.byKey(ObjectKey(engines.engines.single)), findsOneWidget);
      expect(
        FocusManager.instance.primaryFocus?.debugLabel,
        'player-control-2',
      );
      await press(tester, LogicalKeyboardKey.select);
      expect(find.text('已暂停'), findsOneWidget);
      await press(tester, LogicalKeyboardKey.arrowRight);
      await press(tester, LogicalKeyboardKey.select);
      expect(find.text('00:10'), findsOneWidget);
      await playerBack(tester);
      expect(find.byKey(const Key('detail-play')), findsOneWidget);
      expect(engines.active, 0);
      await press(tester, LogicalKeyboardKey.goBack);
      expect(FocusManager.instance.primaryFocus?.debugLabel, 'video-demo-000');
      expect(find.byType(AlertDialog), findsNothing);
    },
  );

  testWidgets('playback failure has reachable retry and Back at 800x450', (
    tester,
  ) async {
    final resolver = FakePlaybackRepository()
      ..failure = const AppFailure(FailureKind.network, '检查网络后重试');
    await pumpMamba(tester, playback: resolver, size: const Size(800, 450));
    await press(tester, LogicalKeyboardKey.arrowRight);
    await press(tester, LogicalKeyboardKey.select);
    await press(tester, LogicalKeyboardKey.select);
    expect(find.text('自动恢复未成功，请检查网络后手动重试'), findsOneWidget);
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'player-control-4');
    expect(resolver.calls, 2);
    resolver.failure = null;
    await press(tester, LogicalKeyboardKey.select);
    expect(find.text('正在播放'), findsOneWidget);
    await playerBack(tester);
    expect(find.byKey(const Key('detail-play')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
