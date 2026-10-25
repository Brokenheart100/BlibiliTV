import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mambatv/app/app.dart';
import 'package:mambatv/app/bootstrap.dart';
import 'package:mambatv/app/providers/infrastructure_providers.dart';
import 'package:mambatv/app/providers/playback_providers.dart';
import 'package:mambatv/app/providers/repository_providers.dart';
import 'package:mambatv/app/router.dart';
import 'package:mambatv/data/repositories/drift_history_repository.dart';
import 'package:mambatv/data/repositories/local_progress_repository.dart';
import 'package:mambatv/data/repositories/local_settings_repository.dart';
import 'package:mambatv/data/repositories/memory_session_repository.dart';
import 'package:mambatv/data/repositories/fake_catalog_repository.dart';
import 'package:mambatv/data/services/local/app_database.dart';
import 'package:mambatv/domain/entities/app_models.dart';
import 'package:mambatv/domain/playback/playback.dart';
import 'package:mambatv/ui/core/images/tv_image_cache.dart';
import 'package:mambatv/ui/features/library/views/personal_actions_dialog.dart';
import 'package:mambatv/ui/features/settings/view_models/settings_view_model.dart';

import '../test/support/fake_playback.dart';
import '../test/support/fake_library.dart';
import 'm3_auth_flow_test.dart' show ValidationPreferences;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  TvImageCache.configure();
  testWidgets(
    'M6 isolated native history, defaults, cache and synthetic account commands',
    (tester) async {
      expect(
        const bool.fromEnvironment('MAMBA_VALIDATION_APP'),
        true,
        reason: 'Native acceptance must use the isolated validation package',
      );
      final db = AppDatabase(driftDatabase(name: 'mambatv_m6_validation'));
      final sessions = MemorySessionRepository(
        const Session(
          ownerKey: 'user:101',
          displayName: '合成账号 A',
          status: SessionStatus.authenticated,
        ),
      );
      final remote = FakeLibraryRepository();
      final engines = FakeEngineFactory();
      final preferences = ValidationPreferences();
      final settings = LocalSettingsRepository(preferences);
      await settings.save(
        const AppSettings(defaultRate: 1.5, defaultQuality: 16, autoNext: true),
      );
      await db.delete(db.watchProgressRows).go();
      await db.delete(db.historyVideos).go();
      final progress = LocalProgressRepository(db),
          history = DriftHistoryRepository(db);
      for (final owner in ['user:101', 'user:202', 'guest']) {
        await progress.save(
          WatchProgress(
            ownerKey: owner,
            videoId: 'demo-000',
            partId: 'demo-000-p1',
            position: Duration(seconds: owner == 'user:101' ? 25 : 40),
            duration: const Duration(minutes: 2),
          ),
        );
        await history.rememberVideo(
          owner,
          libraryVideo('demo-000').copyWith(title: '合成记录 $owner'),
        );
      }
      final container = ProviderContainer(
        retry: (_, _) => null,
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          sessionRepositoryProvider.overrideWithValue(sessions),
          preferencesStoreProvider.overrideWithValue(preferences),
          settingsRepositoryProvider.overrideWithValue(settings),
          catalogRepositoryProvider.overrideWithValue(
            FakeCatalogRepository(latency: Duration.zero),
          ),
          playbackRepositoryProvider.overrideWithValue(
            FakePlaybackRepository(),
          ),
          playbackAdapterProvider.overrideWithValue(engines.adapter),
          libraryRepositoryProvider.overrideWithValue(remote),
        ],
      );
      addTearDown(() async {
        container.dispose();
        await sessions.close();
        await db.close();
      });
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MambaApp(),
        ),
      );
      await tester.runAsync(() => container.read(appStartupProvider.future));
      await tester.pumpAndSettle();
      final router = container.read(appRouterProvider);
      Future<void> key(LogicalKeyboardKey key) async {
        await tester.sendKeyEvent(key);
        await tester.pumpAndSettle();
      }

      router.push<void>('/library/records');
      await tester.pumpAndSettle();
      expect(find.text('合成记录 user:101'), findsOneWidget);
      await key(LogicalKeyboardKey.arrowDown);
      await key(LogicalKeyboardKey.arrowDown);
      await key(LogicalKeyboardKey.select);
      expect(engines.engines.last.openedAt, const Duration(seconds: 25));
      expect(engines.engines.last.snapshot.rate, 1.5);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(engines.active, 0);
      if (find.byKey(const Key('library-clear')).evaluate().isEmpty) {
        router.push<void>('/library/records');
        await tester.pumpAndSettle();
      }
      await tester.tap(find.byKey(const Key('library-clear')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('dialog-confirm')));
      await tester.pumpAndSettle();
      expect((await history.list('user:101')).valueOrThrow.items, isEmpty);
      expect((await history.list('user:202')).valueOrThrow.items, hasLength(1));
      expect((await history.list('guest')).valueOrThrow.items, hasLength(1));
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      router.go('/settings');
      await tester.pumpAndSettle();
      await key(LogicalKeyboardKey.arrowLeft);
      await key(LogicalKeyboardKey.arrowRight);
      for (var i = 0; i < 6; i++) {
        await key(LogicalKeyboardKey.arrowDown);
      }
      expect(FocusManager.instance.primaryFocus?.debugLabel, 'setting-6');
      await key(LogicalKeyboardKey.select);
      await tester.tap(find.byKey(const Key('dialog-confirm')));
      await tester.pumpAndSettle();
      for (
        var i = 0;
        i < 100 &&
            container.read(settingsViewModelProvider).value?.saving == true;
        i++
      ) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(
        container.read(settingsViewModelProvider).requireValue.message,
        contains('已保留'),
      );
      expect(
        (await LocalSettingsRepository(
          preferences,
        ).load()).valueOrThrow.defaultRate,
        1.5,
      );
      expect((await history.list('user:202')).valueOrThrow.items, hasLength(1));
      final dialogContext = router.routerDelegate.navigatorKey.currentContext!;
      showDialog<void>(
        context: dialogContext,
        builder: (_) => const PersonalActionsDialog(
          videoId: 'BVtest',
          ownerKey: 'user:101',
        ),
      );
      await tester.pumpAndSettle();
      expect(remote.writes, 0);
      await tester.tap(find.byKey(const Key('personal-later')));
      await tester.pumpAndSettle();
      expect(remote.writes, 1);
      expect(remote.later, true);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      sessions.replace(const Session(generation: 1));
      await tester.pumpAndSettle();
      router.push<void>('/library/records');
      await tester.pumpAndSettle();
      expect(find.text('合成记录 guest'), findsOneWidget);
      sessions.replace(
        const Session(
          ownerKey: 'user:202',
          displayName: '合成账号 B',
          status: SessionStatus.authenticated,
          generation: 2,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('合成记录 user:202'), findsOneWidget);
      expect(find.text('合成记录 guest'), findsNothing);
      expect(tester.takeException(), isNull);
      binding.reportData = {
        'recordedAtUtc': DateTime.now().toUtc().toIso8601String(),
        'isolatedPackage': true,
        'nativeDriftHistory': true,
        'localResumeSeconds': 25,
        'initialRate': 1.5,
        'ownerScopedClear': true,
        'nativeCacheClearPreservesRecordsAndSettings': true,
        'syntheticWriteCommands': remote.writes,
        'realRemoteWriteCommands': 0,
        'accountSequence': ['synthetic-A', 'guest', 'synthetic-B'],
      };
    },
  );
}
