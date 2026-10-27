import 'dart:async';

import 'package:canvas_danmaku/canvas_danmaku.dart' hide DanmakuItem;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers/ui_providers.dart';
import '../../../../app/providers/overlay_providers.dart';
import '../../../../domain/overlays/overlay_metrics.dart';
import '../../../../domain/overlays/danmaku_load_budget.dart';
import '../../../../domain/overlays/overlays.dart';
import '../../../../domain/playback/playback.dart';
import '../../../../domain/playback/playback_timeline.dart';
import '../view_models/overlay_view_models.dart';

/// Rendering and high frequency clock sampling stay below PlayerPage.
class PlaybackOverlays extends ConsumerWidget {
  const PlaybackOverlays({
    required this.engine,
    required this.videoId,
    required this.partId,
    required this.scopeKey,
    required this.controlsVisible,
    super.key,
  });
  final PlaybackEngine engine;
  final String videoId, partId, scopeKey;
  final bool controlsVisible;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings =
        ref.watch(overlaySettingsViewModelProvider).value ??
        const OverlayPreferences();
    if (!ref.watch(appForegroundProvider) ||
        !TickerMode.valuesOf(context).enabled ||
        !settings.subtitles && !settings.danmaku) {
      return const SizedBox.shrink();
    }
    return _MediaOverlays(
      key: ValueKey((engine, videoId, partId, scopeKey)),
      engine: engine,
      videoId: videoId,
      partId: partId,
      scopeKey: scopeKey,
      preferences: settings,
      controlsVisible: controlsVisible,
    );
  }
}

class _MediaOverlays extends ConsumerStatefulWidget {
  const _MediaOverlays({
    required this.engine,
    required this.videoId,
    required this.partId,
    required this.scopeKey,
    required this.preferences,
    required this.controlsVisible,
    super.key,
  });
  final PlaybackEngine engine;
  final String videoId, partId, scopeKey;
  final OverlayPreferences preferences;
  final bool controlsVisible;
  @override
  ConsumerState<_MediaOverlays> createState() => _MediaOverlaysState();
}

class _MediaOverlaysState extends ConsumerState<_MediaOverlays> {
  final _clock = Stopwatch()..start();
  final _timeline = PlaybackTimeline();
  late final OverlayMetrics _metrics;
  final _caption = ValueNotifier('');
  final _notice = ValueNotifier('');
  final _sent = <String>{};
  Timer? _sampleTimer;
  StreamSubscription<EngineSnapshot>? _subscription;
  DanmakuController<void>? _canvas;
  SubtitleIndex _index = SubtitleIndex(const []);
  List<SubtitleCue>? _cues;
  SubtitleState? _subtitleState;
  List<DanmakuItem> _items = const [];
  late DanmakuLoadBudget _budget;
  int _cursor = 0, _frames = 0, _slow = 0;
  int get _density => _budget.density;
  int _measureAfterUs = 0;
  bool _counted = true, _tickerCounted = false;
  int get _position => _timeline.positionMs(_clock.elapsedMicroseconds);
  DanmakuViewModelProvider get _provider => danmakuViewModelProvider(
    videoId: widget.videoId,
    partId: widget.partId,
    scopeKey: widget.scopeKey,
  );
  @override
  void initState() {
    super.initState();
    _metrics = ref.read(overlayMetricsProvider);
    _metrics.created++;
    _metrics.active++;
    if (_metrics.active > _metrics.maximum) _metrics.maximum = _metrics.active;
    _budget = DanmakuLoadBudget(widget.preferences.density);
    // Loading segments and warming text caches are not sustained raster load.
    _measureAfterUs = _clock.elapsedMicroseconds + 5000000;
    _subscription = widget.engine.snapshots.listen(_snapshot);
    _snapshot(widget.engine.snapshot);
    SchedulerBinding.instance.addTimingsCallback(_timings);
  }

  void _snapshot(EngineSnapshot value) {
    if (_timeline.update(value, _clock.elapsedMicroseconds)) {
      _clear();
      _canvas?.updateOption(_option);
    }
    _syncTicker();
    _frame();
  }

  void _syncTicker() {
    final value = _timeline.snapshot;
    final hasContent =
        widget.preferences.subtitles && !_index.isEmpty ||
        widget.preferences.danmaku && _items.isNotEmpty;
    if (hasContent && value.playing && !value.buffering && !value.completed) {
      // Caption boundaries and admission need a bounded media-clock sample,
      // not a second vsync loop. The canvas owns its animation ticker.
      _sampleTimer ??= Timer.periodic(const Duration(milliseconds: 50), (_) {
        _metrics.clockSamples++;
        _frame();
      });
    } else {
      _sampleTimer?.cancel();
      _sampleTimer = null;
      _canvas?.pause();
    }
    _trackTicker();
  }

  void _trackTicker() {
    final current = _sampleTimer?.isActive ?? false;
    if (current != _tickerCounted) {
      _metrics.activeSchedulers += current ? 1 : -1;
      _tickerCounted = current;
    }
  }

  @override
  void deactivate() {
    _sampleTimer?.cancel();
    _sampleTimer = null;
    _trackTicker();
    _canvas?.pause();
    _subscription?.pause();
    if (_counted) {
      _metrics.active--;
      _counted = false;
    }
    super.deactivate();
  }

  @override
  void activate() {
    super.activate();
    if (!_counted) {
      _metrics.active++;
      _counted = true;
      if (_metrics.active > _metrics.maximum) {
        _metrics.maximum = _metrics.active;
      }
    }
    _subscription?.resume();
    _syncTicker();
  }

  int _lower(int time) {
    var lo = 0, hi = _items.length;
    while (lo < hi) {
      final mid = (lo + hi) ~/ 2;
      if (_items[mid].timeMs < time) {
        lo = mid + 1;
      } else {
        hi = mid;
      }
    }
    return lo;
  }

  void _clear() {
    _metrics.cleared++;
    _canvas?.clear();
    _sent.clear();
    _cursor = _lower(_position);
  }

  DanmakuOption get _option => DanmakuOption(
    fontSize: widget.preferences.fontSize * .8,
    // Alpha belongs to each cached glyph. Group Opacity around the full
    // animated canvas forces a large intermediate surface on Android TV.
    opacity: 1,
    area: widget.preferences.area,
    duration: 6 / _timeline.snapshot.rate,
    staticDuration: 3 / _timeline.snapshot.rate,
    hideTop: !widget.preferences.top,
    hideBottom: !widget.preferences.bottom,
    hideScroll: !widget.preferences.scroll,
    hideSpecial: true,
    safeArea: true,
    massiveMode: false,
  );
  void _frame() {
    if (!mounted) return;
    final position = _position, p = widget.preferences;
    _metrics.lastPositionMs = position;
    _metrics.density = _density;
    // Target cadence; FrameTiming below measures the actual raster cost.
    _metrics.canvasFps = p.danmaku && _canvas != null ? 60 : 0;
    final painted = [...?_canvas?.scrollDanmaku, ...?_canvas?.staticDanmaku];
    _metrics.renderedDanmaku = painted.where((item) => !item.expired).length;
    _metrics.canvasDrawTickMs = painted.fold<int>(
      0,
      (value, item) => (item.drawTick ?? 0) > value ? item.drawTick! : value,
    );
    if (_metrics.renderedDanmaku > _metrics.maximumRenderedDanmaku) {
      _metrics.maximumRenderedDanmaku = _metrics.renderedDanmaku;
    }
    final text = p.subtitles ? _index.at(position, p.offsetMs) : '';
    if (_caption.value != text) {
      _metrics.captionChanges++;
      _caption.value = text;
    }
    if (!p.danmaku) return;
    // The view model acts only when the segment window changes, not per tick.
    if (SchedulerBinding.instance.schedulerPhase !=
        SchedulerPhase.persistentCallbacks) {
      if (ref.read(_provider).hasValue) {
        ref.read(_provider.notifier).moveTo(position);
      }
    }
    if (!_timeline.advancingAt(_clock.elapsedMicroseconds)) {
      if (_canvas?.running == true) _canvas?.pause();
      return;
    }
    if (_canvas?.running == false) _canvas?.resume();
    var scanned = 0;
    while (_canvas != null &&
        _cursor < _items.length &&
        _items[_cursor].timeMs <= position &&
        scanned++ < 500) {
      final entry = _items[_cursor++];
      if (position - entry.timeMs > 250 ||
          !_sent.add(entry.id) ||
          // Include expired objects awaiting lazy cleanup in the memory budget.
          (_canvas!.scrollDanmaku.length + _canvas!.staticDanmaku.length) >=
              _density ||
          p.keywords.any(entry.text.contains)) {
        continue;
      }
      if (entry.mode == 1 && !p.scroll ||
          entry.mode == 4 && !p.bottom ||
          entry.mode == 5 && !p.top) {
        continue;
      }
      final before =
          _canvas!.scrollDanmaku.length + _canvas!.staticDanmaku.length;
      _canvas!.addDanmaku(
        DanmakuContentItem<void>(
          entry.text,
          color: Color(0xff000000 | entry.color).withValues(alpha: p.opacity),
          type: entry.mode == 1
              ? DanmakuItemType.scroll
              : entry.mode == 5
              ? DanmakuItemType.top
              : DanmakuItemType.bottom,
        ),
      );
      final after =
          _canvas!.scrollDanmaku.length + _canvas!.staticDanmaku.length;
      // A full track can reject a comment even below the density limit. Do not
      // reserve six seconds of capacity for text that never reached the screen.
      if (after > before) {
        _metrics.admittedDanmaku++;
        if (after > _metrics.maximumDanmaku) _metrics.maximumDanmaku = after;
      }
    }
    if (scanned >= 500) _cursor = _lower(position + 1);
  }

  void _timings(List<FrameTiming> timings) {
    if (!mounted) return;
    // Measure sustained playback after glass chrome/transition animations close.
    if (widget.controlsVisible ||
        _clock.elapsedMicroseconds < _measureAfterUs ||
        _sampleTimer == null ||
        _items.isEmpty ||
        ref.read(_provider).value?.loading != false ||
        !widget.preferences.danmaku) {
      return;
    }
    for (final timing in timings) {
      _frames++;
      if (timing.rasterDuration.inMicroseconds > 16667) _slow++;
      if (_frames >= 120) {
        _metrics.slowFramePercent = (_slow / _frames * 100).round();
        if (_metrics.loadWindows.length == 64) _metrics.loadWindows.removeAt(0);
        _metrics.loadWindows.add({
          'atMs': _clock.elapsedMilliseconds,
          'fps': _metrics.canvasFps,
          'density': _density,
          'slowPercent': _slow / _frames * 100,
          'items': _items.length,
          'rendered': _metrics.renderedDanmaku,
        });
        final changed = _budget.observeWindow(_slow / _frames);
        _frames = _slow = 0;
        if (changed) {
          _metrics.lowLoadTransitions++;
          _canvas?.updateOption(_option);
          _measureAfterUs = _clock.elapsedMicroseconds + 2000000;
          _notice.value = '弹幕已降低密度以保持播放流畅';
        }
      }
    }
  }

  @override
  void didUpdateWidget(covariant _MediaOverlays oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controlsVisible != widget.controlsVisible) {
      _frames = _slow = 0;
      _budget.resetMeasurements();
      _measureAfterUs = _clock.elapsedMicroseconds + 2000000;
    }
    if (oldWidget.preferences != widget.preferences) {
      _clear();
      if (oldWidget.preferences.danmaku != widget.preferences.danmaku ||
          oldWidget.preferences.density != widget.preferences.density) {
        _budget = DanmakuLoadBudget(widget.preferences.density);
        _frames = _slow = 0;
        _measureAfterUs = _clock.elapsedMicroseconds + 2000000;
        _notice.value = '';
      }
      _canvas?.updateOption(_option);
      if (!widget.preferences.danmaku) _canvas = null;
      _syncTicker();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.preferences.subtitles) {
      final state = ref.watch(
        subtitleViewModelProvider(
          videoId: widget.videoId,
          partId: widget.partId,
          scopeKey: widget.scopeKey,
        ),
      );
      final cues = state.value?.cues ?? const <SubtitleCue>[];
      if (!identical(state.value, _subtitleState) || _cues == null) {
        _subtitleState = state.value;
        _cues = cues;
        _index = SubtitleIndex(cues);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _syncTicker();
            _frame();
          }
        });
      }
    }
    if (widget.preferences.danmaku) {
      final items = ref.watch(_provider).value?.items ?? const <DanmakuItem>[];
      if (!identical(items, _items)) {
        _items = items;
        _measureAfterUs = _clock.elapsedMicroseconds + 2000000;
        _frames = _slow = 0;
        _budget.resetMeasurements();
        _cursor = _lower(_position - 250);
        final ids = items.map((e) => e.id).toSet();
        _sent.retainWhere(ids.contains);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _syncTicker();
            _frame();
          }
        });
      }
    }
    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (widget.preferences.danmaku)
            Padding(
              padding: EdgeInsets.only(
                top: 50,
                bottom: widget.controlsVisible ? 200 : 90,
              ),
              child: ClipRect(
                child: DanmakuScreen<void>(
                  option: _option,
                  createdController: (controller) {
                    _canvas = controller;
                    controller.updateOption(_option);
                    if (_sampleTimer == null) controller.pause();
                  },
                ),
              ),
            ),
          Positioned(
            left: 36,
            right: 36,
            bottom: widget.controlsVisible
                ? 205
                : widget.preferences.subtitleBottom,
            child: RepaintBoundary(
              child: ValueListenableBuilder(
                valueListenable: _caption,
                builder: (_, text, _) => text.isEmpty
                    ? const SizedBox.shrink()
                    : Center(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: .65),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 6,
                            ),
                            child: Text(
                              text,
                              key: const Key('player-subtitle-text'),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: widget.preferences.fontSize,
                                height: 1.3,
                                color: Colors.white,
                                shadows: const [
                                  Shadow(blurRadius: 2, color: Colors.black),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
              ),
            ),
          ),
          Positioned(
            top: 28,
            right: 28,
            child: ValueListenableBuilder(
              valueListenable: _notice,
              builder: (_, text, _) => Text(
                text,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _metrics.disposed++;
    if (_counted) _metrics.active--;
    if (_metrics.active == 0) _metrics.canvasFps = 0;
    _sampleTimer?.cancel();
    _sampleTimer = null;
    _trackTicker();
    SchedulerBinding.instance.removeTimingsCallback(_timings);
    unawaited(_subscription?.cancel());
    _caption.dispose();
    _notice.dispose();
    _clock.stop();
    super.dispose();
  }
}
