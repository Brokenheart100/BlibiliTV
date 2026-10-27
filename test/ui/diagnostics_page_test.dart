import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mambatv/app/logging/app_talker.dart';
import 'package:mambatv/app/providers/infrastructure_providers.dart';
import 'package:mambatv/domain/entities/app_models.dart';
import 'package:mambatv/ui/features/settings/view_models/settings_view_model.dart';
import 'package:mambatv/ui/features/settings/views/diagnostics_page.dart';

import '../support/app_harness.dart';
import 'tv_shell_test.dart' show press;

void main() {
  for (final size in [const Size(640, 360), const Size(960, 540)]) {
    testWidgets(
      'TV log reader filters, freezes, scrolls and restores settings at $size',
      (tester) async {
        final container = await pumpMamba(tester, size: size);
        final talker = container.read(appTalkerProvider);
        for (var i = 0; i < 35; i++) {
          recordHttpMetadata(
            talker,
            '{"event":"http","method":"GET","status":${i == 34 ? 503 : 200},"category":"response","elapsedMs":$i}',
          );
        }
        for (var i = 0; i < 4; i++) {
          await press(tester, LogicalKeyboardKey.arrowDown);
        }
        await press(tester, LogicalKeyboardKey.select);
        await press(tester, LogicalKeyboardKey.arrowRight);
        for (var i = 0; i < 12; i++) {
          await press(tester, LogicalKeyboardKey.arrowDown);
        }
        expect(FocusManager.instance.primaryFocus?.debugLabel, 'setting-12');
        await press(tester, LogicalKeyboardKey.select);
        await tester.pumpAndSettle();
        expect(find.byType(DiagnosticsPage), findsOneWidget);
        if (size.width == 640) {
          final settings = container
              .read(settingsViewModelProvider)
              .requireValue
              .settings;
          await container
              .read(settingsViewModelProvider.notifier)
              .savePreferences(settings.copyWith(theme: AppTheme.light));
          await tester.pumpAndSettle();
          expect(
            Theme.of(tester.element(find.text('诊断日志'))).brightness,
            Brightness.light,
          );
        }
        expect(
          FocusManager.instance.primaryFocus?.debugLabel,
          'logs-toolbar-0',
        );
        await press(tester, LogicalKeyboardKey.arrowRight);
        await press(tester, LogicalKeyboardKey.select); // Network only.
        expect(find.text('筛选：网络'), findsOneWidget);
        await press(tester, LogicalKeyboardKey.arrowDown);
        for (var i = 0; i < 27; i++) {
          await press(tester, LogicalKeyboardKey.arrowDown);
        }
        expect(FocusManager.instance.primaryFocus?.debugLabel, 'log-27');
        expect(find.text('继续更新'), findsOneWidget);
        final detail = tester
            .widget<Text>(find.byKey(const Key('logs-detail')))
            .data;
        recordHttpMetadata(
          talker,
          '{"event":"http","method":"GET","status":204,"category":"response","elapsedMs":999}',
        );
        await tester.pumpAndSettle();
        expect(
          tester.widget<Text>(find.byKey(const Key('logs-detail'))).data,
          detail,
        );
        await press(tester, LogicalKeyboardKey.arrowRight);
        expect(FocusManager.instance.primaryFocus?.debugLabel, 'logs-reader');
        await press(tester, LogicalKeyboardKey.arrowDown);
        await press(tester, LogicalKeyboardKey.arrowLeft);
        expect(FocusManager.instance.primaryFocus?.debugLabel, 'log-27');
        await tester.tap(find.byKey(const Key('logs-live')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('logs-filter'))); // State.
        await tester.pumpAndSettle();
        expect(find.text('筛选：状态'), findsOneWidget);
        await tester.tap(find.byKey(const Key('logs-filter'))); // Errors.
        await tester.pumpAndSettle();
        expect(find.text('1 条'), findsOneWidget);
        expect(
          tester.widget<Text>(find.byKey(const Key('logs-detail'))).data,
          contains('503'),
        );
        await tester.tap(find.byKey(const Key('logs-clear')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('dialog-confirm')));
        await tester.pumpAndSettle();
        expect(talker.history, isEmpty);
        expect(find.text('暂无符合条件的日志'), findsOneWidget);
        await press(tester, LogicalKeyboardKey.goBack);
        expect(FocusManager.instance.primaryFocus?.debugLabel, 'setting-12');
        expect(tester.takeException(), isNull);
      },
    );
  }
}
