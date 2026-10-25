import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:mambatv/app/providers/playback_providers.dart';
import 'package:mambatv/core/result.dart';
import 'package:mambatv/domain/playback/playback.dart';

const syntheticSource = PlaybackSource(
  videoUrl: 'https://example.invalid/video',
  audioUrl: 'https://example.invalid/audio',
  duration: Duration(seconds: 120),
  quality: 32,
  codec: 'avc1.test',
  qualities: [
    PlaybackOption(16, '360P'),
    PlaybackOption(32, '480P'),
    PlaybackOption(80, '1080P', reason: '当前账号不可用'),
  ],
  audioTracks: [
    PlaybackOption(30216, 'AAC 64kbps'),
    PlaybackOption(30280, 'AAC 192kbps'),
  ],
  audioId: 30216,
  videoBackups: ['https://backup.invalid/video'],
  audioBackups: ['https://backup.invalid/audio'],
);

class FakePlaybackRepository implements PlaybackRepository {
  final requests =
      <({String videoId, String partId, int? quality, int? audioId})>[];
  int calls = 0;
  AppFailure? failure;
  Completer<void>? gate;
  CancellationSignal? signal;
  @override
  Future<Result<PlaybackSource>> resolve({
    required String videoId,
    required String partId,
    required CancellationSignal cancellation,
    int? quality,
    int? audioId,
  }) async {
    calls++;
    requests.add((
      videoId: videoId,
      partId: partId,
      quality: quality,
      audioId: audioId,
    ));
    signal = cancellation;
    await gate?.future;
    if (cancellation.isCancelled) {
      return const ResultFailure(
        AppFailure(FailureKind.cancelled, 'cancelled'),
      );
    }
    return failure == null
        ? Success(
            PlaybackSource(
              videoUrl: syntheticSource.videoUrl,
              audioUrl: syntheticSource.audioUrl,
              duration: syntheticSource.duration,
              quality: quality ?? syntheticSource.quality,
              codec: syntheticSource.codec,
              qualities: syntheticSource.qualities,
              audioTracks: syntheticSource.audioTracks,
              audioId: audioId ?? syntheticSource.audioId,
              videoBackups: syntheticSource.videoBackups,
              audioBackups: syntheticSource.audioBackups,
            ),
          )
        : ResultFailure(failure!);
  }
}

class MemoryProgressRepository implements ProgressRepository {
  @override
  Future<Result<WatchProgress?>> latestForVideo(
    String ownerKey,
    String videoId,
  ) async {
    final matches = entries.values.where(
      (p) => p.ownerKey == ownerKey && p.videoId == videoId,
    );
    return Success(matches.isEmpty ? null : matches.last);
  }

  final entries = <String, WatchProgress>{};
  final writes = <WatchProgress>[];
  String key(String owner, String video, String part) => '$owner:$video:$part';
  @override
  Future<Result<WatchProgress?>> load(
    String ownerKey,
    String videoId,
    String partId,
  ) async => Success(entries[key(ownerKey, videoId, partId)]);
  @override
  Future<Result<void>> save(WatchProgress progress) async {
    if (progress.isValid) {
      entries[key(progress.ownerKey, progress.videoId, progress.partId)] =
          progress;
      writes.add(progress);
    }
    return const Success(null);
  }
}

class FakeEngineFactory {
  PlaybackFocus focus = const PassivePlaybackFocus();
  final openFailures = <AppFailure>[];
  final engines = <FakePlaybackEngine>[];
  int active = 0, maxActive = 0;
  Completer<void>? openGate;
  PlaybackAdapter get adapter => PlaybackAdapter(
    focus: focus,
    create: create,
    surface: (engine) =>
        ColoredBox(key: ObjectKey(engine), color: const Color(0xFF102030)),
  );
  FakePlaybackEngine create() {
    final engine = FakePlaybackEngine(this, openGate: openGate);
    engines.add(engine);
    active++;
    if (active > maxActive) maxActive = active;
    return engine;
  }
}

class FakePlaybackEngine implements PlaybackEngine {
  FakePlaybackEngine(this.factory, {this.openGate});
  final FakeEngineFactory factory;
  final Completer<void>? openGate;
  final events = StreamController<EngineSnapshot>.broadcast(sync: true);
  bool disposed = false;
  int opens = 0;
  Duration? openedAt;
  PlaybackSource? source;
  EngineSnapshot value = const EngineSnapshot(duration: Duration(seconds: 120));
  @override
  EngineSnapshot get snapshot => value;
  @override
  Stream<EngineSnapshot> get snapshots => events.stream;
  void emit(EngineSnapshot next) {
    value = next;
    if (!events.isClosed) events.add(next);
  }

  @override
  Future<void> open(
    PlaybackSource source, {
    required Duration startAt,
    bool play = true,
  }) async {
    opens++;
    this.source = source;
    openedAt = startAt;
    await openGate?.future;
    if (factory.openFailures.isNotEmpty) throw factory.openFailures.removeAt(0);
    if (!disposed) {
      emit(
        value.copyWith(
          playing: play,
          position: startAt,
          width: 640,
          height: 360,
          audioSampleRate: 44100,
        ),
      );
    }
  }

  @override
  Future<void> play() async => emit(value.copyWith(playing: true));
  @override
  Future<void> pause() async => emit(value.copyWith(playing: false));
  @override
  Future<void> seek(Duration position) async =>
      emit(value.copyWith(position: position));
  @override
  Future<void> setRate(double rate) async => emit(value.copyWith(rate: rate));
  @override
  Future<void> setVolume(double volume) async =>
      emit(value.copyWith(volume: volume));
  @override
  Future<void> dispose() async {
    if (disposed) return;
    disposed = true;
    factory.active--;
    await events.close();
  }
}
