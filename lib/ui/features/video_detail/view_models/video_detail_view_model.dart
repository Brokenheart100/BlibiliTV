import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers/repository_providers.dart';
import '../../../../core/result.dart';
import '../../../../domain/entities/app_models.dart';
import '../../../../domain/playback/playback.dart';
import '../../catalog/view_models/catalog_view_model.dart';
part 'video_detail_view_model.freezed.dart';
part 'video_detail_view_model.g.dart';

@freezed
abstract class VideoDetailState with _$VideoDetailState {
  const factory VideoDetailState({
    required VideoDetail detail,
    WatchProgress? resume,
    String? notice,
  }) = _VideoDetailState;
}

@riverpod
class VideoDetailViewModel extends _$VideoDetailViewModel {
  @override
  Future<VideoDetailState> build({
    required String id,
    required String pageId,
    required String ownerKey,
  }) async {
    final repository = ref.watch(catalogRepositoryProvider);
    final progress = ref.watch(progressRepositoryProvider);
    final settings = ref.watch(settingsRepositoryProvider);
    final signal = CancellationSignal();
    ref.onDispose(signal.cancel);
    final detail = (await repository.getVideo(
      id,
      ownerKey: ownerKey,
      cancellation: signal,
    )).valueOrThrow;
    if (detail.parts.isEmpty) {
      throw const AppFailure(FailureKind.unavailable, '此视频没有可播放的分集');
    }
    final saved = await progress.latestForVideo(ownerKey, id);
    final preferences = await settings.load();
    final resume = saved is Success<WatchProgress?> ? saved.value : null;
    final remember =
        preferences is Success<AppSettings> && preferences.value.resumePlayback;
    final valid =
        remember &&
        resume != null &&
        resume.isValid &&
        detail.parts.any((p) => p.id == resume.partId) &&
        resume.position < resume.duration - const Duration(seconds: 10);
    return VideoDetailState(
      detail: detail,
      resume: valid ? resume : null,
      notice: saved is ResultFailure ? '播放位置暂不可用，请稍后重试或检查本机存储' : null,
    );
  }
}

@riverpod
Future<List<VideoSummary>> relatedVideos(
  Ref ref, {
  required String id,
  required String pageId,
  required String ownerKey,
}) async {
  final repository = ref.watch(catalogRepositoryProvider);
  final signal = CancellationSignal();
  ref.onDispose(signal.cancel);
  return (await repository.getRelated(
    id,
    ownerKey: ownerKey,
    cancellation: signal,
  )).valueOrThrow;
}

/// The related endpoint is finite. Continue with the existing discovery feed
/// rather than inventing pagination parameters for that endpoint.
@riverpod
class DetailDiscovery extends _$DetailDiscovery {
  CancellationSignal? _signal;
  int _epoch = 0, _stalled = 0;
  @override
  Future<CatalogState> build({
    required String id,
    required String pageId,
    required String ownerKey,
    required String scopeKey,
  }) async {
    final repository = ref.watch(catalogRepositoryProvider);
    ref.watch(sessionProvider.select((s) => s.value?.scopeKey));
    final signal = _signal = CancellationSignal();
    ref.onDispose(() {
      _epoch++;
      signal.cancel();
      _signal?.cancel();
    });
    if (ref.read(sessionProvider).value?.scopeKey != scopeKey) {
      throw const AppFailure(FailureKind.cancelled, '账号已变化');
    }
    final result = await repository.getRelated(
      id,
      ownerKey: ownerKey,
      cancellation: signal,
    );
    if (signal.isCancelled) {
      throw const AppFailure(FailureKind.cancelled, '请求已取消');
    }
    final items = result.valueOrThrow;
    return CatalogState(items: _unique(items), nextCursor: 'discover-start');
  }

  List<VideoSummary> _unique(List<VideoSummary> items) {
    final ids = <String>{id};
    return items.where((item) => ids.add(item.id)).toList();
  }

  void suspend() {
    _epoch++;
    _signal?.cancel();
    final old = state.value;
    if (old != null) state = AsyncData(old.copyWith(loadingMore: false));
  }

  Future<void> loadMore() async {
    final old = state.value;
    if (old == null || old.loadingMore || old.nextCursor == null) return;
    if (ref.read(sessionProvider).value?.scopeKey != scopeKey) return;
    final signal = _signal = CancellationSignal(), epoch = ++_epoch;
    state = AsyncData(
      old.copyWith(loadingMore: true, failure: null, loadMoreFailed: false),
    );
    final result = await ref
        .read(catalogRepositoryProvider)
        .fetchVideos(
          section: 'home',
          ownerKey: ownerKey,
          cancellation: signal,
          cursor: old.nextCursor == 'discover-start' ? null : old.nextCursor,
        );
    if (!ref.mounted ||
        signal.isCancelled ||
        epoch != _epoch ||
        ref.read(sessionProvider).value?.scopeKey != scopeKey) {
      return;
    }
    switch (result) {
      case Success(:final value):
        final merged = _unique([...old.items, ...value.items]);
        _stalled = merged.length > old.items.length ? 0 : _stalled + 1;
        state = AsyncData(
          CatalogState(
            items: merged,
            notice: value.notice,
            nextCursor: _stalled >= 2 || value.nextCursor == old.nextCursor
                ? null
                : value.nextCursor,
          ),
        );
      case ResultFailure(:final failure):
        state = AsyncData(
          old.copyWith(
            loadingMore: false,
            failure: failure,
            loadMoreFailed: true,
          ),
        );
    }
  }
}
