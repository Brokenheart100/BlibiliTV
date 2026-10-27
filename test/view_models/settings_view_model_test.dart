import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mambatv/app/providers/infrastructure_providers.dart';
import 'package:mambatv/ui/features/settings/view_models/settings_view_model.dart';
import 'package:mambatv/domain/entities/app_models.dart';
import 'package:mambatv/data/repositories/local_settings_repository.dart';

import '../support/memory_preferences.dart';

void main() {
  test(
    'appearance migrates old preferences and survives a repository reload',
    () async {
      final store = MemoryPreferencesStore();
      store.values['app.preferences.v1'] = '{"reducedMotion":true}';
      final repo = LocalSettingsRepository(store);
      final old = (await repo.load()).valueOrThrow;
      expect(old.theme, AppTheme.dark);
      expect(old.reducedMotion, isTrue);
      await repo.save(old.copyWith(theme: AppTheme.light));
      final restored = (await LocalSettingsRepository(
        store,
      ).load()).valueOrThrow;
      expect(restored.theme, AppTheme.light);
      expect(restored.reducedMotion, isTrue);
      store.values['app.preferences.v1'] = '{"theme":"future-theme"}';
      expect((await repo.load()).valueOrThrow.theme, AppTheme.dark);
    },
  );
  test(
    'failed preference command preserves committed state and can retry',
    () async {
      final store = MemoryPreferencesStore();
      final container = ProviderContainer(
        retry: (_, _) => null,
        overrides: [preferencesStoreProvider.overrideWithValue(store)],
      );
      addTearDown(container.dispose);
      final initial = await container.read(settingsViewModelProvider.future);
      final desired = initial.settings.copyWith(
        reducedMotion: true,
        theme: AppTheme.light,
      );
      final vm = container.read(settingsViewModelProvider.notifier);
      store.failWrites = true;
      await vm.savePreferences(desired);
      final failed = container.read(settingsViewModelProvider).requireValue;
      expect(failed.settings, initial.settings);
      expect(failed.saving, isFalse);
      expect(failed.message, isNotNull);
      expect(store.values, isEmpty);
      store.failWrites = false;
      await vm.savePreferences(desired);
      expect(
        container.read(settingsViewModelProvider).requireValue.settings,
        desired,
      );
    },
  );
}
