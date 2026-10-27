import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mambatv/app/router.dart';
import 'package:mambatv/app/providers/overlay_providers.dart';
import 'package:mambatv/domain/entities/app_models.dart';
import 'package:mambatv/ui/features/player/view_models/overlay_view_models.dart';

import '../support/app_harness.dart';
import '../support/fake_playback.dart';
import '../support/fake_overlays.dart';
import 'tv_shell_test.dart' show press;

void main() {
  testWidgets(
    'D-pad reaches enhancements and close restores the trigger without a second engine',
    (tester) async {
      final engines = FakeEngineFactory();
      final container = await pumpMamba(tester, engines: engines);
      container.read(appRouterProvider).push('/player/demo-000');
      for (var i = 0; i < 15; i++) {
        await tester.runAsync(() => Future<void>.delayed(Duration.zero));
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(find.byKey(const Key('player-enhancements')), findsOneWidget);
      await tester.tap(find.byKey(const Key('player-toggle')));
      await tester.pumpAndSettle();
      // Explicit key navigation checks the remote path rather than pointer-only access.
      await press(tester, LogicalKeyboardKey.arrowDown);
      for (var i = 0; i < 7; i++) {
        await press(tester, LogicalKeyboardKey.arrowRight);
      }
      await press(tester, LogicalKeyboardKey.select);
      expect(find.text('观看增强'), findsOneWidget);
      expect(find.byKey(const Key('overlay-subtitle-toggle')), findsOneWidget);
      await tester.tap(find.byKey(const Key('overlay-close')));
      await tester.pumpAndSettle();
      expect(
        FocusManager.instance.primaryFocus?.debugLabel,
        contains('player-control-12'),
      );
      expect(engines.maxActive, 1);
      expect(engines.engines.length, 1);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'global defaults do not request media and fit a 720p-class logical viewport',
    (tester) async {
      final container = await pumpMamba(tester, size: const Size(800, 450));
      container.read(appRouterProvider).push('/settings/overlays');
      await tester.pumpAndSettle();
      expect(find.text('观看增强'), findsOneWidget);
      await tester.ensureVisible(find.byKey(const Key('overlay-font-size')));
      await tester.tap(find.byKey(const Key('overlay-font-size')));
      await tester.pumpAndSettle();
      expect(
        container.read(overlaySettingsViewModelProvider).requireValue.fontSize,
        28,
      );
      await tester.ensureVisible(
        find.byKey(const Key('overlay-subtitle-position')),
      );
      await tester.tap(find.byKey(const Key('overlay-subtitle-position')));
      await tester.pumpAndSettle();
      expect(
        container
            .read(overlaySettingsViewModelProvider)
            .requireValue
            .subtitleBottom,
        90,
      );
      expect(
        (container.read(subtitleRepositoryProvider) as FakeOverlays).signals,
        isEmpty,
      );
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'search filters apply explicitly and guest following shows a login action',
    (tester) async {
      final container = await pumpMamba(tester);
      final router = container.read(appRouterProvider);
      router.go('/search');
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('search-order')));
      await tester.pumpAndSettle();
      expect(find.text('应用筛选'), findsOneWidget);
      await tester.tap(find.byKey(const Key('search-filter-apply')));
      await tester.pumpAndSettle();
      expect(find.text('已应用'), findsOneWidget);
      router.go('/home?feed=following');
      await tester.pumpAndSettle();
      expect(find.text('登录后查看关注视频'), findsOneWidget);
      expect(find.text('扫码登录'), findsOneWidget);
      expect(const CatalogOptions().order, VideoOrder.relevance);
      expect(tester.takeException(), isNull);
    },
  );
}
