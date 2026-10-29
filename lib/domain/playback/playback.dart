import 'package:freezed_annotation/freezed_annotation.dart';

import '../../core/result.dart';
import '../entities/app_models.dart';
import 'playback_target.dart';

part 'playback.freezed.dart';

enum PlaybackTransport { dash, hls, flv, single }

/// Ephemeral signed resources. Never serialize or include URLs in diagnostics.
final class PlaybackSource {
  const PlaybackSource({
    required this.videoUrl,
    required this.audioUrl,
    required this.duration,
    required this.quality,
    required this.codec,
    this.qualities = const [],
    this.audioTracks = const [],
    this.audioId = 0,
    this.videoBackups = const [],
    this.audioBackups = const [],
    this.videoDash,
    this.audioDash,
    this.transport = PlaybackTransport.dash,
    this.headers = const {},
  });
  final String videoUrl, audioUrl, codec;
  final Duration duration;
  final int quality;
  final int audioId;
  final List<PlaybackOption> qualities, audioTracks;
  final List<String> videoBackups, audioBackups;
  final DashRepresentation? videoDash, audioDash;
  final PlaybackTransport transport;
  final Map<String, String> headers;
  PlaybackSource? get alternate => videoBackups.isEmpty || audioBackups.isEmpty
      ? null
      : PlaybackSource(
          videoUrl: videoBackups.first,
          audioUrl: audioBackups.first,
          duration: duration,
          quality: quality,
          codec: codec,
          qualities: qualities,
          audioTracks: audioTracks,
          audioId: audioId,
          videoDash: videoDash,
          audioDash: audioDash,
          transport: transport,
          headers: headers,
        );
  @override
  String toString() =>
      'PlaybackSource(quality: $quality, codec: $codec, urls: redacted)';
}

/// Metadata for one on-demand DASH representation; signed URLs stay in source.
final class DashRepresentation {
  const DashRepresentation({
    required this.codecs,
    required this.mimeType,
    required this.bandwidth,
    required this.initializationRange,
    required this.indexRange,
    this.width = 0,
    this.height = 0,
    this.audioSamplingRate = 0,
  });
  final String codecs, mimeType, initializationRange, indexRange;
  final int bandwidth, width, height, audioSamplingRate;
}

final class PlaybackOption {
  const PlaybackOption(this.id, this.label, {this.reason});
  final int id;
  final String label;
  final String? reason;
  bool get available => reason == null;
}

String qualityLabel(int quality) => switch (quality) {
  6 => '240P',
  16 => '360P',
  32 => '480P',
  64 => '720P',
  74 => '720P60',
  80 => '1080P',
  112 => '1080P+',
  116 => '1080P60',
  120 => '4K',
  125 => 'HDR',
  126 => '杜比视界',
  127 => '8K',
  _ => '$quality',
};

abstract interface class PlaybackFocus {
  Stream<void> get interruptions;
  Future<bool> acquire(Object owner);
  Future<void> release(Object owner);
}

class PassivePlaybackFocus implements PlaybackFocus {
  const PassivePlaybackFocus();
  @override
  Stream<void> get interruptions => const Stream.empty();
  @override
  Future<bool> acquire(Object owner) async => true;
  @override
  Future<void> release(Object owner) async {}
}

@freezed
abstract class EngineSnapshot with _$EngineSnapshot {
  const factory EngineSnapshot({
    @Default(false) bool playing,
    @Default(false) bool buffering,
    @Default(false) bool completed,
    @Default(Duration.zero) Duration position,
    @Default(Duration.zero) Duration duration,

    /// Absolute timeline endpoint reported by the native demuxer cache.
    @Default(Duration.zero) Duration bufferedPosition,
    @Default(0) int width,
    @Default(0) int height,
    @Default(0) int audioSampleRate,
    @Default(1.0) double rate,
    @Default(100.0) double volume,
    AppFailure? failure,
  }) = _EngineSnapshot;
}

abstract interface class PlaybackEngine {
  EngineSnapshot get snapshot;
  Stream<EngineSnapshot> get snapshots;
  Future<void> open(
    PlaybackSource source, {
    required Duration startAt,
    bool play = true,
  });
  Future<void> play();
  Future<void> pause();

  /// Completes when the target and native output have settled, or fails with a
  /// bounded timeout so the caller can replace a stalled playback session.
  Future<void> seek(Duration position);
  Future<void> setRate(double rate);
  Future<void> setVolume(double volume);
  Future<void> dispose();
}

abstract interface class PlaybackRepository {
  Future<Result<PlaybackSource>> resolve({
    required String videoId,
    required String partId,
    required CancellationSignal cancellation,
    int? quality,
    int? audioId,
  });
}

final class WatchProgress {
  const WatchProgress({
    required this.ownerKey,
    required this.videoId,
    required this.partId,
    required this.position,
    required this.duration,
    this.kind = ContentKind.ugc,
  });
  final String ownerKey, videoId, partId;
  final ContentKind kind;
  final Duration position, duration;
  bool get isValid =>
      kind != ContentKind.live &&
      position.inMilliseconds >= 1000 &&
      duration > Duration.zero &&
      position <= duration;
}

abstract interface class ProgressRepository {
  Future<Result<void>> rememberVideo(String ownerKey, VideoSummary video);
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
    this.parts = const [],
    this.initialRate = 1,
    this.autoNext = false,
    this.syncHistory = false,
    this.preferenceNotice,
    this.playbackTarget,
    this.capabilities = const PlaybackCapabilities(),
    this.overlayVideoId,
    this.overlayPartId,
  });
  final PlaybackSource source;
  final String videoId, partId, title, partTitle;
  final Duration startAt;
  final bool rememberProgress;
  final List<VideoPart> parts;
  final double initialRate;
  final bool autoNext, syncHistory;
  final String? preferenceNotice;
  final PlaybackTarget? playbackTarget;
  PlaybackTarget get target =>
      playbackTarget ?? PlaybackTarget.ugc(bvid: videoId, cid: partId);
  final PlaybackCapabilities capabilities;
  final String? overlayVideoId, overlayPartId;
}
