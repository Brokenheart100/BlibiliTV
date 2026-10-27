import 'dart:async';

import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:media_kit/media_kit.dart';
import 'package:mambatv/app/app.dart';
import 'package:mambatv/app/bootstrap.dart';
import 'package:mambatv/app/providers/infrastructure_providers.dart';
import 'package:mambatv/app/providers/playback_providers.dart';
import 'package:mambatv/app/providers/repository_providers.dart';
import 'package:mambatv/app/router.dart';
import 'package:mambatv/data/repositories/local_search_history_repository.dart';
import 'package:mambatv/data/repositories/memory_session_repository.dart';
import 'package:mambatv/data/services/local/app_database.dart';
import 'package:mambatv/ui/core/images/tv_image_cache.dart';
import 'package:mambatv/ui/core/widgets/tv_button.dart';
import 'package:mambatv/ui/features/catalog/view_models/catalog_view_model.dart';
import 'package:mambatv/ui/features/player/view_models/player_view_model.dart';
import 'package:mambatv/ui/features/player/views/player_page.dart';
import 'package:mambatv/ui/features/video_detail/video_detail_page.dart';
import 'package:mambatv/ui/features/video_detail/view_models/video_detail_view_model.dart';
import 'package:mambatv/data/services/playback/media_kit_engine.dart';

import 'm2_playback_flow_test.dart' show NativeEngineTracker;

class M4EngineTracker extends NativeEngineTracker {
  @override
  PlaybackAdapter get adapter {
    final delegate = super.adapter;
    return PlaybackAdapter(
      create: () {
        final engine = delegate.create() as MediaKitEngine;
        engine.player.stream.error.listen((message) {
          final category = message.contains('403')
              ? 'http403'
              : message.contains('404')
              ? 'http404'
              : message.toLowerCase().contains('decoder')
              ? 'decoder'
              : message.toLowerCase().contains('audio')
              ? 'audio'
              : message.toLowerCase().contains('open')
              ? 'open'
              : 'other';
          debugPrint('M4 native error category: $category');
        });
        return engine;
      },
      surface: delegate.surface,
    );
  }
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  TvImageCache.configure();
  testWidgets(
    'M4 real guest pages, Chinese results, history, related and P2 playback',
    (tester) async {
      final database = AppDatabase(
        driftDatabase(name: 'mambatv_m4_validation'),
      );
      final sessions = MemorySessionRepository();
      final tracker = M4EngineTracker();
      final container = ProviderContainer(
        retry: (_, _) => null,
        overrides: [
          appDatabaseProvider.overrideWithValue(database),
          sessionRepositoryProvider.overrideWithValue(sessions),
          playbackAdapterProvider.overrideWithValue(tracker.adapter),
        ],
      );
      addTearDown(() async {
        container.dispose();
        await sessions.close();
        await database.close();
      });
      // Only this named validation database is reset; personal history is retained.
      await database.delete(database.searchEntries).go();
      await database.delete(database.watchProgressRows).go();
      Future<void> until(bool Function() condition, {int seconds = 60}) async {
        final deadline = DateTime.now().add(Duration(seconds: seconds));
        while (!condition() && DateTime.now().isBefore(deadline)) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(
          condition(),
          isTrue,
          reason: 'Timed out waiting for native discovery state',
        );
      }

      Future<void> key(LogicalKeyboardKey value) async {
        await tester.sendKeyEvent(value);
        await tester.pump(const Duration(milliseconds: 180));
      }

      Future<void> footer() async {
        for (
          var i = 0;
          i < 50 &&
              FocusManager.instance.primaryFocus?.debugLabel != 'grid-footer';
          i++
        ) {
          await key(LogicalKeyboardKey.arrowDown);
        }
        expect(FocusManager.instance.primaryFocus?.debugLabel, 'grid-footer');
      }

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MambaApp(),
        ),
      );
      await tester.runAsync(() => container.read(appStartupProvider.future));
      final home = catalogViewModelProvider(
        section: 'home',
        pageId: 'home',
        ownerKey: 'guest',
      );
      await until(() => container.read(home).hasValue);
      expect(container.read(home).requireValue.items, isNotEmpty);
      // Switch recommendation -> popular entirely through D-pad focus.
      await key(LogicalKeyboardKey.arrowRight);
      await key(LogicalKeyboardKey.arrowUp);
      await key(LogicalKeyboardKey.arrowUp);
      await key(LogicalKeyboardKey.arrowRight);
      await key(LogicalKeyboardKey.arrowRight);
      expect(FocusManager.instance.primaryFocus?.debugLabel, 'feed-popular');
      await key(LogicalKeyboardKey.select);
      final popular = catalogViewModelProvider(
        section: 'popular',
        pageId: 'home',
        ownerKey: 'guest',
      );
      await until(() => container.read(popular).hasValue);
      await key(LogicalKeyboardKey.arrowDown);
      var pages = 1;
      const pageTarget = int.fromEnvironment('M4_PAGE_LIMIT', defaultValue: 10);
      while (pages < pageTarget &&
          container.read(popular).requireValue.nextCursor != null) {
        await footer();
        final before = container.read(popular).requireValue;
        await key(LogicalKeyboardKey.select);
        await until(() => !container.read(popular).requireValue.loadingMore);
        final after = container.read(popular).requireValue;
        expect(after.failure, isNull);
        expect(after.items.length, greaterThanOrEqualTo(before.items.length));
        expect(after.items.map((v) => v.id).toSet().length, after.items.length);
        pages++;
        await tester.pump(const Duration(milliseconds: 500));
      }
      final popularCount = container.read(popular).requireValue.items.length;
      final ended = container.read(popular).requireValue.nextCursor == null;
      expect(pages == pageTarget || ended, isTrue);
      final router = container.read(appRouterProvider);
      router.go('/search');
      await tester.pump(const Duration(milliseconds: 300));
      await tester.enterText(find.byType(TextField), '纪录片');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      final search = catalogViewModelProvider(
        section: 'search',
        pageId: 'search',
        ownerKey: 'guest',
        query: '纪录片',
      );
      await until(() => container.read(search).hasValue);
      expect(container.read(search).requireValue.items, isNotEmpty);
      await key(LogicalKeyboardKey.arrowDown);
      await key(LogicalKeyboardKey.arrowDown);
      await footer();
      await key(LogicalKeyboardKey.select);
      await until(() => !container.read(search).requireValue.loadingMore);
      expect(container.read(search).requireValue.failure, isNull);
      final history = (await LocalSearchHistoryRepository(
        database,
      ).load('guest')).valueOrThrow;
      expect(history, contains('纪录片'));
      // Public multi-part sample verified in M0 and exercised again by M4.
      const multipartId = String.fromEnvironment(
        'M4_VIDEO_ID',
        defaultValue: 'BV1wR4Xz6EqG',
      );
      unawaited(router.push<void>('/video/$multipartId'));
      await until(
        () => find.byKey(const Key('detail-play')).evaluate().isNotEmpty,
      );
      final detailKey = tester
          .widget<VideoDetailPage>(find.byType(VideoDetailPage))
          .pageId;
      final detailProvider = videoDetailViewModelProvider(
        id: multipartId,
        pageId: detailKey,
        ownerKey: 'guest',
      );
      final detail = container.read(detailProvider).requireValue.detail;
      expect(detail.parts.length, greaterThan(1));
      await key(LogicalKeyboardKey.arrowDown);
      await key(LogicalKeyboardKey.arrowRight);
      expect(
        FocusManager.instance.primaryFocus?.debugLabel,
        'detail-part-${detail.parts[1].id}',
      );
      await key(LogicalKeyboardKey.select);
      await until(
        () => find.byKey(const Key('player-phase')).evaluate().isNotEmpty,
      );
      final player = playerViewModelProvider(
        pageId: tester.widget<PlayerPage>(find.byType(PlayerPage)).pageId,
        ownerKey: 'guest',
      );
      await until(() {
        final state = container.read(player);
        if (state.phase == PlayerPhase.failed) {
          fail(
            'P2 playback failed: ${state.failure?.kind.name}: ${state.failure?.message}',
          );
        }
        return state.phase == PlayerPhase.playing &&
            state.snapshot.position.inSeconds >= 3 &&
            state.snapshot.width > 0 &&
            state.snapshot.audioSampleRate > 0;
      });
      final snapshot = container.read(player).snapshot;
      expect(container.read(player).partTitle, detail.parts[1].title);
      await tester.binding.handlePopRoute();
      await until(
        () =>
            find.byKey(const Key('player-phase')).evaluate().isEmpty &&
            tracker.active == 0,
      );
      await until(
        () => tester
            .widget<TvButton>(find.byKey(const Key('detail-play')))
            .label
            .startsWith('继续播放'),
      );
      expect(
        FocusManager.instance.primaryFocus?.debugLabel,
        'detail-part-${detail.parts[1].id}',
      );
      final relatedProvider = relatedVideosProvider(
        id: multipartId,
        pageId: detailKey,
        ownerKey: 'guest',
      );
      await until(() => container.read(relatedProvider).hasValue);
      final relatedCount = container.read(relatedProvider).requireValue.length;
      expect(relatedCount, greaterThan(0));
      await tester.binding.handlePopRoute();
      await tester.pump(const Duration(milliseconds: 300));
      unawaited(router.push<void>('/video/BVinvalidsynthetic'));
      await until(() => find.text('内容暂不可用').evaluate().isNotEmpty);
      await tester.binding.handlePopRoute();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('内容暂不可用'), findsNothing);
      expect(tracker.maximum, 1);
      expect(tracker.active, 0);
      expect(tester.takeException(), isNull);
      binding.reportData = {
        'recordedAtUtc': DateTime.now().toUtc().toIso8601String(),
        'account': 'guest override',
        'database': 'isolated mambatv_m4_validation',
        'popularPages': pages,
        'popularUniqueItems': popularCount,
        'endedBeforeTen': pages < 10 && ended,
        'searchQuery': '纪录片',
        'searchUniqueItems': container.read(search).value?.items.length,
        'newHistoryRepositoryRestored': history.contains('纪录片'),
        'multipartVideo': multipartId,
        'parts': detail.parts.length,
        'playedPart': 2,
        'width': snapshot.width,
        'height': snapshot.height,
        'audioSampleRate': snapshot.audioSampleRate,
        'relatedCount': relatedCount,
        'resumeLabelAfterReturn': true,
        'partFocusRestored': true,
        'invalidVideoReturned': true,
        'maximumEngines': tracker.maximum,
        'enginesAfterReturn': tracker.active,
        'chineseTextInThisTest':
            'Flutter test input; real native IME is validated separately',
      };
    },
  );
}
