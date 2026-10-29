import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mambatv/app/router.dart';
import 'package:mambatv/core/result.dart';
import 'package:mambatv/domain/discovery/content_search.dart';
import 'package:mambatv/domain/entities/app_models.dart';
import 'package:mambatv/data/repositories/memory_session_repository.dart';
import 'package:mambatv/ui/core/widgets/liquid_glass_card.dart';
import 'package:mambatv/ui/features/search/view_models/content_search_view_model.dart';
import 'package:mambatv/ui/features/search/content_search_results.dart';
import 'package:mambatv/ui/features/settings/view_models/settings_view_model.dart';

import '../support/app_harness.dart';
import '../support/fake_content_search.dart';
import '../support/fake_playback.dart';
import 'tv_shell_test.dart' show press;

Future<void> submit(WidgetTester tester, String query) async {
  await tester.enterText(find.byType(TextField), query);
  await tester.testTextInput.receiveAction(TextInputAction.search);
  await tester.pumpAndSettle();
}

Future<void> select(WidgetTester tester, SearchCategory type) async {
  await tester.tap(find.byKey(ValueKey('search-type-${type.name}')));
  await tester.pumpAndSettle();
}

class DelayedSearch extends FakeContentSearchRepository {
  final pending =
      <
        ({
          SearchCategory category,
          String query,
          CancellationSignal signal,
          Completer<Result<PageSlice<ContentSearchItem>>> result,
        })
      >[];
  @override
  Future<Result<PageSlice<ContentSearchItem>>> search({
    required SearchCategory category,
    required String query,
    required String ownerKey,
    required CancellationSignal cancellation,
    String? cursor,
    bool forceRefresh = false,
  }) {
    final result = Completer<Result<PageSlice<ContentSearchItem>>>();
    pending.add((
      category: category,
      query: query,
      signal: cancellation,
      result: result,
    ));
    return result.future;
  }
}

class FailingPageSearch extends FakeContentSearchRepository {
  bool fail = true;
  @override
  Future<Result<PageSlice<ContentSearchItem>>> search({
    required SearchCategory category,
    required String query,
    required String ownerKey,
    required CancellationSignal cancellation,
    String? cursor,
    bool forceRefresh = false,
  }) {
    if (cursor != null && fail) {
      return Future.value(
        const ResultFailure(AppFailure(FailureKind.network, '合成分页故障')),
      );
    }
    return super.search(
      category: category,
      query: query,
      ownerKey: ownerKey,
      cancellation: cancellation,
      cursor: cursor,
      forceRefresh: forceRefresh,
    );
  }
}

void main() {
  testWidgets(
    'one search retains keyword and video filters across types, with typed navigation and bookmark',
    (tester) async {
      final repository = FakeContentSearchRepository();
      final container = await pumpMamba(tester, contentSearch: repository);
      await tester.tap(find.byKey(const Key('nav-1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('search-order')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('search-filter-apply')));
      await tester.pumpAndSettle();
      await submit(tester, '山海');
      await select(tester, SearchCategory.bangumi);
      expect(repository.calls.single.query, '山海');
      expect(find.byKey(const Key('search-order')), findsNothing);
      await press(tester, LogicalKeyboardKey.arrowDown);
      expect(FocusManager.instance.primaryFocus?.debugLabel, 'video-season:10');
      await press(tester, LogicalKeyboardKey.select);
      expect(container.read(appRouterProvider).state.uri.path, '/season/10');
      await press(tester, LogicalKeyboardKey.goBack);
      expect(FocusManager.instance.primaryFocus?.debugLabel, 'video-season:10');
      await select(tester, SearchCategory.cinema);
      expect(find.text('山海 影视 10'), findsOneWidget);
      await select(tester, SearchCategory.video);
      expect(find.text('排序 · 最新发布'), findsOneWidget);
      expect(find.text('“山海”的搜索结果'), findsOneWidget);
      await select(tester, SearchCategory.bangumi);
      expect(
        repository.calls
            .where((call) => call.category == SearchCategory.bangumi)
            .length,
        2,
      );
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'live results enter a live target and ended rooms never start another engine',
    (tester) async {
      final engines = FakeEngineFactory();
      final container = await pumpMamba(tester, engines: engines);
      await tester.tap(find.byKey(const Key('nav-1')));
      await tester.pumpAndSettle();
      await submit(tester, '主播');
      await select(tester, SearchCategory.live);
      await press(tester, LogicalKeyboardKey.arrowDown);
      await press(tester, LogicalKeyboardKey.select);
      expect(
        container.read(appRouterProvider).state.uri.path,
        '/watch/live/10',
      );
      await tester.tap(find.byKey(const Key('player-back')));
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pumpAndSettle();
      expect(FocusManager.instance.primaryFocus?.debugLabel, 'video-live:10');
      await press(tester, LogicalKeyboardKey.arrowRight);
      await press(tester, LogicalKeyboardKey.select);
      expect(container.read(appRouterProvider).state.uri.path, '/search');
      expect(find.text('主播当前未开播'), findsOneWidget);
    },
  );
  testWidgets(
    'pagination stays category-scoped and clicking a type refreshes page one',
    (tester) async {
      final repository = FakeContentSearchRepository();
      final container = await pumpMamba(tester, contentSearch: repository);
      await tester.tap(find.byKey(const Key('nav-1')));
      await tester.pumpAndSettle();
      await submit(tester, '测试');
      await select(tester, SearchCategory.cinema);
      final provider = contentSearchViewModelProvider(
        category: SearchCategory.cinema,
        query: '测试',
        scopeKey: 'guest:0',
      );
      await container.read(provider.notifier).loadMore();
      await tester.pumpAndSettle();
      expect(container.read(provider).value!.items.length, 40);
      expect(repository.calls.last.cursor, 'cinema:2');
      final scroll = tester.state<ScrollableState>(
        find.descendant(
          of: find.byType(ContentSearchResults),
          matching: find.byType(Scrollable),
        ),
      );
      scroll.position.jumpTo(scroll.position.maxScrollExtent);
      await tester.pumpAndSettle();
      await select(tester, SearchCategory.cinema);
      expect(container.read(provider).value!.items.length, 20);
      expect(scroll.position.pixels, 0);
      await container.read(provider.notifier).loadMore();
      await tester.pumpAndSettle();
      await select(tester, SearchCategory.bangumi);
      await select(tester, SearchCategory.cinema);
      expect(container.read(provider).value!.items.length, 20);
      expect(repository.calls.length, 6);
      expect(repository.calls.last.refresh, true);
    },
  );
  testWidgets('late requests cannot replace another category or keyword', (
    tester,
  ) async {
    final repository = DelayedSearch();
    await pumpMamba(tester, contentSearch: repository);
    await tester.tap(find.byKey(const Key('nav-1')));
    await tester.pumpAndSettle();
    await submit(tester, 'A');
    await tester.tap(find.byKey(const Key('search-type-bangumi')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('search-type-cinema')));
    await tester.pump();
    expect(repository.pending.first.signal.isCancelled, true);
    repository.pending[1].result.complete(
      Success(
        PageSlice(
          items: const [
            ContentSearchItem.season(
              seasonId: '1',
              title: '有效影视',
              subtitle: '电影',
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    repository.pending[0].result.complete(
      Success(
        PageSlice(
          items: const [
            ContentSearchItem.season(
              seasonId: '2',
              title: '过期番剧',
              subtitle: '番剧',
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('有效影视'), findsOneWidget);
    expect(find.text('过期番剧'), findsNothing);
    await tester.enterText(find.byType(TextField), 'B');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'C');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pump();
    expect(repository.pending[2].signal.isCancelled, true);
    repository.pending[3].result.complete(
      Success(
        PageSlice(
          items: const [
            ContentSearchItem.season(
              seasonId: '3',
              title: 'C 的有效结果',
              subtitle: '电影',
            ),
          ],
        ),
      ),
    );
    repository.pending[2].result.complete(Success(PageSlice(items: const [])));
    await tester.pumpAndSettle();
    expect(find.text('C 的有效结果'), findsOneWidget);
  });
  testWidgets(
    'a failed next page retains results and a retry can complete it',
    (tester) async {
      final repository = FailingPageSearch();
      final container = await pumpMamba(tester, contentSearch: repository);
      await tester.tap(find.byKey(const Key('nav-1')));
      await tester.pumpAndSettle();
      await submit(tester, '测试');
      await select(tester, SearchCategory.bangumi);
      final provider = contentSearchViewModelProvider(
        category: SearchCategory.bangumi,
        query: '测试',
        scopeKey: 'guest:0',
      );
      await container.read(provider.notifier).loadMore();
      await tester.pumpAndSettle();
      expect(container.read(provider).value!.items.length, 20);
      expect(container.read(provider).value!.loadMoreFailed, true);
      expect(find.text('测试 番剧 10'), findsOneWidget);
      repository.fail = false;
      await container.read(provider.notifier).loadMore();
      await tester.pumpAndSettle();
      expect(container.read(provider).value!.items.length, 40);
      expect(container.read(provider).value!.loadMoreFailed, false);
    },
  );
  testWidgets(
    'account generation change cancels the old search and never shows its response',
    (tester) async {
      final repository = DelayedSearch(), sessions = MemorySessionRepository();
      await pumpMamba(tester, contentSearch: repository, sessions: sessions);
      await tester.tap(find.byKey(const Key('nav-1')));
      await tester.pumpAndSettle();
      await submit(tester, 'A');
      await tester.tap(find.byKey(const Key('search-type-bangumi')));
      await tester.pump();
      sessions.replace(
        const Session(
          ownerKey: 'B',
          generation: 1,
          status: SessionStatus.authenticated,
        ),
      );
      await tester.pumpAndSettle();
      expect(repository.pending.single.signal.isCancelled, true);
      repository.pending.single.result.complete(
        Success(
          PageSlice(
            items: const [
              ContentSearchItem.season(
                seasonId: '1',
                title: '旧账号结果',
                subtitle: '番剧',
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('旧账号结果'), findsNothing);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        isEmpty,
      );
      expect(tester.takeException(), isNull);
    },
  );
  for (final size in [const Size(640, 360), const Size(960, 540)]) {
    for (final theme in [AppTheme.dark, AppTheme.light]) {
      testWidgets(
        'all tab rails and sidebar have bounded glass at $size $theme with reduced motion',
        (tester) async {
          final container = await pumpMamba(tester, size: size);
          final settings = container
              .read(settingsViewModelProvider)
              .value!
              .settings;
          await container
              .read(settingsViewModelProvider.notifier)
              .savePreferences(
                settings.copyWith(theme: theme, reducedMotion: true),
              );
          await tester.pumpAndSettle();
          expect(
            find.descendant(
              of: find.byKey(const Key('home-pill-tabs')),
              matching: find.byType(LiquidGlassCard),
            ),
            findsWidgets,
          );
          expect(
            find.descendant(
              of: find.byKey(const Key('icon-navigation-rail')),
              matching: find.byType(LiquidGlassCard),
            ),
            findsOneWidget,
          );
          await press(tester, LogicalKeyboardKey.arrowDown);
          await press(tester, LogicalKeyboardKey.arrowDown);
          await press(tester, LogicalKeyboardKey.arrowDown);
          await press(tester, LogicalKeyboardKey.select);
          await submit(tester, '测试');
          for (final category in SearchCategory.values) {
            await select(tester, category);
            expect(tester.takeException(), isNull);
          }
          await select(tester, SearchCategory.video);
          await press(tester, LogicalKeyboardKey.arrowLeft);
          expect(FocusManager.instance.primaryFocus?.debugLabel, 'nav-1');
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
