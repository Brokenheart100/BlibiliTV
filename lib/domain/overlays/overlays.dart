import 'dart:collection';

import 'package:freezed_annotation/freezed_annotation.dart';

import '../../core/result.dart';
part 'overlays.freezed.dart';

@freezed
abstract class SubtitleTrack with _$SubtitleTrack {
  const factory SubtitleTrack({
    required String id,
    required String language,
    required String title,
    @Default(false) bool ai,
  }) = _SubtitleTrack;
}

@Freezed(toStringOverride: false)
abstract class SubtitleCue with _$SubtitleCue {
  const factory SubtitleCue({
    required int startMs,
    required int endMs,
    required String text,
  }) = _SubtitleCue;
}

@Freezed(toStringOverride: false)
abstract class DanmakuItem with _$DanmakuItem {
  const factory DanmakuItem({
    required String id,
    required int timeMs,
    required int mode,
    required int color,
    required String text,
  }) = _DanmakuItem;
}

@freezed
abstract class OverlayPreferences with _$OverlayPreferences {
  const factory OverlayPreferences({
    @Default(true) bool subtitles,
    @Default('zh') String language,
    @Default(24.0) double fontSize,
    @Default(45.0) double subtitleBottom,
    @Default(0) int offsetMs,
    @Default(false) bool danmaku,
    @Default(.8) double opacity,
    @Default(.5) double area,
    @Default(40) int density,
    @Default(true) bool top,
    @Default(true) bool bottom,
    @Default(true) bool scroll,
    @Default(<String>[]) List<String> keywords,
  }) = _OverlayPreferences;
}

class DanmakuManifest {
  const DanmakuManifest(this.segmentMs, this.total);
  final int segmentMs, total;
  int segmentAt(int timeMs) =>
      total == 0 ? 0 : (timeMs ~/ segmentMs + 1).clamp(1, total);
}

abstract interface class SubtitleRepository {
  Future<Result<List<SubtitleTrack>>> tracks(
    String videoId,
    String partId,
    CancellationSignal cancellation,
  );
  Future<Result<List<SubtitleCue>>> cues(
    String trackId,
    CancellationSignal cancellation,
  );
}

abstract interface class DanmakuRepository {
  Future<Result<DanmakuManifest>> manifest(
    String videoId,
    String partId,
    CancellationSignal cancellation,
  );
  Future<Result<List<DanmakuItem>>> segment(
    String partId,
    int index,
    CancellationSignal cancellation,
  );
}

abstract interface class OverlayPreferencesRepository {
  Future<OverlayPreferences> load();
  Future<void> save(OverlayPreferences preferences);
}

/// Sweep overlapping cues once at load time; playback lookup is O(log n).
class SubtitleIndex {
  SubtitleIndex(List<SubtitleCue> cues) {
    final events = <({int time, int id, bool start})>[];
    for (var i = 0; i < cues.length; i++) {
      if (cues[i].endMs <= cues[i].startMs) continue;
      events.add((time: cues[i].startMs, id: i, start: true));
      events.add((time: cues[i].endMs, id: i, start: false));
    }
    events.sort((a, b) => a.time.compareTo(b.time));
    final active = SplayTreeSet<int>();
    var i = 0;
    while (i < events.length) {
      final time = events[i].time;
      while (i < events.length && events[i].time == time) {
        final event = events[i++];
        if (event.start) {
          active.add(event.id);
        } else {
          active.remove(event.id);
        }
      }
      _spans.add((
        time: time,
        text: active.take(2).map((id) => cues[id].text).join('\n'),
      ));
    }
  }
  final _spans = <({int time, String text})>[];
  bool get isEmpty => _spans.isEmpty;

  /// A positive offset delays display.
  String at(int positionMs, int offsetMs) {
    final time = positionMs - offsetMs;
    var lo = 0, hi = _spans.length;
    while (lo < hi) {
      final mid = (lo + hi) ~/ 2;
      if (_spans[mid].time <= time) {
        lo = mid + 1;
      } else {
        hi = mid;
      }
    }
    return lo == 0 ? '' : _spans[lo - 1].text;
  }
}
