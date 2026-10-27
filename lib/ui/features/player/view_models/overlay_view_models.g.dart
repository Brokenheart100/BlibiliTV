// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'overlay_view_models.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Held by the player route, so a quality change keeps its track choice while
/// the previous engine and its render/data subscriptions are fully released.

@ProviderFor(SubtitleChoice)
final subtitleChoiceProvider = SubtitleChoiceFamily._();

/// Held by the player route, so a quality change keeps its track choice while
/// the previous engine and its render/data subscriptions are fully released.
final class SubtitleChoiceProvider
    extends $NotifierProvider<SubtitleChoice, ({bool explicit, String? id})> {
  /// Held by the player route, so a quality change keeps its track choice while
  /// the previous engine and its render/data subscriptions are fully released.
  SubtitleChoiceProvider._({
    required SubtitleChoiceFamily super.from,
    required ({String videoId, String partId, String scopeKey}) super.argument,
  }) : super(
         retry: null,
         name: r'subtitleChoiceProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$subtitleChoiceHash();

  @override
  String toString() {
    return r'subtitleChoiceProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  SubtitleChoice create() => SubtitleChoice();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(({bool explicit, String? id}) value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<({bool explicit, String? id})>(
        value,
      ),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is SubtitleChoiceProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$subtitleChoiceHash() => r'bd2fe87085520879df9d6d78ae87c1dfa0df9985';

/// Held by the player route, so a quality change keeps its track choice while
/// the previous engine and its render/data subscriptions are fully released.

final class SubtitleChoiceFamily extends $Family
    with
        $ClassFamilyOverride<
          SubtitleChoice,
          ({bool explicit, String? id}),
          ({bool explicit, String? id}),
          ({bool explicit, String? id}),
          ({String videoId, String partId, String scopeKey})
        > {
  SubtitleChoiceFamily._()
    : super(
        retry: null,
        name: r'subtitleChoiceProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Held by the player route, so a quality change keeps its track choice while
  /// the previous engine and its render/data subscriptions are fully released.

  SubtitleChoiceProvider call({
    required String videoId,
    required String partId,
    required String scopeKey,
  }) => SubtitleChoiceProvider._(
    argument: (videoId: videoId, partId: partId, scopeKey: scopeKey),
    from: this,
  );

  @override
  String toString() => r'subtitleChoiceProvider';
}

/// Held by the player route, so a quality change keeps its track choice while
/// the previous engine and its render/data subscriptions are fully released.

abstract class _$SubtitleChoice
    extends $Notifier<({bool explicit, String? id})> {
  late final _$args =
      ref.$arg as ({String videoId, String partId, String scopeKey});
  String get videoId => _$args.videoId;
  String get partId => _$args.partId;
  String get scopeKey => _$args.scopeKey;

  ({bool explicit, String? id}) build({
    required String videoId,
    required String partId,
    required String scopeKey,
  });
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<
              ({bool explicit, String? id}),
              ({bool explicit, String? id})
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                ({bool explicit, String? id}),
                ({bool explicit, String? id})
              >,
              ({bool explicit, String? id}),
              Object?,
              Object?
            >;
    return element.handleCreate(
      ref,
      () => build(
        videoId: _$args.videoId,
        partId: _$args.partId,
        scopeKey: _$args.scopeKey,
      ),
    );
  }
}

@ProviderFor(OverlaySettingsViewModel)
final overlaySettingsViewModelProvider = OverlaySettingsViewModelProvider._();

final class OverlaySettingsViewModelProvider
    extends
        $AsyncNotifierProvider<OverlaySettingsViewModel, OverlayPreferences> {
  OverlaySettingsViewModelProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'overlaySettingsViewModelProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$overlaySettingsViewModelHash();

  @$internal
  @override
  OverlaySettingsViewModel create() => OverlaySettingsViewModel();
}

String _$overlaySettingsViewModelHash() =>
    r'25a3ac05393cb63ef043f9af5757f821b47fbe2c';

abstract class _$OverlaySettingsViewModel
    extends $AsyncNotifier<OverlayPreferences> {
  FutureOr<OverlayPreferences> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<OverlayPreferences>, OverlayPreferences>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<OverlayPreferences>, OverlayPreferences>,
              AsyncValue<OverlayPreferences>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(SubtitleViewModel)
final subtitleViewModelProvider = SubtitleViewModelFamily._();

final class SubtitleViewModelProvider
    extends $AsyncNotifierProvider<SubtitleViewModel, SubtitleState> {
  SubtitleViewModelProvider._({
    required SubtitleViewModelFamily super.from,
    required ({String videoId, String partId, String scopeKey}) super.argument,
  }) : super(
         retry: null,
         name: r'subtitleViewModelProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$subtitleViewModelHash();

  @override
  String toString() {
    return r'subtitleViewModelProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  SubtitleViewModel create() => SubtitleViewModel();

  @override
  bool operator ==(Object other) {
    return other is SubtitleViewModelProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$subtitleViewModelHash() => r'47101375b1a100aa4a1e6af962ff6abb0e2027b3';

final class SubtitleViewModelFamily extends $Family
    with
        $ClassFamilyOverride<
          SubtitleViewModel,
          AsyncValue<SubtitleState>,
          SubtitleState,
          FutureOr<SubtitleState>,
          ({String videoId, String partId, String scopeKey})
        > {
  SubtitleViewModelFamily._()
    : super(
        retry: null,
        name: r'subtitleViewModelProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  SubtitleViewModelProvider call({
    required String videoId,
    required String partId,
    required String scopeKey,
  }) => SubtitleViewModelProvider._(
    argument: (videoId: videoId, partId: partId, scopeKey: scopeKey),
    from: this,
  );

  @override
  String toString() => r'subtitleViewModelProvider';
}

abstract class _$SubtitleViewModel extends $AsyncNotifier<SubtitleState> {
  late final _$args =
      ref.$arg as ({String videoId, String partId, String scopeKey});
  String get videoId => _$args.videoId;
  String get partId => _$args.partId;
  String get scopeKey => _$args.scopeKey;

  FutureOr<SubtitleState> build({
    required String videoId,
    required String partId,
    required String scopeKey,
  });
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<SubtitleState>, SubtitleState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<SubtitleState>, SubtitleState>,
              AsyncValue<SubtitleState>,
              Object?,
              Object?
            >;
    return element.handleCreate(
      ref,
      () => build(
        videoId: _$args.videoId,
        partId: _$args.partId,
        scopeKey: _$args.scopeKey,
      ),
    );
  }
}

@ProviderFor(DanmakuViewModel)
final danmakuViewModelProvider = DanmakuViewModelFamily._();

final class DanmakuViewModelProvider
    extends $AsyncNotifierProvider<DanmakuViewModel, DanmakuState> {
  DanmakuViewModelProvider._({
    required DanmakuViewModelFamily super.from,
    required ({String videoId, String partId, String scopeKey}) super.argument,
  }) : super(
         retry: null,
         name: r'danmakuViewModelProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$danmakuViewModelHash();

  @override
  String toString() {
    return r'danmakuViewModelProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  DanmakuViewModel create() => DanmakuViewModel();

  @override
  bool operator ==(Object other) {
    return other is DanmakuViewModelProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$danmakuViewModelHash() => r'f099a28f9fcc7045da2c316900e84b5ab019c30c';

final class DanmakuViewModelFamily extends $Family
    with
        $ClassFamilyOverride<
          DanmakuViewModel,
          AsyncValue<DanmakuState>,
          DanmakuState,
          FutureOr<DanmakuState>,
          ({String videoId, String partId, String scopeKey})
        > {
  DanmakuViewModelFamily._()
    : super(
        retry: null,
        name: r'danmakuViewModelProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  DanmakuViewModelProvider call({
    required String videoId,
    required String partId,
    required String scopeKey,
  }) => DanmakuViewModelProvider._(
    argument: (videoId: videoId, partId: partId, scopeKey: scopeKey),
    from: this,
  );

  @override
  String toString() => r'danmakuViewModelProvider';
}

abstract class _$DanmakuViewModel extends $AsyncNotifier<DanmakuState> {
  late final _$args =
      ref.$arg as ({String videoId, String partId, String scopeKey});
  String get videoId => _$args.videoId;
  String get partId => _$args.partId;
  String get scopeKey => _$args.scopeKey;

  FutureOr<DanmakuState> build({
    required String videoId,
    required String partId,
    required String scopeKey,
  });
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<DanmakuState>, DanmakuState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<DanmakuState>, DanmakuState>,
              AsyncValue<DanmakuState>,
              Object?,
              Object?
            >;
    return element.handleCreate(
      ref,
      () => build(
        videoId: _$args.videoId,
        partId: _$args.partId,
        scopeKey: _$args.scopeKey,
      ),
    );
  }
}
