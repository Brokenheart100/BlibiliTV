import '../../core/result.dart';
import 'playback.dart';

/// Serializes native engine lifetimes across routes and provider invalidations.
class PlaybackCoordinator {
  PlaybackCoordinator(this.create);
  final PlaybackEngine Function() create;
  EngineLease? _current;
  Future<void> _queue = Future<void>.value();
  bool _disposed = false;

  Future<EngineLease> acquire(CancellationSignal cancellation) {
    final result = _queue.then((_) async {
      await _current?.close();
      _current = null;
      if (_disposed || cancellation.isCancelled) {
        throw const AppFailure(FailureKind.cancelled, '已取消播放');
      }
      return _current = EngineLease(create());
    });
    _queue = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }

  Future<void> dispose() async {
    _disposed = true;
    await _queue;
    await _current?.close();
  }
}

class EngineLease {
  EngineLease(this.engine);
  final PlaybackEngine engine;
  Future<void>? _closing;
  bool get isClosed => _closing != null;
  Future<void> close() => _closing ??= engine.dispose();
}
