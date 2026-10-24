import 'dart:async';

import '../../core/result.dart';

import '../../domain/entities/app_models.dart';
import '../../domain/repositories/repositories.dart';

class MemorySessionRepository implements SessionRepository {
  MemorySessionRepository([Session initial = const Session()])
    : _current = initial;
  Session _current;
  @override
  Session get current => _current;
  final _events = StreamController<Session>.broadcast(sync: true);
  @override
  Future<void> restore() async {}
  @override
  Future<void> revalidate({bool force = false}) async {}
  @override
  Future<Result<void>> logout() async {
    replace(Session(generation: _current.generation + 1));
    return const Success(null);
  }

  @override
  Stream<Session> watch() async* {
    yield _current;
    yield* _events.stream;
  }

  void replace(Session value) {
    _current = value;
    _events.add(value);
  }

  Future<void> close() => _events.close();
}
