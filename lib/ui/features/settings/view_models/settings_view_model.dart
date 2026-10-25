import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../app/providers/repository_providers.dart';
import '../../../../app/providers/maintenance_providers.dart';
import '../../../../core/result.dart';
import '../../../../domain/entities/app_models.dart';

part 'settings_view_model.freezed.dart';
part 'settings_view_model.g.dart';

@freezed
abstract class SettingsState with _$SettingsState {
  const factory SettingsState({
    @Default(AppSettings()) AppSettings settings,
    @Default(false) bool saving,
    String? message,
  }) = _SettingsState;
}

@Riverpod(keepAlive: true)
class SettingsViewModel extends _$SettingsViewModel {
  @override
  Future<SettingsState> build() async => SettingsState(
    settings: (await ref.watch(settingsRepositoryProvider).load()).valueOrThrow,
  );
  Future<void> savePreferences(AppSettings settings) async {
    final current = state.value;
    if (current == null || current.saving) return;
    state = AsyncData(current.copyWith(saving: true, message: null));
    final result = await ref.read(settingsRepositoryProvider).save(settings);
    if (!ref.mounted) return;
    state = switch (result) {
      Success() => AsyncData(SettingsState(settings: settings, message: '已保存')),
      ResultFailure(:final failure) => AsyncData(
        current.copyWith(saving: false, message: failure.message),
      ),
    };
  }

  Future<void> clearCaches() async {
    final old = state.value;
    if (old == null || old.saving) return;
    final clean = ref.read(cacheCleanerProvider);
    state = AsyncData(old.copyWith(saving: true, message: null));
    try {
      await clean();
      if (ref.mounted) {
        state = AsyncData(old.copyWith(message: '封面与临时缓存已清理，观看记录和账号已保留'));
      }
    } catch (_) {
      if (ref.mounted) {
        state = AsyncData(old.copyWith(message: '缓存清理未完成，请稍后重试'));
      }
    }
  }
}
