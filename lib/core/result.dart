enum FailureKind {
  network,
  timeout,
  cancelled,
  unavailable,
  storage,
  unknown,
  permission,
  rateLimited,
  unsupported,
  contract,
  authentication,
}

final class AppFailure implements Exception {
  const AppFailure(this.kind, this.message);
  final FailureKind kind;
  final String message;
  @override
  String toString() => message;
}

sealed class Result<T> {
  const Result();
  T get valueOrThrow => switch (this) {
    Success<T>(:final value) => value,
    ResultFailure<T>(:final failure) => throw failure,
  };
}

final class Success<T> extends Result<T> {
  const Success(this.value);
  final T value;
}

final class ResultFailure<T> extends Result<T> {
  const ResultFailure(this.failure);
  final AppFailure failure;
}

/// Pure Dart cancellation shared by repositories and presentation commands.
final class CancellationSignal {
  bool _cancelled = false;
  final _listeners = <void Function()>{};
  bool get isCancelled => _cancelled;
  void Function() onCancel(void Function() listener) {
    if (_cancelled) {
      listener();
    } else {
      _listeners.add(listener);
    }
    return () => _listeners.remove(listener);
  }

  void cancel() {
    if (_cancelled) return;
    _cancelled = true;
    for (final listener in _listeners.toList()) {
      listener();
    }
    _listeners.clear();
  }
}

final class PageSlice<T> {
  PageSlice({required List<T> items, this.nextCursor, this.notice})
    : items = List.unmodifiable(items);
  final List<T> items;
  final String? nextCursor;
  final String? notice;
}
