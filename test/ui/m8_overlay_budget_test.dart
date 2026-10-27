import 'package:canvas_danmaku/canvas_danmaku.dart' hide DanmakuItem;
import 'package:canvas_danmaku/static_danmaku_painter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mambatv/app/providers/overlay_providers.dart';
import 'package:mambatv/domain/overlays/overlays.dart';
import 'package:mambatv/ui/features/player/view_models/overlay_view_models.dart';
import 'package:mambatv/ui/features/player/views/playback_overlays.dart';

import '../support/fake_overlays.dart';
import '../support/fake_playback.dart';

void main() {
  testWidgets('slow canvas stays bounded and manual density restores budget', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repo = FakeOverlays()
      ..segments[1] = List.generate(
        200,
        (i) => DanmakuItem(
          id: '$i',
          timeMs: i * 100,
          mode: 5,
          color: 0xffffff,
          text: 'Bounded canvas $i',
        ),
      );
    final preferences = MemoryOverlayPreferences()
      ..preferences = const OverlayPreferences(
        subtitles: false,
        danmaku: true,
        density: 10,
        area: 1,
      );
    final container = ProviderContainer(
      overrides: [
        danmakuRepositoryProvider.overrideWithValue(repo),
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
            videoId: 'v',
            partId: '1',
            scopeKey: 'guest',
            controlsVisible: false,
          ),
        ),
      ),
    );
    await tester.pump();
    // Media timestamps advance faster than the canvas's real Stopwatch here.
    // Expiring admission timestamps alone must not allow retained canvas objects
    // to exceed the selected limit when drawing/cleanup trails playback.
    for (var i = 0; i < 60; i++) {
      engine.emit(
        engine.snapshot.copyWith(
          playing: true,
          position: Duration(milliseconds: i * 200),
        ),
      );
      await tester.pump(const Duration(milliseconds: 20));
    }
    // Inspect the actual library paint objects through the public painters.
    final staticPainters = tester
        .widgetList<CustomPaint>(find.byType(CustomPaint))
        .map((w) => w.painter)
        .whereType<StaticDanmakuPainter>();
    expect(staticPainters.single.danmakuItems, isNotEmpty);
    expect(staticPainters.single.danmakuItems.length, lessThanOrEqualTo(10));
    await container
        .read(overlaySettingsViewModelProvider.notifier)
        .savePreferences(preferences.preferences.copyWith(density: 40));
    await tester.pump();
    engine.emit(
      engine.snapshot.copyWith(
        position: engine.snapshot.position + const Duration(milliseconds: 200),
      ),
    );
    await tester.pump();
    expect(container.read(overlayMetricsProvider).density, 40);
    expect(
      tester
          .widget<DanmakuScreen<void>>(find.byType(DanmakuScreen<void>))
          .option
          .area,
      1,
    );
    await tester.pumpWidget(const SizedBox.shrink());
    await engine.dispose();
    container.dispose();
    expect(tester.takeException(), isNull);
  });
}
