import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mambatv/app/providers/ui_providers.dart';
import 'package:mambatv/app/router.dart';
import 'package:mambatv/core/result.dart';
import 'package:mambatv/data/repositories/fake_catalog_repository.dart';
import 'package:mambatv/domain/entities/app_models.dart';
import 'package:mambatv/ui/features/player/views/player_page.dart';

import '../support/app_harness.dart';
import '../support/fake_playback.dart';
import 'tv_shell_test.dart' show press;
import 'player_page_test.dart' show playerBack;

class LongCatalog extends FakeCatalogRepository {
  LongCatalog() : super(latency: Duration.zero);
  @override
  Future<Result<VideoDetail>> getVideo(
    String id, {
    required String ownerKey,
    required CancellationSignal cancellation,
  }) async {
    final detail = (await super.getVideo(
      id,
      ownerKey: ownerKey,
      cancellation: cancellation,
    )).valueOrThrow;
    return Success(
      detail.copyWith(
        parts: List.generate(
          103,
          (i) => VideoPart(
            id: 'part-$i',
            title: '第 ${i + 1} 集',
            durationSeconds: 120,
          ),
        ),
      ),
    );
  }
}

Future<void> openPlayer(WidgetTester tester) async {
  await press(tester, LogicalKeyboardKey.arrowRight);
  await press(tester, LogicalKeyboardKey.select);
  await press(tester, LogicalKeyboardKey.select);
}

Future<void> flushPlayer(WidgetTester tester) async {
  // Native/stream disposal completes in a real async zone, as in playerBack.
  for (var i = 0; i < 10; i++) {
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump(const Duration(milliseconds: 100));
  }
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'controls auto-hide and screen keys seek or toggle exactly once',
    (tester) async {
      final factory = FakeEngineFactory();
      await pumpMamba(tester, engines: factory);
      await openPlayer(tester);
      await tester.pump(const Duration(seconds: 6));
      await tester.pump();
      expect(find.byKey(const Key('player-toggle')), findsNothing);
      expect(FocusManager.instance.primaryFocus?.debugLabel, 'player-surface');
      await press(tester, LogicalKeyboardKey.arrowRight);
      expect(factory.engines.last.snapshot.position.inSeconds, 10);
      await press(tester, LogicalKeyboardKey.select);
      expect(factory.engines.last.snapshot.playing, isFalse);
      expect(find.text('已暂停'), findsOneWidget);
      await playerBack(tester);
    },
  );
  testWidgets(
    'menu traps arrows, explains locked quality and Back restores its trigger',
    (tester) async {
      final factory = FakeEngineFactory();
      await pumpMamba(tester, engines: factory);
      await openPlayer(tester);
      await press(tester, LogicalKeyboardKey.select);
      await tester.tap(find.byKey(const Key('player-quality')));
      await tester.pumpAndSettle();
      final position = factory.engines.last.snapshot.position;
      await press(tester, LogicalKeyboardKey.arrowLeft);
      expect(factory.engines.last.snapshot.position, position);
      await tester.tap(find.text('1080P'));
      await tester.pumpAndSettle();
      expect(find.text('当前账号不可用'), findsOneWidget);
      expect(factory.engines.length, 1);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(
        FocusManager.instance.primaryFocus?.debugLabel,
        'player-control-5',
      );
      expect(find.byType(PlayerPage), findsOneWidget);
      await playerBack(tester);
    },
  );
  testWidgets(
    'paused quality selection restores the menu button after native replacement at 800x450',
    (tester) async {
      final factory = FakeEngineFactory();
      await pumpMamba(tester, engines: factory, size: const Size(800, 450));
      await openPlayer(tester);
      await press(tester, LogicalKeyboardKey.select);
      await tester.tap(find.byKey(const Key('player-quality')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('360P'));
      await flushPlayer(tester);
      expect(factory.engines.length, 2);
      expect(factory.engines.last.snapshot.playing, isFalse);
      expect(
        FocusManager.instance.primaryFocus?.debugLabel,
        'player-control-5',
      );
      expect(tester.takeException(), isNull);
      await playerBack(tester);
    },
  );
  testWidgets(
    'long part menu scrolls lazily by D-pad and selects the intended part',
    (tester) async {
      final factory = FakeEngineFactory();
      await pumpMamba(tester, engines: factory, catalog: LongCatalog());
      await openPlayer(tester);
      await tester.tap(find.byKey(const Key('player-parts')));
      await tester.pumpAndSettle();
      for (var i = 0; i < 40; i++) {
        await press(tester, LogicalKeyboardKey.arrowDown);
      }
      expect(FocusManager.instance.primaryFocus?.debugLabel, 'player-menu-40');
      await tester.sendKeyEvent(LogicalKeyboardKey.select);
      await flushPlayer(tester);
      expect(factory.engines.length, 2);
      expect(find.text('第 41 集'), findsOneWidget);
      expect(factory.maxActive, 1);
      expect(tester.takeException(), isNull);
      await playerBack(tester);
    },
  );
  testWidgets(
    'covered route pauses before any account change and returning never auto-plays',
    (tester) async {
      final factory = FakeEngineFactory();
      final container = await pumpMamba(tester, engines: factory);
      await openPlayer(tester);
      container
          .read(appRouterProvider)
          .push<void>('/login?returnTo=%2Flibrary');
      await tester.pumpAndSettle();
      for (var i = 0; i < 5; i++) {
        await tester.runAsync(() => Future<void>.delayed(Duration.zero));
        await tester.pump();
      }
      expect(factory.active, 0);
      await tester.tap(find.byKey(const Key('qr-back')));
      await tester.pumpAndSettle();
      expect(factory.active, 0);
      expect(find.text('已暂停'), findsOneWidget);
      await tester.tap(find.byKey(const Key('player-toggle')));
      await tester.pumpAndSettle();
      expect(factory.active, 1);
      await playerBack(tester);
    },
  );
  testWidgets(
    'foreground state changes leave the route paused until confirmation',
    (tester) async {
      final factory = FakeEngineFactory();
      final container = await pumpMamba(tester, engines: factory);
      await openPlayer(tester);
      container.read(appForegroundProvider.notifier).update(false);
      await tester.pumpAndSettle();
      for (var i = 0; i < 3; i++) {
        await tester.runAsync(() => Future<void>.delayed(Duration.zero));
        await tester.pump();
      }
      expect(factory.active, 0);
      container.read(appForegroundProvider.notifier).update(true);
      await tester.pumpAndSettle();
      expect(factory.active, 0);
      await tester.tap(find.byKey(const Key('player-toggle')));
      await tester.pumpAndSettle();
      expect(factory.active, 1);
      await playerBack(tester);
    },
  );
}
