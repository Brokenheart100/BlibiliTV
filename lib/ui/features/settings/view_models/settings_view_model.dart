import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../app/providers/repository_providers.dart';
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
}
