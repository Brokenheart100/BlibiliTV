import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers/ui_providers.dart';
import '../../../core/result.dart';
import '../../../domain/discovery/content_search.dart';
import '../../../domain/entities/app_models.dart';
import '../../../domain/playback/playback_target.dart';
import '../../core/focus/focus_memory.dart';
import '../../core/theme/tv_theme.dart';
import '../../core/widgets/tv_button.dart';
import '../../core/widgets/tv_grid.dart';
import '../../core/widgets/tv_state_panel.dart';
import '../../core/widgets/tv_video_card.dart';
import 'view_models/content_search_view_model.dart';

class ContentSearchResults extends ConsumerStatefulWidget {
  const ContentSearchResults({
    required this.category,
    required this.query,
    required this.scopeKey,
    required this.controller,
    required this.onTop,
    required this.onInput,
    required this.reducedMotion,
    super.key,
  });
  final SearchCategory category;
  final String query, scopeKey;
  final TvGridController controller;
  final VoidCallback onTop, onInput;
  final bool reducedMotion;
  @override
  ConsumerState<ContentSearchResults> createState() =>
      _ContentSearchResultsState();
}

class _ContentSearchResultsState extends ConsumerState<ContentSearchResults> {
  final action = FocusNode(debugLabel: 'content-search-action');
  ContentSearchViewModelProvider get provider => contentSearchViewModelProvider(
    category: widget.category,
    query: widget.query,
    scopeKey: widget.scopeKey,
  );
  @override
  void dispose() {
    action.dispose();
    super.dispose();
  }

  void _retry() {
    action.requestFocus();
    if (ref.read(provider).hasError) {
      ref.invalidate(provider);
    } else {
      unawaited(ref.read(provider.notifier).refresh());
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(provider);
    final memoryKey =
        '${widget.scopeKey}:search:${widget.category.name}:${widget.query}';
    void left() => TvShellScope.maybeOf(context)?.focusNavigation();
    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onKeyEvent: (_, event) {
        if (!isDirectionEvent(event) || !action.hasFocus) {
          return KeyEventResult.ignored;
        }
        if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
          widget.onTop();
        } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
          left();
        } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
          unawaited(widget.controller.restore());
        } else {
          return KeyEventResult.ignored;
        }
        return KeyEventResult.handled;
      },
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 10, 24, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.query.isEmpty
                        ? '输入关键词，搜索${widget.category.label}'
                        : '“${widget.query}”的${widget.category.label}结果',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: context.tvColors.muted,
                      fontSize: 12,
                    ),
                  ),
                ),
                TvButton(
                  key: const Key('content-search-refresh'),
                  label: '刷新',
                  compact: true,
                  iconOnly: true,
                  icon: CupertinoIcons.refresh,
                  focusNode: action,
                  onPressed: _retry,
                ),
              ],
            ),
            if (state.value?.refreshing == true)
              const LinearProgressIndicator(minHeight: 2),
            if (state.value?.failure case final AppFailure failure)
              Text(
                failure.message,
                maxLines: 2,
                style: TextStyle(color: context.tvColors.muted),
              ),
            const SizedBox(height: 6),
            Expanded(
              child: state.when(
                loading: () =>
                    const Center(child: CupertinoActivityIndicator()),
                error: (error, _) => TvStatePanel(
                  title: '搜索暂不可用',
                  message: error is AppFailure ? error.message : '请稍后重试',
                  actionLabel: '重试',
                  onAction: _retry,
                  focusNode: action,
                ),
                data: (data) => data.items.isEmpty
                    ? TvStatePanel(
                        title: widget.query.isEmpty
                            ? '搜索${widget.category.label}'
                            : '暂时没有找到${widget.category.label}',
                        message: widget.query.isEmpty
                            ? '输入关键词后按搜索键'
                            : '可以换个关键词，或重新搜索',
                        actionLabel: '输入关键词',
                        onAction: widget.onInput,
                      )
                    : TvItemGrid<ContentSearchItem>(
                        key: ValueKey(memoryKey),
                        items: data.items,
                        itemKey: (item) => item.identity,
                        artworkAspectRatio: widget.category.poster
                            ? 3 / 4
                            : 16 / 9,
                        minItemWidth: widget.category.poster ? 120 : 214,
                        memory: ref.read(focusMemoryProvider),
                        memoryKey: memoryKey,
                        controller: widget.controller,
                        reducedMotion: widget.reducedMotion,
                        hasMore: data.nextCursor != null,
                        loadingMore: data.loadingMore,
                        loadMoreFailed: data.loadMoreFailed,
                        onLoadMore: ref.read(provider.notifier).loadMore,
                        onExitLeft: left,
                        onExitUp: widget.onTop,
                        onSelected: (item) async {
                          if (item case LiveSearchItem(broadcasting: false)) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('主播当前未开播')),
                            );
                            return;
                          }
                          await context.push<void>(switch (item) {
                            SeasonSearchItem(:final seasonId) =>
                              '/season/$seasonId',
                            LiveSearchItem(:final roomId) =>
                              PlaybackTarget.live(roomId: roomId).location,
                          });
                          if (mounted) await widget.controller.restore();
                        },
                        itemBuilder: (context, item, bindings) => TvVideoCard(
                          key: ValueKey('search-result-${item.identity}'),
                          video: VideoSummary(
                            id: item.identity,
                            title: item.title,
                            creator: item is LiveSearchItem
                                ? '${item.broadcasting ? "直播中" : "未开播"} · ${item.subtitle}'
                                : item.subtitle,
                            coverUrl: item.coverUrl,
                            creatorAvatarUrl: item is LiveSearchItem
                                ? item.avatarUrl
                                : null,
                            durationSeconds: 0,
                            viewCount: 0,
                          ),
                          poster: widget.category.poster,
                          showViewCount: false,
                          reducedMotion: bindings.reducedMotion,
                          onPressed: bindings.onPressed,
                          onFocus: bindings.onFocus,
                          onKey: bindings.onKey,
                          onAttach: bindings.onAttach,
                          onDetach: bindings.onDetach,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
