import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollCacheExtent;
import 'package:flutter/services.dart';

import '../../../domain/entities/app_models.dart';
import '../focus/focus_memory.dart';
import 'tv_button.dart';
import 'tv_video_card.dart';

class TvGridController {
  _TvGridState? _state;
  Future<void> restore() async {
    await _state?._restore();
  }
}

class TvGrid extends StatefulWidget {
  const TvGrid({
    required this.items,
    required this.memory,
    required this.memoryKey,
    required this.controller,
    required this.onSelected,
    required this.onExitLeft,
    required this.onExitUp,
    required this.onLoadMore,
    required this.hasMore,
    this.loadingMore = false,
    this.loadMoreFailed = false,
    this.reducedMotion = false,
    super.key,
  });
  final List<VideoSummary> items;
  final FocusMemory memory;
  final String memoryKey;
  final TvGridController controller;
  final Future<void> Function(VideoSummary video) onSelected;
  final VoidCallback onExitLeft, onExitUp;
  final Future<void> Function() onLoadMore;
  final bool hasMore, loadingMore, reducedMotion, loadMoreFailed;
  @override
  State<TvGrid> createState() => _TvGridState();
}

class _TvGridState extends State<TvGrid> {
  late final scroll = ScrollController(
    initialScrollOffset: widget.memory.read(widget.memoryKey)?.offset ?? 0,
  );
  final footer = FocusNode(debugLabel: 'grid-footer');
  final nodes = <String, FocusNode>{};
  int columns = 3;
  double rowExtent = 200;
  bool requestingPage = false;
  @override
  void initState() {
    super.initState();
    widget.controller._state = this;
  }

  @override
  void didUpdateWidget(TvGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller._state = null;
      widget.controller._state = this;
    }
  }

  @override
  void dispose() {
    if (widget.controller._state == this) widget.controller._state = null;
    scroll.dispose();
    footer.dispose();
    super.dispose();
  }

  Future<void> _focus(int requested) async {
    if (widget.items.isEmpty || !mounted) return;
    final index = requested.clamp(0, widget.items.length - 1);
    final offset = (index ~/ columns) * rowExtent;
    if (scroll.hasClients) {
      final top = scroll.offset;
      final bottom = top + scroll.position.viewportDimension;
      if (offset < top || offset + rowExtent > bottom) {
        scroll.jumpTo(
          (offset < top
                  ? offset
                  : offset + rowExtent - scroll.position.viewportDimension)
              .clamp(0, scroll.position.maxScrollExtent),
        );
      }
    }
    for (var attempt = 0; attempt < 3 && mounted; attempt++) {
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) return;
      final node = nodes[widget.items[index].id];
      if (node != null && node.context != null) {
        node.requestFocus();
        return;
      }
    }
    if (mounted) widget.onExitUp();
  }

  Future<void> _restore() async {
    final bookmark = widget.memory.read(widget.memoryKey);
    final index = bookmark == null
        ? 0
        : widget.items.indexWhere((v) => v.id == bookmark.id);
    await _focus(index >= 0 ? index : bookmark?.index ?? 0);
  }

  KeyEventResult _key(int index, KeyEvent event) {
    if (!isDirectionEvent(event)) return KeyEventResult.ignored;
    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowLeft:
        if (index % columns == 0) {
          widget.onExitLeft();
        } else {
          unawaited(_focus(index - 1));
        }
      case LogicalKeyboardKey.arrowRight:
        if (index % columns < columns - 1 && index + 1 < widget.items.length) {
          unawaited(_focus(index + 1));
        }
      case LogicalKeyboardKey.arrowUp:
        if (index < columns) {
          widget.onExitUp();
        } else {
          unawaited(_focus(index - columns));
        }
      case LogicalKeyboardKey.arrowDown:
        if (index + columns < widget.items.length) {
          unawaited(_focus(index + columns));
        } else {
          footer.requestFocus();
          unawaited(Scrollable.ensureVisible(footer.context!, alignment: 1));
        }
      default:
        return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  Future<void> _more() async {
    if (!widget.hasMore || widget.loadingMore || requestingPage) return;
    requestingPage = true;
    final oldLength = widget.items.length;
    try {
      await widget.onLoadMore();
      await WidgetsBinding.instance.endOfFrame;
      if (mounted && widget.items.length > oldLength) await _focus(oldLength);
    } finally {
      requestingPage = false;
    }
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      columns = (constraints.maxWidth / 214).floor().clamp(2, 5);
      final width = (constraints.maxWidth - 12 - (columns - 1) * 14) / columns;
      final itemHeight = width * 9 / 16 + 72;
      rowExtent = itemHeight + 14;
      return CustomScrollView(
        key: const Key('catalog-scroll'),
        controller: scroll,
        scrollCacheExtent: ScrollCacheExtent.pixels(rowExtent * 2),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(6),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                mainAxisExtent: itemHeight,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
              ),
              delegate: SliverChildBuilderDelegate((context, index) {
                final video = widget.items[index];
                return TvVideoCard(
                  key: ValueKey('video-${video.id}'),
                  video: video,
                  reducedMotion: widget.reducedMotion,
                  onAttach: (node) => nodes[video.id] = node,
                  onDetach: (node) {
                    if (nodes[video.id] == node) nodes.remove(video.id);
                  },
                  onKey: (event) => _key(index, event),
                  onFocus: () => widget.memory.save(
                    widget.memoryKey,
                    GridBookmark(
                      video.id,
                      index,
                      scroll.hasClients ? scroll.offset : 0,
                    ),
                  ),
                  onPressed: () => unawaited(widget.onSelected(video)),
                );
              }, childCount: widget.items.length),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Center(
                child: TvButton(
                  key: const Key('load-more'),
                  focusNode: footer,
                  label: widget.loadingMore
                      ? '正在加载…'
                      : widget.loadMoreFailed
                      ? '重试加载更多'
                      : widget.hasMore
                      ? '加载更多'
                      : '已经看到全部内容',
                  onPressed: () => unawaited(_more()),
                  onKeyEvent: (event) {
                    if (!isDirectionEvent(event)) return KeyEventResult.ignored;
                    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                      unawaited(_focus(widget.items.length - 1));
                      return KeyEventResult.handled;
                    }
                    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
                      widget.onExitLeft();
                      return KeyEventResult.handled;
                    }
                    return KeyEventResult.ignored;
                  },
                ),
              ),
            ),
          ),
        ],
      );
    },
  );
}
