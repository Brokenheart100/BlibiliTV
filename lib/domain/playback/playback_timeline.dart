import 'playback.dart';

/// Bounded interpolation of the native clock; never an independent timebase.
class PlaybackTimeline {
  EngineSnapshot _snapshot = const EngineSnapshot();
  int _anchorUs = 0;
  int generation = 0;
  EngineSnapshot get snapshot => _snapshot;
  bool advancingAt(int monotonicUs) =>
      _snapshot.playing &&
      !_snapshot.buffering &&
      !_snapshot.completed &&
      monotonicUs - _anchorUs <= 250000;
  bool update(EngineSnapshot snapshot, int monotonicUs) {
    final delta =
        snapshot.position.inMilliseconds - _snapshot.position.inMilliseconds;
    // Display interpolation remains capped at 250 ms. Discontinuity detection
    // must allow elapsed native playback after a delayed platform/UI callback.
    final elapsed = monotonicUs >= _anchorUs ? monotonicUs - _anchorUs : 0;
    final expectedAdvance =
        _snapshot.playing && !_snapshot.buffering && !_snapshot.completed
        ? elapsed / 1000 * _snapshot.rate
        : 0;
    final discontinuity =
        delta.abs() > 1000 && (delta - expectedAdvance).abs() > 1000 ||
        snapshot.rate != _snapshot.rate;
    if (discontinuity) generation++;
    _snapshot = snapshot;
    _anchorUs = monotonicUs;
    return discontinuity;
  }

  void reset() {
    generation++;
    _snapshot = const EngineSnapshot();
    _anchorUs = 0;
  }

  int positionMs(int monotonicUs) {
    final elapsed = (monotonicUs - _anchorUs).clamp(0, 250000);
    final advance =
        _snapshot.playing && !_snapshot.buffering && !_snapshot.completed
        ? (elapsed / 1000 * _snapshot.rate).round()
        : 0;
    final value = _snapshot.position.inMilliseconds + advance;
    return _snapshot.duration > Duration.zero
        ? value.clamp(0, _snapshot.duration.inMilliseconds)
        : value;
  }
}
