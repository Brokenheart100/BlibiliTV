// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'playback_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(playbackAdapter)
final playbackAdapterProvider = PlaybackAdapterProvider._();

final class PlaybackAdapterProvider
    extends
        $FunctionalProvider<PlaybackAdapter, PlaybackAdapter, PlaybackAdapter>
    with $Provider<PlaybackAdapter> {
  PlaybackAdapterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'playbackAdapterProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$playbackAdapterHash();

  @$internal
  @override
  $ProviderElement<PlaybackAdapter> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  PlaybackAdapter create(Ref ref) {
    return playbackAdapter(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PlaybackAdapter value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PlaybackAdapter>(value),
    );
  }
}

String _$playbackAdapterHash() => r'25855e9a77a39884bfbeae27b8ea0c0ee5fb0395';

@ProviderFor(playbackCoordinator)
final playbackCoordinatorProvider = PlaybackCoordinatorProvider._();

final class PlaybackCoordinatorProvider
    extends
        $FunctionalProvider<
          PlaybackCoordinator,
          PlaybackCoordinator,
          PlaybackCoordinator
        >
    with $Provider<PlaybackCoordinator> {
  PlaybackCoordinatorProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'playbackCoordinatorProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$playbackCoordinatorHash();

  @$internal
  @override
  $ProviderElement<PlaybackCoordinator> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  PlaybackCoordinator create(Ref ref) {
    return playbackCoordinator(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PlaybackCoordinator value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PlaybackCoordinator>(value),
    );
  }
}

String _$playbackCoordinatorHash() =>
    r'c18913a30816facf99a4daa408e980dfc14d6f9d';

@ProviderFor(startPlayback)
final startPlaybackProvider = StartPlaybackProvider._();

final class StartPlaybackProvider
    extends $FunctionalProvider<StartPlayback, StartPlayback, StartPlayback>
    with $Provider<StartPlayback> {
  StartPlaybackProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'startPlaybackProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$startPlaybackHash();

  @$internal
  @override
  $ProviderElement<StartPlayback> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  StartPlayback create(Ref ref) {
    return startPlayback(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(StartPlayback value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<StartPlayback>(value),
    );
  }
}

String _$startPlaybackHash() => r'24cd8274264250338b194f53b9e6f775c0a1cc84';
