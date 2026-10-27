import 'dart:async';

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
  testWidgets('buffer bar follows engine updates, including cache eviction', (
    tester,
  ) async {
    final engines = FakeEngineFactory();
    await pumpMamba(tester, engines: engines);
    await press(tester, LogicalKeyboardKey.arrowRight);
    await press(tester, LogicalKeyboardKey.select);
    await press(tester, LogicalKeyboardKey.select);
    final engine = engines.engines.single;
    double value(String key) =>
        tester.widget<LinearProgressIndicator>(find.byKey(Key(key))).value!;
    expect(value('player-buffer-progress'), 0);
    engine.emit(
      engine.snapshot.copyWith(
        position: const Duration(seconds: 20),
        bufferedPosition: const Duration(seconds: 80),
      ),
    );
    await tester.pump();
    expect(value('player-played-progress'), closeTo(20 / 120, .0001));
    expect(value('player-buffer-progress'), closeTo(80 / 120, .0001));
    engine.emit(
      engine.snapshot.copyWith(bufferedPosition: const Duration(seconds: 30)),
    );
    await tester.pump();
    expect(value('player-buffer-progress'), .25);
    engine.emit(
      engine.snapshot.copyWith(bufferedPosition: const Duration(seconds: -1)),
    );
    await tester.pump();
    expect(value('player-buffer-progress'), 0);
    engine.emit(
      engine.snapshot.copyWith(bufferedPosition: const Duration(seconds: 150)),
    );
    await tester.pump();
    expect(value('player-buffer-progress'), 1);
    engine.emit(engine.snapshot.copyWith(duration: Duration.zero));
    await tester.pump();
    expect(value('player-buffer-progress'), 0);
    expect(value('player-played-progress'), 0);
    expect(tester.takeException(), isNull);
    await playerBack(tester);
  });

  testWidgets('seek preview hides stale buffer and replacement starts empty', (
    tester,
  ) async {
    final engines = FakeEngineFactory();
    await pumpMamba(tester, engines: engines);
    await press(tester, LogicalKeyboardKey.arrowRight);
    await press(tester, LogicalKeyboardKey.select);
    await press(tester, LogicalKeyboardKey.select);
    final engine = engines.engines.single;
    engine.emit(
      engine.snapshot.copyWith(bufferedPosition: const Duration(seconds: 100)),
    );
    await tester.pump();
    double buffered() => tester
        .widget<LinearProgressIndicator>(
          find.byKey(const Key('player-buffer-progress')),
        )
        .value!;
    expect(buffered(), closeTo(100 / 120, .0001));
    final gate = engines.seekGate = Completer<void>();
    // Let controls hide so Left/Right take the TV surface seek path.
    await tester.pump(const Duration(seconds: 6));
    await tester.pumpAndSettle();
    await press(tester, LogicalKeyboardKey.arrowRight);
    expect(find.text('跳转至 00:10'), findsOneWidget);
    expect(buffered(), 0);
    engine.emit(
      engine.snapshot.copyWith(bufferedPosition: const Duration(seconds: 110)),
    );
    await tester.pump();
    expect(buffered(), 0);
    gate.complete();
    await tester.pumpAndSettle();
    engine.emit(
      engine.snapshot.copyWith(bufferedPosition: const Duration(seconds: 25)),
    );
    await tester.pump();
    expect(buffered(), closeTo(25 / 120, .0001));
    await tester.tap(find.byKey(const Key('player-quality')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('360P'));
    for (var i = 0; i < 15; i++) {
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.pumpAndSettle();
    expect(engines.engines.length, 2);
    expect(engines.engines.last.snapshot.bufferedPosition, Duration.zero);
    expect(buffered(), 0);
    expect(tester.takeException(), isNull);
    await playerBack(tester);
  });

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
  testWidgets('D-pad seek preview stays visible while the decoder is busy', (
    tester,
  ) async {
    final engines = FakeEngineFactory();
    await pumpMamba(tester, engines: engines);
    await press(tester, LogicalKeyboardKey.arrowRight);
    await press(tester, LogicalKeyboardKey.select);
    await press(tester, LogicalKeyboardKey.select);
    await tester.pump(const Duration(seconds: 6));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('player-toggle')), findsNothing);
    final gate = engines.seekGate = Completer<void>();
    await press(tester, LogicalKeyboardKey.arrowRight);
    expect(find.text('跳转至 00:10'), findsOneWidget);
    await tester.pump(const Duration(seconds: 6));
    expect(find.text('跳转至 00:10'), findsOneWidget);
    await press(tester, LogicalKeyboardKey.arrowLeft);
    expect(find.text('跳转至 00:00'), findsOneWidget);
    gate.complete();
    await tester.pumpAndSettle();
    expect(find.text('跳转至 00:00'), findsNothing);
    expect(engines.engines.single.seeks, [
      const Duration(seconds: 10),
      Duration.zero,
    ]);
    await playerBack(tester);
  });
}
