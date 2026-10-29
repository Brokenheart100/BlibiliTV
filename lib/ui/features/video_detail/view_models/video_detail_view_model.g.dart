// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'video_detail_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(VideoDetailViewModel)
final videoDetailViewModelProvider = VideoDetailViewModelFamily._();

final class VideoDetailViewModelProvider
    extends $AsyncNotifierProvider<VideoDetailViewModel, VideoDetailState> {
  VideoDetailViewModelProvider._({
    required VideoDetailViewModelFamily super.from,
    required ({String id, String pageId, String ownerKey}) super.argument,
  }) : super(
         retry: null,
         name: r'videoDetailViewModelProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$videoDetailViewModelHash();

  @override
  String toString() {
    return r'videoDetailViewModelProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  VideoDetailViewModel create() => VideoDetailViewModel();

  @override
  bool operator ==(Object other) {
    return other is VideoDetailViewModelProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$videoDetailViewModelHash() =>
    r'd5ae2b4b080aa068487d8b10e00c3a222dfab0b7';

final class VideoDetailViewModelFamily extends $Family
    with
        $ClassFamilyOverride<
          VideoDetailViewModel,
          AsyncValue<VideoDetailState>,
          VideoDetailState,
          FutureOr<VideoDetailState>,
          ({String id, String pageId, String ownerKey})
        > {
  VideoDetailViewModelFamily._()
    : super(
        retry: null,
        name: r'videoDetailViewModelProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  VideoDetailViewModelProvider call({
    required String id,
    required String pageId,
    required String ownerKey,
  }) => VideoDetailViewModelProvider._(
    argument: (id: id, pageId: pageId, ownerKey: ownerKey),
    from: this,
  );

  @override
  String toString() => r'videoDetailViewModelProvider';
}

abstract class _$VideoDetailViewModel extends $AsyncNotifier<VideoDetailState> {
  late final _$args = ref.$arg as ({String id, String pageId, String ownerKey});
  String get id => _$args.id;
  String get pageId => _$args.pageId;
  String get ownerKey => _$args.ownerKey;

  FutureOr<VideoDetailState> build({
    required String id,
    required String pageId,
    required String ownerKey,
  });
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<VideoDetailState>, VideoDetailState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<VideoDetailState>, VideoDetailState>,
              AsyncValue<VideoDetailState>,
              Object?,
              Object?
            >;
    return element.handleCreate(
      ref,
      () => build(
        id: _$args.id,
        pageId: _$args.pageId,
        ownerKey: _$args.ownerKey,
      ),
    );
  }
}

@ProviderFor(relatedVideos)
final relatedVideosProvider = RelatedVideosFamily._();

final class RelatedVideosProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<VideoSummary>>,
          List<VideoSummary>,
          FutureOr<List<VideoSummary>>
        >
    with
        $FutureModifier<List<VideoSummary>>,
        $FutureProvider<List<VideoSummary>> {
  RelatedVideosProvider._({
    required RelatedVideosFamily super.from,
    required ({String id, String pageId, String ownerKey}) super.argument,
  }) : super(
         retry: null,
         name: r'relatedVideosProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$relatedVideosHash();

  @override
  String toString() {
    return r'relatedVideosProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<List<VideoSummary>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<VideoSummary>> create(Ref ref) {
    final argument =
        this.argument as ({String id, String pageId, String ownerKey});
    return relatedVideos(
      ref,
      id: argument.id,
      pageId: argument.pageId,
      ownerKey: argument.ownerKey,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is RelatedVideosProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$relatedVideosHash() => r'c0e382dc4b086eb322dd9ae8ca37a8ac2a83c966';

final class RelatedVideosFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<List<VideoSummary>>,
          ({String id, String pageId, String ownerKey})
        > {
  RelatedVideosFamily._()
    : super(
        retry: null,
        name: r'relatedVideosProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  RelatedVideosProvider call({
    required String id,
    required String pageId,
    required String ownerKey,
  }) => RelatedVideosProvider._(
    argument: (id: id, pageId: pageId, ownerKey: ownerKey),
    from: this,
  );

  @override
  String toString() => r'relatedVideosProvider';
}

/// The related endpoint is finite. Continue with the existing discovery feed
/// rather than inventing pagination parameters for that endpoint.

@ProviderFor(DetailDiscovery)
final detailDiscoveryProvider = DetailDiscoveryFamily._();

/// The related endpoint is finite. Continue with the existing discovery feed
/// rather than inventing pagination parameters for that endpoint.
final class DetailDiscoveryProvider
    extends $AsyncNotifierProvider<DetailDiscovery, CatalogState> {
  /// The related endpoint is finite. Continue with the existing discovery feed
  /// rather than inventing pagination parameters for that endpoint.
  DetailDiscoveryProvider._({
    required DetailDiscoveryFamily super.from,
    required ({String id, String pageId, String ownerKey, String scopeKey})
    super.argument,
  }) : super(
         retry: null,
         name: r'detailDiscoveryProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$detailDiscoveryHash();

  @override
  String toString() {
    return r'detailDiscoveryProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  DetailDiscovery create() => DetailDiscovery();

  @override
  bool operator ==(Object other) {
    return other is DetailDiscoveryProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$detailDiscoveryHash() => r'a712710ab79578e28018640ce4ae6e2a9e9e5f73';

/// The related endpoint is finite. Continue with the existing discovery feed
/// rather than inventing pagination parameters for that endpoint.

final class DetailDiscoveryFamily extends $Family
    with
        $ClassFamilyOverride<
          DetailDiscovery,
          AsyncValue<CatalogState>,
          CatalogState,
          FutureOr<CatalogState>,
          ({String id, String pageId, String ownerKey, String scopeKey})
        > {
  DetailDiscoveryFamily._()
    : super(
        retry: null,
        name: r'detailDiscoveryProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The related endpoint is finite. Continue with the existing discovery feed
  /// rather than inventing pagination parameters for that endpoint.

  DetailDiscoveryProvider call({
    required String id,
    required String pageId,
    required String ownerKey,
    required String scopeKey,
  }) => DetailDiscoveryProvider._(
    argument: (id: id, pageId: pageId, ownerKey: ownerKey, scopeKey: scopeKey),
    from: this,
  );

  @override
  String toString() => r'detailDiscoveryProvider';
}

/// The related endpoint is finite. Continue with the existing discovery feed
/// rather than inventing pagination parameters for that endpoint.

abstract class _$DetailDiscovery extends $AsyncNotifier<CatalogState> {
  late final _$args =
      ref.$arg
          as ({String id, String pageId, String ownerKey, String scopeKey});
  String get id => _$args.id;
  String get pageId => _$args.pageId;
  String get ownerKey => _$args.ownerKey;
  String get scopeKey => _$args.scopeKey;

  FutureOr<CatalogState> build({
    required String id,
    required String pageId,
    required String ownerKey,
    required String scopeKey,
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
        id: _$args.id,
        pageId: _$args.pageId,
        ownerKey: _$args.ownerKey,
        scopeKey: _$args.scopeKey,
      ),
    );
  }
}
