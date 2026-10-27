// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'personal_home_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(personalProfile)
final personalProfileProvider = PersonalProfileFamily._();

final class PersonalProfileProvider
    extends
        $FunctionalProvider<
          AsyncValue<PersonalProfile?>,
          PersonalProfile?,
          FutureOr<PersonalProfile?>
        >
    with $FutureModifier<PersonalProfile?>, $FutureProvider<PersonalProfile?> {
  PersonalProfileProvider._({
    required PersonalProfileFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'personalProfileProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$personalProfileHash();

  @override
  String toString() {
    return r'personalProfileProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<PersonalProfile?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<PersonalProfile?> create(Ref ref) {
    final argument = this.argument as String;
    return personalProfile(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is PersonalProfileProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$personalProfileHash() => r'bc9cfda41dc1e9e94694322dfc90da6158f130a5';

final class PersonalProfileFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<PersonalProfile?>, String> {
  PersonalProfileFamily._()
    : super(
        retry: null,
        name: r'personalProfileProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  PersonalProfileProvider call(String scopeKey) =>
      PersonalProfileProvider._(argument: scopeKey, from: this);

  @override
  String toString() => r'personalProfileProvider';
}

@ProviderFor(PersonalCollection)
final personalCollectionProvider = PersonalCollectionFamily._();

final class PersonalCollectionProvider
    extends
        $AsyncNotifierProvider<PersonalCollection, PersonalCollectionState> {
  PersonalCollectionProvider._({
    required PersonalCollectionFamily super.from,
    required ({String scopeKey, PersonalSection section, String? folderId})
    super.argument,
  }) : super(
         retry: null,
         name: r'personalCollectionProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$personalCollectionHash();

  @override
  String toString() {
    return r'personalCollectionProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  PersonalCollection create() => PersonalCollection();

  @override
  bool operator ==(Object other) {
    return other is PersonalCollectionProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$personalCollectionHash() =>
    r'9eb491d37c6bef11bdd30bff4c924e8afe786c36';

final class PersonalCollectionFamily extends $Family
    with
        $ClassFamilyOverride<
          PersonalCollection,
          AsyncValue<PersonalCollectionState>,
          PersonalCollectionState,
          FutureOr<PersonalCollectionState>,
          ({String scopeKey, PersonalSection section, String? folderId})
        > {
  PersonalCollectionFamily._()
    : super(
        retry: null,
        name: r'personalCollectionProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  PersonalCollectionProvider call({
    required String scopeKey,
    required PersonalSection section,
    String? folderId,
  }) => PersonalCollectionProvider._(
    argument: (scopeKey: scopeKey, section: section, folderId: folderId),
    from: this,
  );

  @override
  String toString() => r'personalCollectionProvider';
}

abstract class _$PersonalCollection
    extends $AsyncNotifier<PersonalCollectionState> {
  late final _$args =
      ref.$arg
          as ({String scopeKey, PersonalSection section, String? folderId});
  String get scopeKey => _$args.scopeKey;
  PersonalSection get section => _$args.section;
  String? get folderId => _$args.folderId;

  FutureOr<PersonalCollectionState> build({
    required String scopeKey,
    required PersonalSection section,
    String? folderId,
  });
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<
              AsyncValue<PersonalCollectionState>,
              PersonalCollectionState
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<PersonalCollectionState>,
                PersonalCollectionState
              >,
              AsyncValue<PersonalCollectionState>,
              Object?,
              Object?
            >;
    return element.handleCreate(
      ref,
      () => build(
        scopeKey: _$args.scopeKey,
        section: _$args.section,
        folderId: _$args.folderId,
      ),
    );
  }
}
