import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

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
  return PlaybackAdapter(
    focus: focus,
    create: BetterPlayerEngine.new,
    surface: (engine) => BetterPlayerSurface(engine as BetterPlayerEngine),
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
  pgc: () => ref.read(pgcRepositoryProvider),
  live: () => ref.read(liveRepositoryProvider),
  contentProgress: () => ref.read(contentProgressRepositoryProvider),
);
