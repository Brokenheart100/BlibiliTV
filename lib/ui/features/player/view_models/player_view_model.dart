import 'dart:async';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../app/providers/playback_providers.dart';
import '../../../../app/providers/repository_providers.dart';
import '../../../../core/result.dart';
import '../../../../domain/entities/app_models.dart';
import '../../../../domain/playback/playback.dart';
import '../../../../domain/playback/playback_coordinator.dart';
import '../../../../domain/playback/start_playback.dart';
import '../../../../domain/playback/history_progress_reporter.dart';

part 'player_view_model.freezed.dart';
part 'player_view_model.g.dart';

enum PlayerPhase {
  idle,
  resolving,
  opening,
  playing,
  paused,
  completed,
  failed,
  closed,
}

@freezed
abstract class PlayerState with _$PlayerState {
  const factory PlayerState({
    @Default(PlayerPhase.idle) PlayerPhase phase,
    @Default(EngineSnapshot()) EngineSnapshot snapshot,
    @Default('') String title,
    @Default('') String partTitle,
    @Default('') String partId,
    @Default(<VideoPart>[]) List<VideoPart> parts,
    @Default(<PlaybackOption>[]) List<PlaybackOption> qualities,
    @Default(<PlaybackOption>[]) List<PlaybackOption> audioTracks,
    @Default(0) int quality,
    @Default(0) int audioId,
    @Default(1.0) double rate,
    @Default(100.0) double volume,
    @Default(false) bool autoNext,
    @Default(0) int recoveryAttempts,
    @Default(0) int surfaceGeneration,
    @Default(Duration.zero) Duration resumedFrom,
    AppFailure? failure,
    String? notice,
  }) = _PlayerState;
}

@riverpod
class PlayerViewModel extends _$PlayerViewModel {
  late StartPlayback _start;
  late PlaybackCoordinator _coordinator;
  late ProgressRepository _progress;
  late PlaybackFocus _focus;
  final _focusOwner = Object();
  EngineLease? _lease;
  StreamSubscription<EngineSnapshot>? _subscription;
  StreamSubscription<void>? _interruptions;
  CancellationSignal? _active;
  WatchProgress? _lastValid;
  PlaybackPlan? _plan;
  HistoryProgressReporter? _reporter;
  bool _preferencesApplied = false;
  Future<void> _writes = Future<void>.value();
  Future<void> _operations = Future<void>.value();
  Future<void>? _releasing;
  Duration? _targetPosition;
  int? _targetQuality;
  final _saveClock = Stopwatch();
  Duration _lastSavedPosition = Duration.zero;
  int _epoch = 0;
  ({String videoId, String? partId})? _request;
  bool _wantPlay = true, _foreground = true;
  bool _backupUsed = false,
      _freshUsed = false,
      _failureHandling = false,
      _completionHandled = false;
  PlaybackEngine? get engine => _lease?.engine;

  @override
  PlayerState build({required String pageId, required String ownerKey}) {
    _start = ref.watch(startPlaybackProvider);
    _coordinator = ref.watch(playbackCoordinatorProvider);
    _progress = ref.watch(progressRepositoryProvider);
    _focus = ref.watch(playbackAdapterProvider).focus;
    _interruptions = _focus.interruptions.listen((_) => unawaited(suspend()));
    ref.onDispose(() {
      _epoch++;
      _reporter?.close();
      _active?.cancel();
      final lease = _lease;
      _lease = null;
      unawaited(_subscription?.cancel());
      unawaited(_interruptions?.cancel());
      _subscription = null;
      // Explicit close/suspend already drained writes before releasing the lease.
      // Do not enqueue a duplicate write during provider/database teardown.
      if (lease != null) _save();
      unawaited(lease?.close());
      unawaited(_focus.release(_focusOwner));
    });
    return const PlayerState();
  }

  Future<void> _enqueue(Future<void> Function() work) {
    final result = _operations.then((_) => work());
    _operations = result.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return result;
  }

  bool _current(int epoch, CancellationSignal signal) =>
      ref.mounted && epoch == _epoch && !signal.isCancelled;
  Future<T> _wait<T>(Future<T> work, CancellationSignal signal) async {
    final cancelled = Completer<T>();
    final remove = signal.onCancel(() {
      if (!cancelled.isCompleted) {
        cancelled.completeError(
          const AppFailure(FailureKind.cancelled, '已取消播放'),
        );
      }
    });
    try {
      return await Future.any([work, cancelled.future]);
    } finally {
      remove();
    }
  }

  Future<void> start(String videoId, {String? partId, Duration? remoteResume}) {
    _wantPlay = true;
    return _replace(
      videoId,
      partId: partId,
      manual: true,
      fallbackPosition: remoteResume,
    );
  }

  Future<void> _replace(
    String videoId, {
    String? partId,
    Duration? position,
    int? quality,
    int? audioId,
    bool manual = false,
    PlaybackSource? source,
    Duration? fallbackPosition,
  }) {
    if (!_foreground) return Future.value();
    if (manual) {
      _backupUsed = false;
      _freshUsed = false;
    }
    _active?.cancel();
    final epoch = ++_epoch;
    final signal = _active = CancellationSignal();
    _targetPosition = position;
    _targetQuality = quality;
    _request = (videoId: videoId, partId: partId);
    final oldPlan = _plan;
    state = state.copyWith(
      phase: PlayerPhase.resolving,
      failure: null,
      notice: manual ? null : '正在恢复播放，请稍候',
      recoveryAttempts: manual ? 0 : state.recoveryAttempts,
    );
    return _enqueue(() async {
      await _release();
      await _writes;
      if (!_current(epoch, signal)) return;
      _lastValid = null;
      _lastSavedPosition = Duration.zero;
      _saveClock
        ..reset()
        ..start();
      _failureHandling = false;
      _completionHandled = false;
      try {
        final plan = source != null && oldPlan != null
            ? PlaybackPlan(
                source: source,
                videoId: oldPlan.videoId,
                partId: oldPlan.partId,
                title: oldPlan.title,
                partTitle: oldPlan.partTitle,
                startAt: position ?? Duration.zero,
                rememberProgress: oldPlan.rememberProgress,
                parts: oldPlan.parts,
                initialRate: oldPlan.initialRate,
                autoNext: oldPlan.autoNext,
                syncHistory: oldPlan.syncHistory,
              )
            : await _wait(
                _start(
                  videoId: videoId,
                  partId: partId,
                  ownerKey: ownerKey,
                  cancellation: signal,
                  quality: quality,
                  audioId: audioId,
                  position: position,
                  fallbackPosition: fallbackPosition,
                ),
                signal,
              );
        if (!_current(epoch, signal)) return;
        _plan = plan;
        if (!_preferencesApplied) {
          _preferencesApplied = true;
          state = state.copyWith(
            rate: plan.initialRate,
            autoNext: plan.autoNext,
          );
        }
        if (plan.syncHistory && ownerKey != 'guest') {
          _reporter = HistoryProgressReporter(
            ref.read(libraryRepositoryProvider),
            ownerKey,
            plan.videoId,
            plan.partId,
            onFailure: () {
              if (_current(epoch, signal)) {
                state = state.copyWith(notice: '账号进度同步未确认，本地记录继续保存');
              }
            },
          );
        }
        _targetPosition = plan.startAt;
        _targetQuality = plan.source.quality;
        _request = (videoId: plan.videoId, partId: plan.partId);
        state = state.copyWith(
          phase: PlayerPhase.opening,
          title: plan.title,
          partTitle: plan.partTitle,
          partId: plan.partId,
          parts: plan.parts,
          quality: plan.source.quality,
          qualities: plan.source.qualities,
          audioTracks: plan.source.audioTracks,
          audioId: plan.source.audioId,
          resumedFrom: plan.startAt,
          notice: plan.preferenceNotice,
          snapshot: const EngineSnapshot(),
        );
        if (_wantPlay) {
          final granted = await _focus.acquire(_focusOwner);
          if (!_current(epoch, signal) || !_foreground) {
            await _focus.release(_focusOwner);
            return;
          }
          if (!granted) {
            throw const AppFailure(
              FailureKind.unavailable,
              '音频正在被其他应用使用，请稍后确认重试',
            );
          }
        }
        final lease = await _coordinator.acquire(signal);
        if (!_current(epoch, signal)) {
          await lease.close();
          return;
        }
        _lease = lease;
        state = state.copyWith(
          snapshot: lease.engine.snapshot,
          surfaceGeneration: epoch,
        );
        var resumeConfirmed = plan.startAt == Duration.zero;
        void accept(EngineSnapshot snapshot, {bool ready = false}) {
          if (!_current(epoch, signal) || lease.isClosed) return;
          final opening = !ready && state.phase == PlayerPhase.opening;
          final phase = snapshot.failure != null
              ? PlayerPhase.failed
              : opening
              ? PlayerPhase.opening
              : snapshot.completed
              ? PlayerPhase.completed
              : snapshot.playing
              ? PlayerPhase.playing
              : PlayerPhase.paused;
          state = state.copyWith(
            snapshot: snapshot,
            phase: phase,
            failure: snapshot.failure,
          );
          if (!opening) _reporter?.accept(snapshot);
          if (snapshot.position >= plan.startAt - const Duration(seconds: 2)) {
            resumeConfirmed = true;
          }
          if (!opening && resumeConfirmed && plan.rememberProgress) {
            final progress = WatchProgress(
              ownerKey: ownerKey,
              videoId: plan.videoId,
              partId: plan.partId,
              position: snapshot.completed && snapshot.duration > Duration.zero
                  ? snapshot.duration
                  : snapshot.position,
              duration: snapshot.duration,
            );
            if (progress.isValid) {
              _lastValid = progress;
              if ((progress.position - _lastSavedPosition).abs() >=
                      const Duration(seconds: 5) ||
                  _saveClock.elapsed >= const Duration(seconds: 5) ||
                  snapshot.completed) {
                _save();
              }
            }
          }
          if (!opening && snapshot.completed && !_completionHandled) {
            _completionHandled = true;
            if (state.autoNext && _foreground) {
              unawaited(
                Future<void>.microtask(() async {
                  if (_current(epoch, signal)) await nextPart();
                }),
              );
            }
          }
          if (snapshot.failure != null && !_failureHandling) {
            _failureHandling = true;
            unawaited(
              _recover(
                snapshot.failure!,
                at: opening ? plan.startAt : snapshot.position,
              ),
            );
          }
        }

        _subscription = lease.engine.snapshots.listen(accept);
        await lease.engine.setRate(state.rate);
        await lease.engine.setVolume(state.volume);
        await _wait(
          lease.engine.open(
            plan.source,
            startAt: plan.startAt,
            play: _wantPlay && _foreground,
          ),
          signal,
        );
        if (!_current(epoch, signal) || lease.isClosed) return;
        if (!_wantPlay || !_foreground) await lease.engine.pause();
        accept(lease.engine.snapshot, ready: true);
      } catch (error) {
        if (!_current(epoch, signal)) return;
        final failure = error is AppFailure
            ? error
            : const AppFailure(FailureKind.unavailable, '视频暂时无法播放，请重试或返回');
        state = state.copyWith(phase: PlayerPhase.failed, failure: failure);
        // Recovery is enqueued after this command, so it cannot await itself.
        if (!_failureHandling) {
          _failureHandling = true;
          unawaited(
            _recover(failure, at: _targetPosition ?? state.snapshot.position),
          );
        }
        await _release();
      }
    });
  }

  Future<void> _recover(AppFailure failure, {required Duration at}) async {
    final request = _request;
    if (request == null || !ref.mounted || !_foreground) return;
    final recoverable = {
      FailureKind.cdn,
      FailureKind.resourceExpired,
      FailureKind.network,
      FailureKind.timeout,
    }.contains(failure.kind);
    if (!recoverable) {
      await _release();
      return;
    }
    PlaybackSource? alternate;
    if (failure.kind == FailureKind.cdn && !_backupUsed) {
      alternate = _plan?.source.alternate;
    }
    if (alternate != null) {
      _backupUsed = true;
    } else if (!_freshUsed) {
      _freshUsed = true;
    } else {
      state = state.copyWith(
        phase: PlayerPhase.failed,
        failure: const AppFailure(
          FailureKind.unavailable,
          '自动恢复未成功，请检查网络后手动重试',
        ),
      );
      await _release();
      return;
    }
    state = state.copyWith(recoveryAttempts: state.recoveryAttempts + 1);
    await _replace(
      request.videoId,
      partId: request.partId,
      position: at,
      quality: state.quality == 0 ? null : state.quality,
      audioId: state.audioId == 0 ? null : state.audioId,
      source: alternate,
    );
  }

  void _save() {
    final progress = _lastValid;
    if (progress == null || !progress.isValid) return;
    _lastSavedPosition = progress.position;
    _saveClock.reset();
    final repository = _progress;
    _writes = _writes
        .then((_) async {
          final result = await repository.save(progress);
          if (result is ResultFailure<void> && ref.mounted) {
            state = state.copyWith(notice: result.failure.message);
          }
        })
        .catchError((Object _) {});
  }

  Future<void> _release() {
    if (_releasing != null) return _releasing!;
    final work = _releaseNow();
    _releasing = work;
    return work.whenComplete(() {
      if (identical(_releasing, work)) _releasing = null;
    });
  }

  Future<void> _releaseNow() async {
    _reporter?.close();
    _reporter = null;
    _save();
    final subscription = _subscription, lease = _lease;
    _subscription = null;
    _lease = null;
    await subscription?.cancel();
    await lease?.close();
    await _focus.release(_focusOwner);
  }

  Future<void> togglePause() async {
    if (!_foreground) return;
    final request = _request;
    if (request == null) return;
    if (state.phase == PlayerPhase.opening ||
        state.phase == PlayerPhase.resolving) {
      _wantPlay = !_wantPlay;
      await _replace(
        request.videoId,
        partId: request.partId,
        position: _replacementPosition,
        quality: _targetQuality,
        audioId: state.audioId == 0 ? null : state.audioId,
        manual: true,
      );
      return;
    }
    if (state.phase == PlayerPhase.completed) {
      _wantPlay = true;
      await _replace(
        request.videoId,
        partId: request.partId,
        position: Duration.zero,
        manual: true,
      );
      return;
    }
    if (_lease == null && state.phase == PlayerPhase.paused) {
      _wantPlay = true;
      await _replace(
        request.videoId,
        partId: request.partId,
        position: state.snapshot.position,
        quality: state.quality == 0 ? null : state.quality,
        audioId: state.audioId == 0 ? null : state.audioId,
        manual: true,
      );
      return;
    }
    final epoch = _epoch;
    await _enqueue(() async {
      final lease = _lease;
      if (!ref.mounted || epoch != _epoch || lease == null || lease.isClosed) {
        return;
      }
      if (state.snapshot.playing) {
        _wantPlay = false;
        await lease.engine.pause();
        _save();
        await _focus.release(_focusOwner);
      } else if (_foreground) {
        if (!await _focus.acquire(_focusOwner)) {
          state = state.copyWith(notice: '音频焦点暂不可用，请稍后重试');
          return;
        }
        if (!ref.mounted || epoch != _epoch || !_foreground) {
          await _focus.release(_focusOwner);
          return;
        }
        _wantPlay = true;
        await lease.engine.play();
      }
    });
  }

  Future<void> seekBy(Duration delta) {
    final epoch = _epoch;
    return _enqueue(() async {
      final lease = _lease;
      if (!ref.mounted ||
          epoch != _epoch ||
          lease == null ||
          lease.isClosed ||
          state.snapshot.duration <= Duration.zero) {
        return;
      }
      final target = (state.snapshot.position + delta).inMilliseconds.clamp(
        0,
        (state.snapshot.duration.inMilliseconds - 1000).clamp(0, 1 << 53),
      );
      try {
        await lease.engine.seek(Duration(milliseconds: target));
        _save();
      } catch (_) {
        if (ref.mounted) state = state.copyWith(notice: '暂时无法跳转，请重试');
      }
    });
  }

  Future<void> setRate(double rate) => _parameter(rate, true);
  Future<void> setVolume(double volume) => _parameter(volume, false);
  Duration get _replacementPosition =>
      state.phase == PlayerPhase.resolving || state.phase == PlayerPhase.opening
      ? _targetPosition ?? _lastValid?.position ?? state.snapshot.position
      : state.snapshot.position;
  Future<void> _parameter(double value, bool rate) {
    if (!value.isFinite ||
        (rate ? value < .5 || value > 2 : value < 0 || value > 100)) {
      return Future.value();
    }
    final epoch = _epoch;
    state = rate ? state.copyWith(rate: value) : state.copyWith(volume: value);
    return _enqueue(() async {
      if (!ref.mounted || epoch != _epoch) return;
      try {
        if (rate) {
          await _lease?.engine.setRate(value);
          state = state.copyWith(rate: value);
        } else {
          await _lease?.engine.setVolume(value);
          state = state.copyWith(volume: value);
        }
      } catch (_) {
        if (ref.mounted) state = state.copyWith(notice: '设置暂未生效，请重试');
      }
    });
  }

  void setAutoNext(bool value) => state = state.copyWith(autoNext: value);
  Future<void> selectQuality(int id) async {
    if (!state.qualities.any((q) => q.id == id && q.available) ||
        id == (_targetQuality ?? state.quality)) {
      return;
    }
    final request = _request;
    if (request == null) return;
    await _replace(
      request.videoId,
      partId: request.partId,
      position: _replacementPosition,
      quality: id,
      audioId: state.audioId == 0 ? null : state.audioId,
      manual: true,
    );
  }

  Future<void> selectAudio(int id) async {
    if (!state.audioTracks.any((a) => a.id == id && a.available) ||
        id == state.audioId) {
      return;
    }
    final request = _request;
    if (request == null) return;
    await _replace(
      request.videoId,
      partId: request.partId,
      position: _replacementPosition,
      quality: state.quality,
      audioId: id,
      manual: true,
    );
  }

  Future<void> selectPart(String id) async {
    if (!state.parts.any((p) => p.id == id)) return;
    final request = _request;
    if (request == null) return;
    await _replace(
      request.videoId,
      partId: id,
      position: Duration.zero,
      quality: state.quality == 0 ? null : state.quality,
      manual: true,
    );
  }

  Future<void> nextPart() async {
    final index = state.parts.indexWhere((p) => p.id == state.partId);
    if (index >= 0 && index + 1 < state.parts.length) {
      await selectPart(state.parts[index + 1].id);
    }
  }

  void foregroundChanged(bool active) {
    _foreground = active;
    if (!active) unawaited(suspend(background: true));
  }

  Future<void> suspend({bool background = false}) async {
    if (background) _foreground = false;
    if (state.phase == PlayerPhase.idle || state.phase == PlayerPhase.closed) {
      return;
    }
    _wantPlay = false;
    _epoch++;
    _active?.cancel();
    state = state.copyWith(
      phase: PlayerPhase.paused,
      snapshot: state.snapshot.copyWith(playing: false),
      notice: '已暂停，按确认继续',
      failure: null,
    );
    await _release();
    await _writes;
    if (ref.mounted) state = state.copyWith(surfaceGeneration: _epoch);
  }

  Future<void> close() async {
    _epoch++;
    _active?.cancel();
    if (ref.mounted) state = state.copyWith(phase: PlayerPhase.closed);
    await _release();
    await _operations;
    await _writes;
  }
}
