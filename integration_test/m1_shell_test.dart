import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mambatv/app/app.dart';
import 'package:mambatv/app/bootstrap.dart';
import 'package:mambatv/app/providers/infrastructure_providers.dart';
import 'package:mambatv/app/providers/repository_providers.dart';
import 'package:mambatv/data/repositories/fake_catalog_repository.dart';
import 'package:mambatv/data/repositories/memory_session_repository.dart';
import 'package:mambatv/ui/features/settings/view_models/settings_view_model.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('M1 native startup, D-pad, schema and persistent preferences', (
    tester,
  ) async {
    final sessions = MemorySessionRepository();
    addTearDown(sessions.close);
    final container = ProviderContainer(
      retry: (_, _) => null,
      overrides: [
        sessionRepositoryProvider.overrideWithValue(sessions),
        catalogRepositoryProvider.overrideWithValue(FakeCatalogRepository()),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const MambaApp()),
    );
    await tester.runAsync(() => container.read(appStartupProvider.future));
    await tester.pumpAndSettle();
    final database = container.read(appDatabaseProvider);
    final schema = await tester.runAsync(
      () => database.customSelect('PRAGMA user_version').getSingle(),
    );
    expect(schema!.read<int>('user_version'), database.schemaVersion);

    Future<void> key(LogicalKeyboardKey value) async {
      await tester.sendKeyEvent(value);
      await tester.pumpAndSettle();
    }

    expect(FocusManager.instance.primaryFocus?.debugLabel, 'nav-0');
    await key(LogicalKeyboardKey.arrowRight);
    await key(LogicalKeyboardKey.arrowDown);
    final card = FocusManager.instance.primaryFocus?.debugLabel;
    expect(card, startsWith('video-demo-'));
    await key(LogicalKeyboardKey.select);
    expect(find.byKey(const Key('detail-play')), findsOneWidget);
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'detail-play');
    await tester.sendKeyEvent(
      LogicalKeyboardKey.goBack,
      physicalKey: PhysicalKeyboardKey.escape,
    );
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(FocusManager.instance.primaryFocus?.debugLabel, card);
    await key(LogicalKeyboardKey.arrowLeft);
    for (var index = 0; index < 4; index++) {
      await key(LogicalKeyboardKey.arrowDown);
    }
    await key(LogicalKeyboardKey.select);
    await key(LogicalKeyboardKey.arrowRight);
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'setting-0');

    final original = container
        .read(settingsViewModelProvider)
        .requireValue
        .settings;
    final settingsVm = container.read(settingsViewModelProvider.notifier);
    try {
      await key(LogicalKeyboardKey.select);
      for (var attempt = 0; attempt < 50; attempt++) {
        if (!container.read(settingsViewModelProvider).requireValue.saving) {
          break;
        }
        await tester.pump(const Duration(milliseconds: 100));
      }
      final changed = container.read(settingsViewModelProvider).requireValue;
      expect(changed.saving, isFalse);
      expect(changed.settings.reducedMotion, !original.reducedMotion);
      final restored = await tester.runAsync(
        () => container.read(settingsRepositoryProvider).load(),
      );
      expect(restored!.valueOrThrow, changed.settings);
    } finally {
      await tester.runAsync(() => settingsVm.savePreferences(original));
      await tester.pumpAndSettle();
    }
    expect(tester.takeException(), isNull);
    binding.reportData = {
      'recordedAtUtc': DateTime.now().toUtc().toIso8601String(),
      'schemaVersion': database.schemaVersion,
      'nativeStartup': true,
      'detailBackRestoresCard': true,
      'backKeyPlusPlatformCallbackPopsOnce': true,
      'restoredCard': card,
      'preferencesReadAfterWrite': true,
      'originalPreferencesRestored': true,
      'catalogSource': 'fake',
      'accountLoginAttempted': false,
    };
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
