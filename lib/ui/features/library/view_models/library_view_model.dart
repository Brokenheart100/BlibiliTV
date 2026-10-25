import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers/repository_providers.dart';
import '../../../../core/result.dart';
import '../../../../domain/library/library.dart';

part 'library_view_model.freezed.dart';
part 'library_view_model.g.dart';

@Riverpod(keepAlive: true)
class LibraryRevision extends _$LibraryRevision {
  @override
  int build() => 0;
  void changed() => state++;
}

@freezed
abstract class LibraryState with _$LibraryState {
  const factory LibraryState({
    @Default(<LibraryEntry>[]) List<LibraryEntry> items,
    String? cursor,
    @Default(false) bool loading,
    @Default(false) bool mutating,
    AppFailure? failure,
    String? notice,
  }) = _LibraryState;
}

@riverpod
class LibraryViewModel extends _$LibraryViewModel {
  int _epoch = 0;
  CancellationSignal? _signal;
  @override
  Future<LibraryState> build({
    required String ownerKey,
    required LibrarySection section,
    String? folderId,
  }) async {
    ref.watch(sessionProvider.select((s) => s.value?.scopeKey));
    ref.watch(libraryRevisionProvider);
    if (section == LibrarySection.local) {
      ref.watch(localHistoryRepositoryProvider);
    } else {
      ref.watch(libraryRepositoryProvider);
    }
    final epoch = ++_epoch;
    final signal = _signal = CancellationSignal();
    ref.onDispose(() => _signal?.cancel());
    final result = await _fetch(signal);
    if (!ref.mounted || epoch != _epoch) return const LibraryState();
    return switch (result) {
      Success(:final value) => LibraryState(
        items: value.items,
        cursor: value.nextCursor,
        notice: value.notice,
      ),
      ResultFailure(:final failure) => LibraryState(failure: failure),
    };
  }

  Future<Result<PageSlice<LibraryEntry>>> _fetch(
    CancellationSignal signal, {
    String? cursor,
  }) {
    if (section == LibrarySection.local) {
      return ref
          .read(localHistoryRepositoryProvider)
          .list(ownerKey, cursor: cursor);
    }
    return ref
        .read(libraryRepositoryProvider)
        .list(
          ownerKey: ownerKey,
          section: section,
          folderId: folderId,
          cursor: cursor,
          cancellation: signal,
        );
  }

  Future<void> refresh({bool more = false}) async {
    final old = state.value;
    if (old == null ||
        old.loading ||
        old.mutating ||
        (more && old.cursor == null)) {
      return;
    }
    final epoch = ++_epoch;
    _signal?.cancel();
    final signal = _signal = CancellationSignal();
    state = AsyncData(old.copyWith(loading: true, failure: null, notice: null));
    final result = await _fetch(signal, cursor: more ? old.cursor : null);
    if (!ref.mounted || epoch != _epoch || signal.isCancelled) return;
    if (result is Success<PageSlice<LibraryEntry>>) {
      final unique = {
        if (more)
          for (final item in old.items) item.key: item,
        for (final item in result.value.items) item.key: item,
      };
      final progressing = !more || unique.length > old.items.length;
      state = AsyncData(
        LibraryState(
          items: unique.values.toList(),
          cursor:
              progressing && (!more || result.value.nextCursor != old.cursor)
              ? result.value.nextCursor
              : null,
          notice: result.value.notice,
        ),
      );
    } else {
      state = AsyncData(
        old.copyWith(
          loading: false,
          failure: (result as ResultFailure<PageSlice<LibraryEntry>>).failure,
          notice: old.items.isEmpty ? null : '刷新未完成，仍显示上次读取的内容',
        ),
      );
    }
  }

  Future<void> removeLocal(String? videoId) async {
    final old = state.value;
    if (section != LibrarySection.local ||
        old == null ||
        old.loading ||
        old.mutating) {
      return;
    }
    final epoch = ++_epoch;
    state = AsyncData(old.copyWith(mutating: true, failure: null));
    final repository = ref.read(localHistoryRepositoryProvider);
    final result = videoId == null
        ? await repository.clear(ownerKey)
        : await repository.remove(ownerKey, videoId);
    if (!ref.mounted || epoch != _epoch) return;
    state = AsyncData(old.copyWith(mutating: false));
    if (result is Success<void>) {
      await refresh();
    } else {
      state = AsyncData(
        old.copyWith(failure: (result as ResultFailure<void>).failure),
      );
    }
  }
}

@freezed
abstract class PersonalActionsState with _$PersonalActionsState {
  const factory PersonalActionsState({
    LibraryMembership? membership,
    @Default(false) bool busy,
    @Default(false) bool pending,
    String? pendingFolder,
    bool? pendingDesired,
    String? message,
  }) = _PersonalActionsState;
}

@riverpod
class PersonalActionsViewModel extends _$PersonalActionsViewModel {
  CancellationSignal? _signal;
  int _epoch = 0;
  @override
  Future<PersonalActionsState> build({
    required String videoId,
    required String ownerKey,
  }) async {
    ref.watch(sessionProvider.select((s) => s.value?.scopeKey));
    final repository = ref.watch(libraryRepositoryProvider);
    final epoch = ++_epoch;
    final signal = _signal = CancellationSignal();
    ref.onDispose(() => _signal?.cancel());
    final value = (await repository.membership(
      ownerKey: ownerKey,
      videoId: videoId,
      aid: 0,
      cancellation: signal,
    )).valueOrThrow;
    if (!ref.mounted || epoch != _epoch) return const PersonalActionsState();
    return PersonalActionsState(membership: value);
  }

  Future<void> change({String? folderId, required bool desired}) async {
    final old = state.value;
    if (old == null || old.busy || old.pending || old.membership == null) {
      return;
    }
    final epoch = ++_epoch;
    final signal = _signal = CancellationSignal();
    final repository = ref.read(libraryRepositoryProvider);
    state = AsyncData(old.copyWith(busy: true, message: null));
    final result = await repository.change(
      ownerKey: ownerKey,
      videoId: videoId,
      aid: old.membership!.aid,
      folderId: folderId,
      desired: desired,
      cancellation: signal,
    );
    if (!ref.mounted || epoch != _epoch || signal.isCancelled) return;
    if (result is Success<LibraryWriteResult>) {
      state = AsyncData(
        old.copyWith(
          busy: false,
          pending: result.value.status == WriteStatus.uncertain,
          pendingFolder: result.value.pendingFolder ?? folderId,
          pendingDesired: result.value.pendingDesired ?? desired,
          message: result.value.message,
        ),
      );
      if (result.value.status == WriteStatus.confirmed) {
        ref.read(libraryRevisionProvider.notifier).changed();
        await recheck();
      }
    } else {
      state = AsyncData(
        old.copyWith(
          busy: false,
          message:
              (result as ResultFailure<LibraryWriteResult>).failure.message,
        ),
      );
    }
  }

  Future<void> recheck() async {
    final old = state.value;
    if (old == null || old.busy) return;
    final epoch = ++_epoch;
    final signal = _signal = CancellationSignal();
    state = AsyncData(old.copyWith(busy: true));
    final result = await ref
        .read(libraryRepositoryProvider)
        .membership(
          ownerKey: ownerKey,
          videoId: videoId,
          aid: old.membership?.aid ?? 0,
          cancellation: signal,
        );
    if (!ref.mounted || epoch != _epoch || signal.isCancelled) return;
    if (result is Success<LibraryMembership>) {
      final selected = old.pendingFolder == null
          ? result.value.watchLater
          : result.value.folders.any(
              (f) => f.id == old.pendingFolder && f.selected,
            );
      final pending = old.pending && selected != old.pendingDesired;
      state = AsyncData(
        old.copyWith(
          membership: result.value,
          busy: false,
          pending: pending,
          message: pending ? '上次操作仍待确认，未重复提交' : '已读取最新状态',
        ),
      );
      if (old.pending && !pending) {
        ref.read(libraryRevisionProvider.notifier).changed();
      }
    } else {
      state = AsyncData(
        old.copyWith(
          busy: false,
          message: (result as ResultFailure<LibraryMembership>).failure.message,
        ),
      );
    }
  }
}
