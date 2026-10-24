import 'package:freezed_annotation/freezed_annotation.dart';

import '../../core/result.dart';

part 'playback.freezed.dart';

/// Ephemeral signed resources. Never serialize or include URLs in diagnostics.
final class PlaybackSource {
  const PlaybackSource({
    required this.videoUrl,
    required this.audioUrl,
    required this.duration,
    required this.quality,
    required this.codec,
  });
  final String videoUrl, audioUrl, codec;
  final Duration duration;
  final int quality;
  @override
  String toString() =>
      'PlaybackSource(quality: $quality, codec: $codec, urls: redacted)';
}

@freezed
abstract class EngineSnapshot with _$EngineSnapshot {
  const factory EngineSnapshot({
    @Default(false) bool playing,
    @Default(false) bool buffering,
    @Default(false) bool completed,
    @Default(Duration.zero) Duration position,
    @Default(Duration.zero) Duration duration,
    @Default(0) int width,
    @Default(0) int height,
    @Default(0) int audioSampleRate,
    AppFailure? failure,
  }) = _EngineSnapshot;
}

abstract interface class PlaybackEngine {
  EngineSnapshot get snapshot;
  Stream<EngineSnapshot> get snapshots;
  Future<void> open(PlaybackSource source, {required Duration startAt});
  Future<void> play();
  Future<void> pause();
  Future<void> seek(Duration position);
  Future<void> dispose();
}

abstract interface class PlaybackRepository {
  Future<Result<PlaybackSource>> resolve({
    required String videoId,
    required String partId,
    required CancellationSignal cancellation,
  });
}

final class WatchProgress {
  const WatchProgress({
    required this.ownerKey,
    required this.videoId,
    required this.partId,
    required this.position,
    required this.duration,
  });
  final String ownerKey, videoId, partId;
  final Duration position, duration;
  bool get isValid =>
      position.inMilliseconds >= 1000 &&
      duration > Duration.zero &&
      position <= duration;
}

abstract interface class ProgressRepository {
  Future<Result<WatchProgress?>> latestForVideo(
    String ownerKey,
    String videoId,
  );
  Future<Result<WatchProgress?>> load(
    String ownerKey,
    String videoId,
    String partId,
  );
  Future<Result<void>> save(WatchProgress progress);
}

final class PlaybackPlan {
  const PlaybackPlan({
    required this.source,
    required this.videoId,
    required this.partId,
    required this.title,
    required this.partTitle,
    required this.startAt,
    required this.rememberProgress,
  });
  final PlaybackSource source;
  final String videoId, partId, title, partTitle;
  final Duration startAt;
  final bool rememberProgress;
}
