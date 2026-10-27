import 'package:flutter_test/flutter_test.dart';
import 'package:mambatv/data/services/playback/native_buffer_ranges.dart';

void main() {
  test('actual ranges work even when the simplified endpoint is stale', () {
    final ranges = parseNativeBufferRanges(
      '{"cache-end":-0.1,"seekable-ranges":[{"start":0,"end":199.8}]}',
    );
    expect(
      nativeBufferedEndAt(ranges, const Duration(seconds: 60)),
      const Duration(milliseconds: 199800),
    );
  });
  test('overlapping unordered ranges merge without bridging uncached gaps', () {
    final ranges = parseNativeBufferRanges(
      '{"seekable-ranges":[{"start":90,"end":120},{"start":20,"end":40},'
      '{"start":0,"end":25},{"start":40,"end":50}]}',
    );
    expect(
      nativeBufferedEndAt(ranges, const Duration(seconds: 10)),
      const Duration(seconds: 50),
    );
    expect(
      nativeBufferedEndAt(ranges, const Duration(seconds: 70)),
      Duration.zero,
    );
    expect(
      nativeBufferedEndAt(ranges, const Duration(seconds: 100)),
      const Duration(seconds: 120),
    );
    expect(
      nativeBufferedEndAt(ranges, const Duration(seconds: 121)),
      Duration.zero,
    );
  });
  test('unknown and malformed cache data stays empty', () {
    for (final raw in [
      '',
      'null',
      '[]',
      '{}',
      '{"seekable-ranges":null}',
      '{',
    ]) {
      expect(parseNativeBufferRanges(raw), isEmpty);
    }
    final ranges = parseNativeBufferRanges(
      '{"seekable-ranges":[null,{"start":"0","end":10},{"start":8,"end":2},'
      '{"start":0,"end":1e300},{"start":-5,"end":-1},{"start":-0.1,"end":10}]}',
    );
    expect(ranges, [(start: Duration.zero, end: const Duration(seconds: 10))]);
  });
}
