import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter/foundation.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/services/playback/media_kit_engine.dart';
import '../../data/services/playback/audio_session_focus.dart';
import '../../data/services/playback/better_player_engine.dart';
import '../../domain/playback/playback.dart';
import '../../domain/playback/playback_coordinator.dart';
import '../../domain/playback/start_playback.dart';
import 'repository_providers.dart';

part 'playback_providers.g.dart';

/// Platform composition keeps native rendering types out of the ViewModel.
class PlaybackAdapter {
  const PlaybackAdapter({
    required this.create,
    required this.surface,
    this.focus = const PassivePlaybackFocus(),
  });
  final PlaybackEngine Function() create;
  final Widget Function(PlaybackEngine) surface;
  final PlaybackFocus focus;
}

@Riverpod(keepAlive: true)
PlaybackAdapter playbackAdapter(Ref ref) {
  final focus = AudioSessionFocus();
  ref.onDispose(() => unawaited(focus.dispose()));
  const backend = String.fromEnvironment(
    'MAMBA_PLAYBACK_ENGINE',
    defaultValue: 'better_player',
  );
  if (!kIsWeb &&
      defaultTargetPlatform == TargetPlatform.android &&
      backend == 'better_player') {
    return PlaybackAdapter(
      focus: focus,
      create: BetterPlayerEngine.new,
      surface: (engine) => BetterPlayerSurface(engine as BetterPlayerEngine),
    );
  }
  return PlaybackAdapter(
    focus: focus,
    create: MediaKitEngine.new,
    surface: (engine) => Video(
      controller: (engine as MediaKitEngine).controller,
      controls: null,
      fit: BoxFit.contain,
      pauseUponEnteringBackgroundMode: false,
      resumeUponEnteringForegroundMode: false,
    ),
  );
}

@Riverpod(keepAlive: true)
PlaybackCoordinator playbackCoordinator(Ref ref) {
  final coordinator = PlaybackCoordinator(
    ref.watch(playbackAdapterProvider).create,
  );
  ref.onDispose(() => unawaited(coordinator.dispose()));
  return coordinator;
}

@Riverpod(keepAlive: true)
StartPlayback startPlayback(Ref ref) => StartPlayback(
  ref.watch(catalogRepositoryProvider),
  ref.watch(playbackRepositoryProvider),
  ref.watch(progressRepositoryProvider),
  ref.watch(settingsRepositoryProvider),
);
