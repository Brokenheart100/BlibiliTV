import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mambatv/core/result.dart';
import 'package:mambatv/app/router.dart';
import 'package:mambatv/data/repositories/memory_session_repository.dart';
import 'package:mambatv/domain/entities/app_models.dart';
import 'package:mambatv/domain/library/library.dart';
import 'package:mambatv/domain/library/personal_home.dart';
import 'package:mambatv/ui/core/widgets/tv_pill_tabs.dart';

import '../support/app_harness.dart';
import '../support/fake_library.dart';
import '../support/fake_personal_home.dart';
import 'tv_shell_test.dart' show press;

void main() {
  testWidgets(
    'my page shows profile and typed collections, opens folders and isolates logout',
    (tester) async {
      final sessions = MemorySessionRepository(
        const Session(
          ownerKey: 'user:7',
          displayName: '我的账号',
          status: SessionStatus.authenticated,
        ),
      );
      final repo = FakePersonalHomeRepository(session: () => sessions.current)
        ..profileValue = const PersonalProfile(mid: 7, name: '我的账号')
        ..pages['submissions'] = PageSlice(
          items: [PersonalVideo(libraryVideo('demo-000'))],
        )
        ..pages['folders'] = PageSlice(
          items: [const PersonalFolder(id: '9', title: '我的收藏', count: 3)],
        )
        ..pages['bangumi'] = PageSlice(
          items: [
            const PersonalSeason(
              id: 10,
              title: '我的番剧',
              subtitle: '更新至第 5 话',
              progress: '看到第 2 话',
            ),
          ],
        )
        ..pages['drama'] = PageSlice(
          items: [
            const PersonalSeason(id: 11, title: '我的追剧', subtitle: '全 12 集'),
          ],
        );
      final library = FakeLibraryRepository();
      final container = await pumpMamba(
        tester,
        sessions: sessions,
        personalHome: repo,
        library: library,
      );
      container.read(appRouterProvider).go('/library');
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('account-avatar')), findsOneWidget);
      expect(find.byType(TvCapsuleTabs<PersonalSection>), findsOneWidget);
      expect(find.text('我的账号'), findsOneWidget);
      await tester.tap(find.byKey(const Key('nav-2')));
      await tester.pumpAndSettle();
      await press(tester, LogicalKeyboardKey.arrowRight);
      for (var i = 0; i < 5; i++) {
        await press(tester, LogicalKeyboardKey.arrowRight);
      }
      expect(
        FocusManager.instance.primaryFocus?.debugLabel,
        'personal-refresh',
      );
      expect(find.text('合成视频 demo-000'), findsOneWidget);
      await tester.tap(find.byKey(const Key('personal-folders')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('personal-item-folder:9')));
      await tester.pumpAndSettle();
      expect(library.calls.last.$2, LibrarySection.folder);
      expect(
        container.read(appRouterProvider).state.uri.path,
        '/library/folder/9',
      );
      await press(tester, LogicalKeyboardKey.goBack);
      await press(tester, LogicalKeyboardKey.goBack);
      await tester.tap(find.byKey(const Key('personal-bangumi')));
      await tester.pumpAndSettle();
      expect(find.text('我的番剧'), findsOneWidget);
      await tester.tap(find.byKey(const Key('personal-item-season:10')));
      await tester.pumpAndSettle();
      expect(container.read(appRouterProvider).state.uri.path, '/season/10');
      expect(find.byKey(const Key('episode-1')), findsOneWidget);
      await press(tester, LogicalKeyboardKey.goBack);
      await tester.tap(find.byKey(const Key('personal-drama')));
      await tester.pumpAndSettle();
      expect(find.text('我的追剧'), findsOneWidget);
      sessions.replace(const Session(generation: 1));
      await tester.pumpAndSettle();
      expect(find.text('我的追剧'), findsNothing);
      expect(find.byKey(const Key('account-avatar')), findsNothing);
      expect(find.text('你的观看故事，从这里开始'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('history rail has local and Bilibili history with D-pad return', (
    tester,
  ) async {
    final container = await pumpMamba(tester);
    await tester.tap(find.byKey(const Key('nav-4')));
    await tester.pumpAndSettle();
    expect(container.read(appRouterProvider).state.uri.path, '/history');
    expect(find.text('历史记录'), findsOneWidget);
    expect(find.text('本地观看'), findsOneWidget);
    expect(find.text('B站历史'), findsOneWidget);
    expect(find.text('收藏夹'), findsNothing);
    await press(tester, LogicalKeyboardKey.arrowRight);
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'library-tab-0');
    await press(tester, LogicalKeyboardKey.arrowLeft);
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'nav-4');
    expect(tester.takeException(), isNull);
  });
  for (final size in [const Size(640, 360), const Size(960, 540)]) {
    testWidgets('authenticated profile fits $size', (tester) async {
      final sessions = MemorySessionRepository(
        const Session(
          ownerKey: 'user:1',
          displayName: '很长很长很长的昵称也需要正常显示',
          status: SessionStatus.authenticated,
        ),
      );
      final container = await pumpMamba(tester, size: size, sessions: sessions);
      container.read(appRouterProvider).go('/library');
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('personal-bangumi')), findsOneWidget);
      await tester.tap(find.byKey(const Key('nav-theme')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
