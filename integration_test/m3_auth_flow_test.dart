import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mambatv/app/app.dart';
import 'package:mambatv/app/bootstrap.dart';
import 'package:mambatv/app/providers/auth_providers.dart';
import 'package:mambatv/app/providers/repository_providers.dart';
import 'package:mambatv/data/repositories/fake_catalog_repository.dart';
import 'package:mambatv/data/repositories/persistent_session_repository.dart';
import 'package:mambatv/data/services/local/local_stores.dart';
import 'package:mambatv/domain/auth/auth.dart';

import '../test/support/fake_auth.dart';

// Real Android storage plugins, synthetic credentials in a separate namespace.
// This test cannot overwrite or validate a person's real Bilibili session.
class ValidationVault implements CredentialStore {
  final delegate = const SecureCredentialStore();
  String key(String value) => 'm3.validation.$value';
  @override
  Future<String?> read(String name) => delegate.read(key(name));
  @override
  Future<void> write(String name, String value) =>
      delegate.write(key(name), value);
  @override
  Future<void> delete(String name) => delegate.delete(key(name));
}

class ValidationPreferences implements PreferencesStore {
  final delegate = PlatformPreferencesStore();
  @override
  Future<String?> read(String name) => delegate.read('m3.validation.$name');
  @override
  Future<void> write(String name, String value) =>
      delegate.write('m3.validation.$name', value);
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'M3 native D-pad, QR cancellation, secure commit, repository recreation and logout',
    (tester) async {
      final vault = ValidationVault();
      final preferences = ValidationPreferences();
      await vault.delete(PersistentSessionRepository.credentialKey);
      await preferences.write(PersistentSessionRepository.blockedKey, 'true');
      final gateway = FakeAuthGateway();
      final sessions = PersistentSessionRepository(gateway, vault, preferences);
      final container = ProviderContainer(
        retry: (_, _) => null,
        overrides: [
          persistentSessionProvider.overrideWithValue(sessions),
          authGatewayProvider.overrideWithValue(gateway),
          catalogRepositoryProvider.overrideWithValue(FakeCatalogRepository()),
          qrTimingProvider.overrideWithValue(
            const QrTiming(
              pollInterval: Duration(milliseconds: 150),
              tickInterval: Duration(milliseconds: 50),
            ),
          ),
        ],
      );
      addTearDown(() async {
        container.dispose();
        await sessions.dispose();
        await vault.delete(PersistentSessionRepository.credentialKey);
        await preferences.write(PersistentSessionRepository.blockedKey, 'true');
      });
      Future<void> until(bool Function() condition) async {
        final deadline = DateTime.now().add(const Duration(seconds: 30));
        while (!condition() && DateTime.now().isBefore(deadline)) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(
          condition(),
          isTrue,
          reason: 'Timed out waiting for native auth state',
        );
      }

      Future<void> key(LogicalKeyboardKey value) async {
        await tester.sendKeyEvent(value);
        await tester.pump(const Duration(milliseconds: 250));
      }

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MambaApp(),
        ),
      );
      await tester.runAsync(() => container.read(appStartupProvider.future));
      await tester.pumpAndSettle();
      await key(LogicalKeyboardKey.arrowDown);
      await key(LogicalKeyboardKey.arrowDown);
      await key(LogicalKeyboardKey.select);
      await key(LogicalKeyboardKey.arrowRight);
      expect(FocusManager.instance.primaryFocus?.debugLabel, 'account-primary');
      await key(LogicalKeyboardKey.select);
      await until(
        () => find.byKey(const Key('login-qr')).evaluate().isNotEmpty,
      );
      final pollsBeforeCancel = gateway.polls;
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('login-qr')), findsNothing);
      await tester.pump(const Duration(seconds: 1));
      expect(gateway.polls, pollsBeforeCancel);
      expect(FocusManager.instance.primaryFocus?.debugLabel, 'account-primary');
      await key(LogicalKeyboardKey.select);
      await until(
        () => find.byKey(const Key('login-qr')).evaluate().isNotEmpty,
      );
      gateway.pollStatus = QrPollStatus.scanned;
      await until(() => find.text('已扫码，请在手机上确认').evaluate().isNotEmpty);
      gateway.pollStatus = QrPollStatus.completed;
      await until(() => sessions.current.isAuthenticated);
      await until(() => find.text('合成验收账号 101').evaluate().isNotEmpty);
      expect(
        await vault.read(PersistentSessionRepository.credentialKey),
        isNotNull,
      );
      final recreated = PersistentSessionRepository(
        gateway,
        ValidationVault(),
        ValidationPreferences(),
      );
      await recreated.restore();
      expect(recreated.current.ownerKey, 'user:101');
      expect(recreated.current.isAuthenticated, isTrue);
      await recreated.dispose();
      await key(LogicalKeyboardKey.arrowRight);
      await tester.tap(find.byKey(const Key('account-primary')));
      await tester.pumpAndSettle();
      expect(find.text('退出当前账号？'), findsOneWidget);
      // The confirmation action must be reachable using a remote control.
      await key(LogicalKeyboardKey.arrowRight);
      await key(LogicalKeyboardKey.select);
      await until(
        () =>
            !sessions.current.isAuthenticated &&
            find.text('你的观看故事，从这里开始').evaluate().isNotEmpty,
      );
      await until(() => gateway.logouts == 1);
      expect(
        await vault.read(PersistentSessionRepository.credentialKey),
        isNull,
      );
      final afterLogout = PersistentSessionRepository(
        gateway,
        ValidationVault(),
        ValidationPreferences(),
      );
      await afterLogout.restore();
      expect(afterLogout.current.isAuthenticated, isFalse);
      await afterLogout.dispose();
      expect(tester.takeException(), isNull);
      binding.reportData = {
        'recordedAtUtc': DateTime.now().toUtc().toIso8601String(),
        'fixture': 'synthetic account; real Android storage plugins; isolated validation namespace',
        'dpadLoginAndLogout': true,
        'backStopsPolling': true,
        'scannedAndCompletedStates': true,
        'secureCommit': true,
        'newRepositoryRestoredFromPlatformStorage': true,
        'logoutRemovedCredential': true,
        'newRepositoryAfterLogoutIsGuest': true,
        'realAccountConfirmed': false,
        'fullProcessRestartValidated': false,
      };
    },
  );
}
