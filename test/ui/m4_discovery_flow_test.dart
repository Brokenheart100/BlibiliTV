import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mambatv/core/result.dart';
import 'package:mambatv/data/repositories/fake_catalog_repository.dart';
import 'package:mambatv/domain/entities/app_models.dart';
import 'package:mambatv/domain/playback/playback.dart';

import '../support/app_harness.dart';
import '../support/fake_playback.dart';
import '../support/memory_search_history.dart';
import 'player_page_test.dart' show playerBack;
import 'tv_shell_test.dart' show press;

class SearchAttempt {
  SearchAttempt(this.query, this.signal);
  final String query;
  final CancellationSignal signal;
  final result = Completer<Result<PageSlice<VideoSummary>>>();
}

class SearchRaceCatalog extends FakeCatalogRepository {
  SearchRaceCatalog() : super(latency: Duration.zero);
  final attempts = <SearchAttempt>[];
  @override
  Future<Result<PageSlice<VideoSummary>>> fetchVideos({
    required String section,
    required String ownerKey,
    String query = '',
    String? cursor,
    int limit = 12,
    bool forceRefresh = false,
    required CancellationSignal cancellation,
  }) {
    if (section != 'search' || query.isEmpty) {
      return super.fetchVideos(
        section: section,
        ownerKey: ownerKey,
        query: query,
        cancellation: cancellation,
        cursor: cursor,
        limit: limit,
      );
    }
    final attempt = SearchAttempt(query, cancellation);
    attempts.add(attempt);
    return attempt.result.future;
  }
}

class LongDetailCatalog extends FakeCatalogRepository {
  LongDetailCatalog({this.failRelated = false}) : super(latency: Duration.zero);
  bool failRelated;
  @override
  Future<Result<VideoDetail>> getVideo(
    String id, {
    required String ownerKey,
    required CancellationSignal cancellation,
  }) async => Success(
    VideoDetail(
      video: FakeCatalogRepository.videos.first,
      description: '这是一段完整简介。' * 30,
      parts: List.generate(
        40,
        (i) => VideoPart(
          id: 'part-$i',
          title: '第 ${i + 1} 集',
          durationSeconds: 120,
        ),
      ),
    ),
  );
  @override
  Future<Result<List<VideoSummary>>> getRelated(
    String id, {
    required String ownerKey,
    required CancellationSignal cancellation,
  }) async => failRelated
      ? const ResultFailure(AppFailure(FailureKind.network, '合成网络故障'))
      : Success(FakeCatalogRepository.videos.skip(1).take(6).toList());
}

Future<void> openSearch(WidgetTester tester) async {
  await press(tester, LogicalKeyboardKey.arrowDown);
  await press(tester, LogicalKeyboardKey.select);
}

void main() {
  testWidgets(
    'an IME composing range must be committed before a search is sent',
    (tester) async {
      final catalog = SearchRaceCatalog();
      await pumpMamba(tester, catalog: catalog);
      await openSearch(tester);
      await tester.tap(find.byType(TextField));
      tester.testTextInput.updateEditingValue(
        const TextEditingValue(
          text: '中文',
          composing: TextRange(start: 0, end: 2),
        ),
      );
      await tester.pump();
      await tester.tap(find.byKey(const Key('search-submit')));
      await tester.pump();
      expect(catalog.attempts, isEmpty);
      tester.testTextInput.updateEditingValue(
        const TextEditingValue(text: '中文'),
      );
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pump();
      expect(catalog.attempts.single.query, '中文');
      catalog.attempts.single.result.complete(
        Success(PageSlice(items: const [])),
      );
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
    },
  );
  testWidgets('a late search A cannot replace B', (tester) async {
    final catalog = SearchRaceCatalog();
    await pumpMamba(tester, catalog: catalog);
    await openSearch(tester);
    await tester.enterText(find.byType(TextField), 'A');
    expect(catalog.attempts, isEmpty);
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'B');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pump();
    expect(catalog.attempts.map((r) => r.query), ['A', 'B']);
    expect(catalog.attempts.first.signal.isCancelled, isTrue);
    catalog.attempts.last.result.complete(
      Success(
        PageSlice(
          items: [
            FakeCatalogRepository.videos.first.copyWith(title: 'B 的有效结果'),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    catalog.attempts.first.result.complete(
      Success(
        PageSlice(
          items: [
            FakeCatalogRepository.videos.first.copyWith(title: 'A 的过期结果'),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('B 的有效结果'), findsOneWidget);
    expect(find.text('A 的过期结果'), findsNothing);
  });
  testWidgets('Chinese submission, history reuse and clear work at 800x450', (
    tester,
  ) async {
    final history = MemorySearchHistoryRepository();
    await pumpMamba(tester, size: const Size(800, 450), history: history);
    await openSearch(tester);
    await tester.enterText(find.byType(TextField), '山海');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    expect(history.entries['guest'], ['山海']);
    await tester.tap(find.byKey(const Key('search-history-0')));
    await tester.pumpAndSettle();
    expect(history.entries['guest'], ['山海']);
    await tester.tap(find.byKey(const Key('search-history-clear')));
    await tester.pumpAndSettle();
    expect(history.entries['guest'], isNull);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'native keyboard insets do not overflow and dismissal restores submit focus',
    (tester) async {
      await pumpMamba(tester, size: const Size(800, 450));
      await openSearch(tester);
      await tester.tap(find.byType(TextField));
      await tester.pump();
      tester.view.viewInsets = const FakeViewPadding(bottom: 260);
      await tester.pumpAndSettle();
      expect(find.text('确认关键词后，按键盘上的搜索键'), findsOneWidget);
      expect(tester.takeException(), isNull);
      tester.view.viewInsets = FakeViewPadding.zero;
      await tester.pumpAndSettle();
      expect(FocusManager.instance.primaryFocus?.debugLabel, 'search-submit');
      addTearDown(tester.view.resetViewInsets);
    },
  );
  testWidgets(
    'long part list is remote-navigable and related errors do not block playback',
    (tester) async {
      final catalog = LongDetailCatalog(failRelated: true);
      final engines = FakeEngineFactory();
      await pumpMamba(
        tester,
        catalog: catalog,
        engines: engines,
        size: const Size(800, 450),
      );
      await press(tester, LogicalKeyboardKey.arrowRight);
      await press(tester, LogicalKeyboardKey.select);
      expect(find.byKey(const Key('detail-play')), findsOneWidget);
      await press(tester, LogicalKeyboardKey.arrowDown);
      for (var i = 0; i < 12; i++) {
        await press(tester, LogicalKeyboardKey.arrowRight);
      }
      expect(
        FocusManager.instance.primaryFocus?.debugLabel,
        'detail-part-part-12',
      );
      await press(tester, LogicalKeyboardKey.arrowDown);
      expect(FocusManager.instance.primaryFocus?.debugLabel, 'related-retry');
      catalog.failRelated = false;
      await press(tester, LogicalKeyboardKey.select);
      await press(tester, LogicalKeyboardKey.arrowUp);
      await press(tester, LogicalKeyboardKey.select);
      expect(engines.active, 1);
      await playerBack(tester);
      expect(engines.active, 0);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'continue action chooses the saved part; guest personal entry requests login',
    (tester) async {
      final catalog = LongDetailCatalog();
      final progress = MemoryProgressRepository();
      await progress.save(
        const WatchProgress(
          ownerKey: 'guest',
          videoId: 'demo-000',
          partId: 'part-1',
          position: Duration(seconds: 25),
          duration: Duration(minutes: 2),
        ),
      );
      await pumpMamba(tester, catalog: catalog, progress: progress);
      await press(tester, LogicalKeyboardKey.arrowRight);
      await press(tester, LogicalKeyboardKey.select);
      expect(find.text('继续播放 · P2 0:25'), findsOneWidget);
      await press(tester, LogicalKeyboardKey.arrowRight);
      await press(tester, LogicalKeyboardKey.select);
      expect(find.text('以游客继续探索'), findsOneWidget);
      await press(tester, LogicalKeyboardKey.goBack);
      expect(find.byType(AlertDialog), findsNothing);
    },
  );
}
