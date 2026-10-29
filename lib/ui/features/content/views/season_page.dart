import 'dart:async';
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/providers/repository_providers.dart';
import '../../../../core/result.dart';
import '../../../../domain/playback/content_playback.dart';
import '../../../../domain/playback/playback_target.dart';
import '../../../core/images/tv_image_cache.dart';
import '../../../core/theme/tv_theme.dart';
import '../../../core/widgets/liquid_glass_card.dart';
import '../../../core/widgets/tv_button.dart';
import '../../../core/widgets/tv_motion.dart';
import '../../../core/widgets/tv_pill_tabs.dart';
import '../../../core/widgets/tv_state_panel.dart';
import '../view_models/content_view_models.dart';

class SeasonPage extends ConsumerWidget {
  const SeasonPage({required this.id, super.key});
  final String id;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scope = ref.watch(sessionProvider).value?.scopeKey;
    void back() => context.canPop() ? context.pop() : context.go('/pgc');
    if (scope == null) {
      return const Scaffold(body: Center(child: CupertinoActivityIndicator()));
    }
    final provider = contentSeasonProvider(id: id, scopeKey: scope);
    final state = ref.watch(provider);
    return Scaffold(
      body: SafeArea(
        child: state.when(
          loading: () => const Center(child: CupertinoActivityIndicator()),
          error: (error, _) => Column(
            children: [
              TvButton(label: '返回', onPressed: back),
              Expanded(
                child: TvStatePanel(
                  title: '番剧／影视暂不可用',
                  message: error is AppFailure ? error.message : '请稍后重试',
                  actionLabel: '重试',
                  onAction: () => ref.invalidate(provider),
                ),
              ),
            ],
          ),
          data: (season) => _SeasonDetail(
            key: ValueKey('$scope:${season.id}'),
            season: season,
            refreshing: state.isRefreshing,
            onBack: back,
            onRefresh: () => ref.invalidate(provider),
          ),
        ),
      ),
    );
  }
}

class _SeasonDetail extends StatefulWidget {
  const _SeasonDetail({
    required this.season,
    required this.refreshing,
    required this.onBack,
    required this.onRefresh,
    super.key,
  });
  final ContentSeason season;
  final bool refreshing;
  final VoidCallback onBack, onRefresh;
  @override
  State<_SeasonDetail> createState() => _SeasonDetailState();
}

class _SeasonDetailState extends State<_SeasonDetail> {
  final scroll = ScrollController();
  final tabs = List.generate(3, (i) => FocusNode(debugLabel: 'season-tab-$i'));
  final groupNodes = <String, FocusNode>{};
  final rangeNodes = <int, FocusNode>{};
  final episodeNodes = <String, FocusNode>{};
  final play = FocusNode(debugLabel: 'season-play');
  final back = FocusNode(debugLabel: 'season-back');
  final info = FocusNode(debugLabel: 'season-info');
  final gridKey = GlobalKey();
  int tab = 0, group = 0, range = 0, selected = 0, columns = 3;
  bool firstFocus = true;
  int get pageSize => columns * 2;
  List<({String title, List<ContentEpisode> episodes})> get groups => [
    if (widget.season.episodes.isNotEmpty)
      (title: '正片', episodes: widget.season.episodes),
    for (final entry in widget.season.groups.entries)
      if (entry.value.isNotEmpty) (title: entry.key, episodes: entry.value),
    if (widget.season.episodes.isEmpty &&
        widget.season.groups.values.every((e) => e.isEmpty))
      (title: '正片', episodes: <ContentEpisode>[]),
  ];
  List<ContentEpisode> get episodes =>
      groups[group.clamp(0, groups.length - 1)].episodes;
  @override
  void dispose() {
    scroll.dispose();
    for (final node in [
      ...tabs,
      ...groupNodes.values,
      ...rangeNodes.values,
      ...episodeNodes.values,
      play,
      back,
      info,
    ]) {
      node.dispose();
    }
    super.dispose();
  }

  void _show(FocusNode node) {
    node.requestFocus();
    if (node.context != null) {
      final box = node.context!.findRenderObject();
      final rect = box is RenderBox
          ? box.localToGlobal(Offset.zero) & box.size
          : null;
      unawaited(
        Scrollable.ensureVisible(
          node.context!,
          alignmentPolicy: rect != null && (rect.top < 0 || rect.left < 0)
              ? ScrollPositionAlignmentPolicy.keepVisibleAtStart
              : ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
        ),
      );
    }
  }

  Future<void> _focusEpisode(int index) async {
    if (!mounted || index < 0 || index >= episodes.length) return;
    final destination = index ~/ pageSize;
    setState(() {
      range = destination;
      selected = index;
    });
    await WidgetsBinding.instance.endOfFrame;
    if (mounted) {
      final node = episodeNodes[episodes[index].id];
      if (node != null) _show(node);
    }
  }

  Future<void> _playEpisode(int index) async {
    if (episodes.isEmpty) return;
    final episode = episodes[index.clamp(0, episodes.length - 1)];
    await context.push<void>(
      PlaybackTarget.pgc(
        seasonId: widget.season.id,
        episodeId: episode.id,
      ).location,
    );
    if (mounted) await _focusEpisode(index);
  }

  Future<void> _description() async {
    final reader = ScrollController();
    final focus = FocusNode();
    try {
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(widget.season.title),
          content: SizedBox(
            width: 640,
            child: Focus(
              autofocus: true,
              focusNode: focus,
              onKeyEvent: (_, event) {
                if (!isDirectionEvent(event)) return KeyEventResult.ignored;
                if ((event.logicalKey == LogicalKeyboardKey.arrowUp ||
                        event.logicalKey == LogicalKeyboardKey.arrowDown) &&
                    reader.hasClients) {
                  final delta = event.logicalKey == LogicalKeyboardKey.arrowDown
                      ? 100
                      : -100;
                  reader.jumpTo(
                    (reader.offset + delta).clamp(
                      0,
                      reader.position.maxScrollExtent,
                    ),
                  );
                  return KeyEventResult.handled;
                }
                if (event.logicalKey == LogicalKeyboardKey.select ||
                    event.logicalKey == LogicalKeyboardKey.enter) {
                  Navigator.pop(context);
                  return KeyEventResult.handled;
                }
                return KeyEventResult.ignored;
              },
              child: SingleChildScrollView(
                controller: reader,
                child: Text(widget.season.description),
              ),
            ),
          ),
          actions: [
            TvButton(
              label: '关闭',
              compact: true,
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
    } finally {
      reader.dispose();
      focus.dispose();
    }
  }

  void _selectTab(int index) {
    setState(() => tab = index);
    widget.onRefresh();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _show(tabs[index]);
    });
  }

  KeyEventResult _tabKey(KeyEvent event, int index) {
    if (!isDirectionEvent(event)) return KeyEventResult.ignored;
    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowLeft:
        _show(index == 0 ? back : tabs[index - 1]);
      case LogicalKeyboardKey.arrowRight:
        _show(tabs[(index + 1).clamp(0, 2)]);
      case LogicalKeyboardKey.arrowUp:
        _show(play);
      case LogicalKeyboardKey.arrowDown:
        if (tab == 2 || episodes.isEmpty) {
          _show(info);
        } else {
          unawaited(_focusEpisode(selected.clamp(0, episodes.length - 1)));
        }
      default:
        return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  KeyEventResult _episodeKey(int index, KeyEvent event) {
    if (!isDirectionEvent(event)) return KeyEventResult.ignored;
    final local = index - range * pageSize;
    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowLeft:
        if (local % columns == 0) {
          _show(tabs[tab]);
        } else {
          unawaited(_focusEpisode(index - 1));
        }
      case LogicalKeyboardKey.arrowRight:
        if (local % columns < columns - 1) unawaited(_focusEpisode(index + 1));
      case LogicalKeyboardKey.arrowUp:
        if (index >= columns) {
          unawaited(_focusEpisode(index - columns));
        } else {
          _show(rangeNodes[range] ?? tabs[tab]);
        }
      case LogicalKeyboardKey.arrowDown:
        if (index + columns < episodes.length) {
          unawaited(_focusEpisode(index + columns));
        } else {
          _show(info);
        }
      default:
        return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) => Focus(
    canRequestFocus: false,
    skipTraversal: true,
    onKeyEvent: (_, event) {
      // Android dispatches its Back button through the Navigator. Handling
      // goBack here as well can pop twice and reach the shell exit dialog.
      if (event is KeyDownEvent &&
          event.logicalKey == LogicalKeyboardKey.escape) {
        widget.onBack();
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    },
    child: SingleChildScrollView(
      key: const Key('season-detail-scroll'),
      controller: scroll,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SeasonHero(
            season: widget.season,
            playNode: play,
            backNode: back,
            onBack: widget.onBack,
            onPlay: () => unawaited(_playEpisode(selected)),
            onDescription: () => unawaited(_description()),
            onDown: () => _show(tabs[tab]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
            child: TvCapsuleTabs<int>(
              key: const Key('season-detail-tabs'),
              values: const [0, 1, 2],
              selected: tab,
              nodes: tabs,
              label: (index) => const ['作品详情', '选集', '角色与制作'][index],
              tabKey: (index) => ValueKey('season-tab-$index'),
              onSelected: _selectTab,
              onKey: _tabKey,
            ),
          ),
          if (widget.refreshing) const LinearProgressIndicator(minHeight: 2),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: LayoutBuilder(
              builder: (context, constraints) {
                group = group.clamp(0, groups.length - 1);
                selected = episodes.isEmpty
                    ? 0
                    : selected.clamp(0, episodes.length - 1);
                final sidebar = tab == 0 && constraints.maxWidth >= 820;
                final width = constraints.maxWidth - (sidebar ? 250 : 0);
                columns = (width / 185).floor().clamp(2, 4);
                final count = (episodes.length / pageSize).ceil();
                if (range >= count) range = count == 0 ? 0 : count - 1;
                if (firstFocus) {
                  firstFocus = false;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) _show(episodes.isEmpty ? back : play);
                  });
                }
                final cast = _CastPanel(
                  facts: widget.season.facts,
                  full: tab == 2,
                  onMore: () => _selectTab(2),
                  focused: info.hasFocus,
                );
                final castContent = Focus(
                  focusNode: info,
                  onFocusChange: (_) {
                    if (mounted) setState(() {});
                  },
                  onKeyEvent: (_, event) {
                    if (!isDirectionEvent(event)) return KeyEventResult.ignored;
                    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                      _show(tabs[tab]);
                      return KeyEventResult.handled;
                    }
                    if (event.logicalKey == LogicalKeyboardKey.arrowDown &&
                        scroll.hasClients) {
                      scroll.jumpTo(
                        (scroll.offset + 160).clamp(
                          0,
                          scroll.position.maxScrollExtent,
                        ),
                      );
                      return KeyEventResult.handled;
                    }
                    return KeyEventResult.ignored;
                  },
                  child: cast,
                );
                if (tab == 2) return castContent;
                final selections = LiquidGlassCard(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: groups.length * 110.0 + 13,
                        ),
                        child: TvCapsuleTabs<int>(
                          key: const Key('season-group-tabs'),
                          values: List.generate(groups.length, (i) => i),
                          selected: group.clamp(0, groups.length - 1),
                          nodes: [
                            for (var i = 0; i < groups.length; i++)
                              groupNodes.putIfAbsent(
                                groups[i].title,
                                () => FocusNode(debugLabel: 'season-group-$i'),
                              ),
                          ],
                          label: (index) => groups[index].title,
                          tabKey: (index) => ValueKey('season-group-$index'),
                          onSelected: (index) {
                            setState(() {
                              group = index;
                              range = 0;
                              selected = 0;
                            });
                            widget.onRefresh();
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (mounted) {
                                _show(groupNodes[groups[index].title]!);
                              }
                            });
                          },
                          onKey: (event, index) {
                            if (!isDirectionEvent(event)) {
                              return KeyEventResult.ignored;
                            }
                            if (event.logicalKey ==
                                    LogicalKeyboardKey.arrowDown &&
                                episodes.isNotEmpty) {
                              unawaited(
                                _focusEpisode(
                                  selected.clamp(0, episodes.length - 1),
                                ),
                              );
                            } else if (event.logicalKey ==
                                LogicalKeyboardKey.arrowUp) {
                              _show(tabs[tab]);
                            } else if (event.logicalKey ==
                                    LogicalKeyboardKey.arrowRight &&
                                index + 1 < groups.length) {
                              _show(groupNodes[groups[index + 1].title]!);
                            } else if (event.logicalKey ==
                                LogicalKeyboardKey.arrowLeft) {
                              _show(
                                index > 0
                                    ? groupNodes[groups[index - 1].title]!
                                    : tabs[tab],
                              );
                            } else {
                              return KeyEventResult.ignored;
                            }
                            return KeyEventResult.handled;
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (episodes.isNotEmpty)
                        SizedBox(
                          height: 46,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: count,
                            separatorBuilder: (_, _) =>
                                const SizedBox(width: 8),
                            itemBuilder: (_, index) {
                              final node = rangeNodes.putIfAbsent(
                                index,
                                () => FocusNode(
                                  debugLabel: 'season-range-$index',
                                ),
                              );
                              return TvButton(
                                key: ValueKey('season-range-$index'),
                                focusNode: node,
                                compact: true,
                                selected: range == index,
                                label:
                                    '第${index * pageSize + 1}–${((index + 1) * pageSize).clamp(0, episodes.length)}话',
                                onFocusChange: (focus) {
                                  if (focus) _show(node);
                                },
                                onPressed: () {
                                  setState(() {
                                    range = index;
                                    selected = index * pageSize;
                                  });
                                  node.requestFocus();
                                },
                                onKeyEvent: (event) {
                                  if (!isDirectionEvent(event)) {
                                    return KeyEventResult.ignored;
                                  }
                                  if (event.logicalKey ==
                                      LogicalKeyboardKey.arrowDown) {
                                    unawaited(_focusEpisode(range * pageSize));
                                    return KeyEventResult.handled;
                                  }
                                  if (event.logicalKey ==
                                      LogicalKeyboardKey.arrowUp) {
                                    _show(groupNodes[groups[group].title]!);
                                    return KeyEventResult.handled;
                                  }
                                  return KeyEventResult.ignored;
                                },
                              );
                            },
                          ),
                        ),
                      const SizedBox(height: 12),
                      GridView.builder(
                        key: const Key('season-episodes'),
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: EdgeInsets.zero,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columns,
                          mainAxisExtent: 88,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                        itemCount: (episodes.length - range * pageSize).clamp(
                          0,
                          pageSize,
                        ),
                        itemBuilder: (context, local) {
                          final index = range * pageSize + local,
                              episode = episodes[index];
                          final node = episodeNodes.putIfAbsent(
                            episode.id,
                            () =>
                                FocusNode(debugLabel: 'episode-${episode.id}'),
                          );
                          return _EpisodeTile(
                            episode: episode,
                            node: node,
                            selected: selected == index,
                            onFocus: () {
                              selected = index;
                              _show(node);
                            },
                            onKey: (event) => _episodeKey(index, event),
                            onPressed: () => unawaited(_playEpisode(index)),
                          );
                        },
                      ),
                      if (episodes.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text('暂无可播放剧集'),
                        ),
                    ],
                  ),
                );
                return sidebar
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: selections),
                          const SizedBox(width: 18),
                          SizedBox(width: 232, child: castContent),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          selections,
                          const SizedBox(height: 18),
                          castContent,
                        ],
                      );
              },
            ),
          ),
        ],
      ),
    ),
  );
}

class _EpisodeTile extends StatelessWidget {
  const _EpisodeTile({
    required this.episode,
    required this.node,
    required this.selected,
    required this.onFocus,
    required this.onKey,
    required this.onPressed,
  });
  final ContentEpisode episode;
  final FocusNode node;
  final bool selected;
  final VoidCallback onFocus, onPressed;
  final TvKeyHandler onKey;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: node,
    builder: (context, _) => Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onKeyEvent: (_, event) => onKey(event),
      child: TvFocusMotion(
        focused: node.hasFocus,
        child: LiquidGlassCard(
          focused: node.hasFocus,
          radius: 14,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              key: ValueKey('episode-${episode.id}'),
              focusNode: node,
              onTap: onPressed,
              onFocusChange: (focus) {
                if (focus) onFocus();
              },
              child: Row(
                children: [
                  if (episode.coverUrl != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: SizedBox(
                        width: 80,
                        height: 70,
                        child: CachedNetworkImage(
                          imageUrl: episode.coverUrl!,
                          cacheManager: TvImageCache.manager,
                          memCacheWidth: 240,
                          fit: BoxFit.cover,
                          errorWidget: (_, _, _) =>
                              const Icon(CupertinoIcons.play_rectangle),
                        ),
                      ),
                    ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            episode.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: node.hasFocus
                                  ? context.tvColors.accent
                                  : null,
                            ),
                          ),
                          if (episode.restricted)
                            Text(
                              episode.badge.isEmpty ? '需校验权限' : episode.badge,
                              maxLines: 1,
                              style: TextStyle(
                                fontSize: 11,
                                color: context.tvColors.muted,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _SeasonHero extends StatelessWidget {
  const _SeasonHero({
    required this.season,
    required this.playNode,
    required this.backNode,
    required this.onBack,
    required this.onPlay,
    required this.onDown,
    required this.onDescription,
  });
  final ContentSeason season;
  final FocusNode playNode, backNode;
  final VoidCallback onBack, onPlay, onDown, onDescription;
  @override
  Widget build(BuildContext context) {
    final colors = context.tvColors, facts = season.facts;
    final light = Theme.of(context).brightness == Brightness.light;
    KeyEventResult key(KeyEvent event) {
      if (isDirectionEvent(event) &&
          event.logicalKey == LogicalKeyboardKey.arrowDown) {
        onDown();
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }

    return ClipRect(
      child: Stack(
        children: [
          if (season.coverUrl != null)
            Positioned.fill(
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                child: CachedNetworkImage(
                  imageUrl: season.coverUrl!,
                  cacheManager: TvImageCache.manager,
                  memCacheWidth: 96,
                  fit: BoxFit.cover,
                  errorWidget: (_, _, _) => const SizedBox.shrink(),
                ),
              ),
            ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    colors.background.withValues(alpha: light ? .83 : .66),
                    colors.background.withValues(alpha: light ? .93 : .88),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LayoutBuilder(
                  builder: (context, constraints) => Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: constraints.maxWidth < 700 ? 120 : 164,
                        child: AspectRatio(
                          aspectRatio: 3 / 4,
                          child: LiquidGlassCard(
                            radius: 14,
                            child: season.coverUrl == null
                                ? const Icon(CupertinoIcons.film)
                                : CachedNetworkImage(
                                    key: const Key('season-poster'),
                                    imageUrl: season.coverUrl!,
                                    cacheManager: TvImageCache.manager,
                                    memCacheWidth: 480,
                                    maxWidthDiskCache: 480,
                                    fit: BoxFit.contain,
                                    errorWidget: (_, _, _) =>
                                        const Icon(CupertinoIcons.film),
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    season.title,
                                    key: const Key('season-title'),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineMedium,
                                  ),
                                ),
                                if (facts.score != null)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 14),
                                    child: _Rating(facts: facts),
                                  ),
                              ],
                            ),
                            if (facts.tags.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Wrap(
                                  spacing: 7,
                                  runSpacing: 5,
                                  children: [
                                    for (final tag in facts.tags)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 7,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: colors.line,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        child: Text(
                                          tag,
                                          style: const TextStyle(fontSize: 11),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 22,
                              runSpacing: 8,
                              children: [
                                if (facts.views != null)
                                  _Statistic('总播放', _count(facts.views!)),
                                if (facts.followText.isNotEmpty)
                                  _Statistic(
                                    '追番人数',
                                    facts.followText
                                        .replaceAll('系列追番', '')
                                        .replaceAll('人追番', ''),
                                  ),
                                if (facts.danmaku != null)
                                  _Statistic('弹幕总数', _count(facts.danmaku!)),
                              ],
                            ),
                            if (facts.published.isNotEmpty ||
                                facts.status.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: Text(
                                  '${facts.published}  ${facts.status}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: colors.muted,
                                  ),
                                ),
                              ),
                            const SizedBox(height: 10),
                            Text(
                              season.description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                height: 1.5,
                                color: colors.muted,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 10,
                              runSpacing: 8,
                              children: [
                                TvButton(
                                  key: const Key('season-back'),
                                  label: '返回',
                                  icon: CupertinoIcons.chevron_left,
                                  compact: true,
                                  focusNode: backNode,
                                  onPressed: onBack,
                                  onKeyEvent: key,
                                ),
                                if (season.episodes.isNotEmpty ||
                                    season.groups.values.any(
                                      (e) => e.isNotEmpty,
                                    ))
                                  TvButton(
                                    key: const Key('season-play'),
                                    label: '立即播放',
                                    icon: CupertinoIcons.play_fill,
                                    compact: true,
                                    focusNode: playNode,
                                    onPressed: onPlay,
                                    onKeyEvent: key,
                                  ),
                                TvButton(
                                  key: const Key('season-description'),
                                  label: '完整简介',
                                  compact: true,
                                  onPressed: onDescription,
                                  onKeyEvent: key,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _count(int value) => value >= 100000000
    ? '${(value / 100000000).toStringAsFixed(1)}亿'
    : value >= 10000
    ? '${(value / 10000).toStringAsFixed(1)}万'
    : '$value';

class _Statistic extends StatelessWidget {
  const _Statistic(this.label, this.value);
  final String label, value;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: TextStyle(fontSize: 11, color: context.tvColors.muted),
      ),
      const SizedBox(height: 4),
      Text(
        value,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ],
  );
}

class _CastPanel extends StatelessWidget {
  const _CastPanel({
    required this.facts,
    required this.full,
    required this.onMore,
    this.focused = false,
  });
  final SeasonFacts facts;
  final bool full, focused;
  final VoidCallback onMore;
  @override
  Widget build(BuildContext context) => LiquidGlassCard(
    focused: focused,
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('角色配音', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        Text(
          facts.actors.isEmpty ? '暂无配音资料' : facts.actors,
          maxLines: full ? null : 7,
          overflow: full ? TextOverflow.visible : TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 13, height: 1.7),
        ),
        if (full && facts.staff.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text('制作人员', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 10),
          Text(facts.staff, style: const TextStyle(fontSize: 13, height: 1.7)),
        ],
        if (!full)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: TvButton(label: '展开更多', compact: true, onPressed: onMore),
          ),
      ],
    ),
  );
}

class _Rating extends StatelessWidget {
  const _Rating({required this.facts});
  final SeasonFacts facts;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        facts.score!.toStringAsFixed(1),
        key: const Key('season-rating'),
        style: const TextStyle(
          fontSize: 30,
          color: Color(0xFFFFA323),
          fontWeight: FontWeight.w600,
        ),
      ),
      const SizedBox(width: 8),
      Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const Text(
            '★★★★★',
            style: TextStyle(color: Color(0xFFFFA323), fontSize: 13),
          ),
          if (facts.ratingCount != null)
            Text(
              '${facts.ratingCount}人评价',
              style: TextStyle(fontSize: 11, color: context.tvColors.muted),
            ),
        ],
      ),
    ],
  );
}
