import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../app/providers/repository_providers.dart';
import '../../../../core/result.dart';
import '../../../../domain/discovery/content_search.dart';

part 'content_search_view_model.freezed.dart';
part 'content_search_view_model.g.dart';

@freezed
abstract class ContentSearchState with _$ContentSearchState {
  const factory ContentSearchState({
    @Default(<ContentSearchItem>[]) List<ContentSearchItem> items,
    String? nextCursor,
    @Default(false) bool refreshing,
    @Default(false) bool loadingMore,
    @Default(false) bool paused,
    @Default(false) bool loadMoreFailed,
    AppFailure? failure,
  }) = _ContentSearchState;
}

@riverpod
class ContentSearchViewModel extends _$ContentSearchViewModel {
  late ContentSearchRepository repository;
  CancellationSignal? _active;
  int _epoch = 0, _stalled = 0;
  @override
  Future<ContentSearchState> build({
    required SearchCategory category,
    required String query,
    required String scopeKey,
  }) async {
    repository = ref.watch(contentSearchRepositoryProvider);
    ref.watch(sessionProvider.select((value) => value.value?.scopeKey));
    final signal = _active = CancellationSignal();
    ref.onDispose(() {
      _epoch++;
      signal.cancel();
      _active?.cancel();
    });
    if (query.trim().isEmpty) return const ContentSearchState();
    final result = await _fetch(signal, refresh: true);
    if (signal.isCancelled) return const ContentSearchState(paused: true);
    final page = result.valueOrThrow;
    return ContentSearchState(
      items: _unique(page.items),
      nextCursor: page.nextCursor,
    );
  }

  Future<Result<PageSlice<ContentSearchItem>>> _fetch(
    CancellationSignal signal, {
    String? cursor,
    bool refresh = false,
  }) {
    final session = ref.read(sessionProvider).value;
    if (session == null || session.scopeKey != scopeKey) {
      return Future.value(
        const ResultFailure(AppFailure(FailureKind.cancelled, '账号已变化')),
      );
    }
    return repository.search(
      category: category,
      query: query,
      ownerKey: session.ownerKey,
      cancellation: signal,
      cursor: cursor,
      forceRefresh: refresh,
    );
  }

  Future<void> refresh() => _load(refresh: true);
  Future<void> loadMore() => _load(refresh: false);
  Future<void> _load({required bool refresh}) async {
    final old = state.value;
    if (old == null ||
        query.trim().isEmpty ||
        (!refresh &&
            (old.loadingMore || old.refreshing || old.nextCursor == null))) {
      return;
    }
    _active?.cancel();
    final signal = _active = CancellationSignal(), epoch = ++_epoch;
    state = AsyncData(
      old.copyWith(
        refreshing: refresh,
        loadingMore: !refresh,
        paused: false,
        failure: null,
        loadMoreFailed: false,
      ),
    );
    final result = await _fetch(
      signal,
      cursor: refresh ? null : old.nextCursor,
      refresh: refresh,
    );
    if (!ref.mounted ||
        signal.isCancelled ||
        epoch != _epoch ||
        ref.read(sessionProvider).value?.scopeKey != scopeKey) {
      return;
    }
    switch (result) {
      case Success(:final value):
        final merged = _unique(
          refresh ? value.items : [...old.items, ...value.items],
        );
        _stalled = refresh || merged.length > old.items.length
            ? 0
            : _stalled + 1;
        state = AsyncData(
          ContentSearchState(
            items: merged,
            nextCursor:
                !refresh &&
                    (value.nextCursor == old.nextCursor || _stalled >= 2)
                ? null
                : value.nextCursor,
          ),
        );
      case ResultFailure(:final failure):
        state = AsyncData(
          old.copyWith(
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
    final old = state.value;
    if (old != null) {
      state = AsyncData(
        old.copyWith(
          refreshing: false,
          loadingMore: false,
          paused: old.items.isEmpty,
        ),
      );
    }
  }

  Future<void> resume() async {
    if (state.value?.paused == true) await refresh();
  }
}

List<ContentSearchItem> _unique(List<ContentSearchItem> items) {
  final ids = <String>{};
  return items.where((item) => ids.add(item.identity)).toList();
}
