import 'dart:async';

import 'package:better_player/better_player.dart' as bp;
import 'package:flutter/widgets.dart';

import '../../../core/result.dart';
import '../../../domain/playback/playback.dart';
import '../bilibili/bilibili_api.dart';
import 'dash_manifest.dart';
import 'loopback_dash_manifest.dart';
import 'media_kit_engine.dart' show classifyNativePlaybackFailure;

/// Uses Better Player's exported engine API with our existing TV controls.
class BetterPlayerEngine implements PlaybackEngine {
  BetterPlayerEngine() {
    // The native logger can include full source URLs. Keep it disconnected.
    unawaited(bp.BetterPlayerPlatform.instance.setupLogCallback(null));
    controller = bp.PlayerEngineController();
    controller.addListener(_publish);
    _subscription = controller.videoEventStreamController.stream.listen(
      (event) {
        if (_disposed) return;
        if (event.eventType == bp.VideoEventType.completed) {
          _completed = true;
          _nativePosition = controller.value.duration;
        }
        _publish();
      },
      onError: (Object error) {
        if (!_disposed) {
          _emit(
            _snapshot.copyWith(
              playing: false,
              failure: classifyNativePlaybackFailure(error.toString()),
            ),
          );
        }
      },
    );
  }

  late final bp.PlayerEngineController controller;
  late final StreamSubscription<bp.VideoEvent> _subscription;
  final _events = StreamController<EngineSnapshot>.broadcast(sync: true);
  EngineSnapshot _snapshot = const EngineSnapshot();
  LoopbackDashManifest? _manifest;
  Timer? _clockTimer;
  bool _disposed = false,
      _completed = false,
      _seeking = false,
      _polling = false;
  int _clockEpoch = 0;
  Duration? _nativePosition;
  double _rate = 1, _volume = 100;

  @override
  EngineSnapshot get snapshot => _snapshot;
  @override
  Stream<EngineSnapshot> get snapshots => _events.stream;

  void _check() {
    if (_disposed) throw const AppFailure(FailureKind.cancelled, '已停止播放');
  }

  void _emit(EngineSnapshot value) {
    if (_disposed || value == _snapshot) return;
    _snapshot = value;
    _events.add(value);
  }

  void _publish() {
    if (_disposed) return;
    final value = controller.value;
    final position = _nativePosition ?? value.position;
    var buffered = Duration.zero;
    if (!_seeking) {
      for (final range in value.buffered) {
        if (range.start <= position &&
            position <= range.end &&
            range.end > buffered) {
          buffered = range.end;
        }
      }
    }
    _emit(
      _snapshot.copyWith(
        playing: value.isPlaying,
        buffering: value.isBuffering,
        completed: _completed,
        position: position,
        duration: value.duration ?? Duration.zero,
        bufferedPosition: buffered,
        width: value.size?.width.round() ?? 0,
        height: value.size?.height.round() ?? 0,
        rate: _rate,
        volume: _volume,
        failure: value.hasError
            ? classifyNativePlaybackFailure(value.errorDescription!)
            : _snapshot.failure,
      ),
    );
    if (value.isPlaying && value.initialized && !_completed) {
      // Better Player polls at 300 ms; overlays require a fresh native clock
      // within 250 ms. This bounded sampler never interpolates native time.
      _clockTimer ??= Timer.periodic(
        const Duration(milliseconds: 100),
        (_) => unawaited(_sampleClock()),
      );
    } else {
      _clockTimer?.cancel();
      _clockTimer = null;
    }
  }

  Future<void> _sampleClock() async {
    if (_disposed || _seeking || _polling || !controller.value.initialized) {
      return;
    }
    _polling = true;
    final epoch = _clockEpoch;
    try {
      final position = await controller.position;
      if (!_disposed && epoch == _clockEpoch && position != null) {
        _nativePosition = position;
        _publish();
      }
    } catch (_) {
      // Platform playback errors arrive on the event stream, with safe mapping.
    } finally {
      _polling = false;
    }
  }

  @override
  Future<void> open(
    PlaybackSource source, {
    required Duration startAt,
    bool play = true,
  }) async {
    _check();
    _clockEpoch++;
    _completed = false;
    _seeking = true;
    _nativePosition = null;
    _emit(const EngineSnapshot());
    try {
      final manifest = source.transport == PlaybackTransport.dash
          ? await LoopbackDashManifest.serve(buildDashManifest(source))
          : null;
      if (_disposed) {
        await manifest?.close();
        _check();
      }
      await _manifest?.close();
      _manifest = manifest;
      await controller
          .setNetworkDataSource(
            manifest?.uri.toString() ?? source.videoUrl,
            formatHint: switch (source.transport) {
              PlaybackTransport.dash => bp.VideoFormat.dash,
              PlaybackTransport.hls => bp.VideoFormat.hls,
              _ => null,
            },
            headers: {...bilibiliMediaHeaders, ...source.headers},
            useCache: false,
          )
          .timeout(const Duration(seconds: 30));
      _check();
      await controller.setVolume(_volume / 100);
      await controller.setSpeed(_rate);
      _seeking = false;
      if (startAt > Duration.zero) await seek(startAt);
      if (play) {
        await controller.play();
      } else {
        await controller.pause();
      }
      await _sampleClock();
      _publish();
    } on AppFailure {
      rethrow;
    } on TimeoutException {
      throw const AppFailure(FailureKind.timeout, '视频加载超时，请重试');
    } catch (error) {
      throw classifyNativePlaybackFailure(error.toString());
    }
  }

  @override
  Future<void> play() async {
    _check();
    _completed = false;
    await controller.play();
  }

  @override
  Future<void> pause() async {
    if (_disposed) return;
    await controller.pause();
    await _sampleClock();
  }

  @override
  Future<void> seek(Duration position) async {
    _check();
    _clockEpoch++;
    _seeking = true;
    _completed = false;
    _emit(
      _snapshot.copyWith(bufferedPosition: Duration.zero, completed: false),
    );
    try {
      await controller.seekTo(position);
      final clock = Stopwatch()..start();
      var stable = 0;
      while (clock.elapsed < const Duration(seconds: 10)) {
        _check();
        final actual = await controller.position;
        final elapsed = Duration(
          microseconds: (clock.elapsedMicroseconds * _rate).round(),
        );
        // Android 1.9.0 declares onSeek but does not emit it. Read Media3's
        // currentPosition and bufferedPosition instead of Dart's optimistic
        // value.position or an event that this backend never sends.
        final hasBuffer =
            actual != null &&
            controller.value.buffered.any(
              (range) => range.start <= actual && range.end > actual,
            );
        stable =
            hasBuffer &&
                !controller.value.isBuffering &&
                actual >= position - const Duration(seconds: 1) &&
                actual <= position + elapsed + const Duration(seconds: 1)
            ? stable + 1
            : 0;
        if (stable >= 2) {
          _nativePosition = actual;
          _seeking = false;
          _publish();
          return;
        }
        await Future<void>.delayed(const Duration(milliseconds: 80));
      }
      throw const AppFailure(FailureKind.timeout, '跳转未就绪，请重试');
    } catch (error) {
      if (error is AppFailure) rethrow;
      throw classifyNativePlaybackFailure(error.toString());
    }
  }

  @override
  Future<void> setRate(double rate) async {
    _check();
    _rate = rate;
    if (controller.value.initialized) await controller.setSpeed(rate);
    _publish();
  }

  @override
  Future<void> setVolume(double volume) async {
    _check();
    _volume = volume;
    if (controller.value.initialized) await controller.setVolume(volume / 100);
    _publish();
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _clockEpoch++;
    _clockTimer?.cancel();
    controller.removeListener(_publish);
    await _subscription.cancel();
    try {
      await controller.dispose();
    } finally {
      await _manifest?.close();
      _manifest = null;
      await _events.close();
    }
  }
}

class BetterPlayerSurface extends StatefulWidget {
  const BetterPlayerSurface(this.engine, {super.key});
  final BetterPlayerEngine engine;
  @override
  State<BetterPlayerSurface> createState() => _BetterPlayerSurfaceState();
}

class _BetterPlayerSurfaceState extends State<BetterPlayerSurface> {
  late final size = ValueNotifier<Size?>(widget.engine.controller.value.size);
  void _geometryChanged() => size.value = widget.engine.controller.value.size;
  @override
  void initState() {
    super.initState();
    widget.engine.controller.addListener(_geometryChanged);
  }

  @override
  void didUpdateWidget(covariant BetterPlayerSurface oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.engine != widget.engine) {
      oldWidget.engine.controller.removeListener(_geometryChanged);
      widget.engine.controller.addListener(_geometryChanged);
      _geometryChanged();
    }
  }

  @override
  void dispose() {
    widget.engine.controller.removeListener(_geometryChanged);
    size.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: ColoredBox(
      color: const Color(0xFF000000),
      child: ValueListenableBuilder<Size?>(
        valueListenable: size,
        child: bp.PlayerEngineView(widget.engine.controller),
        builder: (context, size, child) {
          return ClipRect(
            child: SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.contain,
                child: SizedBox(
                  width: size != null && size.width > 0 ? size.width : 1,
                  height: size != null && size.height > 0 ? size.height : 1,
                  child: child,
                ),
              ),
            ),
          );
        },
      ),
    ),
  );
}
