import 'dart:convert';

typedef NativeBufferRange = ({Duration start, Duration end});

/// Reads mpv's actual seekable cache ranges, ignoring unknown or invalid data.
List<NativeBufferRange> parseNativeBufferRanges(String raw) {
  Object? decoded;
  try {
    decoded = jsonDecode(raw);
  } on FormatException {
    return const [];
  }
  if (decoded is! Map<String, dynamic>) return const [];
  final ranges = decoded['seekable-ranges'];
  if (ranges is! List) return const [];
  final valid = <NativeBufferRange>[];
  for (final range in ranges) {
    if (range is! Map<String, dynamic>) continue;
    final start = range['start'], end = range['end'];
    if (start is! num || end is! num || !start.isFinite || !end.isFinite) {
      continue;
    }
    // Keep the microsecond conversion within the exact integer range.
    const maxSeconds = 9007199254740991 / Duration.microsecondsPerSecond;
    if (end <= start || end <= 0 || end > maxSeconds) {
      continue;
    }
    valid.add((
      start: Duration(microseconds: (start.clamp(0, end) * 1e6).round()),
      end: Duration(microseconds: (end * 1e6).round()),
    ));
  }
  valid.sort((a, b) => a.start.compareTo(b.start));
  final merged = <NativeBufferRange>[];
  for (final range in valid) {
    if (merged.isEmpty || range.start > merged.last.end) {
      merged.add(range);
    } else if (range.end > merged.last.end) {
      merged[merged.length - 1] = (start: merged.last.start, end: range.end);
    }
  }
  return merged;
}

/// Never bridges a gap to an unrelated range cached by an earlier seek.
Duration nativeBufferedEndAt(
  List<NativeBufferRange> ranges,
  Duration position,
) {
  for (final range in ranges) {
    if (range.start <= position && position <= range.end) return range.end;
  }
  return Duration.zero;
}
