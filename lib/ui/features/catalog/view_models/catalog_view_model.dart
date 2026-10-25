import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../app/providers/repository_providers.dart';
import '../../../../core/result.dart';
import '../../../../domain/entities/app_models.dart';
import '../../../../domain/repositories/repositories.dart';

part 'catalog_view_model.freezed.dart';
part 'catalog_view_model.g.dart';

@freezed
abstract class CatalogState with _$CatalogState {
  const factory CatalogState({
    @Default(<VideoSummary>[]) List<VideoSummary> items,
    String? nextCursor,
    @Default(false) bool refreshing,
    @Default(false) bool loadingMore,
    @Default(false) bool paused,
    @Default(false) bool loadMoreFailed,
    String? notice,
    AppFailure? failure,
  }) = _CatalogState;
}

@riverpod
class CatalogViewModel extends _$CatalogViewModel {
  late CatalogRepository _repository;
  CancellationSignal? _active;
  int _epoch = 0;
  int _stalledPages = 0;

  @override
  Future<CatalogState> build({
    required String section,
    required String pageId,
    required String ownerKey,
    String query = '',
  }) async {
    _repository = ref.watch(catalogRepositoryProvider);
    final signal = _active = CancellationSignal();
    ref.onDispose(() {
      _epoch++;
      signal.cancel();
      _active?.cancel();
    });
    final result = await _repository.fetchVideos(
      section: section,
      ownerKey: ownerKey,
      query: query,
      cancellation: signal,
    );
    if (signal.isCancelled) return const CatalogState(paused: true);
    final page = result.valueOrThrow;
    return CatalogState(
      items: _unique(page.items),
      nextCursor: page.nextCursor,
      notice: page.notice,
    );
  }

  Future<void> refresh() => _load(refresh: true);
  Future<void> loadMore() => _load(refresh: false);

  Future<void> _load({required bool refresh}) async {
    final previous = state.value;
    if (previous == null ||
        (!refresh &&
            (previous.loadingMore ||
                previous.refreshing ||
                previous.nextCursor == null))) {
      return;
    }
    _active?.cancel();
    final epoch = ++_epoch;
    final signal = _active = CancellationSignal();
    state = AsyncData(
      previous.copyWith(
        refreshing: refresh,
        loadingMore: !refresh,
        paused: false,
        failure: null,
        loadMoreFailed: false,
      ),
    );
    final result = await _repository.fetchVideos(
      section: section,
      ownerKey: ownerKey,
      query: query,
      cursor: refresh ? null : previous.nextCursor,
      forceRefresh: refresh,
      cancellation: signal,
    );
    if (!ref.mounted || signal.isCancelled || epoch != _epoch) return;
    switch (result) {
      case Success(:final value):
        final merged = _unique(
          refresh ? value.items : [...previous.items, ...value.items],
        );
        _stalledPages = refresh || merged.length > previous.items.length
            ? 0
            : _stalledPages + 1;
        final stalled =
            !refresh &&
            (value.nextCursor == previous.nextCursor || _stalledPages >= 2);
        state = AsyncData(
          CatalogState(
            items: merged,
            nextCursor: stalled ? null : value.nextCursor,
            notice: stalled
                ? '暂时没有更多新内容，刷新可重新探索'
                : value.notice ?? previous.notice,
          ),
        );
      case ResultFailure(:final failure):
        state = AsyncData(
          previous.copyWith(
            refreshing: false,
            loadingMore: false,
            paused: false,
            failure: failure,
            loadMoreFailed: !refresh,
          ),
        );
    }
  }

  void suspend() {
    _active?.cancel();
    _epoch++;
    final current = state.value;
    if (current != null) {
      state = AsyncData(
        current.copyWith(
          refreshing: false,
          loadingMore: false,
          paused: current.items.isEmpty,
        ),
      );
    }
  }

  Future<void> resume() async {
    if (state.value?.paused == true) await refresh();
  }
}

List<VideoSummary> _unique(List<VideoSummary> values) {
  final ids = <String>{};
  return values.where((v) => ids.add(v.id)).toList();
}

@riverpod
class SearchQuery extends _$SearchQuery {
  @override
  String build(String ownerKey) => '';
  void submit(String value) => state = value.trim();
}
