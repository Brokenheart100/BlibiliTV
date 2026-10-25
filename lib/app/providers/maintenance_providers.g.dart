// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'maintenance_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(cacheCleaner)
final cacheCleanerProvider = CacheCleanerProvider._();

final class CacheCleanerProvider
    extends $FunctionalProvider<CacheCleaner, CacheCleaner, CacheCleaner>
    with $Provider<CacheCleaner> {
  CacheCleanerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'cacheCleanerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$cacheCleanerHash();

  @$internal
  @override
  $ProviderElement<CacheCleaner> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  CacheCleaner create(Ref ref) {
    return cacheCleaner(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CacheCleaner value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CacheCleaner>(value),
    );
  }
}

String _$cacheCleanerHash() => r'1cbc2c2614de7f2868ea4134341859aafaeb1ea3';

@ProviderFor(installedAppVersion)
final installedAppVersionProvider = InstalledAppVersionProvider._();

final class InstalledAppVersionProvider
    extends $FunctionalProvider<AsyncValue<String>, String, FutureOr<String>>
    with $FutureModifier<String>, $FutureProvider<String> {
  InstalledAppVersionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'installedAppVersionProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$installedAppVersionHash();

  @$internal
  @override
  $FutureProviderElement<String> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<String> create(Ref ref) {
    return installedAppVersion(ref);
  }
}

String _$installedAppVersionHash() =>
    r'e6ce522bed44dffb7ed8537ede80c6433016ad1e';
