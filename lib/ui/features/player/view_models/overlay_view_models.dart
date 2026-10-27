import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../app/providers/overlay_providers.dart';
import '../../../../app/providers/ui_providers.dart';
import '../../../../core/result.dart';
import '../../../../domain/overlays/overlays.dart';
part 'overlay_view_models.freezed.dart';
part 'overlay_view_models.g.dart';

/// Held by the player route, so a quality change keeps its track choice while
/// the previous engine and its render/data subscriptions are fully released.
@riverpod
class SubtitleChoice extends _$SubtitleChoice {
  @override
  ({bool explicit, String? id}) build({
    required String videoId,
    required String partId,
    required String scopeKey,
  }) => (explicit: false, id: null);
  void choose(String? id) => state = (explicit: true, id: id);
}

@Riverpod(keepAlive: true)
class OverlaySettingsViewModel extends _$OverlaySettingsViewModel {
  Future<void> _writes = Future.value();
  @override
  Future<OverlayPreferences> build() =>
      ref.watch(overlayPreferencesRepositoryProvider).load();
  Future<Result<void>> savePreferences(OverlayPreferences preferences) async {
    final previous = state.value ?? const OverlayPreferences();
    state = AsyncData(preferences);
    try {
      final repository = ref.read(overlayPreferencesRepositoryProvider);
      final write = _writes.then((_) => repository.save(preferences));
      _writes = write.then<void>((_) {}, onError: (Object _, StackTrace _) {});
      await write;
      return const Success(null);
    } catch (_) {
      if (ref.mounted && state.value == preferences) {
        state = AsyncData(previous);
      }
      return const ResultFailure(
        AppFailure(FailureKind.storage, '增强设置未能保存，请重试'),
      );
    }
  }
}

@freezed
abstract class SubtitleState with _$SubtitleState {
  const factory SubtitleState({
    @Default(<SubtitleTrack>[]) List<SubtitleTrack> tracks,
    @Default(<SubtitleCue>[]) List<SubtitleCue> cues,
    String? selected,
    @Default(false) bool loading,
    AppFailure? failure,
  }) = _SubtitleState;
}

@riverpod
class SubtitleViewModel extends _$SubtitleViewModel {
  CancellationSignal? _active;
  int _epoch = 0;
  @override
  Future<SubtitleState> build({
    required String videoId,
    required String partId,
    required String scopeKey,
  }) async {
    final repository = ref.watch(subtitleRepositoryProvider);
    final foreground = ref.watch(appForegroundProvider);
    final settings = ref.watch(
      overlaySettingsViewModelProvider.select(
        (s) => (s.value?.subtitles ?? true, s.value?.language ?? 'zh'),
      ),
    );
    final signal = _active = CancellationSignal();
    ref.onDispose(() {
      _epoch++;
      signal.cancel();
      _active?.cancel();
    });
    if (!settings.$1 || !foreground) return const SubtitleState();
    final tracks = (await repository.tracks(
      videoId,
      partId,
      signal,
    )).valueOrThrow;
    if (signal.isCancelled) return const SubtitleState();
    if (tracks.isEmpty) return const SubtitleState();
    final choice = ref.read(
      subtitleChoiceProvider(
        videoId: videoId,
        partId: partId,
        scopeKey: scopeKey,
      ),
    );
    if (choice.explicit && choice.id == null) {
      return SubtitleState(tracks: tracks);
    }
    final chosen =
        tracks.where((t) => choice.explicit && t.id == choice.id).firstOrNull ??
        tracks
            .where(
              (t) => t.language.replaceFirst('ai-', '').startsWith(settings.$2),
            )
            .firstOrNull ??
        tracks.first;
    final cues = await repository.cues(chosen.id, signal);
    return SubtitleState(
      tracks: tracks,
      selected: chosen.id,
      cues: cues is Success<List<SubtitleCue>> ? cues.value : const [],
      failure: cues is ResultFailure<List<SubtitleCue>> ? cues.failure : null,
    );
  }

  Future<void> select(String? id) async {
    final previous = state.value;
    if (previous == null ||
        id != null && !previous.tracks.any((t) => t.id == id)) {
      return;
    }
    _active?.cancel();
    ref
        .read(
          subtitleChoiceProvider(
            videoId: videoId,
            partId: partId,
            scopeKey: scopeKey,
          ).notifier,
        )
        .choose(id);
    final signal = _active = CancellationSignal(), epoch = ++_epoch;
    state = AsyncData(
      previous.copyWith(
        selected: id,
        cues: [],
        loading: id != null,
        failure: null,
      ),
    );
    if (id == null) return;
    final result = await ref.read(subtitleRepositoryProvider).cues(id, signal);
    if (!ref.mounted || signal.isCancelled || epoch != _epoch) return;
    state = AsyncData(
      state.requireValue.copyWith(
        loading: false,
        cues: result is Success<List<SubtitleCue>> ? result.value : const [],
        failure: result is ResultFailure<List<SubtitleCue>>
            ? result.failure
            : null,
      ),
    );
  }
}

@freezed
abstract class DanmakuState with _$DanmakuState {
  const factory DanmakuState({
    DanmakuManifest? manifest,
    @Default(<DanmakuItem>[]) List<DanmakuItem> items,
    @Default(false) bool loading,
    @Default(0) int window,
    AppFailure? failure,
  }) = _DanmakuState;
}

@riverpod
class DanmakuViewModel extends _$DanmakuViewModel {
  final _cache = <int, List<DanmakuItem>>{};
  CancellationSignal? _active;
  int _epoch = 0, _window = 0;
  @override
  Future<DanmakuState> build({
    required String videoId,
    required String partId,
    required String scopeKey,
  }) async {
    final repository = ref.watch(danmakuRepositoryProvider);
    final foreground = ref.watch(appForegroundProvider);
    final enabled = ref.watch(
      overlaySettingsViewModelProvider.select((p) => p.value?.danmaku ?? false),
    );
    final signal = _active = CancellationSignal();
    ref.onDispose(() {
      _epoch++;
      signal.cancel();
      _active?.cancel();
      _cache.clear();
      _window = 0;
    });
    if (!enabled || !foreground) return const DanmakuState();
    final manifest = (await repository.manifest(
      videoId,
      partId,
      signal,
    )).valueOrThrow;
    return DanmakuState(manifest: manifest);
  }

  void moveTo(int positionMs, {bool retry = false}) {
    final data = state.value, manifest = state.value?.manifest;
    if (data == null || manifest == null || manifest.total == 0) return;
    final target = manifest.segmentAt(positionMs);
    if (_window == target && !retry) return;
    _window = target;
    _active?.cancel();
    final signal = _active = CancellationSignal(), epoch = ++_epoch;
    _cache.removeWhere((i, _) => (i - target).abs() > 1);
    state = AsyncData(
      data.copyWith(
        window: target,
        loading: true,
        failure: null,
        items: _merged(),
      ),
    );
    unawaited(_load(target, manifest.total, epoch, signal));
  }

  List<DanmakuItem> _merged() => _cache.values.expand((v) => v).toList()
    ..sort(
      (a, b) => a.timeMs != b.timeMs
          ? a.timeMs.compareTo(b.timeMs)
          : a.id.compareTo(b.id),
    );
  Future<void> _load(
    int target,
    int total,
    int epoch,
    CancellationSignal signal,
  ) async {
    // Sequential requests deliberately stay below the two-request budget.
    for (final index in [target, target + 1, target - 1]) {
      if (index < 1 || index > total || _cache.containsKey(index)) continue;
      final result = await ref
          .read(danmakuRepositoryProvider)
          .segment(partId, index, signal);
      if (!ref.mounted || signal.isCancelled || epoch != _epoch) return;
      if (result is Success<List<DanmakuItem>>) {
        _cache[index] = result.value;
        int estimate() => _cache.values
            .expand((v) => v)
            .fold(0, (n, e) => n + 160 + e.text.length * 2);
        while (estimate() > 32 * 1024 * 1024 && _cache.length > 1) {
          _cache.remove(_cache.keys.firstWhere((i) => i != target));
        }
        state = AsyncData(
          state.requireValue.copyWith(items: _merged(), loading: true),
        );
      } else if (index == target) {
        state = AsyncData(
          state.requireValue.copyWith(
            loading: false,
            failure: (result as ResultFailure<List<DanmakuItem>>).failure,
          ),
        );
      }
    }
    if (ref.mounted && !signal.isCancelled && epoch == _epoch) {
      state = AsyncData(state.requireValue.copyWith(loading: false));
    }
  }
}
