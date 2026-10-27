import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mambatv/app/providers/repository_providers.dart';
import 'package:mambatv/app/router.dart';
import 'package:mambatv/domain/discovery/home_feed.dart';
import 'package:mambatv/domain/entities/app_models.dart';
import 'package:mambatv/ui/features/settings/view_models/settings_view_model.dart';
import 'package:mambatv/ui/features/player/views/player_page.dart';
import 'package:mambatv/ui/core/widgets/creator_avatar.dart';
import 'package:mambatv/ui/core/widgets/liquid_glass_card.dart';

import '../support/app_harness.dart';
import 'tv_shell_test.dart' show press;

void main() {
  testWidgets('rail order matches D-pad order and has no bottom account icon', (
    tester,
  ) async {
    await pumpMamba(tester);
    const order = [0, 4, 1, 2, 3];
    final positions = [
      for (final i in order) tester.getCenter(find.byKey(Key('nav-$i'))).dy,
    ];
    expect([...positions]..sort(), positions);
    expect(find.byTooltip('游客模式'), findsNothing);
    expect(find.byTooltip('账号已登录'), findsNothing);
    for (final i in order.skip(1)) {
      await press(tester, LogicalKeyboardKey.arrowDown);
      expect(FocusManager.instance.primaryFocus?.debugLabel, 'nav-$i');
    }
    await press(tester, LogicalKeyboardKey.arrowDown);
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'nav-theme');
    for (final i in order.reversed) {
      await press(tester, LogicalKeyboardKey.arrowUp);
      expect(FocusManager.instance.primaryFocus?.debugLabel, 'nav-$i');
    }
  });

  testWidgets('glass video cards keep avatar and whole-card D-pad activation', (
    tester,
  ) async {
    await pumpMamba(tester, size: const Size(640, 360));
    final card = find.byKey(const Key('video-demo-000'));
    expect(
      find.descendant(of: card, matching: find.byType(CreatorAvatar)),
      findsOneWidget,
    );
    expect(
      find.descendant(of: card, matching: find.byType(LiquidGlassCard)),
      findsOneWidget,
    );
    expect(
      find.descendant(of: card, matching: find.byType(BackdropFilter)),
      findsOneWidget,
    );
    await press(tester, LogicalKeyboardKey.arrowRight);
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'video-demo-000');
    expect(
      tester
          .widget<LiquidGlassCard>(
            find.descendant(of: card, matching: find.byType(LiquidGlassCard)),
          )
          .focused,
      isTrue,
    );
    await press(tester, LogicalKeyboardKey.select);
    expect(find.byKey(const Key('detail-play')), findsOneWidget);
    await press(tester, LogicalKeyboardKey.goBack);
    await tester.tap(find.byKey(const Key('nav-theme')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'system appearance follows brightness without overwriting the preference',
    (tester) async {
      final container = await pumpMamba(tester);
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      final settings = container
          .read(settingsViewModelProvider)
          .requireValue
          .settings;
      await container
          .read(settingsViewModelProvider.notifier)
          .savePreferences(settings.copyWith(theme: AppTheme.system));
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
      await tester.pumpAndSettle();
      expect(
        Theme.of(tester.element(find.text('个性推荐'))).brightness,
        Brightness.light,
      );
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
      await tester.pumpAndSettle();
      expect(
        Theme.of(tester.element(find.text('个性推荐'))).brightness,
        Brightness.dark,
      );
      expect(
        (await container.read(settingsRepositoryProvider).load())
            .valueOrThrow
            .theme,
        AppTheme.system,
      );
    },
  );
  testWidgets(
    'icon rail keeps accessible names and restores its saved appearance',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final container = await pumpMamba(tester);
      for (var index = 0; index < 4; index++) {
        expect(
          find.descendant(
            of: find.byKey(Key('nav-$index')),
            matching: find.byType(Text),
          ),
          findsNothing,
        );
      }
      expect(find.bySemanticsLabel('发现'), findsWidgets);
      expect(
        tester.getSize(find.byKey(const Key('icon-navigation-rail'))).width,
        lessThan(100),
      );
      expect(
        Theme.of(tester.element(find.text('个性推荐'))).brightness,
        Brightness.dark,
      );
      await tester.tap(find.byKey(const Key('nav-theme')));
      await tester.pumpAndSettle();
      expect(
        Theme.of(tester.element(find.text('个性推荐'))).brightness,
        Brightness.light,
      );
      expect(
        container.read(settingsViewModelProvider).requireValue.settings.theme,
        AppTheme.light,
      );
      final saved = (await container.read(settingsRepositoryProvider).load())
          .valueOrThrow;
      expect(saved.theme, AppTheme.light);
      container.invalidate(settingsViewModelProvider);
      await tester.pumpAndSettle();
      expect(
        container.read(settingsViewModelProvider).requireValue.settings.theme,
        AppTheme.light,
      );
      expect(
        Theme.of(tester.element(find.text('个性推荐'))).brightness,
        Brightness.light,
      );
      expect(tester.takeException(), isNull);
      semantics.dispose();
    },
  );

  testWidgets(
    'all six capsule tabs follow the reference order and D-pad navigation',
    (tester) async {
      final container = await pumpMamba(tester);
      final positions = HomeFeed.values
          .map((feed) => tester.getCenter(find.text(feed.label)).dx)
          .toList();
      expect([...positions]..sort(), positions);
      await press(tester, LogicalKeyboardKey.arrowRight);
      await press(tester, LogicalKeyboardKey.arrowUp);
      await press(tester, LogicalKeyboardKey.arrowUp);
      expect(
        FocusManager.instance.primaryFocus?.debugLabel,
        'feed-recommendation',
      );
      for (final section in [
        'following',
        'popular',
        'weekly',
        'ranking',
        'live',
      ]) {
        await press(tester, LogicalKeyboardKey.arrowRight);
        expect(FocusManager.instance.primaryFocus?.debugLabel, 'feed-$section');
        await press(tester, LogicalKeyboardKey.select);
        expect(
          container
              .read(appRouterProvider)
              .routeInformationProvider
              .value
              .uri
              .queryParameters['feed'],
          section,
        );
      }
      expect(find.text('直播还在准备中'), findsOneWidget);
      await press(tester, LogicalKeyboardKey.arrowDown);
      await press(tester, LogicalKeyboardKey.select);
      expect(
        container
            .read(appRouterProvider)
            .routeInformationProvider
            .value
            .uri
            .path,
        '/home',
      );
      expect(tester.takeException(), isNull);
    },
  );

  for (final size in [const Size(640, 360), const Size(1280, 720)]) {
    testWidgets('light home fits $size and video chrome remains dark', (
      tester,
    ) async {
      final container = await pumpMamba(tester, size: size);
      await tester.tap(find.byKey(const Key('nav-theme')));
      await tester.pumpAndSettle();
      for (final feed in HomeFeed.values) {
        expect(find.text(feed.label), findsOneWidget);
        expect(
          tester.getRect(find.text(feed.label)).right,
          lessThan(size.width),
        );
      }
      final colors = Theme.of(tester.element(find.text('个性推荐'))).colorScheme;
      expect(tester.widget<Text>(find.text('3:00')).style?.color, Colors.white);
      final luminances = [
        colors.surface.computeLuminance(),
        colors.onSurface.computeLuminance(),
      ]..sort();
      expect(
        (luminances.last + .05) / (luminances.first + .05),
        greaterThan(4.5),
      );
      container.read(appRouterProvider).go('/player/demo-000');
      await tester.pumpAndSettle();
      expect(
        Theme.of(tester.element(find.byType(PlayerPage))).brightness,
        Brightness.dark,
      );
      container.read(appRouterProvider).go('/home');
      await tester.pumpAndSettle();
      expect(
        Theme.of(tester.element(find.text('个性推荐'))).brightness,
        Brightness.light,
      );
      expect(tester.takeException(), isNull);
    });
  }
}
