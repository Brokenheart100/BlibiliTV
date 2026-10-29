import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mambatv/app/router.dart';
import 'package:mambatv/core/result.dart';
import 'package:mambatv/domain/playback/playback_target.dart';
import 'package:mambatv/ui/features/player/views/player_page.dart';
import 'package:mambatv/ui/features/player/view_models/player_view_model.dart';

import '../support/app_harness.dart';
import '../support/fake_content.dart';
import '../support/fake_playback.dart';
import 'tv_shell_test.dart' show press;

Future<void> completeCommand(WidgetTester tester, Future<void> command) async {
  var done = false;
  Object? failure;
  unawaited(
    command.then(
      (_) {
        done = true;
      },
      onError: (Object e) {
        failure = e;
        done = true;
      },
    ),
  );
  for (var i = 0; i < 100 && !done; i++) {
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump(const Duration(milliseconds: 20));
  }
  expect(done, isTrue, reason: 'Player command must complete');
  expect(failure, isNull);
}

void main() {
  testWidgets(
    'content catalog does not invent view counts missing from its API',
    (tester) async {
      final container = await pumpMamba(tester);
      container.read(appRouterProvider).push<void>('/pgc');
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('video-10')), findsOneWidget);
      expect(find.text('更新至第 30 话'), findsOneWidget);
      expect(find.textContaining('万次观看'), findsNothing);
    },
  );

  testWidgets(
    'live reconnect budget is three and background cancels pending reconnect',
    (tester) async {
      final engines = FakeEngineFactory(), live = FakeLiveRepository();
      final container = await pumpMamba(tester, engines: engines, live: live);
      container.read(appRouterProvider).push<void>('/watch/live/6');
      await tester.pumpAndSettle();
      final page = tester.widget<PlayerPage>(find.byType(PlayerPage));
      final provider = playerViewModelProvider(
        pageId: page.pageId,
        ownerKey: 'guest',
      );
      for (final delay in [1, 3, 10]) {
        final previous = engines.engines.length;
        engines.engines.last.emit(
          engines.engines.last.snapshot.copyWith(
            playing: false,
            failure: const AppFailure(FailureKind.network, '合成断流'),
          ),
        );
        await tester.pump();
        await tester.pump(Duration(seconds: delay));
        for (var i = 0; i < 100 && engines.engines.length == previous; i++) {
          await tester.runAsync(() => Future<void>.delayed(Duration.zero));
          await tester.pump(const Duration(milliseconds: 20));
        }
        expect(engines.engines.length, previous + 1);
        expect(engines.maxActive, 1);
      }
      engines.engines.last.emit(
        engines.engines.last.snapshot.copyWith(
          playing: false,
          failure: const AppFailure(FailureKind.network, '合成断流'),
        ),
      );
      await tester.pump(const Duration(seconds: 20));
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump();
      expect(container.read(provider).recoveryAttempts, 3);
      expect(live.resolutions, 4);
      expect(engines.active, 0);
      final vm = container.read(provider.notifier);
      await completeCommand(
        tester,
        vm.startTarget(const PlaybackTarget.live(roomId: '6')),
      );
      expect(engines.active, 1);
      engines.engines.last.emit(
        engines.engines.last.snapshot.copyWith(
          playing: false,
          failure: const AppFailure(FailureKind.network, '合成断流'),
        ),
      );
      await tester.pump();
      await completeCommand(tester, vm.suspend(background: true));
      final resolutions = live.resolutions;
      await tester.pump(const Duration(seconds: 20));
      expect(live.resolutions, resolutions);
      expect(engines.active, 0);
    },
  );

  testWidgets(
    'live has no VOD controls and pause releases instead of saving a resume point',
    (tester) async {
      final engines = FakeEngineFactory(), live = FakeLiveRepository();
      final progress = MemoryContentProgress();
      final container = await pumpMamba(
        tester,
        engines: engines,
        live: live,
        progress: progress,
      );
      container.read(appRouterProvider).push<void>('/watch/live/6');
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('player-toggle')), findsOneWidget);
      for (final key in [
        'player-forward',
        'player-rewind',
        'player-rate',
        'player-parts',
        'player-next',
        'player-enhancements',
        'player-played-progress',
      ]) {
        expect(find.byKey(Key(key)), findsNothing);
      }
      final page = tester.widget<PlayerPage>(find.byType(PlayerPage));
      final provider = playerViewModelProvider(
        pageId: page.pageId,
        ownerKey: 'guest',
      );
      final vm = container.read(provider.notifier);
      await vm.seekBy(const Duration(seconds: 30));
      await vm.setRate(2);
      expect(engines.engines.single.seeks, isEmpty);
      expect(container.read(provider).rate, 1);
      await completeCommand(tester, vm.togglePause());
      await tester.pumpAndSettle();
      expect(engines.active, 0);
      expect(progress.writes, isEmpty);
      await completeCommand(tester, vm.togglePause());
      await tester.pumpAndSettle();
      expect(live.resolutions, 2);
      expect(engines.active, 1);
      expect(engines.maxActive, 1);
      expect(engines.engines.last.openedAt, Duration.zero);
      expect(
        container.read(provider).target,
        const PlaybackTarget.live(roomId: '100'),
      );
      await completeCommand(tester, vm.close());
    },
  );

  testWidgets(
    'long episode list is reachable by D-pad and player returns to the selected episode',
    (tester) async {
      final pgc = FakePgcRepository();
      final engines = FakeEngineFactory();
      final container = await pumpMamba(tester, engines: engines, pgc: pgc);
      container.read(appRouterProvider).push<void>('/season/10');
      await tester.pumpAndSettle();
      expect(FocusManager.instance.primaryFocus?.debugLabel, 'season-play');
      await press(tester, LogicalKeyboardKey.arrowDown);
      await press(tester, LogicalKeyboardKey.arrowDown);
      expect(FocusManager.instance.primaryFocus?.debugLabel, 'episode-1');
      for (var i = 0; i < 8; i++) {
        await press(tester, LogicalKeyboardKey.arrowDown);
      }
      expect(FocusManager.instance.primaryFocus?.debugLabel, 'episode-25');
      await press(tester, LogicalKeyboardKey.select);
      await tester.pumpAndSettle();
      expect(pgc.requested.last.episodeId, '25');
      expect(engines.active, 1);
      await tester.tap(find.byKey(const Key('player-back')));
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pumpAndSettle();
      expect(engines.active, 0);
      expect(FocusManager.instance.primaryFocus?.debugLabel, 'episode-25');
    },
  );

  testWidgets(
    'preview-only episode reports permission without creating a native engine',
    (tester) async {
      final engines = FakeEngineFactory();
      final container = await pumpMamba(tester, engines: engines);
      container.read(appRouterProvider).push<void>('/watch/pgc/10/3');
      await tester.pumpAndSettle();
      expect(find.textContaining('当前仅提供试看'), findsOneWidget);
      expect(engines.engines, isEmpty);
      expect(find.byKey(const Key('player-retry')), findsOneWidget);
    },
  );
}
