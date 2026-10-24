import 'package:freezed_annotation/freezed_annotation.dart';

part 'probe_models.freezed.dart';

/// Sanitized evidence only: never include credentials or signed media URLs.
@freezed
abstract class ProbeCheck with _$ProbeCheck {
  const factory ProbeCheck({
    required String capability,
    required bool passed,
    required String detail,
  }) = _ProbeCheck;
}

@Freezed(toStringOverride: false)
abstract class ProbeState with _$ProbeState {
  const factory ProbeState({
    @Default(false) bool busy,
    @Default('等待验证') String message,
    @Default(<ProbeCheck>[]) List<ProbeCheck> checks,
    String? qrUrl,
    @Default(false) bool polling,
    @Default(false) bool authenticated,
    @Default(false) bool playable,
  }) = _ProbeState;
}

/// Short-lived in-memory media request. Deliberately has no JSON or toString.
class ProbeMedia {
  const ProbeMedia({
    required this.bvid,
    required this.cid,
    required this.videoUrl,
    required this.audioUrl,
    required this.quality,
    required this.codec,
    required this.durationSeconds,
  });

  final String bvid;
  final int cid;
  final String videoUrl;
  final String audioUrl;
  final int quality;
  final String codec;
  final int durationSeconds;
}

class QrChallenge {
  const QrChallenge(this.key, this.url);
  final String key;
  final String url;
}

class QrPoll {
  const QrPoll(this.code, {this.cookie});
  final int code;
  final String? cookie;
}
