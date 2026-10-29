import 'dart:async';

import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mambatv/app/app.dart';
import 'package:mambatv/app/bootstrap.dart';
import 'package:mambatv/app/providers/infrastructure_providers.dart';
import 'package:mambatv/app/providers/playback_providers.dart';
import 'package:mambatv/app/providers/repository_providers.dart';
import 'package:mambatv/app/router.dart';
import 'package:mambatv/data/services/local/app_database.dart';
import 'package:mambatv/data/repositories/memory_session_repository.dart';
import 'package:mambatv/data/services/playback/better_player_engine.dart';
import 'package:mambatv/ui/features/catalog/view_models/catalog_view_model.dart';
import 'package:mambatv/ui/features/player/view_models/player_view_model.dart';
import 'package:mambatv/ui/features/player/views/player_page.dart';

class NativeEngineTracker {
  int active = 0, maximum = 0, created = 0, released = 0;
  PlaybackAdapter get adapter => PlaybackAdapter(
    create: () => TrackedNativeEngine(this),
    surface: (engine) => BetterPlayerSurface(engine as BetterPlayerEngine),
  );
}

class TrackedNativeEngine extends BetterPlayerEngine {
  TrackedNativeEngine(this.tracker) {
    tracker.created++;
    tracker.active++;
    if (tracker.active > tracker.maximum) tracker.maximum = tracker.active;
  }
  final NativeEngineTracker tracker;
  bool closing = false;
  @override
  Future<void> dispose() async {
    if (closing) return;
    closing = true;
    try {
      await super.dispose();
    } finally {
      tracker.active--;
      tracker.released++;
    }
  }
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'M2 guest TV flow, audio/video, seek, SQLite resume and 20 switches',
    (tester) async {
      final tracker = NativeEngineTracker();
      final database = AppDatabase(
        driftDatabase(name: 'mambatv_m2_validation'),
      );
      final sessions = MemorySessionRepository();
      final container = ProviderContainer(
        retry: (_, _) => null,
        overrides: [
          sessionRepositoryProvider.overrideWithValue(sessions),
          appDatabaseProvider.overrideWithValue(database),
          playbackAdapterProvider.overrideWithValue(tracker.adapter),
        ],
      );
      addTearDown(() async {
        container.dispose();
        await database.close();
        await sessions.close();
      });
      Future<void> until(bool Function() condition, {int seconds = 60}) async {
        final deadline = DateTime.now().add(Duration(seconds: seconds));
        while (!condition() && DateTime.now().isBefore(deadline)) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(
          condition(),
          isTrue,
          reason: 'Timed out waiting for native app state',
        );
      }

      Future<void> key(LogicalKeyboardKey key) async {
        await tester.sendKeyEvent(key);
        await tester.pump(const Duration(milliseconds: 250));
      }

      Future<void> back() async {
        await tester.binding.handlePopRoute();
        await until(() => find.byType(PlayerPage).evaluate().isEmpty);
        expect(tracker.active, 0);
        await tester.pump(const Duration(milliseconds: 300));
      }

      PlayerViewModelProvider current() {
        final page = tester.widget<PlayerPage>(find.byType(PlayerPage));
        return playerViewModelProvider(pageId: page.pageId, ownerKey: 'guest');
      }

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MambaApp(),
        ),
      );
      await tester.runAsync(() => container.read(appStartupProvider.future));
      // Only the dedicated acceptance database is reset; the user's app DB is preserved.
      await tester.runAsync(
        () => database.delete(database.watchProgressRows).go(),
      );
      const m4Regression = bool.fromEnvironment('M4_PLAYBACK_REGRESSION');
      if (m4Regression) {
        container.read(appRouterProvider).go('/home?feed=popular');
        await tester.pump(const Duration(milliseconds: 300));
      }
      final list = catalogViewModelProvider(
        section: m4Regression ? 'popular' : 'home',
        pageId: 'home',
        ownerKey: 'guest',
      );
      await until(() => container.read(list).hasValue);
      final videos = container.read(list).requireValue.items;
      expect(videos.length, greaterThanOrEqualTo(2));
      final video = videos.first;
      await key(LogicalKeyboardKey.arrowRight);
      await until(
        () =>
            FocusManager.instance.primaryFocus?.debugLabel ==
            'video-${video.id}',
      );
      await key(LogicalKeyboardKey.select);
      await until(
        () => find.byKey(const Key('detail-play')).evaluate().isNotEmpty,
      );
      await tester.pump(const Duration(milliseconds: 300));
      await key(LogicalKeyboardKey.select);
      await until(() => find.byType(PlayerPage).evaluate().isNotEmpty);
      final first = current();
      await until(() {
        final value = container.read(first);
        return value.phase == PlayerPhase.playing &&
            value.snapshot.position.inSeconds >= 3 &&
            value.snapshot.width > 0 &&
            value.snapshot.duration > Duration.zero;
      });
      final firstSnapshot = container.read(first).snapshot;
      await key(LogicalKeyboardKey.select);
      await until(() => container.read(first).phase == PlayerPhase.paused);
      final paused = container.read(first).snapshot.position;
      await tester.pump(const Duration(milliseconds: 700));
      expect(
        (container.read(first).snapshot.position - paused).inMilliseconds.abs(),
        lessThan(500),
      );
      await key(LogicalKeyboardKey.arrowRight);
      await key(LogicalKeyboardKey.select);
      await until(
        () =>
            container.read(first).snapshot.position >=
            paused + const Duration(seconds: 8),
      );
      final sought = container.read(first).snapshot.position;
      final part = tester.widget<PlayerPage>(find.byType(PlayerPage)).partId!;
      await key(LogicalKeyboardKey.arrowLeft);
      await key(LogicalKeyboardKey.select);
      await until(() => container.read(first).phase == PlayerPhase.playing);
      await back();
      final saved = (await tester.runAsync(
        () => container
            .read(progressRepositoryProvider)
            .load('guest', video.id, part),
      ))!.valueOrThrow!;
      expect(
        saved.position,
        greaterThanOrEqualTo(sought - const Duration(seconds: 1)),
      );
      await key(LogicalKeyboardKey.select);
      await until(() => find.byType(PlayerPage).evaluate().isNotEmpty);
      final resumed = current();
      await until(() => container.read(resumed).phase == PlayerPhase.playing);
      final resumeAt = container.read(resumed).resumedFrom;
      expect(resumeAt, saved.position);
      await until(
        () =>
            container.read(resumed).snapshot.position >=
            saved.position - const Duration(seconds: 2),
      );
      final actualResume = container.read(resumed).snapshot.position;
      await back();
      await tester.binding.handlePopRoute();
      await until(
        () =>
            FocusManager.instance.primaryFocus?.debugLabel ==
            'video-${video.id}',
      );

      final router = container.read(appRouterProvider);
      final switched = <String>[];
      for (var index = 0; index < 20; index++) {
        final selected = videos[index % 2];
        unawaited(router.push<void>('/player/${selected.id}'));
        await tester.pump(const Duration(milliseconds: 100));
        final provider = current();
        await until(() {
          final value = container.read(provider);
          return value.phase == PlayerPhase.playing &&
              value.snapshot.width > 0 &&
              value.snapshot.duration > Duration.zero;
        });
        expect(tracker.active, 1);
        switched.add(selected.id);
        await back();
        // Compact progress only: no resource URLs or native error strings.
        debugPrint('M2 native switch ${index + 1}/20 passed');
      }
      expect(tracker.maximum, 1);
      expect(tracker.created, tracker.released);
      expect(tester.takeException(), isNull);
      binding.reportData = {
        'recordedAtUtc': DateTime.now().toUtc().toIso8601String(),
        'videoId': video.id,
        'partId': part,
        'width': firstSnapshot.width,
        'height': firstSnapshot.height,
        'audioSampleRate': null, // Not exposed by the Better Player engine API.
        'pausedAtMs': paused.inMilliseconds,
        'seekedToMs': sought.inMilliseconds,
        'savedAtMs': saved.position.inMilliseconds,
        'resumedFromMs': resumeAt.inMilliseconds,
        'actualResumePositionMs': actualResume.inMilliseconds,
        'switchCount': switched.length,
        'switchVideoIds': switched.toSet().toList(),
        'maximumLiveEngines': tracker.maximum,
        'enginesCreated': tracker.created,
        'enginesReleased': tracker.released,
        'liveAfterBack': tracker.active,
        'returnedToOriginalCard': true,
        'database': 'dedicated native validation SQLite',
        'accountLoginAttempted': false,
      };
      await tester.pumpWidget(const SizedBox.shrink());
    },
    timeout: const Timeout(Duration(minutes: 12)),
  );
}
