// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'search_history_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(SearchHistoryViewModel)
final searchHistoryViewModelProvider = SearchHistoryViewModelFamily._();

final class SearchHistoryViewModelProvider
    extends $AsyncNotifierProvider<SearchHistoryViewModel, SearchHistoryState> {
  SearchHistoryViewModelProvider._({
    required SearchHistoryViewModelFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'searchHistoryViewModelProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$searchHistoryViewModelHash();

  @override
  String toString() {
    return r'searchHistoryViewModelProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  SearchHistoryViewModel create() => SearchHistoryViewModel();

  @override
  bool operator ==(Object other) {
    return other is SearchHistoryViewModelProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$searchHistoryViewModelHash() =>
    r'6f6e4576db1c66389f2c8af751851c8b65ab3c2d';

final class SearchHistoryViewModelFamily extends $Family
    with
        $ClassFamilyOverride<
          SearchHistoryViewModel,
          AsyncValue<SearchHistoryState>,
          SearchHistoryState,
          FutureOr<SearchHistoryState>,
          String
        > {
  SearchHistoryViewModelFamily._()
    : super(
        retry: null,
        name: r'searchHistoryViewModelProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  SearchHistoryViewModelProvider call(String ownerKey) =>
      SearchHistoryViewModelProvider._(argument: ownerKey, from: this);

  @override
  String toString() => r'searchHistoryViewModelProvider';
}

abstract class _$SearchHistoryViewModel
    extends $AsyncNotifier<SearchHistoryState> {
  late final _$args = ref.$arg as String;
  String get ownerKey => _$args;

  FutureOr<SearchHistoryState> build(String ownerKey);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<SearchHistoryState>, SearchHistoryState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<SearchHistoryState>, SearchHistoryState>,
              AsyncValue<SearchHistoryState>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
