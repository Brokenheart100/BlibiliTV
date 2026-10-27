import 'dart:convert';

import 'package:fixnum/fixnum.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mambatv/data/repositories/bilibili_overlay_repository.dart';
import 'package:mambatv/data/repositories/local_overlay_preferences.dart';
import 'package:mambatv/data/services/danmaku/generated/danmaku.pb.dart'
    as wire;
import 'package:mambatv/domain/overlays/overlays.dart';

import '../support/memory_preferences.dart';

void main() {
  test('subtitle parser sorts valid cues, preserves plain text, rejects bad ranges', () {
    final data = utf8.encode(
      jsonEncode({
        'body': [
          {'from': 2, 'to': 3, 'content': '<literal>'},
          {'from': 0, 'to': 1.5, 'content': 'first'},
          {'from': 3, 'to': 2, 'content': 'bad'},
          {'from': -1, 'to': 2, 'content': 'negative'},
        ],
      }),
    );
    final cues = parseSubtitle(data);
    expect(cues.map((e) => e.startMs), [0, 2000]);
    expect(cues.last.text, '<literal>');
    expect(cues.last.toString(), isNot(contains('<literal>')));
    expect(() => parseSubtitle(utf8.encode('{}')), throwsFormatException);
  });
  test('protobuf decoder tolerates unknown fields, filters unsupported modes and deduplicates', () {
    final message = wire.Segment(
      elems: [
        wire.DanmakuEntry(
          id: Int64(1),
          progress: 1000,
          mode: 1,
          color: 0xffffff,
          content: 'synthetic',
        ),
        wire.DanmakuEntry(
          id: Int64(1),
          progress: 1000,
          mode: 1,
          content: 'updated',
        ),
        wire.DanmakuEntry(
          id: Int64(2),
          progress: 0,
          mode: 8,
          content: 'not executable',
        ),
        wire.DanmakuEntry(id: Int64(3), progress: -1, mode: 5, content: 'bad'),
      ],
    );
    final items = parseDanmaku([...message.writeToBuffer(), 0xa0, 0x06, 0x01]);
    expect(items.length, 1);
    expect(items.single.text, 'updated');
    expect(items.single.toString(), isNot(contains('updated')));
    expect(() => parseDanmaku([0x0a, 0xff]), throwsA(anything));
  });
  test('missing and corrupt overlay preferences recover per field without changing old settings', () async {
    final store = MemoryPreferencesStore();
    final repository = LocalOverlayPreferences(store);
    expect(await repository.load(), const OverlayPreferences());
    await store.write(
      LocalOverlayPreferences.key,
      '{"fontSize":"bad","danmaku":true,"offsetMs":99999,"keywords":[null,"safe"]}',
    );
    final restored = await repository.load();
    expect(restored.fontSize, 24);
    expect(restored.offsetMs, 5000);
    expect(restored.danmaku, true);
    expect(restored.keywords, ['safe']);
    await repository.save(restored.copyWith(opacity: .4, density: 20));
    expect((await repository.load()).density, 20);
    await store.write(LocalOverlayPreferences.key, '{bad');
    expect(await repository.load(), const OverlayPreferences());
  });
}
