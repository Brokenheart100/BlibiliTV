import 'dart:async';

import '../../core/result.dart';
import '../library/library.dart';
import 'playback.dart';

/// Explicitly enabled progress reporting, independent of durable local saves.
class HistoryProgressReporter {
  HistoryProgressReporter(
    this.repository,
    this.ownerKey,
    this.videoId,
    this.partId, {
    Duration Function()? elapsed,
    this.onFailure,
  }) {
    final watch = Stopwatch()..start();
    _elapsed = elapsed ?? (() => watch.elapsed);
  }
  final LibraryRepository repository;
  final String ownerKey, videoId, partId;
  final void Function()? onFailure;
  late final Duration Function() _elapsed;
  final _signal = CancellationSignal();
  Duration _last = Duration.zero;
  bool _sending = false;
  bool _active = false;
  void accept(EngineSnapshot snapshot) {
    final active =
        snapshot.playing &&
        !snapshot.buffering &&
        snapshot.duration > Duration.zero;
    if (!active || !_active) {
      _last = _elapsed();
      _active = active;
      return;
    }
    if (_signal.isCancelled ||
        _sending ||
        !snapshot.playing ||
        snapshot.buffering ||
        snapshot.position < const Duration(seconds: 1) ||
        snapshot.duration <= Duration.zero ||
        _elapsed() - _last < const Duration(seconds: 30)) {
      return;
    }
    _last = _elapsed();
    _sending = true;
    unawaited(() async {
      try {
        final result = await repository.heartbeat(
          ownerKey: ownerKey,
          videoId: videoId,
          partId: partId,
          seconds: snapshot.position.inSeconds,
          cancellation: _signal,
        );
        if (result is ResultFailure<void> && !_signal.isCancelled) {
          onFailure?.call();
        }
      } catch (_) {
        if (!_signal.isCancelled) onFailure?.call();
      } finally {
        _sending = false;
      }
    }());
  }

  void close() => _signal.cancel();
}
