import 'dart:async';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../app/providers/playback_providers.dart';
import '../../../../app/providers/repository_providers.dart';
import '../../../../core/result.dart';
import '../../../../domain/playback/playback.dart';
import '../../../../domain/playback/playback_coordinator.dart';
import '../../../../domain/playback/start_playback.dart';

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
    @Default(0) int quality,
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
  EngineLease? _lease;
  StreamSubscription<EngineSnapshot>? _subscription;
  CancellationSignal? _active;
  WatchProgress? _lastValid;
  Future<void> _writes = Future<void>.value();
  int _epoch = 0, _lastSavedSecond = 0;
  ({String videoId, String? partId})? _request;
  bool _command = false;
  PlaybackEngine? get engine => _lease?.engine;

  @override
  PlayerState build({required String pageId, required String ownerKey}) {
    _start = ref.watch(startPlaybackProvider);
    _coordinator = ref.watch(playbackCoordinatorProvider);
    _progress = ref.watch(progressRepositoryProvider);
    ref.onDispose(() {
      _epoch++;
      _active?.cancel();
      final lease = _lease;
      _lease = null;
      unawaited(_subscription?.cancel());
      _subscription = null;
      _save();
      unawaited(lease?.close());
    });
    // Provider creation/rebuild deliberately does not open media.
    return const PlayerState();
  }

  bool _current(int epoch, CancellationSignal signal) =>
      ref.mounted && epoch == _epoch && !signal.isCancelled;

  Future<void> start(String videoId, {String? partId}) async {
    if (state.phase == PlayerPhase.resolving ||
        state.phase == PlayerPhase.opening) {
      return;
    }
    _active?.cancel();
    _request = (videoId: videoId, partId: partId);
    final epoch = ++_epoch;
    final signal = _active = CancellationSignal();
    state = const PlayerState(phase: PlayerPhase.resolving);
    await _release();
    await _writes;
    if (!_current(epoch, signal)) return;
    _lastValid = null;
    _lastSavedSecond = 0;
    try {
      final plan = await _start(
        videoId: videoId,
        partId: partId,
        ownerKey: ownerKey,
        cancellation: signal,
      );
      if (!_current(epoch, signal)) return;
      state = PlayerState(
        phase: PlayerPhase.opening,
        title: plan.title,
        partTitle: plan.partTitle,
        quality: plan.source.quality,
        resumedFrom: plan.startAt,
      );
      final lease = await _coordinator.acquire(signal);
      if (!_current(epoch, signal)) {
        await lease.close();
        return;
      }
      _lease = lease;
      // Publishing the lease mounts its surface before waiting for the first frame.
      state = state.copyWith(
        snapshot: lease.engine.snapshot,
        surfaceGeneration: epoch,
      );
      var resumeConfirmed = plan.startAt == Duration.zero;
      _subscription = lease.engine.snapshots.listen((snapshot) {
        if (!_current(epoch, signal) || lease.isClosed) return;
        final opening = state.phase == PlayerPhase.opening;
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
        if (snapshot.position >= plan.startAt - const Duration(seconds: 2)) {
          resumeConfirmed = true;
        }
        if (!opening &&
            resumeConfirmed &&
            plan.rememberProgress &&
            snapshot.position.inSeconds >= 1 &&
            snapshot.duration > Duration.zero) {
          final progress = WatchProgress(
            ownerKey: ownerKey,
            videoId: plan.videoId,
            partId: plan.partId,
            position: snapshot.position,
            duration: snapshot.duration,
          );
          if (progress.isValid) {
            _lastValid = progress;
            if (snapshot.position.inSeconds - _lastSavedSecond >= 5) {
              _lastSavedSecond = snapshot.position.inSeconds;
              _save();
            }
          }
        }
        if (snapshot.failure != null) unawaited(_release());
      });
      await lease.engine.open(plan.source, startAt: plan.startAt);
      if (!_current(epoch, signal) || lease.isClosed) return;
      final snapshot = lease.engine.snapshot;
      if (snapshot.failure case final AppFailure failure) throw failure;
      state = state.copyWith(
        snapshot: snapshot,
        phase: snapshot.playing ? PlayerPhase.playing : PlayerPhase.paused,
      );
    } catch (error) {
      if (!_current(epoch, signal)) return;
      state = state.copyWith(
        phase: PlayerPhase.failed,
        failure: error is AppFailure
            ? error
            : const AppFailure(FailureKind.unavailable, '视频暂时无法播放，请重试或返回'),
      );
      await _release();
    }
  }

  void _save() {
    final progress = _lastValid;
    if (progress == null || !progress.isValid) return;
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

  Future<void> _release() async {
    _save();
    final subscription = _subscription;
    final lease = _lease;
    _subscription = null;
    _lease = null;
    await subscription?.cancel();
    await lease?.close();
  }

  Future<void> togglePause() async {
    final request = _request;
    if (state.phase == PlayerPhase.completed && request != null) {
      await start(request.videoId, partId: request.partId);
      return;
    }
    final lease = _lease;
    if (lease == null ||
        lease.isClosed ||
        _command ||
        (state.phase != PlayerPhase.playing &&
            state.phase != PlayerPhase.paused)) {
      return;
    }
    _command = true;
    try {
      if (state.snapshot.playing) {
        await lease.engine.pause();
        _save();
      } else {
        await lease.engine.play();
      }
    } catch (_) {
      if (ref.mounted) state = state.copyWith(notice: '操作暂未完成，请重试');
    } finally {
      _command = false;
    }
  }

  Future<void> seekBy(Duration delta) async {
    final lease = _lease;
    if (lease == null ||
        lease.isClosed ||
        _command ||
        state.snapshot.duration <= Duration.zero ||
        (state.phase != PlayerPhase.playing &&
            state.phase != PlayerPhase.paused)) {
      return;
    }
    _command = true;
    try {
      final target = (state.snapshot.position + delta).inMilliseconds.clamp(
        0,
        (state.snapshot.duration.inMilliseconds - 1000).clamp(0, 1 << 53),
      );
      await lease.engine.seek(Duration(milliseconds: target));
    } catch (_) {
      if (ref.mounted) state = state.copyWith(notice: '暂时无法跳转，请重试');
    } finally {
      _command = false;
    }
  }

  Future<void> suspend() async {
    if (state.phase == PlayerPhase.playing) {
      await togglePause();
    } else if (state.phase == PlayerPhase.resolving ||
        state.phase == PlayerPhase.opening) {
      _epoch++;
      _active?.cancel();
      state = state.copyWith(
        phase: PlayerPhase.failed,
        failure: const AppFailure(FailureKind.cancelled, '播放已中断，确认后可重新播放'),
      );
      await _release();
    }
  }

  Future<void> close() async {
    _epoch++;
    _active?.cancel();
    if (ref.mounted) state = state.copyWith(phase: PlayerPhase.closed);
    await _release();
    await _writes;
  }
}
