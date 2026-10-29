import 'package:freezed_annotation/freezed_annotation.dart';

part 'playback_target.freezed.dart';

enum ContentKind { ugc, pgc, live }

@freezed
sealed class PlaybackTarget with _$PlaybackTarget {
  const PlaybackTarget._();
  const factory PlaybackTarget.ugc({required String bvid, String? cid}) =
      UgcTarget;
  const factory PlaybackTarget.pgc({
    required String seasonId,
    required String episodeId,
  }) = PgcTarget;
  const factory PlaybackTarget.live({required String roomId}) = LiveTarget;

  ContentKind get kind => switch (this) {
    UgcTarget() => ContentKind.ugc,
    PgcTarget() => ContentKind.pgc,
    LiveTarget() => ContentKind.live,
  };
  String get contentId => switch (this) {
    UgcTarget(:final bvid) => bvid,
    PgcTarget(:final seasonId) => seasonId,
    LiveTarget(:final roomId) => roomId,
  };
  String? get partId => switch (this) {
    UgcTarget(:final cid) => cid,
    PgcTarget(:final episodeId) => episodeId,
    LiveTarget() => null,
  };
  PlaybackTarget withPart(String id) => switch (this) {
    UgcTarget(:final bvid) => PlaybackTarget.ugc(bvid: bvid, cid: id),
    PgcTarget(:final seasonId) => PlaybackTarget.pgc(
      seasonId: seasonId,
      episodeId: id,
    ),
    LiveTarget() => this,
  };
  String get location => switch (this) {
    UgcTarget(:final bvid, :final cid) => Uri(
      pathSegments: ['', 'player', bvid],
      queryParameters: cid == null ? null : {'part': cid},
    ).toString(),
    PgcTarget(:final seasonId, :final episodeId) =>
      '/watch/pgc/$seasonId/$episodeId',
    LiveTarget(:final roomId) => '/watch/live/$roomId',
  };
}

@freezed
abstract class PlaybackCapabilities with _$PlaybackCapabilities {
  const factory PlaybackCapabilities({
    @Default(true) bool seek,
    @Default(true) bool rate,
    @Default(true) bool duration,
    @Default(true) bool parts,
    @Default(true) bool audioTracks,
    @Default(true) bool subtitles,
    @Default(true) bool danmaku,
    @Default(true) bool resume,
    @Default(true) bool remoteHistory,
  }) = _PlaybackCapabilities;

  static const live = PlaybackCapabilities(
    seek: false,
    rate: false,
    duration: false,
    parts: false,
    audioTracks: false,
    subtitles: false,
    danmaku: false,
    resume: false,
    remoteHistory: false,
  );
  static const pgc = PlaybackCapabilities(remoteHistory: false);
}
