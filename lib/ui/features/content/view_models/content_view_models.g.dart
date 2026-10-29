// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'content_view_models.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ContentBrowse)
final contentBrowseProvider = ContentBrowseFamily._();

final class ContentBrowseProvider
    extends $AsyncNotifierProvider<ContentBrowse, ContentBrowseState> {
  ContentBrowseProvider._({
    required ContentBrowseFamily super.from,
    required ({bool live, String scopeKey}) super.argument,
  }) : super(
         retry: null,
         name: r'contentBrowseProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$contentBrowseHash();

  @override
  String toString() {
    return r'contentBrowseProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  ContentBrowse create() => ContentBrowse();

  @override
  bool operator ==(Object other) {
    return other is ContentBrowseProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$contentBrowseHash() => r'f467d8203fe1d6fc44980179099749e5caedbde4';

final class ContentBrowseFamily extends $Family
    with
        $ClassFamilyOverride<
          ContentBrowse,
          AsyncValue<ContentBrowseState>,
          ContentBrowseState,
          FutureOr<ContentBrowseState>,
          ({bool live, String scopeKey})
        > {
  ContentBrowseFamily._()
    : super(
        retry: null,
        name: r'contentBrowseProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ContentBrowseProvider call({required bool live, required String scopeKey}) =>
      ContentBrowseProvider._(
        argument: (live: live, scopeKey: scopeKey),
        from: this,
      );

  @override
  String toString() => r'contentBrowseProvider';
}

abstract class _$ContentBrowse extends $AsyncNotifier<ContentBrowseState> {
  late final _$args = ref.$arg as ({bool live, String scopeKey});
  bool get live => _$args.live;
  String get scopeKey => _$args.scopeKey;

  FutureOr<ContentBrowseState> build({
    required bool live,
    required String scopeKey,
  });
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<ContentBrowseState>, ContentBrowseState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<ContentBrowseState>, ContentBrowseState>,
              AsyncValue<ContentBrowseState>,
              Object?,
              Object?
            >;
    return element.handleCreate(
      ref,
      () => build(live: _$args.live, scopeKey: _$args.scopeKey),
    );
  }
}

@ProviderFor(contentSeason)
final contentSeasonProvider = ContentSeasonFamily._();

final class ContentSeasonProvider
    extends
        $FunctionalProvider<
          AsyncValue<ContentSeason>,
          ContentSeason,
          FutureOr<ContentSeason>
        >
    with $FutureModifier<ContentSeason>, $FutureProvider<ContentSeason> {
  ContentSeasonProvider._({
    required ContentSeasonFamily super.from,
    required ({String id, String scopeKey}) super.argument,
  }) : super(
         retry: null,
         name: r'contentSeasonProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$contentSeasonHash();

  @override
  String toString() {
    return r'contentSeasonProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<ContentSeason> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<ContentSeason> create(Ref ref) {
    final argument = this.argument as ({String id, String scopeKey});
    return contentSeason(ref, id: argument.id, scopeKey: argument.scopeKey);
  }

  @override
  bool operator ==(Object other) {
    return other is ContentSeasonProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$contentSeasonHash() => r'8348808c2a38f93537fd1fba96d4db373e0a3c08';

final class ContentSeasonFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<ContentSeason>,
          ({String id, String scopeKey})
        > {
  ContentSeasonFamily._()
    : super(
        retry: null,
        name: r'contentSeasonProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ContentSeasonProvider call({required String id, required String scopeKey}) =>
      ContentSeasonProvider._(
        argument: (id: id, scopeKey: scopeKey),
        from: this,
      );

  @override
  String toString() => r'contentSeasonProvider';
}
