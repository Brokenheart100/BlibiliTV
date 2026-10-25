import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
// media_kit_video 2.0.1 does not expose an Android callback-drain API in its
// barrel. Keep this version-specific disposal workaround inside the adapter.
// ignore: implementation_imports
import 'package:media_kit_video/src/video_controller/android_video_controller/android_video_controller.dart';

import '../../../core/result.dart';
import '../../../domain/playback/playback.dart';
import '../bilibili/bilibili_api.dart';

class MediaKitEngine implements PlaybackEngine {
  MediaKitEngine({this.onOpenStage}) {
    player = Player(
      configuration: const PlayerConfiguration(
        title: 'MambaTV',
        logLevel: MPVLogLevel.error,
      ),
    );
    controller = VideoController(
      player,
      configuration: defaultTargetPlatform == TargetPlatform.android
          ? const VideoControllerConfiguration(
              vo: 'mediacodec_embed',
              hwdec: 'mediacodec',
            )
          : const VideoControllerConfiguration(),
    );
    _subscriptions.addAll([
      player.stream.playing.listen(
        (v) => _emit(_snapshot.copyWith(playing: v)),
      ),
      player.stream.buffering.listen(
        (v) => _emit(_snapshot.copyWith(buffering: v)),
      ),
      player.stream.completed.listen(
        (v) => _emit(_snapshot.copyWith(completed: v)),
      ),
      player.stream.position.listen(
        (v) => _emit(_snapshot.copyWith(position: v)),
      ),
      player.stream.duration.listen(
        (v) => _emit(_snapshot.copyWith(duration: v)),
      ),
      player.stream.width.listen(
        (v) => _emit(_snapshot.copyWith(width: v ?? 0)),
      ),
      player.stream.height.listen(
        (v) => _emit(_snapshot.copyWith(height: v ?? 0)),
      ),
      player.stream.audioParams.listen(
        (v) => _emit(_snapshot.copyWith(audioSampleRate: v.sampleRate ?? 0)),
      ),
      player.stream.rate.listen((v) => _emit(_snapshot.copyWith(rate: v))),
      player.stream.volume.listen((v) => _emit(_snapshot.copyWith(volume: v))),
      // Native messages may contain signed URLs. Only a safe domain failure escapes.
      player.stream.error.listen(
        (message) => _emit(
          _snapshot.copyWith(
            playing: false,
            failure: classifyNativePlaybackFailure(message),
          ),
        ),
      ),
    ]);
  }
  late final Player player;
  final void Function(String stage)? onOpenStage;
  late final VideoController controller;
  final _events = StreamController<EngineSnapshot>.broadcast(sync: true);
  final _subscriptions = <StreamSubscription<Object?>>[];
  EngineSnapshot _snapshot = const EngineSnapshot();
  bool _disposed = false;
  Media? _audio;
  @override
  EngineSnapshot get snapshot => _snapshot;
  @override
  Stream<EngineSnapshot> get snapshots => _events.stream;
  void _emit(EngineSnapshot value) {
    if (_disposed) return;
    _snapshot = value;
    _events.add(value);
  }

  void _check() {
    if (_disposed) throw const AppFailure(FailureKind.cancelled, '已停止播放');
  }

  @override
  Future<void> open(
    PlaybackSource source, {
    required Duration startAt,
    bool play = true,
  }) async {
    _check();
    try {
      // Retain both resources with the fixed CDN headers. The primary file
      // must finish loading before audio-add can use its native stream options.
      _audio = Media(source.audioUrl, httpHeaders: bilibiliMediaHeaders);
      onOpenStage?.call('video');
      await player.open(
        Media(
          source.videoUrl,
          httpHeaders: bilibiliMediaHeaders,
          start: startAt > Duration.zero ? startAt : null,
        ),
        play: false,
      );
      _check();
      // open() returns when loadfile is queued. Wait for the main file to load
      // so media_kit's on_load hook has applied its HTTP headers before an
      // external audio-add command uses the current stream options.
      if (player.state.duration <= Duration.zero) {
        onOpenStage?.call('duration');
        await player.stream.duration
            .firstWhere((value) => value > Duration.zero)
            .timeout(const Duration(seconds: 20));
      }
      _check();
      onOpenStage?.call('audio');
      await player.setAudioTrack(AudioTrack.uri(_audio!.uri));
      _check();
      if (play) {
        onOpenStage?.call('frame');
        await player.play();
        await controller.waitUntilFirstFrameRendered.timeout(
          const Duration(seconds: 45),
        );
      } else {
        onOpenStage?.call('pause_position');
        await player.pause();
        await player.seek(startAt);
        // Android mediacodec_embed may defer its first decoded frame until play.
        // Confirm the paused timeline without ever starting audible playback.
        if ((player.state.position - startAt).abs() >
            const Duration(seconds: 2)) {
          await player.stream.position
              .firstWhere(
                (value) =>
                    (value - startAt).abs() <= const Duration(seconds: 2),
              )
              .timeout(const Duration(seconds: 10));
        }
      }
      _check();
      if (startAt > Duration.zero &&
          _snapshot.position < startAt - const Duration(seconds: 2)) {
        await player.seek(startAt);
      }
      if (_snapshot.failure case final AppFailure failure) throw failure;
      onOpenStage?.call('ready');
    } on AppFailure {
      rethrow;
    } catch (_) {
      throw const AppFailure(FailureKind.unavailable, '视频加载失败，请检查网络后重试');
    }
  }

  @override
  Future<void> play() async {
    _check();
    await player.play();
  }

  @override
  Future<void> pause() async {
    if (!_disposed) await player.pause();
  }

  @override
  Future<void> seek(Duration position) async {
    _check();
    await player.seek(position);
    // The native command is queued before the position event is delivered.
    // Confirm it before another relative seek or progress save reads the clock.
    if ((_snapshot.position - position).abs() > const Duration(seconds: 2)) {
      await player.stream.position
          .firstWhere(
            (value) => (value - position).abs() <= const Duration(seconds: 2),
          )
          .timeout(const Duration(seconds: 10));
    }
    _check();
  }

  @override
  Future<void> setRate(double rate) async {
    _check();
    await player.setRate(rate);
  }

  @override
  Future<void> setVolume(double volume) async {
    _check();
    await player.setVolume(volume);
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    final videoPlatform = await controller.platform.future;
    if (videoPlatform is AndroidVideoController) {
      // Stop new callbacks, then drain pending surface/resize work before the
      // player is destroyed. Otherwise widListener can seek a disposed player.
      videoPlatform.wid.removeListener(videoPlatform.widListener);
      await videoPlatform.videoParamsSubscription?.cancel();
      await videoPlatform.lock.synchronized(player.dispose);
    } else {
      await player.dispose();
    }
    _audio = null;
    await _events.close();
  }
}

// Native messages are inspected locally and discarded; signed URLs never escape.
AppFailure classifyNativePlaybackFailure(String message) {
  final text = message.toLowerCase();
  if (RegExp(r'\b(403|410)\b').hasMatch(text)) {
    return const AppFailure(FailureKind.resourceExpired, '播放地址已失效，正在尝试重新获取');
  }
  if (RegExp(
    r'\b(500|502|503|504)\b|timed out|connection|network|failed to open|error opening',
  ).hasMatch(text)) {
    return const AppFailure(FailureKind.cdn, '播放线路暂不可用');
  }
  return const AppFailure(FailureKind.unsupported, '当前解码器无法播放此内容，请返回选择其他视频');
}
