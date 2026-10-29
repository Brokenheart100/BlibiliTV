import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mambatv/app/router.dart';
import 'package:mambatv/core/result.dart';
import 'package:mambatv/data/repositories/fake_catalog_repository.dart';
import 'package:mambatv/data/repositories/memory_session_repository.dart';
import 'package:mambatv/domain/entities/app_models.dart';
import 'package:mambatv/domain/playback/content_playback.dart';
import 'package:mambatv/ui/features/video_detail/video_detail_page.dart';
import 'package:mambatv/ui/features/video_detail/view_models/video_detail_view_model.dart';
import 'package:mambatv/ui/features/settings/view_models/settings_view_model.dart';

import '../support/app_harness.dart';
import '../support/fake_content.dart';
import '../support/fake_content_search.dart';
import '../support/fake_personal_home.dart';
import 'tv_shell_test.dart' show press;

class FactsSeason extends FakePgcRepository {
  int calls = 0;
  @override
  Future<Result<ContentSeason>> season(
    String id,
    CancellationSignal signal,
  ) async {
    calls++;
    final original = (await super.season(id, signal)).valueOrThrow;
    return Success(
      ContentSeason(
        id: id,
        title: '甘城光辉游乐园',
        description: '真实字段布局验证。' * 200,
        episodes: original.episodes,
        groups: {
          'SP': [
            const ContentEpisode(
              id: '101',
              title: '特别篇',
              cid: '1001',
              bvid: 'BVsp',
            ),
          ],
        },
        facts: SeasonFacts(
          score: 9.7,
          ratingCount: 34657,
          views: 79501303,
          danmaku: 1653208,
          followText: '348.2万系列追番',
          published: '2014年10月06日',
          status: '已完结, 全30话',
          tags: const ['日常', '奇幻', '励志', '职场'],
          actors: List.generate(20, (i) => '角色$i：配音$i').join('\n'),
          staff: '导演：合成人员',
        ),
      ),
    );
  }
}

class RefreshCatalog extends FakeCatalogRepository {
  RefreshCatalog() : super(latency: Duration.zero);
  final calls = <({String section, bool refresh})>[];
  @override
  Future<Result<PageSlice<VideoSummary>>> fetchVideos({
    required String section,
    required String ownerKey,
    String query = '',
    CatalogOptions options = const CatalogOptions(),
    String? cursor,
    int limit = 12,
    bool forceRefresh = false,
    required CancellationSignal cancellation,
  }) {
    calls.add((section: section, refresh: forceRefresh));
    return super.fetchVideos(
      section: section,
      ownerKey: ownerKey,
      query: query,
      options: options,
      cursor: cursor,
      limit: limit,
      forceRefresh: forceRefresh,
      cancellation: cancellation,
    );
  }
}

class DiscoveryCatalog extends FakeCatalogRepository {
  DiscoveryCatalog() : super(latency: Duration.zero);
  bool entered = false, fail = false;
  final cursors = <String?>[];
  @override
  Future<Result<List<VideoSummary>>> getRelated(
    String id, {
    required String ownerKey,
    required CancellationSignal cancellation,
  }) async {
    entered = true;
    return Success(FakeCatalogRepository.videos.skip(1).take(12).toList());
  }

  @override
  Future<Result<PageSlice<VideoSummary>>> fetchVideos({
    required String section,
    required String ownerKey,
    String query = '',
    CatalogOptions options = const CatalogOptions(),
    String? cursor,
    int limit = 12,
    bool forceRefresh = false,
    required CancellationSignal cancellation,
  }) async {
    if (!entered) {
      return super.fetchVideos(
        section: section,
        ownerKey: ownerKey,
        cancellation: cancellation,
      );
    }
    cursors.add(cursor);
    if (fail) {
      return const ResultFailure(AppFailure(FailureKind.network, '合成续载故障'));
    }
    return Success(
      PageSlice(
        items: FakeCatalogRepository.videos
            .skip(cursor == null ? 0 : 24)
            .take(24)
            .toList(),
        nextCursor: cursor == null ? 'next' : null,
      ),
    );
  }
}

void main() {
  testWidgets('season supports keyboard and platform Back without exiting', (
    tester,
  ) async {
    final container = await pumpMamba(tester, pgc: FactsSeason());
    container.read(appRouterProvider).push<void>('/season/281');
    await tester.pumpAndSettle();
    await press(tester, LogicalKeyboardKey.goBack);
    expect(find.byKey(const Key('season-title')), findsNothing);
    expect(find.text('退出 MambaTV？'), findsNothing);
    container.read(appRouterProvider).push<void>('/season/281');
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('season-title')), findsNothing);
    expect(find.text('退出 MambaTV？'), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'detail discovery is a lazy vertical grid and scrolling requests unique continuation automatically',
    (tester) async {
      final catalog = DiscoveryCatalog();
      final container = await pumpMamba(tester, catalog: catalog);
      container.read(appRouterProvider).push<void>('/video/demo-000');
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('detail-scroll')), findsOneWidget);
      await tester.drag(
        find.byKey(const Key('detail-scroll')),
        const Offset(0, -2200),
      );
      await tester.pumpAndSettle();
      expect(catalog.cursors, isNotEmpty);
      expect(find.byType(SliverGrid), findsOneWidget);
      final page = tester.widget<VideoDetailPage>(find.byType(VideoDetailPage));
      final state = container
          .read(
            detailDiscoveryProvider(
              id: page.id,
              pageId: page.pageId,
              ownerKey: 'guest',
              scopeKey: 'guest:0',
            ),
          )
          .value!;
      expect(state.items.length, greaterThan(12));
      expect(state.items.map((e) => e.id).toSet().length, state.items.length);
      expect(state.items.any((e) => e.id == 'demo-000'), false);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'continuation failure retains related items and retries the same cursor',
    (tester) async {
      final catalog = DiscoveryCatalog()..fail = true;
      final container = await pumpMamba(tester, catalog: catalog);
      final provider = detailDiscoveryProvider(
        id: 'demo-000',
        pageId: 'direct',
        ownerKey: 'guest',
        scopeKey: 'guest:0',
      );
      final subscription = container.listen(provider, (_, _) {});
      addTearDown(subscription.close);
      await container.read(provider.future);
      await container.read(provider.notifier).loadMore();
      expect(container.read(provider).value!.items.length, 12);
      expect(container.read(provider).value!.loadMoreFailed, true);
      catalog.fail = false;
      await container.read(provider.notifier).loadMore();
      expect(catalog.cursors, [null, null]);
      expect(container.read(provider).value!.items.length, 23);
    },
  );
  testWidgets(
    'a discovery request from an obsolete account generation is refused before transport',
    (tester) async {
      final catalog = DiscoveryCatalog();
      final container = await pumpMamba(tester, catalog: catalog);
      final provider = detailDiscoveryProvider(
        id: 'demo-000',
        pageId: 'stale',
        ownerKey: 'guest',
        scopeKey: 'guest:99',
      );
      final subscription = container.listen(provider, (_, _) {});
      addTearDown(subscription.close);
      await expectLater(
        container.read(provider.future),
        throwsA(
          isA<AppFailure>().having(
            (f) => f.kind,
            'kind',
            FailureKind.cancelled,
          ),
        ),
      );
      expect(catalog.entered, false);
    },
  );
  testWidgets(
    'clicking home, search and personal tabs refreshes the selected content and keeps tab focus',
    (tester) async {
      final catalog = RefreshCatalog(), search = FakeContentSearchRepository();
      final personal = FakePersonalHomeRepository();
      final sessions = MemorySessionRepository(
        const Session(ownerKey: 'user:7', status: SessionStatus.authenticated),
      );
      await pumpMamba(
        tester,
        catalog: catalog,
        contentSearch: search,
        personalHome: personal,
        sessions: sessions,
      );
      final before = catalog.calls.length;
      await tester.tap(find.byKey(const Key('feed-recommendation')));
      await tester.pumpAndSettle();
      expect(catalog.calls.length, before + 1);
      expect(catalog.calls.last.refresh, true);
      await tester.tap(find.byKey(const Key('feed-recommendation')));
      await tester.pumpAndSettle();
      expect(catalog.calls.length, before + 2);
      expect(catalog.calls.last.refresh, true);
      await tester.tap(find.byKey(const Key('nav-1')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '测试');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();
      for (var i = 0; i < 2; i++) {
        await tester.tap(find.byKey(const Key('search-type-bangumi')));
        await tester.pumpAndSettle();
      }
      expect(search.calls.length, 2);
      expect(search.calls.every((call) => call.refresh), true);
      expect(
        FocusManager.instance.primaryFocus?.debugLabel,
        'search-type-bangumi',
      );
      await tester.tap(find.byKey(const Key('nav-2')));
      await tester.pumpAndSettle();
      final count = personal.calls.length;
      await tester.tap(find.byKey(const Key('personal-submissions')));
      await tester.pumpAndSettle();
      expect(personal.calls.length, count + 1);
      expect(
        FocusManager.instance.primaryFocus?.debugLabel,
        'personal-tab-submissions',
      );
    },
  );
  testWidgets(
    'full season description scrolls by D-pad and closes with focus restored',
    (tester) async {
      final container = await pumpMamba(tester, pgc: FactsSeason());
      container.read(appRouterProvider).push<void>('/season/281');
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('season-description')));
      await tester.tap(find.byKey(const Key('season-description')));
      await tester.pumpAndSettle();
      final reader = tester
          .widget<SingleChildScrollView>(
            find.descendant(
              of: find.byType(AlertDialog),
              matching: find.byType(SingleChildScrollView),
            ),
          )
          .controller!;
      await press(tester, LogicalKeyboardKey.arrowDown);
      expect(reader.offset, greaterThan(0));
      await press(tester, LogicalKeyboardKey.select);
      expect(find.byType(AlertDialog), findsNothing);
      expect(FocusManager.instance.primaryFocus?.context, isNotNull);
      expect(tester.takeException(), isNull);
    },
  );
  for (final size in [const Size(640, 360), const Size(960, 540)]) {
    for (final theme in [AppTheme.dark, AppTheme.light]) {
      testWidgets(
        'season hero, real facts, grouped grid and refreshed tabs fit $size $theme',
        (tester) async {
          final pgc = FactsSeason();
          final container = await pumpMamba(tester, size: size, pgc: pgc);
          final settings = container
              .read(settingsViewModelProvider)
              .value!
              .settings;
          await container
              .read(settingsViewModelProvider.notifier)
              .savePreferences(settings.copyWith(theme: theme));
          await tester.pumpAndSettle();
          container.read(appRouterProvider).push<void>('/season/281');
          await tester.pumpAndSettle();
          expect(find.text('9.7'), findsOneWidget);
          expect(find.text('7950.1万'), findsOneWidget);
          expect(find.text('348.2万'), findsOneWidget);
          expect(find.text('165.3万'), findsOneWidget);
          expect(find.byKey(const Key('season-episodes')), findsOneWidget);
          expect(find.byType(GridView), findsOneWidget);
          expect(FocusManager.instance.primaryFocus?.debugLabel, 'season-play');
          expect(
            tester.getTopLeft(find.byKey(const Key('season-title'))).dy,
            greaterThanOrEqualTo(0),
          );
          await press(tester, LogicalKeyboardKey.arrowDown);
          await press(tester, LogicalKeyboardKey.arrowDown);
          expect(FocusManager.instance.primaryFocus?.debugLabel, 'episode-1');
          await press(tester, LogicalKeyboardKey.arrowDown);
          expect(
            FocusManager.instance.primaryFocus?.debugLabel,
            contains('episode-'),
          );
          await tester.ensureVisible(find.byKey(const Key('season-group-1')));
          await tester.tap(find.byKey(const Key('season-group-1')));
          await tester.pumpAndSettle();
          expect(find.byKey(const Key('episode-101')), findsOneWidget);
          expect(find.byKey(const Key('episode-1')), findsNothing);
          expect(pgc.calls, 2);
          await tester.ensureVisible(find.byKey(const Key('season-tab-2')));
          await tester.tap(find.byKey(const Key('season-tab-2')));
          await tester.pumpAndSettle();
          expect(find.text('制作人员'), findsOneWidget);
          expect(pgc.calls, 3);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
