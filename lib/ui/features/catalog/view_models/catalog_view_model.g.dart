// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'catalog_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(CatalogViewModel)
final catalogViewModelProvider = CatalogViewModelFamily._();

final class CatalogViewModelProvider
    extends $AsyncNotifierProvider<CatalogViewModel, CatalogState> {
  CatalogViewModelProvider._({
    required CatalogViewModelFamily super.from,
    required ({String section, String pageId, String ownerKey, String query})
    super.argument,
  }) : super(
         retry: null,
         name: r'catalogViewModelProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$catalogViewModelHash();

  @override
  String toString() {
    return r'catalogViewModelProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  CatalogViewModel create() => CatalogViewModel();

  @override
  bool operator ==(Object other) {
    return other is CatalogViewModelProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$catalogViewModelHash() => r'6f13c4783a9f238559dc302fb9171394118a7c54';

final class CatalogViewModelFamily extends $Family
    with
        $ClassFamilyOverride<
          CatalogViewModel,
          AsyncValue<CatalogState>,
          CatalogState,
          FutureOr<CatalogState>,
          ({String section, String pageId, String ownerKey, String query})
        > {
  CatalogViewModelFamily._()
    : super(
        retry: null,
        name: r'catalogViewModelProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  CatalogViewModelProvider call({
    required String section,
    required String pageId,
    required String ownerKey,
    String query = '',
  }) => CatalogViewModelProvider._(
    argument: (
      section: section,
      pageId: pageId,
      ownerKey: ownerKey,
      query: query,
    ),
    from: this,
  );

  @override
  String toString() => r'catalogViewModelProvider';
}

abstract class _$CatalogViewModel extends $AsyncNotifier<CatalogState> {
  late final _$args =
      ref.$arg
          as ({String section, String pageId, String ownerKey, String query});
  String get section => _$args.section;
  String get pageId => _$args.pageId;
  String get ownerKey => _$args.ownerKey;
  String get query => _$args.query;

  FutureOr<CatalogState> build({
    required String section,
    required String pageId,
    required String ownerKey,
    String query = '',
  });
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<CatalogState>, CatalogState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<CatalogState>, CatalogState>,
              AsyncValue<CatalogState>,
              Object?,
              Object?
            >;
    return element.handleCreate(
      ref,
      () => build(
        section: _$args.section,
        pageId: _$args.pageId,
        ownerKey: _$args.ownerKey,
        query: _$args.query,
      ),
    );
  }
}

@ProviderFor(SearchQuery)
final searchQueryProvider = SearchQueryFamily._();

final class SearchQueryProvider extends $NotifierProvider<SearchQuery, String> {
  SearchQueryProvider._({
    required SearchQueryFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'searchQueryProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$searchQueryHash();

  @override
  String toString() {
    return r'searchQueryProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  SearchQuery create() => SearchQuery();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is SearchQueryProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$searchQueryHash() => r'b5b3e1e30bedceb21bd705fa4f3a7ef729e996bc';

final class SearchQueryFamily extends $Family
    with $ClassFamilyOverride<SearchQuery, String, String, String, String> {
  SearchQueryFamily._()
    : super(
        retry: null,
        name: r'searchQueryProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  SearchQueryProvider call(String ownerKey) =>
      SearchQueryProvider._(argument: ownerKey, from: this);

  @override
  String toString() => r'searchQueryProvider';
}

abstract class _$SearchQuery extends $Notifier<String> {
  late final _$args = ref.$arg as String;
  String get ownerKey => _$args;

  String build(String ownerKey);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<String, String>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String, String>,
              String,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
