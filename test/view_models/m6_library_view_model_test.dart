import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mambatv/app/providers/repository_providers.dart';
import 'package:mambatv/app/providers/maintenance_providers.dart';
import 'package:mambatv/core/result.dart';
import 'package:mambatv/data/repositories/memory_session_repository.dart';
import 'package:mambatv/data/repositories/local_settings_repository.dart';
import 'package:mambatv/domain/entities/app_models.dart';
import 'package:mambatv/domain/library/library.dart';
import 'package:mambatv/ui/features/library/view_models/library_view_model.dart';
import 'package:mambatv/ui/features/settings/view_models/settings_view_model.dart';

import '../support/fake_library.dart';
import '../support/memory_preferences.dart';

void main() {
  late ProviderContainer container;
  late FakeLibraryRepository remote;
  late MemorySessionRepository sessions;
  final provider = libraryViewModelProvider(
    ownerKey: 'user:101',
    section: LibrarySection.remote,
  );
  setUp(() {
    remote = FakeLibraryRepository();
    sessions = MemorySessionRepository(
      const Session(ownerKey: 'user:101', status: SessionStatus.authenticated),
    );
    container = ProviderContainer.test(
      retry: (_, _) => null,
      overrides: [
        sessionRepositoryProvider.overrideWithValue(sessions),
        libraryRepositoryProvider.overrideWithValue(remote),
        localHistoryRepositoryProvider.overrideWithValue(MemoryLocalHistory()),
      ],
    );
    container.listen(sessionProvider, (_, _) {});
    addTearDown(() async {
      container.dispose();
      await sessions.close();
    });
  });
  LibraryEntry item(String id) =>
      LibraryEntry(key: id, video: libraryVideo(id));
  test('paging deduplicates, stops repeated pages and retains usable data on refresh failure', () async {
    await container.read(sessionProvider.future);
    remote.pages['first'] = PageSlice(items: [item('a')], nextCursor: '2');
    remote.pages['2'] = PageSlice(
      items: [item('a'), item('b')],
      nextCursor: '3',
    );
    remote.pages['3'] = PageSlice(items: [item('b')], nextCursor: '3');
    container.listen(provider, (_, _) {});
    await container.read(provider.future);
    final vm = container.read(provider.notifier);
    await vm.refresh(more: true);
    expect(container.read(provider).requireValue.items.map((v) => v.key), [
      'a',
      'b',
    ]);
    await vm.refresh(more: true);
    expect(container.read(provider).requireValue.cursor, isNull);
    remote.listFailure = const AppFailure(FailureKind.network, '合成断网');
    await vm.refresh();
    expect(container.read(provider).requireValue.items, hasLength(2));
    expect(container.read(provider).requireValue.failure, isNotNull);
    remote.listFailure = null;
    await vm.refresh();
    expect(
      container.read(provider).requireValue.cursor,
      '2',
      reason: 'Refresh must retain the first-page cursor',
    );
    expect(remote.writes, 0);
  });
  test('session generation replacement cancels stale requests', () async {
    await container.read(sessionProvider.future);
    remote.gate = Completer<Result<PageSlice<LibraryEntry>>>();
    final sub = container.listen(provider, (_, _) {});
    await container.pump();
    final old = remote.signals.single;
    sessions.replace(const Session(generation: 1));
    await container.pump();
    expect(old.isCancelled, true);
    remote.gate!.complete(Success(PageSlice(items: [item('old')])));
    await container.pump();
    sub.close();
    final guest = libraryViewModelProvider(
      ownerKey: 'guest',
      section: LibrarySection.local,
    );
    expect((await container.read(guest.future)).items, isEmpty);
  });
  test('personal provider builds read-only and unresolved writes allow only read reconciliation', () async {
    await container.read(sessionProvider.future);
    final p = personalActionsViewModelProvider(
      videoId: 'BVtest',
      ownerKey: 'user:101',
    );
    container.listen(p, (_, _) {});
    await container.read(p.future);
    expect(remote.writes, 0);
    remote.uncertain = true;
    final vm = container.read(p.notifier);
    await vm.change(desired: true);
    await vm.change(desired: false);
    expect(remote.writes, 1);
    await vm.recheck();
    expect(remote.writes, 1);
    expect(container.read(p).requireValue.pending, true);
    remote.later = true;
    await vm.recheck();
    expect(container.read(p).requireValue.pending, false);
    expect(container.read(libraryRevisionProvider), 1);
  });
  test('cache cleanup preserves persisted preferences and serializes duplicate commands', () async {
    final gate = Completer<void>();
    var cleans = 0;
    final store = MemoryPreferencesStore();
    final c = ProviderContainer.test(
      overrides: [
        settingsRepositoryProvider.overrideWithValue(
          LocalSettingsRepository(store),
        ),
        cacheCleanerProvider.overrideWithValue(() async {
          cleans++;
          await gate.future;
        }),
      ],
    );
    addTearDown(c.dispose);
    await c.read(settingsViewModelProvider.future);
    final vm = c.read(settingsViewModelProvider.notifier);
    await vm.savePreferences(const AppSettings(defaultRate: 1.5));
    final values = Map.of(store.values);
    final pending = vm.clearCaches();
    await vm.clearCaches();
    expect(cleans, 1);
    gate.complete();
    await pending;
    expect(store.values, values);
    expect(
      c.read(settingsViewModelProvider).requireValue.settings.defaultRate,
      1.5,
    );
    expect(c.read(settingsViewModelProvider).requireValue.saving, false);
  });
}
