import 'dart:async';
import 'dart:ui';

import 'package:better_player/better_player.dart' as bp;
import 'package:flutter_test/flutter_test.dart';
import 'package:mambatv/data/services/playback/better_player_engine.dart';

import '../support/dash_source.dart';

class FakeBetterPlayerPlatform extends bp.BetterPlayerPlatform {
  @override
  Future<void> setupLogCallback(
    void Function({required int levelIndex, required String message})? callback,
  ) async {}
  final events = StreamController<bp.VideoEvent>.broadcast();
  Duration position = Duration.zero;
  double rate = 1, volume = 1;
  bool disposed = false;
  bool delayNativePosition = false;
  Completer<void>? seekGate, disposeGate;
  bp.DataSource? source;
  void send(
    bp.VideoEventType type, {
    Duration? at,
    List<bp.DurationRange>? buffer,
  }) => events.add(
    bp.VideoEvent(eventType: type, key: null, position: at, buffered: buffer),
  );
  @override
  Future<int?> create({
    bp.BufferingConfiguration? bufferingConfiguration,
  }) async => 1;
  @override
  Stream<bp.VideoEvent> videoEventsFor(int? textureId) => events.stream;
  @override
  Future<void> setDataSource(int? textureId, bp.DataSource dataSource) async {
    source = dataSource;
    events.add(
      bp.VideoEvent(
        eventType: bp.VideoEventType.initialized,
        key: dataSource.key,
        duration: const Duration(seconds: 120),
        size: const Size(640, 360),
      ),
    );
  }

  @override
  Future<void> setLooping(int? textureId, bool looping) async {}
  @override
  Future<void> play(int? textureId) async => send(bp.VideoEventType.play);
  @override
  Future<void> pause(int? textureId) async => send(bp.VideoEventType.pause);
  @override
  Future<void> setVolume(int? textureId, double volume) async {
    this.volume = volume;
  }

  @override
  Future<void> setSpeed(int? textureId, double speed) async {
    rate = speed;
  }

  @override
  Future<Duration> getPosition(int? textureId) async => position;
  @override
  Future<DateTime?> getAbsolutePosition(int? textureId) async => null;
  @override
  Future<void> seekTo(int? textureId, Duration? position) async {
    await seekGate?.future;
    if (!delayNativePosition) this.position = position!;
    send(
      bp.VideoEventType.bufferingUpdate,
      buffer: [
        bp.DurationRange(position!, position + const Duration(seconds: 20)),
      ],
    );
  }

  @override
  Future<void> dispose(int? textureId) async {
    await disposeGate?.future;
    disposed = true;
    await events.close();
  }
}

void main() {
  late bp.BetterPlayerPlatform previous;
  late FakeBetterPlayerPlatform platform;
  late BetterPlayerEngine engine;
  setUp(() {
    previous = bp.BetterPlayerPlatform.instance;
    platform = FakeBetterPlayerPlatform();
    bp.BetterPlayerPlatform.instance = platform;
    engine = BetterPlayerEngine();
  });
  tearDown(() async {
    await engine.dispose();
    bp.BetterPlayerPlatform.instance = previous;
  });
  test(
    'open preserves preconfigured speed and volume and supplies CDN headers',
    () async {
      await engine.setRate(1.5);
      await engine.setVolume(35);
      await engine.open(dashSource, startAt: Duration.zero, play: false);
      expect(platform.rate, 1.5);
      expect(platform.volume, .35);
      expect(engine.snapshot.playing, isFalse);
      expect(platform.source!.formatHint, bp.VideoFormat.dash);
      expect(platform.source!.headers!['Referer'], 'https://www.bilibili.com/');
      expect(Uri.parse(platform.source!.uri!).host, '127.0.0.1');
      expect(engine.snapshot.width, 640);
    },
  );
  test(
    'paused seek waits for native completion and never starts playback',
    () async {
      await engine.open(dashSource, startAt: Duration.zero, play: false);
      final gate = platform.seekGate = Completer<void>();
      var returned = false;
      final seek = engine
          .seek(const Duration(seconds: 30))
          .then((_) => returned = true);
      await Future<void>.delayed(Duration.zero);
      expect(returned, isFalse);
      expect(engine.snapshot.bufferedPosition, Duration.zero);
      gate.complete();
      await seek;
      expect(engine.snapshot.position, const Duration(seconds: 30));
      expect(engine.snapshot.playing, isFalse);
      platform.send(
        bp.VideoEventType.bufferingUpdate,
        buffer: [bp.DurationRange(Duration.zero, const Duration(seconds: 70))],
      );
      await Future<void>.delayed(Duration.zero);
      expect(engine.snapshot.bufferedPosition, const Duration(seconds: 70));
      platform.send(bp.VideoEventType.bufferingUpdate, buffer: []);
      await Future<void>.delayed(Duration.zero);
      expect(engine.snapshot.bufferedPosition, Duration.zero);
    },
  );
  test('optimistic Dart seek position cannot complete a native seek', () async {
    await engine.open(dashSource, startAt: Duration.zero, play: false);
    platform.delayNativePosition = true;
    var returned = false;
    final seek = engine
        .seek(const Duration(seconds: 30))
        .then((_) => returned = true);
    await Future<void>.delayed(const Duration(milliseconds: 200));
    expect(engine.controller.value.position, const Duration(seconds: 30));
    expect(returned, isFalse);
    platform.position = const Duration(seconds: 30);
    await seek;
    expect(engine.snapshot.position, const Duration(seconds: 30));
  });
  test(
    'dispose waits for native release before allowing another engine lease',
    () async {
      await engine.open(dashSource, startAt: Duration.zero, play: false);
      final gate = platform.disposeGate = Completer<void>();
      var returned = false;
      final disposing = engine.dispose().then((_) => returned = true);
      await Future<void>.delayed(Duration.zero);
      expect(returned, isFalse);
      expect(platform.disposed, isFalse);
      gate.complete();
      await disposing;
      expect(platform.disposed, isTrue);
    },
  );
}
