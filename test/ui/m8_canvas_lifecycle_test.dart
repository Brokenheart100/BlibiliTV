import 'package:canvas_danmaku/canvas_danmaku.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final duration in [2.0, 3.0]) {
    testWidgets(
      'official canvas moves, freezes, updates duration $duration and releases ticker',
      (tester) async {
        late DanmakuController<void> controller;
        await tester.pumpWidget(
          MaterialApp(
            home: Center(
              child: SizedBox(
                width: 600,
                height: 240,
                child: DanmakuScreen<void>(
                  option: DanmakuOption(duration: duration),
                  createdController: (value) => controller = value,
                ),
              ),
            ),
          ),
        );
        controller.addDanmaku(
          DanmakuContentItem<void>('Synthetic lifecycle fixture'),
        );
        Future<void> advance() async {
          await tester.pump(const Duration(milliseconds: 100));
        }

        for (var i = 0; i < 5; i++) {
          await advance();
        }
        expect(controller.scrollDanmaku, hasLength(1));
        final item = controller.scrollDanmaku.single;
        final first = item.xPosition;
        expect(first, lessThan(600));
        controller.pause();
        await advance();
        expect(item.xPosition, first);
        controller.resume();
        await advance();
        await advance();
        expect(item.xPosition, lessThan(first));
        controller.updateOption(const DanmakuOption(duration: 4));
        expect(controller.getOption().duration, 4);
        await tester.pump(const Duration(milliseconds: 100));
        controller.updateOption(DanmakuOption(duration: duration));
        await advance();
        controller.clear();
        expect(controller.scrollDanmaku, isEmpty);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(seconds: 1));
        expect(tester.takeException(), isNull);
      },
    );
  }
}
