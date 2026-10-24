// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'probe_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(probeService)
final probeServiceProvider = ProbeServiceProvider._();

final class ProbeServiceProvider
    extends
        $FunctionalProvider<
          BilibiliProbeService,
          BilibiliProbeService,
          BilibiliProbeService
        >
    with $Provider<BilibiliProbeService> {
  ProbeServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'probeServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$probeServiceHash();

  @$internal
  @override
  $ProviderElement<BilibiliProbeService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  BilibiliProbeService create(Ref ref) {
    return probeService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BilibiliProbeService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BilibiliProbeService>(value),
    );
  }
}

String _$probeServiceHash() => r'54d0b32bac0850d0765852c181e8489bbb9c0394';

/// M0 wiring only; M1 will place production dependency providers in App.

@ProviderFor(ProbeViewModel)
final probeViewModelProvider = ProbeViewModelProvider._();

/// M0 wiring only; M1 will place production dependency providers in App.
final class ProbeViewModelProvider
    extends $NotifierProvider<ProbeViewModel, ProbeState> {
  /// M0 wiring only; M1 will place production dependency providers in App.
  ProbeViewModelProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'probeViewModelProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$probeViewModelHash();

  @$internal
  @override
  ProbeViewModel create() => ProbeViewModel();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ProbeState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ProbeState>(value),
    );
  }
}

String _$probeViewModelHash() => r'e5dd802b44a84ada28f15a877059dce607a03987';

/// M0 wiring only; M1 will place production dependency providers in App.

abstract class _$ProbeViewModel extends $Notifier<ProbeState> {
  ProbeState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<ProbeState, ProbeState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ProbeState, ProbeState>,
              ProbeState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
