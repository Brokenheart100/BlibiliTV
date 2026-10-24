// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ui_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(focusMemory)
final focusMemoryProvider = FocusMemoryProvider._();

final class FocusMemoryProvider
    extends $FunctionalProvider<FocusMemory, FocusMemory, FocusMemory>
    with $Provider<FocusMemory> {
  FocusMemoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'focusMemoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$focusMemoryHash();

  @$internal
  @override
  $ProviderElement<FocusMemory> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  FocusMemory create(Ref ref) {
    return focusMemory(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FocusMemory value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FocusMemory>(value),
    );
  }
}

String _$focusMemoryHash() => r'e64dd3af2c9c2426c5ccd811b519f84f6fd94b87';

@ProviderFor(AppForeground)
final appForegroundProvider = AppForegroundProvider._();

final class AppForegroundProvider
    extends $NotifierProvider<AppForeground, bool> {
  AppForegroundProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appForegroundProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appForegroundHash();

  @$internal
  @override
  AppForeground create() => AppForeground();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$appForegroundHash() => r'369f1f0793096644dc1ca401562063393fdea008';

abstract class _$AppForeground extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
