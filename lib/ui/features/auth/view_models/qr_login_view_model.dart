import 'dart:async';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../app/providers/auth_providers.dart';
import '../../../../app/providers/repository_providers.dart';
import '../../../../core/result.dart';
import '../../../../domain/auth/auth.dart';

part 'qr_login_view_model.freezed.dart';
part 'qr_login_view_model.g.dart';

enum QrPhase {
  idle,
  creating,
  waiting,
  scanned,
  completed,
  expired,
  paused,
  failed,
}

@freezed
abstract class QrLoginState with _$QrLoginState {
  const factory QrLoginState({
    @Default(QrPhase.idle) QrPhase phase,
    QrChallenge? challenge,
    @Default(0) int remainingSeconds,
    @Default(false) bool polling,
    @Default(0) int failures,
    @Default(0) int effectId,
    AppFailure? failure,
  }) = _QrLoginState;
}

@riverpod
class QrLoginViewModel extends _$QrLoginViewModel {
  late AuthRepository _repository;
  late QrTiming _timing;
  CancellationSignal? _signal;
  Timer? _timer;
  int _epoch = 0;
  bool _polling = false;
  DateTime _nextPoll = DateTime.fromMillisecondsSinceEpoch(0);
  @override
  QrLoginState build({required String pageId}) {
    _repository = ref.watch(authRepositoryProvider);
    _timing = ref.watch(qrTimingProvider);
    ref.onDispose(() {
      _epoch++;
      _signal?.cancel();
      _timer?.cancel();
    });
    return const QrLoginState();
  }

  bool _current(int epoch, CancellationSignal signal) =>
      ref.mounted && epoch == _epoch && !signal.isCancelled;
  Future<void> start() async {
    _timer?.cancel();
    _signal?.cancel();
    final epoch = ++_epoch;
    final signal = _signal = CancellationSignal();
    state = const QrLoginState(phase: QrPhase.creating);
    final result = await _repository.create(signal);
    if (!_current(epoch, signal)) return;
    switch (result) {
      case ResultFailure(:final failure):
        state = QrLoginState(phase: QrPhase.failed, failure: failure);
      case Success(:final value):
        state = QrLoginState(
          phase: QrPhase.waiting,
          challenge: value,
          remainingSeconds: value.expiresAt
              .difference(DateTime.now())
              .inSeconds
              .clamp(0, 180),
        );
        _nextPoll = DateTime.now();
        _timer = Timer.periodic(
          _timing.tickInterval,
          (_) => _tick(epoch, signal),
        );
        await _poll(epoch, signal);
    }
  }

  void _tick(int epoch, CancellationSignal signal) {
    if (!_current(epoch, signal)) return;
    final challenge = state.challenge;
    if (challenge == null) return;
    final left = challenge.expiresAt
        .difference(DateTime.now())
        .inSeconds
        .clamp(0, 180);
    if (!DateTime.now().isBefore(challenge.expiresAt)) {
      signal.cancel();
      _timer?.cancel();
      state = const QrLoginState(phase: QrPhase.expired);
      return;
    }
    if (left != state.remainingSeconds) {
      state = state.copyWith(remainingSeconds: left);
    }
    if (!_polling && !DateTime.now().isBefore(_nextPoll)) {
      unawaited(_poll(epoch, signal));
    }
  }

  Future<void> _poll(int epoch, CancellationSignal signal) async {
    if (_polling || !_current(epoch, signal) || state.challenge == null) return;
    _polling = true;
    final challenge = state.challenge!;
    state = state.copyWith(polling: true);
    try {
      final result = await _repository.poll(challenge, signal);
      if (!_current(epoch, signal)) return;
      switch (result) {
        case Success(:final value):
          if (value == QrPollStatus.completed ||
              value == QrPollStatus.expired) {
            _timer?.cancel();
            state = QrLoginState(
              phase: value == QrPollStatus.completed
                  ? QrPhase.completed
                  : QrPhase.expired,
              effectId: value == QrPollStatus.completed ? epoch : 0,
            );
          } else {
            state = state.copyWith(
              phase: value == QrPollStatus.scanned
                  ? QrPhase.scanned
                  : QrPhase.waiting,
              failure: null,
              failures: 0,
              polling: false,
            );
            _nextPoll = DateTime.now().add(_timing.pollInterval);
          }
        case ResultFailure(:final failure):
          final failures = state.failures + 1;
          if ((failure.kind == FailureKind.network ||
                  failure.kind == FailureKind.timeout) &&
              failures < _timing.maxFailures) {
            state = state.copyWith(
              failure: failure,
              failures: failures,
              polling: false,
            );
            _nextPoll = DateTime.now().add(
              _timing.pollInterval * (1 << failures),
            );
          } else {
            _timer?.cancel();
            state = QrLoginState(
              phase: QrPhase.failed,
              failure: failure,
              failures: failures,
            );
          }
      }
    } finally {
      _polling = false;
    }
  }

  void pause() {
    if (state.phase == QrPhase.completed || state.phase == QrPhase.idle) return;
    _epoch++;
    _signal?.cancel();
    _timer?.cancel();
    state = const QrLoginState(phase: QrPhase.paused);
  }

  Future<void> resume() async {
    if (state.phase == QrPhase.paused) await start();
  }

  void cancel() {
    _epoch++;
    _signal?.cancel();
    _timer?.cancel();
    if (ref.mounted) state = const QrLoginState();
  }
}
