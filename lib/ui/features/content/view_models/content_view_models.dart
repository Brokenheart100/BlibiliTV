import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../app/providers/repository_providers.dart';
import '../../../../core/result.dart';
import '../../../../domain/entities/app_models.dart';
import '../../../../domain/playback/content_playback.dart';

part 'content_view_models.freezed.dart';
part 'content_view_models.g.dart';

@freezed
abstract class ContentBrowseState with _$ContentBrowseState {
  const factory ContentBrowseState({
    @Default(<VideoSummary>[]) List<VideoSummary> items,
    int? nextPage,
    @Default(false) bool loadingMore,
    AppFailure? failure,
  }) = _ContentBrowseState;
}

@riverpod
class ContentBrowse extends _$ContentBrowse {
  late CancellationSignal _signal;
  int _epoch = 0;
  @override
  Future<ContentBrowseState> build({
    required bool live,
    required String scopeKey,
  }) async {
    _signal = CancellationSignal();
    _epoch++;
    ref.onDispose(_signal.cancel);
    ref.watch(sessionProvider.select((s) => s.value?.scopeKey));
    final result = await _page(1);
    return ContentBrowseState(
      items: result.items,
      nextPage: result.nextCursor == null
          ? null
          : int.parse(result.nextCursor!),
    );
  }

  Future<PageSlice<VideoSummary>> _page(int page) async {
    if (ref.read(sessionProvider).value?.scopeKey != scopeKey) {
      throw const AppFailure(FailureKind.cancelled, '账号已变化');
    }
    if (!live) {
      return (await ref.read(pgcRepositoryProvider).browse(_signal, page: page))
          .valueOrThrow;
    }
    final result =
        (await ref.read(liveRepositoryProvider).browse(_signal, page: page))
            .valueOrThrow;
    return PageSlice(
      items: result.items
          .map(
            (r) => VideoSummary(
              id: r.id,
              title: r.title,
              creator: r.creator,
              coverUrl: r.coverUrl,
              durationSeconds: 0,
              viewCount: 0,
            ),
          )
          .toList(),
      nextCursor: result.nextCursor,
    );
  }

  Future<void> loadMore() async {
    final old = state.value;
    if (old == null || old.loadingMore || old.nextPage == null) return;
    state = AsyncData(old.copyWith(loadingMore: true, failure: null));
    final epoch = _epoch, signal = _signal;
    try {
      final page = await _page(old.nextPage!);
      if (!ref.mounted ||
          signal.isCancelled ||
          epoch != _epoch ||
          ref.read(sessionProvider).value?.scopeKey != scopeKey) {
        return;
      }
      final seen = old.items.map((e) => e.id).toSet();
      state = AsyncData(
        old.copyWith(
          items: [...old.items, ...page.items.where((e) => seen.add(e.id))],
          nextPage: page.nextCursor == null
              ? null
              : int.parse(page.nextCursor!),
          loadingMore: false,
        ),
      );
    } catch (e) {
      if (ref.mounted &&
          !signal.isCancelled &&
          epoch == _epoch &&
          ref.read(sessionProvider).value?.scopeKey == scopeKey) {
        state = AsyncData(
          old.copyWith(
            loadingMore: false,
            failure: e is AppFailure
                ? e
                : const AppFailure(FailureKind.unavailable, '列表暂不可用'),
          ),
        );
      }
    }
  }
}

@riverpod
Future<ContentSeason> contentSeason(
  Ref ref, {
  required String id,
  required String scopeKey,
}) async {
  ref.watch(sessionProvider.select((s) => s.value?.scopeKey));
  if (ref.read(sessionProvider).value?.scopeKey != scopeKey) {
    throw const AppFailure(FailureKind.cancelled, '账号已变化');
  }
  final signal = CancellationSignal();
  ref.onDispose(signal.cancel);
  return (await ref.watch(pgcRepositoryProvider).season(id, signal))
      .valueOrThrow;
}
