import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mambatv/app/providers/auth_providers.dart';
import 'package:mambatv/app/router.dart';
import 'package:mambatv/data/repositories/memory_session_repository.dart';
import 'package:mambatv/domain/auth/auth.dart';

import '../support/app_harness.dart';
import '../support/fake_auth.dart';
import 'tv_shell_test.dart' show press;

void main() {
  testWidgets(
    'D-pad opens login, Back cancels and returns focus to the account action',
    (tester) async {
      final sessions = MemorySessionRepository();
      final auth = FakeAuthRepository(sessions);
      await pumpMamba(tester, sessions: sessions, auth: auth);
      await press(tester, LogicalKeyboardKey.arrowDown);
      await press(tester, LogicalKeyboardKey.arrowDown);
      await press(tester, LogicalKeyboardKey.arrowDown);
      await press(tester, LogicalKeyboardKey.arrowDown);
      await press(tester, LogicalKeyboardKey.select);
      await press(tester, LogicalKeyboardKey.arrowRight);
      expect(FocusManager.instance.primaryFocus?.debugLabel, 'account-primary');
      await press(tester, LogicalKeyboardKey.select);
      expect(find.byKey(const Key('login-qr')), findsOneWidget);
      await press(tester, LogicalKeyboardKey.goBack);
      expect(find.byKey(const Key('login-qr')), findsNothing);
      expect(auth.lastSignal?.isCancelled, isTrue);
      expect(FocusManager.instance.primaryFocus?.debugLabel, 'account-primary');
    },
  );

  testWidgets(
    'successful login consumes its return once; remote logout confirmation remains actionable',
    (tester) async {
      final sessions = MemorySessionRepository();
      final auth = FakeAuthRepository(sessions)
        ..status = QrPollStatus.completed;
      final container = await pumpMamba(tester, sessions: sessions, auth: auth);
      container.read(appRouterProvider).go('/login?returnTo=%2Flibrary');
      await tester.pumpAndSettle();
      expect(find.text('合成验收账号'), findsOneWidget);
      expect(find.byKey(const Key('login-qr')), findsNothing);
      expect(container.read(appRouterProvider).state.uri.path, '/library');
      await tester.tap(find.byKey(const Key('account-primary')));
      await tester.pumpAndSettle();
      expect(find.text('退出当前账号？'), findsOneWidget);
      await tester.tap(find.byKey(const Key('dialog-confirm')));
      await tester.pumpAndSettle();
      expect(sessions.current.isAuthenticated, isFalse);
      expect(find.text('你的观看故事，从这里开始'), findsOneWidget);
    },
  );

  testWidgets(
    'expired QR at 800x450 has a visible refresh action and no layout error',
    (tester) async {
      final sessions = MemorySessionRepository();
      final auth = FakeAuthRepository(sessions)..status = QrPollStatus.expired;
      final container = await pumpMamba(
        tester,
        sessions: sessions,
        auth: auth,
        size: const Size(800, 450),
      );
      container.read(appRouterProvider).go('/login');
      await tester.pumpAndSettle();
      expect(find.text('二维码已过期'), findsOneWidget);
      expect(find.byKey(const Key('login-qr')), findsNothing);
      expect(FocusManager.instance.primaryFocus?.debugLabel, 'qr-primary');
      expect(tester.takeException(), isNull);
      expect(safeLoginReturn('/player/BVtest'), '/video/BVtest');
    },
  );
}
