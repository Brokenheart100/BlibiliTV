// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'infrastructure_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(appTalker)
final appTalkerProvider = AppTalkerProvider._();

final class AppTalkerProvider
    extends $FunctionalProvider<Talker, Talker, Talker>
    with $Provider<Talker> {
  AppTalkerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appTalkerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appTalkerHash();

  @$internal
  @override
  $ProviderElement<Talker> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Talker create(Ref ref) {
    return appTalker(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Talker value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Talker>(value),
    );
  }
}

String _$appTalkerHash() => r'49b64a1065655873ff9529d309a3187898176b18';

@ProviderFor(apiClient)
final apiClientProvider = ApiClientProvider._();

final class ApiClientProvider extends $FunctionalProvider<Dio, Dio, Dio>
    with $Provider<Dio> {
  ApiClientProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'apiClientProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$apiClientHash();

  @$internal
  @override
  $ProviderElement<Dio> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Dio create(Ref ref) {
    return apiClient(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Dio value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Dio>(value),
    );
  }
}

String _$apiClientHash() => r'9e59923b23c4c5553bbdd90a1cbee366d4b76461';

@ProviderFor(appDatabase)
final appDatabaseProvider = AppDatabaseProvider._();

final class AppDatabaseProvider
    extends $FunctionalProvider<AppDatabase, AppDatabase, AppDatabase>
    with $Provider<AppDatabase> {
  AppDatabaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appDatabaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appDatabaseHash();

  @$internal
  @override
  $ProviderElement<AppDatabase> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AppDatabase create(Ref ref) {
    return appDatabase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppDatabase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppDatabase>(value),
    );
  }
}

String _$appDatabaseHash() => r'e94c9361b1f30af66c93089d4ada619f493c49c2';

@ProviderFor(preferencesStore)
final preferencesStoreProvider = PreferencesStoreProvider._();

final class PreferencesStoreProvider
    extends
        $FunctionalProvider<
          PreferencesStore,
          PreferencesStore,
          PreferencesStore
        >
    with $Provider<PreferencesStore> {
  PreferencesStoreProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'preferencesStoreProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$preferencesStoreHash();

  @$internal
  @override
  $ProviderElement<PreferencesStore> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  PreferencesStore create(Ref ref) {
    return preferencesStore(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PreferencesStore value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PreferencesStore>(value),
    );
  }
}

String _$preferencesStoreHash() => r'2b7119f4c5fb363b95b0d89a402af1584b5b4227';

@ProviderFor(credentialStore)
final credentialStoreProvider = CredentialStoreProvider._();

final class CredentialStoreProvider
    extends
        $FunctionalProvider<CredentialStore, CredentialStore, CredentialStore>
    with $Provider<CredentialStore> {
  CredentialStoreProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'credentialStoreProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$credentialStoreHash();

  @$internal
  @override
  $ProviderElement<CredentialStore> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  CredentialStore create(Ref ref) {
    return credentialStore(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CredentialStore value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CredentialStore>(value),
    );
  }
}

String _$credentialStoreHash() => r'ac157de9777f0e03275ce46efd4807833982d22f';
