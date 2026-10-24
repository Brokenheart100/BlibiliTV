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
import '../../../core/theme/tv_theme.dart';
import '../../../core/widgets/glass_panel.dart';
import '../../../core/widgets/tv_button.dart';
import '../view_models/player_view_model.dart';

class PlayerPage extends ConsumerStatefulWidget {
  const PlayerPage({
    required this.videoId,
    required this.pageId,
    this.partId,
    super.key,
  });
  final String videoId, pageId;
  final String? partId;
  @override
  ConsumerState<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends ConsumerState<PlayerPage> {
  final nodes = List.generate(
    5,
    (i) => FocusNode(debugLabel: 'player-control-$i'),
  );
  bool leaving = false;
  String? routeOwner;
  String? routeScope;
  bool identityChanged = false;
  late PlayerViewModelProvider provider;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      routeOwner = ref.read(sessionProvider).value?.ownerKey ?? 'guest';
      routeScope = ref.read(sessionProvider).value?.scopeKey;
      provider = playerViewModelProvider(
        pageId: widget.pageId,
        ownerKey: routeOwner!,
      );
      // Opening belongs to this route-entry event, never Provider.build.
      unawaited(
        ref
            .read(provider.notifier)
            .start(widget.videoId, partId: widget.partId),
      );
    });
  }

  Future<void> _leave() async {
    if (leaving) return;
    leaving = true;
    await ref.read(provider.notifier).close();
    if (mounted) {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/home');
      }
    }
  }

  @override
  void dispose() {
    for (final node in nodes) {
      node.dispose();
    }
    super.dispose();
  }

  KeyEventResult _key(int index, KeyEvent event) {
    if (!isDirectionEvent(event)) return KeyEventResult.ignored;
    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowUp:
        nodes[0].requestFocus();
      case LogicalKeyboardKey.arrowDown:
        nodes[2].requestFocus();
      case LogicalKeyboardKey.arrowLeft:
        nodes[index <= 1 ? 1 : index - 1].requestFocus();
      case LogicalKeyboardKey.arrowRight:
        nodes[index >= 3 ? 3 : index + 1].requestFocus();
      case LogicalKeyboardKey.mediaPlayPause:
      case LogicalKeyboardKey.space:
        unawaited(ref.read(provider.notifier).togglePause());
      default:
        return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final owner =
        routeOwner ?? ref.read(sessionProvider).value?.ownerKey ?? 'guest';
    provider = playerViewModelProvider(pageId: widget.pageId, ownerKey: owner);
    // Position updates rebuild only the controls Consumer below, not the video.
    ref.watch(
      provider.select(
        (s) => (
          s.phase,
          s.title,
          s.partTitle,
          s.quality,
          s.resumedFrom,
          s.failure,
          s.notice,
          s.surfaceGeneration,
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
    final vm = ref.read(provider.notifier);
    ref.listen(appForegroundProvider, (_, active) {
      if (!active) unawaited(vm.suspend());
    });
    ref.listen(sessionProvider, (_, next) {
      if (routeScope != null &&
          next.hasValue &&
          next.value?.scopeKey != routeScope) {
        identityChanged = true;
        unawaited(vm.close());
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && !leaving) {
            setState(() {});
            nodes[4].requestFocus();
          }
        });
      }
    });
    ref.listen(provider, (previous, next) {
      final ready =
          next.phase == PlayerPhase.playing || next.phase == PlayerPhase.paused;
      final wasReady =
          previous?.phase == PlayerPhase.playing ||
          previous?.phase == PlayerPhase.paused;
      if ((ready && !wasReady) || next.phase == PlayerPhase.failed) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && !leaving) {
            nodes[next.phase == PlayerPhase.failed ? 4 : 2].requestFocus();
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
    final snapshot = state.snapshot;
    final label = switch (state.phase) {
      PlayerPhase.idle => '准备播放',
      PlayerPhase.resolving => '正在获取播放资源',
      PlayerPhase.opening => '正在加载画面',
      PlayerPhase.playing => snapshot.buffering ? '缓冲中' : '正在播放',
      PlayerPhase.paused => '已暂停',
      PlayerPhase.completed => '播放完毕',
      PlayerPhase.failed => '暂时无法播放',
      PlayerPhase.closed => '正在返回',
    };
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_leave());
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            if (engine != null && state.phase != PlayerPhase.failed)
              ref.watch(playbackAdapterProvider).surface(engine),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        TvButton(
                          key: const Key('player-back'),
                          label: '返回',
                          icon: CupertinoIcons.chevron_left,
                          focusNode: nodes[0],
                          autofocus: true,
                          onKeyEvent: (e) => _key(0, e),
                          onPressed: () => unawaited(_leave()),
                        ),
                        const SizedBox(width: 18),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                state.title.isEmpty ? 'MambaTV' : state.title,
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
                                  padding: const EdgeInsets.all(24),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        CupertinoIcons.exclamationmark_circle,
                                        size: 38,
                                        color: TvColors.accent,
                                      ),
                                      const SizedBox(height: 14),
                                      Text(
                                        state.failure?.message ?? '确认后开始播放',
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 20),
                                      TvButton(
                                        key: const Key('player-retry'),
                                        label: identityChanged
                                            ? '返回重新选择'
                                            : '重新播放',
                                        focusNode: nodes[4],
                                        onPressed: () => unawaited(
                                          identityChanged
                                              ? _leave()
                                              : vm.start(
                                                  widget.videoId,
                                                  partId: widget.partId,
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
                    Consumer(
                      builder: (context, ref, _) {
                        final snapshot = ref.watch(
                          provider.select((s) => s.snapshot),
                        );
                        return GlassPanel(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 22,
                            vertical: 16,
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
                                  if (state.resumedFrom > Duration.zero)
                                    Text(
                                      '从 ${playbackTime(state.resumedFrom)} 继续  ·  ',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Colors.white70,
                                      ),
                                    ),
                                  if (state.quality > 0)
                                    Text(
                                      '${state.quality == 16
                                          ? '360P'
                                          : state.quality == 32
                                          ? '480P'
                                          : state.quality} · AVC',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Colors.white70,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  minHeight: 3,
                                  backgroundColor: Colors.white12,
                                  color: Colors.white,
                                  value: snapshot.duration.inMilliseconds > 0
                                      ? (snapshot.position.inMilliseconds /
                                                snapshot
                                                    .duration
                                                    .inMilliseconds)
                                            .clamp(0, 1)
                                      : 0,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Text(
                                    playbackTime(snapshot.position),
                                    key: const Key('player-position'),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontFeatures: [
                                        FontFeature.tabularFigures(),
                                      ],
                                    ),
                                  ),
                                  const Spacer(),
                                  TvButton(
                                    key: const Key('player-rewind'),
                                    label: '后退 10 秒',
                                    compact: true,
                                    icon: CupertinoIcons.gobackward_10,
                                    focusNode: nodes[1],
                                    onKeyEvent: (e) => _key(1, e),
                                    onPressed: () => unawaited(
                                      vm.seekBy(const Duration(seconds: -10)),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  TvButton(
                                    key: const Key('player-toggle'),
                                    label: state.phase == PlayerPhase.completed
                                        ? '重播'
                                        : snapshot.playing
                                        ? '暂停'
                                        : '播放',
                                    compact: true,
                                    icon: snapshot.playing
                                        ? CupertinoIcons.pause_fill
                                        : CupertinoIcons.play_fill,
                                    focusNode: nodes[2],
                                    onKeyEvent: (e) => _key(2, e),
                                    onPressed: () =>
                                        unawaited(vm.togglePause()),
                                  ),
                                  const SizedBox(width: 10),
                                  TvButton(
                                    key: const Key('player-forward'),
                                    label: '快进 10 秒',
                                    compact: true,
                                    icon: CupertinoIcons.goforward_10,
                                    focusNode: nodes[3],
                                    onKeyEvent: (e) => _key(3, e),
                                    onPressed: () => unawaited(
                                      vm.seekBy(const Duration(seconds: 10)),
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    playbackTime(snapshot.duration),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                              if (state.notice case final String notice)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    notice,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.amber,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String playbackTime(Duration value) {
  final seconds = value.inSeconds.clamp(0, 1 << 53);
  final minutes = seconds ~/ 60;
  final prefix = seconds >= 3600 ? '${seconds ~/ 3600}:' : '';
  return '$prefix${(minutes % (seconds >= 3600 ? 60 : 100000)).toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}';
}
