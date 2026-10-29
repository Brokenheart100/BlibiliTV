// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'library_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(LibraryRevision)
final libraryRevisionProvider = LibraryRevisionProvider._();

final class LibraryRevisionProvider
    extends $NotifierProvider<LibraryRevision, int> {
  LibraryRevisionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'libraryRevisionProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$libraryRevisionHash();

  @$internal
  @override
  LibraryRevision create() => LibraryRevision();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$libraryRevisionHash() => r'ed21719f3f1f9218e004ae752939e9a9efff0ec5';

abstract class _$LibraryRevision extends $Notifier<int> {
  int build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<int, int>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<int, int>,
              int,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(LibraryViewModel)
final libraryViewModelProvider = LibraryViewModelFamily._();

final class LibraryViewModelProvider
    extends $AsyncNotifierProvider<LibraryViewModel, LibraryState> {
  LibraryViewModelProvider._({
    required LibraryViewModelFamily super.from,
    required ({String ownerKey, LibrarySection section, String? folderId})
    super.argument,
  }) : super(
         retry: null,
         name: r'libraryViewModelProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$libraryViewModelHash();

  @override
  String toString() {
    return r'libraryViewModelProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  LibraryViewModel create() => LibraryViewModel();

  @override
  bool operator ==(Object other) {
    return other is LibraryViewModelProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$libraryViewModelHash() => r'462676b17fc73085c2482bae0c5f0b3436887088';

final class LibraryViewModelFamily extends $Family
    with
        $ClassFamilyOverride<
          LibraryViewModel,
          AsyncValue<LibraryState>,
          LibraryState,
          FutureOr<LibraryState>,
          ({String ownerKey, LibrarySection section, String? folderId})
        > {
  LibraryViewModelFamily._()
    : super(
        retry: null,
        name: r'libraryViewModelProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  LibraryViewModelProvider call({
    required String ownerKey,
    required LibrarySection section,
    String? folderId,
  }) => LibraryViewModelProvider._(
    argument: (ownerKey: ownerKey, section: section, folderId: folderId),
    from: this,
  );

  @override
  String toString() => r'libraryViewModelProvider';
}

abstract class _$LibraryViewModel extends $AsyncNotifier<LibraryState> {
  late final _$args =
      ref.$arg as ({String ownerKey, LibrarySection section, String? folderId});
  String get ownerKey => _$args.ownerKey;
  LibrarySection get section => _$args.section;
  String? get folderId => _$args.folderId;

  FutureOr<LibraryState> build({
    required String ownerKey,
    required LibrarySection section,
    String? folderId,
  });
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<LibraryState>, LibraryState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<LibraryState>, LibraryState>,
              AsyncValue<LibraryState>,
              Object?,
              Object?
            >;
    return element.handleCreate(
      ref,
      () => build(
        ownerKey: _$args.ownerKey,
        section: _$args.section,
        folderId: _$args.folderId,
      ),
    );
  }
}

@ProviderFor(PersonalActionsViewModel)
final personalActionsViewModelProvider = PersonalActionsViewModelFamily._();

final class PersonalActionsViewModelProvider
    extends
        $AsyncNotifierProvider<PersonalActionsViewModel, PersonalActionsState> {
  PersonalActionsViewModelProvider._({
    required PersonalActionsViewModelFamily super.from,
    required ({String videoId, String ownerKey}) super.argument,
  }) : super(
         retry: null,
         name: r'personalActionsViewModelProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$personalActionsViewModelHash();

  @override
  String toString() {
    return r'personalActionsViewModelProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  PersonalActionsViewModel create() => PersonalActionsViewModel();

  @override
  bool operator ==(Object other) {
    return other is PersonalActionsViewModelProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$personalActionsViewModelHash() =>
    r'39c90944ba612195177510cebca778bb23c140f4';

final class PersonalActionsViewModelFamily extends $Family
    with
        $ClassFamilyOverride<
          PersonalActionsViewModel,
          AsyncValue<PersonalActionsState>,
          PersonalActionsState,
          FutureOr<PersonalActionsState>,
          ({String videoId, String ownerKey})
        > {
  PersonalActionsViewModelFamily._()
    : super(
        retry: null,
        name: r'personalActionsViewModelProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  PersonalActionsViewModelProvider call({
    required String videoId,
    required String ownerKey,
  }) => PersonalActionsViewModelProvider._(
    argument: (videoId: videoId, ownerKey: ownerKey),
    from: this,
  );

  @override
  String toString() => r'personalActionsViewModelProvider';
}

abstract class _$PersonalActionsViewModel
    extends $AsyncNotifier<PersonalActionsState> {
  late final _$args = ref.$arg as ({String videoId, String ownerKey});
  String get videoId => _$args.videoId;
  String get ownerKey => _$args.ownerKey;

  FutureOr<PersonalActionsState> build({
    required String videoId,
    required String ownerKey,
  });
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<AsyncValue<PersonalActionsState>, PersonalActionsState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<PersonalActionsState>,
                PersonalActionsState
              >,
              AsyncValue<PersonalActionsState>,
              Object?,
              Object?
            >;
    return element.handleCreate(
      ref,
      () => build(videoId: _$args.videoId, ownerKey: _$args.ownerKey),
    );
  }
}
