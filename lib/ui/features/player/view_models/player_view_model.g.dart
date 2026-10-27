// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'player_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(PlayerViewModel)
final playerViewModelProvider = PlayerViewModelFamily._();

final class PlayerViewModelProvider
    extends $NotifierProvider<PlayerViewModel, PlayerState> {
  PlayerViewModelProvider._({
    required PlayerViewModelFamily super.from,
    required ({String pageId, String ownerKey}) super.argument,
  }) : super(
         retry: null,
         name: r'playerViewModelProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$playerViewModelHash();

  @override
  String toString() {
    return r'playerViewModelProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  PlayerViewModel create() => PlayerViewModel();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PlayerState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PlayerState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is PlayerViewModelProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$playerViewModelHash() => r'134f32232cdf180208f78bcc3f470255d8f6b196';

final class PlayerViewModelFamily extends $Family
    with
        $ClassFamilyOverride<
          PlayerViewModel,
          PlayerState,
          PlayerState,
          PlayerState,
          ({String pageId, String ownerKey})
        > {
  PlayerViewModelFamily._()
    : super(
        retry: null,
        name: r'playerViewModelProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  PlayerViewModelProvider call({
    required String pageId,
    required String ownerKey,
  }) => PlayerViewModelProvider._(
    argument: (pageId: pageId, ownerKey: ownerKey),
    from: this,
  );

  @override
  String toString() => r'playerViewModelProvider';
}

abstract class _$PlayerViewModel extends $Notifier<PlayerState> {
  late final _$args = ref.$arg as ({String pageId, String ownerKey});
  String get pageId => _$args.pageId;
  String get ownerKey => _$args.ownerKey;

  PlayerState build({required String pageId, required String ownerKey});
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<PlayerState, PlayerState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<PlayerState, PlayerState>,
              PlayerState,
              Object?,
              Object?
            >;
    return element.handleCreate(
      ref,
      () => build(pageId: _$args.pageId, ownerKey: _$args.ownerKey),
    );
  }
}
