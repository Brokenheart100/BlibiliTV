import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../app/providers/repository_providers.dart';
import '../../../../core/result.dart';
import '../../../../domain/repositories/repositories.dart';
part 'search_history_view_model.freezed.dart';
part 'search_history_view_model.g.dart';

@freezed
abstract class SearchHistoryState with _$SearchHistoryState {
  const factory SearchHistoryState({
    @Default(<String>[]) List<String> items,
    AppFailure? failure,
  }) = _SearchHistoryState;
}

@riverpod
class SearchHistoryViewModel extends _$SearchHistoryViewModel {
  late SearchHistoryRepository _repository;
  int _epoch = 0;
  @override
  Future<SearchHistoryState> build(String ownerKey) async {
    _repository = ref.watch(searchHistoryRepositoryProvider);
    ref.onDispose(() => _epoch++);
    return SearchHistoryState(
      items: (await _repository.load(ownerKey)).valueOrThrow,
    );
  }

  Future<void> remember(String value) =>
      _change(() => _repository.remember(ownerKey, value));
  Future<void> clear() => _change(() => _repository.clear(ownerKey));
  Future<void> _change(Future<Result<void>> Function() command) async {
    final epoch = ++_epoch;
    final result = await command();
    if (!ref.mounted || epoch != _epoch) return;
    if (result case ResultFailure(:final failure)) {
      state = AsyncData(
        (state.value ?? const SearchHistoryState()).copyWith(failure: failure),
      );
      return;
    }
    final loaded = await _repository.load(ownerKey);
    if (!ref.mounted || epoch != _epoch) return;
    state = AsyncData(switch (loaded) {
      Success(:final value) => SearchHistoryState(items: value),
      ResultFailure(:final failure) =>
        (state.value ?? const SearchHistoryState()).copyWith(failure: failure),
    });
  }
}
