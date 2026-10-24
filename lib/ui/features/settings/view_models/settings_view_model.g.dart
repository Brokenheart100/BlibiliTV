// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(SettingsViewModel)
final settingsViewModelProvider = SettingsViewModelProvider._();

final class SettingsViewModelProvider
    extends $AsyncNotifierProvider<SettingsViewModel, SettingsState> {
  SettingsViewModelProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'settingsViewModelProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$settingsViewModelHash();

  @$internal
  @override
  SettingsViewModel create() => SettingsViewModel();
}

String _$settingsViewModelHash() => r'bad3d77f863a91a957f49d338a71caa552c83679';

abstract class _$SettingsViewModel extends $AsyncNotifier<SettingsState> {
  FutureOr<SettingsState> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<SettingsState>, SettingsState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<SettingsState>, SettingsState>,
              AsyncValue<SettingsState>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
