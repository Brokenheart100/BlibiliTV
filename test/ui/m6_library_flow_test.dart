import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mambatv/core/result.dart';
import 'package:mambatv/app/router.dart';
import 'package:mambatv/data/repositories/memory_session_repository.dart';
import 'package:mambatv/domain/entities/app_models.dart';
import 'package:mambatv/domain/library/library.dart';
import 'package:mambatv/ui/features/library/views/personal_actions_dialog.dart';

import '../support/app_harness.dart';
import '../support/fake_library.dart';
import 'tv_shell_test.dart' show press;

void main() {
  testWidgets(
    'local history scrolls by D-pad, confirms deletion and retains other owners at 800x450',
    (tester) async {
      final local = MemoryLocalHistory();
      local.entries['guest'] = [
        for (var i = 0; i < 30; i++)
          LibraryEntry(
            key: 'BV$i',
            video: libraryVideo('BV$i'),
            partId: '1',
            position: const Duration(seconds: 20),
          ),
      ];
      local.entries['user:2'] = [
        LibraryEntry(key: 'BV0', video: libraryVideo('BV0')),
      ];
      final c = await pumpMamba(
        tester,
        localHistory: local,
        size: const Size(800, 450),
      );
      c.read(appRouterProvider).push<void>('/library/records');
      await tester.pumpAndSettle();
      await press(tester, LogicalKeyboardKey.arrowDown);
      await press(tester, LogicalKeyboardKey.arrowDown);
      for (var i = 0; i < 20; i++) {
        await press(tester, LogicalKeyboardKey.arrowDown);
      }
      expect(
        FocusManager.instance.primaryFocus?.debugLabel,
        'library-item-BV20',
      );
      await press(tester, LogicalKeyboardKey.arrowRight);
      await press(tester, LogicalKeyboardKey.select);
      expect(find.text('删除这条本地记录？'), findsOneWidget);
      await tester.tap(find.byKey(const Key('dialog-confirm')));
      await tester.pumpAndSettle();
      expect(local.entries['guest']!.any((e) => e.key == 'BV20'), false);
      expect(local.entries['user:2'], hasLength(1));
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'guest private list offers login and empty list Up returns to its tab',
    (tester) async {
      final c = await pumpMamba(tester, size: const Size(800, 450));
      c.read(appRouterProvider).push<void>('/library/records');
      await tester.pumpAndSettle();
      await press(tester, LogicalKeyboardKey.arrowDown);
      await press(tester, LogicalKeyboardKey.arrowDown);
      await press(tester, LogicalKeyboardKey.arrowUp);
      expect(FocusManager.instance.primaryFocus?.debugLabel, 'library-tab-0');
      await tester.tap(find.byKey(const Key('library-tab-1')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('library-login')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('a local clear confirmation cannot cross a session change', (
    tester,
  ) async {
    final sessions = MemorySessionRepository(
      const Session(ownerKey: 'user:101', status: SessionStatus.authenticated),
    );
    final local = MemoryLocalHistory();
    for (final owner in ['user:101', 'user:202']) {
      local.entries[owner] = [
        LibraryEntry(key: 'BV1', video: libraryVideo('BV1')),
      ];
    }
    final c = await pumpMamba(tester, sessions: sessions, localHistory: local);
    c.read(appRouterProvider).push<void>('/library/records');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('library-clear')));
    await tester.pumpAndSettle();
    sessions.replace(
      const Session(
        ownerKey: 'user:202',
        status: SessionStatus.authenticated,
        generation: 1,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('dialog-confirm')));
    await tester.pumpAndSettle();
    expect(local.clears, 0);
    expect(local.entries['user:202'], hasLength(1));
  });
  testWidgets(
    'long personal folder list scrolls with focus and build executes no writes',
    (tester) async {
      final sessions = MemorySessionRepository(
        const Session(
          ownerKey: 'user:101',
          status: SessionStatus.authenticated,
        ),
      );
      final remote = FakeLibraryRepository()
        ..folders = [
          for (var i = 0; i < 20; i++) FavouriteFolder('$i', '测试收藏夹 $i'),
        ];
      final c = await pumpMamba(
        tester,
        sessions: sessions,
        library: remote,
        size: const Size(800, 450),
      );
      final context = c
          .read(appRouterProvider)
          .routerDelegate
          .navigatorKey
          .currentContext!;
      showDialog<void>(
        context: context,
        builder: (_) => const PersonalActionsDialog(
          videoId: 'BVtest',
          ownerKey: 'user:101',
        ),
      );
      await tester.pumpAndSettle();
      for (var i = 0; i < 15; i++) {
        await press(tester, LogicalKeyboardKey.arrowDown);
      }
      expect(
        find.byKey(const Key('personal-folder-14')).hitTestable(),
        findsOneWidget,
      );
      expect(remote.writes, 0);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'settings scroll to cache, cancellation is inert and defaults are persisted',
    (tester) async {
      var cleans = 0;
      final c = await pumpMamba(
        tester,
        cacheCleaner: () async {
          cleans++;
        },
        size: const Size(800, 450),
      );
      c.read(appRouterProvider).go('/settings');
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byKey(const Key('setting-cache')),
        220,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(find.byKey(const Key('setting-cache')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('dialog-cancel')));
      await tester.pumpAndSettle();
      expect(cleans, 0);
      await tester.tap(find.byKey(const Key('setting-cache')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('dialog-confirm')));
      await tester.pumpAndSettle();
      expect(cleans, 1);
      expect(find.byKey(const Key('settings-message')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'folder navigation returns to its tab and settings can reenter after a long scroll',
    (tester) async {
      final remote = FakeLibraryRepository();
      remote.pages['first'] = PageSlice(
        items: [
          LibraryEntry(
            key: 'folder:1',
            video: libraryVideo('folder'),
            folderId: '1',
          ),
        ],
      );
      final sessions = MemorySessionRepository(
        const Session(
          ownerKey: 'user:101',
          status: SessionStatus.authenticated,
        ),
      );
      final c = await pumpMamba(
        tester,
        sessions: sessions,
        library: remote,
        size: const Size(800, 450),
      );
      c.read(appRouterProvider).push<void>('/library/records');
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('library-tab-2')));
      await tester.pumpAndSettle();
      await press(tester, LogicalKeyboardKey.arrowDown);
      await press(tester, LogicalKeyboardKey.select);
      expect(remote.calls.last.$2, LibrarySection.folder);
      await press(tester, LogicalKeyboardKey.goBack);
      expect(remote.calls.last.$2, LibrarySection.folders);
      expect(FocusManager.instance.primaryFocus?.debugLabel, 'library-tab-2');
      await press(tester, LogicalKeyboardKey.goBack);
      c.read(appRouterProvider).go('/settings');
      await tester.pumpAndSettle();
      await press(tester, LogicalKeyboardKey.arrowLeft);
      await press(tester, LogicalKeyboardKey.arrowRight);
      for (var i = 0; i < 8; i++) {
        await press(tester, LogicalKeyboardKey.arrowDown);
      }
      expect(FocusManager.instance.primaryFocus?.debugLabel, 'setting-8');
      await press(tester, LogicalKeyboardKey.arrowLeft);
      await press(tester, LogicalKeyboardKey.arrowRight);
      expect(FocusManager.instance.primaryFocus?.debugLabel, 'setting-0');
      expect(tester.takeException(), isNull);
    },
  );
}
