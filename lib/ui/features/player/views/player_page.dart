import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/providers/playback_providers.dart';
import '../../../../app/providers/repository_providers.dart';
import '../../../../app/providers/ui_providers.dart';
import '../../../../core/result.dart';
import '../../../../domain/playback/playback.dart';
import '../../../core/theme/tv_theme.dart';
import '../../../core/widgets/glass_panel.dart';
import '../../../core/widgets/tv_button.dart';
import '../view_models/player_view_model.dart';

class PlayerPage extends ConsumerStatefulWidget {
  const PlayerPage({
    required this.videoId,
    required this.pageId,
    this.partId,
    this.remoteResume,
    super.key,
  });
  final String videoId, pageId;
  final String? partId;
  final Duration? remoteResume;
  @override
  ConsumerState<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends ConsumerState<PlayerPage> {
  final nodes = List.generate(
    12,
    (i) => FocusNode(debugLabel: 'player-control-$i'),
  );
  final screen = FocusNode(debugLabel: 'player-surface');
  Timer? _hideTimer;
  int? _restoreControl;
  bool leaving = false,
      controls = true,
      menuOpen = false,
      identityChanged = false;
  String? routeOwner, routeScope;
  PlayerViewModelProvider? _provider;
  PlayerViewModelProvider get provider => _provider!;
  PlayerViewModel get vm => ref.read(provider.notifier);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      routeOwner = ref.read(sessionProvider).value?.ownerKey ?? 'guest';
      routeScope = ref.read(sessionProvider).value?.scopeKey;
      _provider = playerViewModelProvider(
        pageId: widget.pageId,
        ownerKey: routeOwner!,
      );
      unawaited(
        vm.start(
          widget.videoId,
          partId: widget.partId,
          remoteResume: widget.remoteResume,
        ),
      );
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final visible = TickerMode.valuesOf(context).enabled;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _provider != null && !leaving && !menuOpen) {
        vm.foregroundChanged(visible && ref.read(appForegroundProvider));
      }
    });
  }

  Future<void> _leave() async {
    if (leaving) return;
    leaving = true;
    _hideTimer?.cancel();
    await vm.close();
    if (!mounted) return;
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/home');
    }
  }

  void _show({bool focus = false}) {
    if (!mounted) return;
    if (!controls) setState(() => controls = true);
    if (focus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !menuOpen) nodes[2].requestFocus();
      });
    }
    _arm();
  }

  void _arm() {
    _hideTimer?.cancel();
    if (_provider == null ||
        ref.read(provider).phase != PlayerPhase.playing ||
        menuOpen) {
      return;
    }
    _hideTimer = Timer(const Duration(seconds: 5), () {
      if (!mounted ||
          menuOpen ||
          ref.read(provider).phase != PlayerPhase.playing) {
        return;
      }
      screen.requestFocus();
      setState(() => controls = false);
    });
  }

  KeyEventResult _controlKey(int index, KeyEvent event) {
    if (!isDirectionEvent(event)) return KeyEventResult.ignored;
    if (leaving) return KeyEventResult.handled;
    if (!const [
      LogicalKeyboardKey.arrowUp,
      LogicalKeyboardKey.arrowDown,
      LogicalKeyboardKey.arrowLeft,
      LogicalKeyboardKey.arrowRight,
    ].contains(event.logicalKey)) {
      return KeyEventResult.ignored;
    }
    _show();
    final phase = ref.read(provider).phase;
    if (phase == PlayerPhase.resolving || phase == PlayerPhase.opening) {
      return KeyEventResult.handled;
    }
    if (phase == PlayerPhase.failed || phase == PlayerPhase.idle) {
      if (event.logicalKey == LogicalKeyboardKey.arrowUp ||
          event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        nodes[0].requestFocus();
      } else {
        nodes[4].requestFocus();
      }
      return KeyEventResult.handled;
    }
    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowUp:
        nodes[index >= 5 ? 2 : 0].requestFocus();
      case LogicalKeyboardKey.arrowDown:
        nodes[index == 0 ? 2 : 5].requestFocus();
      case LogicalKeyboardKey.arrowLeft:
        nodes[index <= 1
                ? 1
                : index == 5
                ? 5
                : index - 1]
            .requestFocus();
      case LogicalKeyboardKey.arrowRight:
        nodes[index == 3
                ? 3
                : index >= 11
                ? 11
                : index + 1]
            .requestFocus();
      default:
        return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  KeyEventResult _screenKey(KeyEvent event) {
    if (leaving) return KeyEventResult.handled;
    if (!isDirectionEvent(event) || menuOpen) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.mediaPlayPause ||
        event.logicalKey == LogicalKeyboardKey.space) {
      unawaited(vm.togglePause());
      _show();
      return KeyEventResult.handled;
    }
    if (!screen.hasPrimaryFocus) return KeyEventResult.ignored;
    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowLeft:
        unawaited(vm.seekBy(const Duration(seconds: -10)));
        _show();
      case LogicalKeyboardKey.arrowRight:
        unawaited(vm.seekBy(const Duration(seconds: 10)));
        _show();
      case LogicalKeyboardKey.select:
      case LogicalKeyboardKey.enter:
        unawaited(vm.togglePause());
        _show();
      case LogicalKeyboardKey.arrowUp:
      case LogicalKeyboardKey.arrowDown:
        _show(focus: true);
      default:
        return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  Future<void> _menu(
    String title,
    List<({String label, String? reason, bool selected, VoidCallback action})>
    items,
    int trigger,
  ) async {
    _hideTimer?.cancel();
    menuOpen = true;
    await showDialog<void>(
      context: context,
      builder: (context) => _PlayerMenu(title: title, items: items),
    );
    menuOpen = false;
    if (!mounted || leaving) return;
    final phase = ref.read(provider).phase;
    _restoreControl =
        phase == PlayerPhase.opening || phase == PlayerPhase.resolving
        ? trigger
        : null;
    vm.foregroundChanged(
      TickerMode.valuesOf(context).enabled && ref.read(appForegroundProvider),
    );
    _show();
    nodes[trigger].requestFocus();
  }

  void _openMenu(int kind) {
    if (leaving) return;
    final state = ref.read(provider);
    switch (kind) {
      case 5:
        unawaited(
          _menu('清晰度 · AVC', [
            for (final q in state.qualities)
              (
                label: q.label,
                reason: q.reason,
                selected: q.id == state.quality,
                action: () => unawaited(vm.selectQuality(q.id)),
              ),
          ], kind),
        );
      case 6:
        unawaited(
          _menu('播放速度', [
            for (final rate in [.5, .75, 1.0, 1.25, 1.5, 2.0])
              (
                label: '$rate×',
                reason: null,
                selected: state.rate == rate,
                action: () => unawaited(vm.setRate(rate)),
              ),
          ], kind),
        );
      case 7:
        unawaited(
          _menu('音轨 · 当前可用 AAC', [
            for (final a in state.audioTracks)
              (
                label: a.label,
                reason: a.reason,
                selected: a.id == state.audioId,
                action: () => unawaited(vm.selectAudio(a.id)),
              ),
          ], kind),
        );
      case 8:
        unawaited(
          _menu('选集 · ${state.parts.length}', [
            for (var i = 0; i < state.parts.length; i++)
              (
                label: 'P${i + 1} · ${state.parts[i].title}',
                reason: null,
                selected: state.partId == state.parts[i].id,
                action: () => unawaited(vm.selectPart(state.parts[i].id)),
              ),
          ], kind),
        );
      case 10:
        unawaited(
          _menu('播放器音量', [
            for (final volume in [0.0, 25.0, 50.0, 75.0, 100.0])
              (
                label: '${volume.round()}%',
                reason: null,
                selected: state.volume == volume,
                action: () => unawaited(vm.setVolume(volume)),
              ),
          ], kind),
        );
    }
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    for (final node in nodes) {
      node.dispose();
    }
    screen.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final owner =
        routeOwner ?? ref.read(sessionProvider).value?.ownerKey ?? 'guest';
    _provider = playerViewModelProvider(pageId: widget.pageId, ownerKey: owner);
    ref.watch(
      provider.select(
        (s) => (
          s.phase,
          s.title,
          s.partTitle,
          s.partId,
          s.quality,
          s.surfaceGeneration,
          s.failure,
          s.notice,
          s.rate,
          s.volume,
          s.autoNext,
          s.snapshot.playing,
          s.snapshot.buffering,
        ),
      ),
    );
    final state = identityChanged
        ? const PlayerState(
            phase: PlayerPhase.failed,
            failure: AppFailure(
              FailureKind.authentication,
              '账号状态已变化，请返回重新打开视频',
            ),
          )
        : ref.read(provider);
    ref.listen(appForegroundProvider, (_, active) {
      vm.foregroundChanged(active && TickerMode.valuesOf(context).enabled);
    });
    ref.listen(sessionProvider, (_, next) {
      if (routeScope != null &&
          next.hasValue &&
          next.value?.scopeKey != routeScope) {
        identityChanged = true;
        unawaited(vm.close());
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && !leaving) {
            setState(() => controls = true);
            nodes[4].requestFocus();
          }
        });
      }
    });
    ref.listen(provider.select((s) => s.phase), (previous, next) {
      if (next == PlayerPhase.playing ||
          next == PlayerPhase.paused ||
          next == PlayerPhase.completed ||
          next == PlayerPhase.failed) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || leaving || menuOpen) return;
          _show();
          if (previous == PlayerPhase.opening ||
              next == PlayerPhase.failed ||
              next == PlayerPhase.paused) {
            nodes[next == PlayerPhase.failed ? 4 : _restoreControl ?? 2]
                .requestFocus();
            _restoreControl = null;
          }
        });
      }
    });
    final busy =
        state.phase == PlayerPhase.resolving ||
        state.phase == PlayerPhase.opening;
    final retry =
        state.phase == PlayerPhase.failed || state.phase == PlayerPhase.idle;
    final engine = identityChanged ? null : vm.engine;
    final label = switch (state.phase) {
      PlayerPhase.idle => '准备播放',
      PlayerPhase.resolving => '正在获取播放资源',
      PlayerPhase.opening => '正在加载画面',
      PlayerPhase.playing => state.snapshot.buffering ? '缓冲中' : '正在播放',
      PlayerPhase.paused => '已暂停',
      PlayerPhase.completed => '播放完毕',
      PlayerPhase.failed => '暂时无法播放',
      PlayerPhase.closed => '正在返回',
    };
    Widget button(
      int index,
      String key,
      String label,
      VoidCallback action, {
      IconData? icon,
    }) => TvButton(
      key: Key(key),
      label: label,
      icon: icon,
      compact: true,
      focusNode: nodes[index],
      onKeyEvent: (event) => _controlKey(index, event),
      onPressed: () {
        if (leaving) return;
        _show();
        action();
      },
    );
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_leave());
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Focus(
          focusNode: screen,
          onKeyEvent: (_, event) => _screenKey(event),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _show(focus: true),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (engine != null && state.phase != PlayerPhase.failed)
                  KeyedSubtree(
                    key: ValueKey(state.surfaceGeneration),
                    child: ref.watch(playbackAdapterProvider).surface(engine),
                  ),
                if (controls || busy || retry) ...[
                  const IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0xB3000000),
                            Colors.transparent,
                            Color(0xD9000000),
                          ],
                          stops: [0, .38, 1],
                        ),
                      ),
                    ),
                  ),
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(TvSpacing.page),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              button(
                                0,
                                'player-back',
                                '返回',
                                () => unawaited(_leave()),
                                icon: CupertinoIcons.chevron_left,
                              ),
                              const SizedBox(width: 18),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      state.title.isEmpty
                                          ? 'MambaTV'
                                          : state.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      state.partTitle,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: TvColors.muted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          Expanded(
                            child: Center(
                              child: busy
                                  ? Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const CupertinoActivityIndicator(
                                          radius: 15,
                                          color: Colors.white,
                                        ),
                                        const SizedBox(height: 16),
                                        Text(label),
                                      ],
                                    )
                                  : retry
                                  ? ConstrainedBox(
                                      constraints: const BoxConstraints(
                                        maxWidth: 480,
                                      ),
                                      child: GlassPanel(
                                        padding: const EdgeInsets.all(20),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              CupertinoIcons
                                                  .exclamationmark_circle,
                                              size: 32,
                                              color: TvColors.accent,
                                            ),
                                            const SizedBox(height: 12),
                                            Text(
                                              state.failure?.message ??
                                                  '确认后开始播放',
                                              textAlign: TextAlign.center,
                                            ),
                                            const SizedBox(height: 12),
                                            button(
                                              4,
                                              'player-retry',
                                              identityChanged
                                                  ? '返回重新选择'
                                                  : '重新播放',
                                              () => unawaited(
                                                identityChanged
                                                    ? _leave()
                                                    : vm.start(
                                                        widget.videoId,
                                                        partId:
                                                            state.partId.isEmpty
                                                            ? widget.partId
                                                            : state.partId,
                                                      ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    )
                                  : const SizedBox.shrink(),
                            ),
                          ),
                          if (!retry && !busy)
                            GlassPanel(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 12,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        label,
                                        key: const Key('player-phase'),
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.white70,
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        '${qualityLabel(state.quality)} · AVC · ${state.rate}×',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Colors.white70,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  _PlayerProgress(provider: provider),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      button(
                                        1,
                                        'player-rewind',
                                        '后退 10 秒',
                                        () => unawaited(
                                          vm.seekBy(
                                            const Duration(seconds: -10),
                                          ),
                                        ),
                                        icon: CupertinoIcons.gobackward_10,
                                      ),
                                      const SizedBox(width: 10),
                                      button(
                                        2,
                                        'player-toggle',
                                        state.phase == PlayerPhase.completed
                                            ? '重播'
                                            : state.snapshot.playing
                                            ? '暂停'
                                            : '播放',
                                        () => unawaited(vm.togglePause()),
                                        icon: state.snapshot.playing
                                            ? CupertinoIcons.pause_fill
                                            : CupertinoIcons.play_fill,
                                      ),
                                      const SizedBox(width: 10),
                                      button(
                                        3,
                                        'player-forward',
                                        '快进 10 秒',
                                        () => unawaited(
                                          vm.seekBy(
                                            const Duration(seconds: 10),
                                          ),
                                        ),
                                        icon: CupertinoIcons.goforward_10,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 6,
                                    alignment: WrapAlignment.center,
                                    children: [
                                      button(
                                        5,
                                        'player-quality',
                                        '清晰度',
                                        () => _openMenu(5),
                                      ),
                                      button(
                                        6,
                                        'player-rate',
                                        '${state.rate}×',
                                        () => _openMenu(6),
                                      ),
                                      button(
                                        7,
                                        'player-audio',
                                        '音轨',
                                        () => _openMenu(7),
                                      ),
                                      button(
                                        8,
                                        'player-parts',
                                        '选集',
                                        () => _openMenu(8),
                                      ),
                                      button(
                                        9,
                                        'player-auto-next',
                                        state.autoNext ? '连播：开' : '连播：关',
                                        () => vm.setAutoNext(!state.autoNext),
                                      ),
                                      button(
                                        10,
                                        'player-volume',
                                        '音量 ${state.volume.round()}%',
                                        () => _openMenu(10),
                                      ),
                                      button(
                                        11,
                                        'player-next',
                                        '下一集',
                                        () => unawaited(vm.nextPart()),
                                      ),
                                    ],
                                  ),
                                  if (state.notice != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 6),
                                      child: Text(
                                        state.notice!,
                                        maxLines: 2,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Colors.amber,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PlayerProgress extends ConsumerWidget {
  const _PlayerProgress({required this.provider});
  final PlayerViewModelProvider provider;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = ref.watch(
      provider.select((s) => (s.snapshot.position, s.snapshot.duration)),
    );
    return Column(
      children: [
        LinearProgressIndicator(
          minHeight: 3,
          backgroundColor: Colors.white12,
          color: Colors.white,
          value: snapshot.$2.inMilliseconds > 0
              ? (snapshot.$1.inMilliseconds / snapshot.$2.inMilliseconds).clamp(
                  0,
                  1,
                )
              : 0,
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              playbackTime(snapshot.$1),
              key: const Key('player-position'),
              style: const TextStyle(
                fontSize: 12,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
            Text(
              playbackTime(snapshot.$2),
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
      ],
    );
  }
}

class _PlayerMenu extends StatefulWidget {
  const _PlayerMenu({required this.title, required this.items});
  final String title;
  final List<
    ({String label, String? reason, bool selected, VoidCallback action})
  >
  items;
  @override
  State<_PlayerMenu> createState() => _PlayerMenuState();
}

class _PlayerMenuState extends State<_PlayerMenu> {
  late final nodes = List.generate(
    widget.items.length,
    (i) => FocusNode(debugLabel: 'player-menu-$i'),
  );
  late final initial = widget.items
      .indexWhere((item) => item.selected)
      .clamp(0, (widget.items.length - 1).clamp(0, 99999));
  late final scroll = ScrollController(initialScrollOffset: initial * 72.0);
  String? reason;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && nodes.isNotEmpty) unawaited(_focus(initial));
    });
  }

  Future<void> _focus(int index) async {
    if (index < 0 || index >= nodes.length) return;
    final target = (index * 72.0).clamp(0.0, scroll.position.maxScrollExtent);
    scroll.jumpTo(target);
    await WidgetsBinding.instance.endOfFrame;
    if (mounted) nodes[index].requestFocus();
  }

  @override
  void dispose() {
    scroll.dispose();
    for (final node in nodes) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Dialog(
    backgroundColor: Colors.transparent,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 430, maxHeight: 430),
      child: GlassPanel(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.title,
              style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            if (reason != null)
              Text(
                reason!,
                key: const Key('player-menu-reason'),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: Colors.amber),
              ),
            if (widget.items.isEmpty)
              const Padding(
                padding: EdgeInsets.all(20),
                child: Text('当前内容没有可切换的选项'),
              ),
            if (widget.items.isNotEmpty)
              Flexible(
                child: ListView.builder(
                  controller: scroll,
                  shrinkWrap: true,
                  itemCount: widget.items.length,
                  itemExtent: 72,
                  itemBuilder: (context, index) {
                    final item = widget.items[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: TvButton(
                        key: ValueKey('player-menu-item-$index'),
                        label: item.label,
                        compact: true,
                        selected: item.selected,
                        icon: item.reason != null
                            ? CupertinoIcons.lock
                            : item.selected
                            ? CupertinoIcons.check_mark
                            : null,
                        focusNode: nodes[index],
                        onKeyEvent: (event) {
                          if (!isDirectionEvent(event)) {
                            return KeyEventResult.ignored;
                          }
                          if (event.logicalKey == LogicalKeyboardKey.arrowUp ||
                              event.logicalKey ==
                                  LogicalKeyboardKey.arrowDown) {
                            unawaited(
                              _focus(
                                index +
                                    (event.logicalKey ==
                                            LogicalKeyboardKey.arrowDown
                                        ? 1
                                        : -1),
                              ),
                            );
                            return KeyEventResult.handled;
                          }
                          // Horizontal arrows belong to the menu, never to the player.
                          if (event.logicalKey ==
                                  LogicalKeyboardKey.arrowLeft ||
                              event.logicalKey ==
                                  LogicalKeyboardKey.arrowRight) {
                            return KeyEventResult.handled;
                          }
                          return KeyEventResult.ignored;
                        },
                        onPressed: () {
                          if (item.reason != null) {
                            setState(() => reason = item.reason);
                            return;
                          }
                          Navigator.of(context).pop();
                          item.action();
                        },
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

String playbackTime(Duration value) {
  final seconds = value.inSeconds.clamp(0, 1 << 53);
  final minutes = seconds ~/ 60;
  final prefix = seconds >= 3600 ? '${seconds ~/ 3600}:' : '';
  return '$prefix${(minutes % (seconds >= 3600 ? 60 : 100000)).toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}';
}
