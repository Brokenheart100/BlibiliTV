// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'content_search_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ContentSearchViewModel)
final contentSearchViewModelProvider = ContentSearchViewModelFamily._();

final class ContentSearchViewModelProvider
    extends $AsyncNotifierProvider<ContentSearchViewModel, ContentSearchState> {
  ContentSearchViewModelProvider._({
    required ContentSearchViewModelFamily super.from,
    required ({SearchCategory category, String query, String scopeKey})
    super.argument,
  }) : super(
         retry: null,
         name: r'contentSearchViewModelProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$contentSearchViewModelHash();

  @override
  String toString() {
    return r'contentSearchViewModelProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  ContentSearchViewModel create() => ContentSearchViewModel();

  @override
  bool operator ==(Object other) {
    return other is ContentSearchViewModelProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$contentSearchViewModelHash() =>
    r'3bc6f687597fdb79a0c59a418bd39dbd9df969cc';

final class ContentSearchViewModelFamily extends $Family
    with
        $ClassFamilyOverride<
          ContentSearchViewModel,
          AsyncValue<ContentSearchState>,
          ContentSearchState,
          FutureOr<ContentSearchState>,
          ({SearchCategory category, String query, String scopeKey})
        > {
  ContentSearchViewModelFamily._()
    : super(
        retry: null,
        name: r'contentSearchViewModelProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ContentSearchViewModelProvider call({
    required SearchCategory category,
    required String query,
    required String scopeKey,
  }) => ContentSearchViewModelProvider._(
    argument: (category: category, query: query, scopeKey: scopeKey),
    from: this,
  );

  @override
  String toString() => r'contentSearchViewModelProvider';
}

abstract class _$ContentSearchViewModel
    extends $AsyncNotifier<ContentSearchState> {
  late final _$args =
      ref.$arg as ({SearchCategory category, String query, String scopeKey});
  SearchCategory get category => _$args.category;
  String get query => _$args.query;
  String get scopeKey => _$args.scopeKey;

  FutureOr<ContentSearchState> build({
    required SearchCategory category,
    required String query,
    required String scopeKey,
  });
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<ContentSearchState>, ContentSearchState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<ContentSearchState>, ContentSearchState>,
              AsyncValue<ContentSearchState>,
              Object?,
              Object?
            >;
    return element.handleCreate(
      ref,
      () => build(
        category: _$args.category,
        query: _$args.query,
        scopeKey: _$args.scopeKey,
      ),
    );
  }
}
