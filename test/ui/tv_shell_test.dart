import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mambatv/core/result.dart';
import 'package:mambatv/data/repositories/fake_catalog_repository.dart';
import 'package:mambatv/domain/entities/app_models.dart';
import 'package:mambatv/app/providers/ui_providers.dart';

import '../support/app_harness.dart';

Future<void> press(WidgetTester tester, LogicalKeyboardKey key) async {
  if (key == LogicalKeyboardKey.goBack) {
    await tester.binding.handlePopRoute();
  } else {
    await tester.sendKeyEvent(key);
  }
  await tester.pumpAndSettle();
}

class FailOnceCatalog extends FakeCatalogRepository {
  FailOnceCatalog() : super(latency: Duration.zero);
  int calls = 0;
  @override
  Future<Result<PageSlice<VideoSummary>>> fetchVideos({
    required String section,
    required String ownerKey,
    String query = '',
    String? cursor,
    int limit = 12,
    required CancellationSignal cancellation,
  }) {
    calls++;
    if (calls == 1) {
      return Future.value(
        const ResultFailure(AppFailure(FailureKind.network, '合成网络故障')),
      );
    }
    return super.fetchVideos(
      section: section,
      ownerKey: ownerKey,
      query: query,
      cursor: cursor,
      limit: limit,
      cancellation: cancellation,
    );
  }
}

class GatedCatalog extends FakeCatalogRepository {
  GatedCatalog() : super(latency: Duration.zero);
  final gate = Completer<void>();
  final signals = <CancellationSignal>[];
  @override
  Future<Result<PageSlice<VideoSummary>>> fetchVideos({
    required String section,
    required String ownerKey,
    String query = '',
    String? cursor,
    int limit = 12,
    required CancellationSignal cancellation,
  }) async {
    signals.add(cancellation);
    await gate.future;
    return super.fetchVideos(
      section: section,
      ownerKey: ownerKey,
      query: query,
      cursor: cursor,
      limit: limit,
      cancellation: cancellation,
    );
  }
}

void main() {
  testWidgets('background cancellation waits for foreground before reloading', (
    tester,
  ) async {
    final repository = GatedCatalog();
    final container = await pumpMamba(
      tester,
      catalog: repository,
      settle: false,
    );
    await tester.pump();
    container.read(appForegroundProvider.notifier).update(false);
    expect(repository.signals.single.isCancelled, isTrue);
    repository.gate.complete();
    await tester.pumpAndSettle();
    expect(repository.signals, hasLength(1));
    container.read(appForegroundProvider.notifier).update(true);
    await tester.pumpAndSettle();
    expect(repository.signals, hasLength(2));
    expect(find.byKey(const Key('video-demo-000')), findsOneWidget);
  });

  testWidgets(
    'D-pad opens a scrolled card and restores its stable ID on Back',
    (tester) async {
      await pumpMamba(tester);
      expect(FocusManager.instance.primaryFocus?.debugLabel, 'nav-0');
      await press(tester, LogicalKeyboardKey.arrowRight);
      expect(FocusManager.instance.primaryFocus?.debugLabel, 'video-demo-000');
      for (var i = 0; i < 3; i++) {
        await press(tester, LogicalKeyboardKey.arrowDown);
      }
      expect(FocusManager.instance.primaryFocus?.debugLabel, 'video-demo-009');
      await press(tester, LogicalKeyboardKey.select);
      expect(find.byKey(const Key('detail-play')), findsOneWidget);
      expect(FocusManager.instance.primaryFocus?.debugLabel, 'detail-play');
      // Android sends both the physical key and the platform route callback.
      await tester.sendKeyEvent(
        LogicalKeyboardKey.goBack,
        physicalKey: PhysicalKeyboardKey.escape,
      );
      await press(tester, LogicalKeyboardKey.goBack);
      expect(find.byType(AlertDialog), findsNothing);
      expect(FocusManager.instance.primaryFocus?.debugLabel, 'video-demo-009');
      await press(tester, LogicalKeyboardKey.arrowLeft);
      expect(FocusManager.instance.primaryFocus?.debugLabel, 'nav-0');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('D-pad can request another page and focus the first new card', (
    tester,
  ) async {
    await pumpMamba(tester);
    await press(tester, LogicalKeyboardKey.arrowRight);
    for (var i = 0; i < 4; i++) {
      await press(tester, LogicalKeyboardKey.arrowDown);
    }
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'grid-footer');
    await press(tester, LogicalKeyboardKey.select);
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'video-demo-012');
    expect(tester.takeException(), isNull);
  });

  testWidgets('dialog traps focus and Back restores its settings trigger', (
    tester,
  ) async {
    await pumpMamba(tester);
    for (var i = 0; i < 3; i++) {
      await press(tester, LogicalKeyboardKey.arrowDown);
    }
    await press(tester, LogicalKeyboardKey.select);
    await press(tester, LogicalKeyboardKey.arrowRight);
    await press(tester, LogicalKeyboardKey.arrowDown);
    await press(tester, LogicalKeyboardKey.arrowDown);
    final trigger = FocusManager.instance.primaryFocus;
    expect(trigger?.debugLabel, 'setting-2');
    await press(tester, LogicalKeyboardKey.select);
    expect(find.byType(AlertDialog), findsOneWidget);
    for (var i = 0; i < 5; i++) {
      await press(tester, LogicalKeyboardKey.tab);
      expect(
        FocusManager.instance.primaryFocus?.context
            ?.findAncestorWidgetOfExactType<AlertDialog>(),
        isNotNull,
      );
    }
    await press(tester, LogicalKeyboardKey.escape);
    expect(find.byType(AlertDialog), findsNothing);
    expect(FocusManager.instance.primaryFocus, trigger);
  });

  testWidgets(
    'error does not automatically retry and retry keeps focus reachable',
    (tester) async {
      final repository = FailOnceCatalog();
      await pumpMamba(tester, catalog: repository);
      expect(find.text('暂时没有加载成功'), findsOneWidget);
      await tester.pump(const Duration(seconds: 5));
      expect(repository.calls, 1);
      await press(tester, LogicalKeyboardKey.arrowRight);
      expect(
        FocusManager.instance.primaryFocus?.debugLabel,
        'catalog-empty-action',
      );
      await press(tester, LogicalKeyboardKey.select);
      expect(find.byKey(const Key('video-demo-000')), findsOneWidget);
      expect(FocusManager.instance.primaryFocus?.debugLabel, 'catalog-action');
    },
  );

  testWidgets('search and the empty library expose actionable states', (
    tester,
  ) async {
    await pumpMamba(tester);
    await press(tester, LogicalKeyboardKey.arrowDown);
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'nav-1');
    await press(tester, LogicalKeyboardKey.select);
    expect(find.byType(TextField), findsOneWidget);
    await press(tester, LogicalKeyboardKey.arrowRight);
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'search-input');
    await tester.enterText(find.byType(TextField), 'Flutter');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    expect(find.text('“Flutter”的搜索结果'), findsOneWidget);
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'search-submit');
    await press(tester, LogicalKeyboardKey.arrowLeft);
    await press(tester, LogicalKeyboardKey.arrowDown);
    await press(tester, LogicalKeyboardKey.select);
    await press(tester, LogicalKeyboardKey.arrowRight);
    await press(tester, LogicalKeyboardKey.select);
    expect(find.text('以游客继续探索'), findsOneWidget);
    await press(tester, LogicalKeyboardKey.goBack);
    expect(find.text('你的观看故事，从这里开始'), findsOneWidget);
    expect(FocusManager.instance.primaryFocus?.context, isNotNull);
  });

  testWidgets('root Back offers cancel and restores navigation focus', (
    tester,
  ) async {
    await pumpMamba(tester, size: const Size(800, 450));
    final previous = FocusManager.instance.primaryFocus;
    await press(tester, LogicalKeyboardKey.goBack);
    expect(find.text('退出 MambaTV？'), findsOneWidget);
    await press(tester, LogicalKeyboardKey.select);
    expect(find.byType(AlertDialog), findsNothing);
    expect(FocusManager.instance.primaryFocus, previous);
    expect(tester.takeException(), isNull);
  });
}
