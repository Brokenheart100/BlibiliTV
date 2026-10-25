import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mambatv/app/router.dart';
import 'package:mambatv/ui/features/settings/view_models/licenses_view_model.dart';

import '../support/app_harness.dart';
import 'tv_shell_test.dart' show press;

void main() {
  testWidgets(
    'TV licenses lazily navigate long packages and scroll full license text at 800x450',
    (tester) async {
      final licenses = [
        for (var i = 0; i < 40; i++)
          LicenseNotice(
            'package-$i',
            'License $i\n${'Original license paragraph.\n' * 120}',
          ),
      ];
      final c = await pumpMamba(
        tester,
        licenses: licenses,
        size: const Size(800, 450),
      );
      c.read(appRouterProvider).push<void>('/settings/licenses');
      await tester.pumpAndSettle();
      await press(tester, LogicalKeyboardKey.arrowDown);
      for (var i = 0; i < 25; i++) {
        await press(tester, LogicalKeyboardKey.arrowDown);
      }
      expect(FocusManager.instance.primaryFocus?.debugLabel, 'license-25');
      await press(tester, LogicalKeyboardKey.arrowRight);
      expect(FocusManager.instance.primaryFocus?.debugLabel, 'licenses-reader');
      final before = tester
          .getTopLeft(find.byKey(const Key('license-text')))
          .dy;
      await press(tester, LogicalKeyboardKey.arrowDown);
      expect(
        tester.getTopLeft(find.byKey(const Key('license-text'))).dy,
        lessThan(before),
      );
      await press(tester, LogicalKeyboardKey.arrowLeft);
      expect(FocusManager.instance.primaryFocus?.debugLabel, 'license-25');
      await press(tester, LogicalKeyboardKey.goBack);
      expect(find.byKey(const Key('licenses-back')), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'empty license registry has an accessible return without crashing',
    (tester) async {
      final c = await pumpMamba(
        tester,
        licenses: [],
        size: const Size(800, 450),
      );
      c.read(appRouterProvider).push<void>('/settings/licenses');
      await tester.pumpAndSettle();
      expect(find.text('此构建没有读取到许可文本'), findsOneWidget);
      await press(tester, LogicalKeyboardKey.select);
      expect(find.byKey(const Key('licenses-back')), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
