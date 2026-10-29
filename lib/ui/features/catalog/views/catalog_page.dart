import '../../content/views/content_pages.dart';

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/providers/repository_providers.dart';
import '../../../../app/providers/ui_providers.dart';
import '../../../../core/result.dart';
import '../../../../domain/entities/app_models.dart';
import '../../../../domain/discovery/home_feed.dart';
import '../../../core/widgets/tv_pill_tabs.dart';
import '../../../core/focus/focus_memory.dart';
import '../../../core/theme/tv_theme.dart';
import '../../../core/widgets/tv_button.dart';
import '../../../core/widgets/tv_grid.dart';
import '../../../core/widgets/tv_state_panel.dart';
import '../../settings/view_models/settings_view_model.dart';
import '../view_models/catalog_view_model.dart';

class CatalogPage extends ConsumerStatefulWidget {
  const CatalogPage({
    required this.section,
    required this.pageId,
    required this.branchIndex,
    required this.title,
    required this.subtitle,
    this.query = '',
    this.registerEntry = true,
    this.compactHeader = false,
    this.forceInitialRefresh = false,
    this.onTop,
    this.controller,
    this.options = const CatalogOptions(),
    super.key,
  });
  final String section, pageId, title, subtitle, query;
  final int branchIndex;
  final bool registerEntry;
  final bool compactHeader;
  final bool forceInitialRefresh;
  final VoidCallback? onTop;
  final TvGridController? controller;
  final CatalogOptions options;
  @override
  ConsumerState<CatalogPage> createState() => _CatalogPageState();
}

class _CatalogPageState extends ConsumerState<CatalogPage> {
  late final grid = widget.controller ?? TvGridController();
  final action = FocusNode(debugLabel: 'catalog-action');
  final liveContent = ContentBrowseController();
  final tabs = [
    for (final feed in HomeFeed.values)
      FocusNode(
        debugLabel:
            'feed-${feed == HomeFeed.recommendation ? 'recommendation' : feed.section}',
      ),
  ];
  final emptyAction = FocusNode(debugLabel: 'catalog-empty-action');
  TvShellScope? shell;
  bool visible = true;
  bool tabRefresh = false;
  bool get active => visible && ref.read(appForegroundProvider);
  String get owner => ref.read(sessionProvider).value?.ownerKey ?? 'guest';
  CatalogViewModelProvider get provider => catalogViewModelProvider(
    section: widget.section,
    pageId: widget.pageId,
    ownerKey: owner,
    query: widget.query,
    options: widget.options == const CatalogOptions() ? null : widget.options,
    forceInitialRefresh: widget.forceInitialRefresh || tabRefresh,
  );
  void _entry() {
    if (widget.section == 'live') {
      liveContent.focusEntry();
      return;
    }
    final value = ref.read(provider).value;
    if (value != null && value.items.isNotEmpty) {
      unawaited(grid.restore());
    } else if (emptyAction.context != null) {
      emptyAction.requestFocus();
    } else {
      action.requestFocus();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    shell = TvShellScope.maybeOf(context);
    if (widget.registerEntry) {
      shell?.registerContent(widget.branchIndex, _entry);
    }
    visible = TickerMode.valuesOf(context).enabled;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final vm = ref.read(provider.notifier);
      if (active) {
        unawaited(vm.resume());
      } else {
        vm.suspend();
      }
    });
  }

  @override
  void dispose() {
    if (widget.registerEntry) {
      shell?.unregisterContent(widget.branchIndex, _entry);
    }
    action.dispose();
    for (final node in tabs) {
      node.dispose();
    }
    emptyAction.dispose();
    super.dispose();
  }

  void _left() {
    if (shell != null) {
      shell!.focusNavigation();
    } else {
      widget.onTop?.call();
    }
  }

  Future<void> _retry() async {
    action.requestFocus();
    if (ref.read(provider).hasError) {
      ref.invalidate(provider);
    } else {
      await ref.read(provider.notifier).refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final ownerKey = ref.watch(sessionProvider).value?.ownerKey ?? 'guest';
    final listProvider = catalogViewModelProvider(
      section: widget.section,
      pageId: widget.pageId,
      ownerKey: ownerKey,
      query: widget.query,
      options: widget.options == const CatalogOptions() ? null : widget.options,
      forceInitialRefresh: widget.forceInitialRefresh || tabRefresh,
    );
    final result = ref.watch(listProvider);
    ref.listen(appForegroundProvider, (_, foreground) {
      if (foreground && visible) {
        unawaited(ref.read(listProvider.notifier).resume());
      } else {
        ref.read(listProvider.notifier).suspend();
      }
    });
    ref.listen(listProvider, (_, next) {
      if (next.value?.paused == true && active) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && active) {
            unawaited(ref.read(listProvider.notifier).resume());
          }
        });
      }
    });
    ref.listen(sessionProvider, (previous, next) {
      if (previous?.value?.ownerKey != next.value?.ownerKey && visible) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _left();
        });
      }
    });
    final reduced =
        ref.watch(settingsViewModelProvider).value?.settings.reducedMotion ??
        false;
    final memoryKey =
        '$ownerKey:${widget.pageId}:${widget.section}:${widget.query}:${widget.options}';
    return Padding(
      padding: EdgeInsets.fromLTRB(24, widget.compactHeader ? 10 : 22, 24, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.compactHeader ? widget.subtitle : widget.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: widget.compactHeader
                          ? Theme.of(context).textTheme.bodySmall
                          : Theme.of(context).textTheme.headlineLarge,
                    ),
                    if (!widget.compactHeader) const SizedBox(height: 3),
                    if (!widget.compactHeader)
                      Text(
                        widget.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: context.tvColors.muted,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              TvButton(
                key: const Key('catalog-refresh'),
                label: '刷新',
                compact: widget.compactHeader,
                iconOnly: widget.compactHeader,
                icon: Icons.refresh,
                focusNode: action,
                onPressed: () => unawaited(_retry()),
                onKeyEvent: (event) {
                  if (!isDirectionEvent(event)) return KeyEventResult.ignored;
                  if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
                    _left();
                    return KeyEventResult.handled;
                  }
                  if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                    _entry();
                    return KeyEventResult.handled;
                  }
                  if (event.logicalKey == LogicalKeyboardKey.arrowUp &&
                      widget.pageId == 'home') {
                    tabs[HomeFeed.fromSection(widget.section).index]
                        .requestFocus();
                    return KeyEventResult.handled;
                  }
                  return KeyEventResult.ignored;
                },
              ),
            ],
          ),
          if (widget.pageId == 'home')
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: TvPillTabs(
                selected: HomeFeed.fromSection(widget.section),
                nodes: tabs,
                reducedMotion: reduced,
                onKey: _tabKey,
                onSelected: (feed) {
                  grid.reset();
                  ref
                      .read(focusMemoryProvider)
                      .forget(
                        '$owner:${widget.pageId}:${feed.section}:${widget.query}:${widget.options}',
                      );
                  if (feed.section == widget.section) {
                    if (feed == HomeFeed.live) {
                      liveContent.refresh();
                    } else if (tabRefresh || widget.forceInitialRefresh) {
                      if (ref.read(listProvider).hasError) {
                        ref.invalidate(listProvider);
                      } else {
                        unawaited(ref.read(listProvider.notifier).refresh());
                      }
                    } else {
                      setState(() => tabRefresh = true);
                    }
                    return;
                  }
                  ref.read(listProvider.notifier).suspend();
                  setState(() => tabRefresh = true);
                  context.go(feed.location);
                },
              ),
            ),
          const SizedBox(height: 14),
          if (result.value?.notice case final String notice)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                notice,
                style: TextStyle(fontSize: 11, color: context.tvColors.muted),
              ),
            ),
          if (result.value?.refreshing == true)
            const LinearProgressIndicator(minHeight: 2),
          if (result.value?.failure case final AppFailure failure)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                failure.message,
                style: const TextStyle(color: Colors.amber),
              ),
            ),
          Expanded(
            child: widget.section == 'live'
                ? ContentBrowseView(
                    live: true,
                    embedded: true,
                    controller: liveContent,
                    onExitUp: () => tabs[HomeFeed.live.index].requestFocus(),
                  )
                : widget.section == 'following' &&
                      ref.watch(sessionProvider).value?.isAuthenticated != true
                ? TvStatePanel(
                    title: '登录后查看关注视频',
                    message: '关注内容按当前账号读取',
                    focusNode: emptyAction,
                    actionLabel: '扫码登录',
                    onAction: () => context.push(
                      '/login?returnTo=%2Fhome%3Ffeed%3Dfollowing',
                    ),
                  )
                : result.when(
                    loading: () => const Center(
                      child: SizedBox(
                        width: 30,
                        height: 30,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                    error: (error, _) => TvStatePanel(
                      title: '暂时没有加载成功',
                      message: error is AppFailure ? error.message : '请稍后重试',
                      actionLabel: '重试',
                      focusNode: emptyAction,
                      icon: Icons.wifi_off_outlined,
                      onAction: () => unawaited(_retry()),
                    ),
                    data: (data) => data.items.isEmpty
                        ? TvStatePanel(
                            title: widget.section == 'library'
                                ? '你的观看故事，从这里开始'
                                : '暂时没有找到内容',
                            message: widget.section == 'library'
                                ? '当前以游客身份浏览，账号列表和观看记录页面将在后续开放。'
                                : '换一个关键词，或重新刷新试试。',
                            actionLabel: data.nextCursor != null
                                ? '继续加载'
                                : widget.section == 'library'
                                ? '了解账号登录'
                                : '重新加载',
                            focusNode: emptyAction,
                            onAction: () {
                              if (data.nextCursor != null) {
                                unawaited(
                                  ref.read(listProvider.notifier).loadMore(),
                                );
                              } else if (widget.section == 'library') {
                                unawaited(context.push<void>('/login'));
                              } else {
                                unawaited(_retry());
                              }
                            },
                          )
                        : TvGrid(
                            key: ValueKey(memoryKey),
                            items: data.items,
                            memory: ref.read(focusMemoryProvider),
                            memoryKey: memoryKey,
                            controller: grid,
                            reducedMotion: reduced,
                            hasMore: data.nextCursor != null,
                            loadingMore: data.loadingMore,
                            loadMoreFailed: data.loadMoreFailed,
                            onExitLeft: _left,
                            onExitUp: widget.onTop ?? action.requestFocus,
                            onLoadMore: ref
                                .read(listProvider.notifier)
                                .loadMore,
                            onSelected: (video) async {
                              await context.push<void>('/video/${video.id}');
                              if (mounted && visible) await grid.restore();
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  KeyEventResult _tabKey(KeyEvent event, int index) {
    if (!isDirectionEvent(event)) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      _entry();
    } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      action.requestFocus();
    } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      tabs[(index + 1).clamp(0, tabs.length - 1)].requestFocus();
    } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      if (index == 0) {
        _left();
      } else {
        tabs[index - 1].requestFocus();
      }
    } else {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }
}
