import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers/repository_providers.dart';
import '../../../../core/result.dart';
import '../../../../domain/library/personal_home.dart';

part 'personal_home_view_model.freezed.dart';
part 'personal_home_view_model.g.dart';

@riverpod
Future<PersonalProfile?> personalProfile(Ref ref, String scopeKey) async {
  final session = ref.watch(sessionProvider).value;
  if (session?.isAuthenticated != true || session!.scopeKey != scopeKey) {
    return null;
  }
  final signal = CancellationSignal();
  ref.onDispose(signal.cancel);
  final profile =
      (await ref
              .watch(personalHomeRepositoryProvider)
              .profile(session.ownerKey, signal))
          .valueOrThrow;
  return signal.isCancelled ? null : profile;
}

@freezed
abstract class PersonalCollectionState with _$PersonalCollectionState {
  const factory PersonalCollectionState({
    @Default(<PersonalItem>[]) List<PersonalItem> items,
    String? cursor,
    @Default(false) bool loading,
    AppFailure? failure,
    String? notice,
  }) = _PersonalCollectionState;
}

@riverpod
class PersonalCollection extends _$PersonalCollection {
  int _epoch = 0;
  CancellationSignal? _signal;
  String _owner() {
    final session = ref.read(sessionProvider).value;
    if (session?.isAuthenticated != true || session!.scopeKey != scopeKey) {
      throw const AppFailure(FailureKind.cancelled, '账号已变化，请重新打开');
    }
    return session.ownerKey;
  }

  @override
  Future<PersonalCollectionState> build({
    required String scopeKey,
    required PersonalSection section,
    String? folderId,
  }) async {
    ref.watch(sessionProvider.select((value) => value.value?.scopeKey));
    final repository = ref.watch(personalHomeRepositoryProvider);
    final session = ref.read(sessionProvider).value;
    _signal?.cancel();
    final epoch = ++_epoch;
    if (session?.isAuthenticated != true || session!.scopeKey != scopeKey) {
      return const PersonalCollectionState();
    }
    final signal = _signal = CancellationSignal();
    ref.onDispose(signal.cancel);
    final result = await repository.list(
      ownerKey: session.ownerKey,
      section: section,
      folderId: folderId,
      cancellation: signal,
    );
    if (!ref.mounted || epoch != _epoch || signal.isCancelled) {
      return const PersonalCollectionState();
    }
    final page = result.valueOrThrow;
    return PersonalCollectionState(
      items: _unique(page.items),
      cursor: page.nextCursor,
      notice: page.notice,
    );
  }

  Future<void> refresh({bool more = false}) async {
    final old = state.value;
    if (old == null || old.loading || (more && old.cursor == null)) return;
    final epoch = ++_epoch;
    _signal?.cancel();
    final signal = _signal = CancellationSignal();
    state = AsyncData(old.copyWith(loading: true, failure: null));
    try {
      final page =
          (await ref
                  .read(personalHomeRepositoryProvider)
                  .list(
                    ownerKey: _owner(),
                    section: section,
                    folderId: folderId,
                    cursor: more ? old.cursor : null,
                    cancellation: signal,
                  ))
              .valueOrThrow;
      if (!ref.mounted || epoch != _epoch || signal.isCancelled) return;
      final items = _unique([
        ...more ? old.items : <PersonalItem>[],
        ...page.items,
      ]);
      final stalled =
          more &&
          (items.length == old.items.length || page.nextCursor == old.cursor);
      state = AsyncData(
        PersonalCollectionState(
          items: items,
          cursor: stalled ? null : page.nextCursor,
          notice: page.notice,
        ),
      );
    } catch (error) {
      if (ref.mounted && epoch == _epoch && !signal.isCancelled) {
        state = AsyncData(
          old.copyWith(
            loading: false,
            failure: error is AppFailure
                ? error
                : const AppFailure(FailureKind.unavailable, '个人列表暂不可用'),
          ),
        );
      }
    }
  }
}

List<PersonalItem> _unique(List<PersonalItem> items) =>
    {for (final item in items) item.key: item}.values.toList();
