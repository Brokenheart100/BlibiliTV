import 'dart:async';

import 'package:canvas_danmaku/scroll_danmaku_painter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mambatv/app/providers/overlay_providers.dart';
import 'package:mambatv/domain/overlays/overlays.dart';
import 'package:mambatv/ui/features/player/views/playback_overlays.dart';

import '../support/fake_overlays.dart';
import '../support/fake_playback.dart';

class PendingOverlayPreferences extends MemoryOverlayPreferences {
  final pending = Completer<OverlayPreferences>();
  @override
  Future<OverlayPreferences> load() => pending.future;
}

void main() {
  testWidgets('loading preferences never prefetch disabled subtitles', (
    tester,
  ) async {
    final subtitles = FakeOverlays();
    final danmaku = FakeOverlays()
      ..segments[1] = const [
        DanmakuItem(
          id: 'one',
          timeMs: 0,
          mode: 1,
          color: 0xffffff,
          text: 'One',
        ),
      ];
    final preferences = PendingOverlayPreferences();
    final container = ProviderContainer(
      overrides: [
        subtitleRepositoryProvider.overrideWithValue(subtitles),
        danmakuRepositoryProvider.overrideWithValue(danmaku),
        overlayPreferencesRepositoryProvider.overrideWithValue(preferences),
      ],
    );
    final engine = FakeEngineFactory().create();
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: PlaybackOverlays(
            engine: engine,
            videoId: 'fixture',
            partId: '1',
            scopeKey: 'guest',
            controlsVisible: false,
          ),
        ),
      ),
    );
    await tester.pump();
    expect(subtitles.signals, isEmpty);
    expect(danmaku.signals, isEmpty);
    preferences.pending.complete(
      const OverlayPreferences(subtitles: false, danmaku: true),
    );
    await tester.pump();
    await tester.pump();
    expect(danmaku.signals, isNotEmpty);
    expect(subtitles.signals, isEmpty);
    expect(find.byKey(const Key('player-subtitle-text')), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    await engine.dispose();
    container.dispose();
  });

  testWidgets('native clock bursts do not run duplicate admission passes', (
    tester,
  ) async {
    final repo = FakeOverlays()
      ..segments[1] = const [
        DanmakuItem(
          id: 'one',
          timeMs: 0,
          mode: 1,
          color: 0xffffff,
          text: 'One',
        ),
      ];
    final prefs = MemoryOverlayPreferences()
      ..preferences = const OverlayPreferences(subtitles: false, danmaku: true);
    final container = ProviderContainer(
      overrides: [
        danmakuRepositoryProvider.overrideWithValue(repo),
        overlayPreferencesRepositoryProvider.overrideWithValue(prefs),
      ],
    );
    final engine = FakeEngineFactory().create();
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: PlaybackOverlays(
            engine: engine,
            videoId: 'fixture',
            partId: '1',
            scopeKey: 'guest',
            controlsVisible: false,
          ),
        ),
      ),
    );
    await tester.pump();
    engine.emit(engine.snapshot.copyWith(playing: true));
    await tester.pump();
    final metrics = container.read(overlayMetricsProvider);
    expect(metrics.activeSchedulers, 1);
    final before = metrics.frameEvaluations;
    for (var i = 0; i < 100; i++) {
      engine.emit(
        engine.snapshot.copyWith(bufferedPosition: Duration(seconds: i + 1)),
      );
    }
    await tester.pump();
    expect(
      metrics.frameEvaluations,
      before,
      reason: 'Buffer/progress events anchor time; the 50 ms timer admits text',
    );
    engine.emit(engine.snapshot.copyWith(playing: false));
    await tester.pump();
    expect(metrics.activeSchedulers, 0);
    expect(metrics.frameEvaluations, before + 1);
    await tester.pumpWidget(const SizedBox.shrink());
    await engine.dispose();
    container.dispose();
    expect(metrics.active, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('rejected burst entries do not block later free tracks', (
    tester,
  ) async {
    final repo = FakeOverlays()
      ..segments[1] = [
        for (var i = 0; i < 60; i++)
          DanmakuItem(
            id: 'burst-$i',
            timeMs: 0,
            mode: 1,
            color: 0xffffff,
            text: 'Short',
          ),
        const DanmakuItem(
          id: 'later',
          timeMs: 2000,
          mode: 1,
          color: 0xffffff,
          text: 'Later',
        ),
      ];
    final prefs = MemoryOverlayPreferences()
      ..preferences = const OverlayPreferences(
        subtitles: false,
        danmaku: true,
        area: 1,
        density: 40,
      );
    final container = ProviderContainer(
      overrides: [
        danmakuRepositoryProvider.overrideWithValue(repo),
        overlayPreferencesRepositoryProvider.overrideWithValue(prefs),
      ],
    );
    final engine = FakeEngineFactory().create();
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Center(
            child: SizedBox(
              width: 600,
              height: 220,
              child: PlaybackOverlays(
                engine: engine,
                videoId: 'fixture',
                partId: '1',
                scopeKey: 'guest',
                controlsVisible: false,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    engine.emit(engine.snapshot.copyWith(playing: true));
    await tester.pump();
    final metrics = container.read(overlayMetricsProvider);
    // Rejected comments must not appear in the admission counter either.
    expect(metrics.admittedDanmaku, inInclusiveRange(1, 5));
    // The small viewport admits only a handful from a simultaneous burst.
    for (var ms = 100; ms <= 2100; ms += 100) {
      engine.emit(
        engine.snapshot.copyWith(position: Duration(milliseconds: ms)),
      );
      await tester.pump(const Duration(milliseconds: 100));
    }
    final painter = tester
        .widgetList<CustomPaint>(find.byType(CustomPaint))
        .map((widget) => widget.painter)
        .whereType<ScrollDanmakuPainter>()
        .single;
    expect(
      painter.danmakuItems.any((item) => item.content.text == 'Later'),
      isTrue,
    );
    final visible = painter.danmakuItems.toList();
    final clears = metrics.cleared;
    engine.emit(engine.snapshot.copyWith(playing: false));
    await tester.pump(const Duration(seconds: 1));
    expect(painter.danmakuItems, containsAll(visible));
    expect(metrics.cleared, clears);
    engine.emit(engine.snapshot.copyWith(playing: true));
    await tester.pump(const Duration(milliseconds: 50));
    expect(painter.danmakuItems, containsAll(visible));
    engine.emit(
      engine.snapshot.copyWith(position: const Duration(seconds: 20)),
    );
    await tester.pump();
    expect(painter.danmakuItems, isEmpty);
    expect(metrics.cleared, clears + 1);
    await tester.pumpWidget(const SizedBox.shrink());
    await engine.dispose();
    container.dispose();
    expect(tester.takeException(), isNull);
  });
}
