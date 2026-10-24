// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(qrTiming)
final qrTimingProvider = QrTimingProvider._();

final class QrTimingProvider
    extends $FunctionalProvider<QrTiming, QrTiming, QrTiming>
    with $Provider<QrTiming> {
  QrTimingProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'qrTimingProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$qrTimingHash();

  @$internal
  @override
  $ProviderElement<QrTiming> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  QrTiming create(Ref ref) {
    return qrTiming(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(QrTiming value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<QrTiming>(value),
    );
  }
}

String _$qrTimingHash() => r'da7e2e210952a30a3f0860c4807fa7a2c8cf42d4';
