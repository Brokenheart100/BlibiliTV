import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/providers/repository_providers.dart';
import '../../../../app/providers/ui_providers.dart';
import '../../../../core/result.dart';
import '../../../../domain/playback/playback_target.dart';
import '../../../core/widgets/tv_button.dart';
import '../../../core/widgets/tv_grid.dart';
import '../../../core/widgets/tv_state_panel.dart';
import '../../../core/focus/focus_memory.dart';
import '../../../core/widgets/tv_motion.dart';
import '../../settings/view_models/settings_view_model.dart';
import '../view_models/content_view_models.dart';

export 'season_page.dart';

String? contentInputId(String input, {required bool live}) {
  var value = input.trim();
  final uri = Uri.tryParse(value);
  if (uri != null && uri.hasScheme) {
    if (uri.scheme != 'https' ||
        uri.userInfo.isNotEmpty ||
        uri.host != (live ? 'live.bilibili.com' : 'www.bilibili.com')) {
      return null;
    }
    if (!live && !uri.path.startsWith('/bangumi/play/ss')) return null;
    value = uri.pathSegments.where((s) => s.isNotEmpty).lastOrNull ?? '';
  }
  if (!live && value.startsWith('ss')) value = value.substring(2);
  return RegExp(r'^[1-9][0-9]{0,15}$').hasMatch(value) ? value : null;
}

class ContentBrowsePage extends StatefulWidget {
  const ContentBrowsePage({this.live = false, super.key});
  final bool live;
  @override
  State<ContentBrowsePage> createState() => _ContentBrowsePageState();
}

class _ContentBrowsePageState extends State<ContentBrowsePage> {
  final controller = ContentBrowseController();
  TvShellScope? shell;
  void _entry() => controller.focusEntry();
  void _left() => shell?.focusNavigation();
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    shell = TvShellScope.maybeOf(context);
    shell?.registerContent(5, _entry);
  }

  @override
  void dispose() {
    shell?.unregisterContent(5, _entry);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ContentBrowseView(
    live: widget.live,
    controller: controller,
    navigationRoot: true,
    onExitUp: _left,
  );
}

class ContentBrowseController {
  VoidCallback? _entry;
  VoidCallback? _refresh;
  void focusEntry() => _entry?.call();
  void refresh() => _refresh?.call();
}

class ContentBrowseView extends ConsumerStatefulWidget {
  const ContentBrowseView({
    this.live = false,
    this.embedded = false,
    this.onExitUp,
    this.controller,
    this.navigationRoot = false,
    super.key,
  });
  final bool live, embedded, navigationRoot;
  final VoidCallback? onExitUp;
  final ContentBrowseController? controller;
  @override
  ConsumerState<ContentBrowseView> createState() => _ContentBrowseViewState();
}

class _ContentBrowseViewState extends ConsumerState<ContentBrowseView> {
  final input = TextEditingController();
  final entry = FocusNode(debugLabel: 'content-input');
  final open = FocusNode(debugLabel: 'content-open');
  final refresh = FocusNode(debugLabel: 'content-refresh');
  final link = FocusNode(debugLabel: 'content-link');
  bool showLinkInput = false;
  final grid = TvGridController();
  void _entry() {
    final scope = ref.read(sessionProvider).value?.scopeKey;
    if (!widget.live &&
        scope != null &&
        (ref
                .read(contentBrowseProvider(live: false, scopeKey: scope))
                .value
                ?.items
                .isNotEmpty ??
            false)) {
      unawaited(grid.restore());
    } else {
      (widget.navigationRoot ? link : open).requestFocus();
    }
  }

  @override
  void initState() {
    super.initState();
    widget.controller?._entry = _entry;
    widget.controller?._refresh = _refresh;
  }

  void _refresh() {
    final scope = ref.read(sessionProvider).value?.scopeKey;
    if (scope != null) {
      ref.invalidate(contentBrowseProvider(live: widget.live, scopeKey: scope));
    }
  }

  @override
  void dispose() {
    if (widget.controller?._entry == _entry) widget.controller?._entry = null;
    if (widget.controller?._refresh == _refresh) {
      widget.controller?._refresh = null;
    }
    input.dispose();
    entry.dispose();
    open.dispose();
    refresh.dispose();
    link.dispose();
    super.dispose();
  }

  Future<void> _openId() async {
    final id = contentInputId(input.text, live: widget.live);
    if (id == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('请输入有效的B站链接或编号')));
      entry.requestFocus();
      return;
    }
    entry.unfocus();
    await context.push<void>(
      widget.live ? PlaybackTarget.live(roomId: id).location : '/season/$id',
    );
    if (mounted) {
      if (widget.navigationRoot) {
        setState(() => showLinkInput = false);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) link.requestFocus();
        });
      } else {
        open.requestFocus();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scope = ref.watch(sessionProvider).value?.scopeKey;
    if (scope == null) return const Center(child: CupertinoActivityIndicator());
    final provider = contentBrowseProvider(live: widget.live, scopeKey: scope);
    final state = ref.watch(provider);
    final reduced =
        ref.watch(settingsViewModelProvider).value?.settings.reducedMotion ??
        false;
    return Padding(
      padding: EdgeInsets.all(widget.embedded ? 0 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!widget.embedded)
            TvSceneMotion(
              child: Row(
                children: [
                  if (!widget.navigationRoot)
                    TvButton(
                      label: '返回',
                      icon: CupertinoIcons.chevron_left,
                      onPressed: () => context.canPop()
                          ? context.pop()
                          : context.go('/home'),
                    ),
                  if (!widget.navigationRoot) const SizedBox(width: 18),
                  Expanded(
                    child: Text(
                      widget.live ? '直播' : '番剧与影视',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ),
                  if (widget.navigationRoot) ...[
                    TvButton(
                      key: const Key('content-link-toggle'),
                      label: showLinkInput ? '收起链接' : '打开链接',
                      icon: CupertinoIcons.link,
                      compact: true,
                      focusNode: link,
                      onPressed: () {
                        setState(() => showLinkInput = !showLinkInput);
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) {
                            (showLinkInput ? entry : link).requestFocus();
                          }
                        });
                      },
                      onKeyEvent: (event) {
                        if (!isDirectionEvent(event)) {
                          return KeyEventResult.ignored;
                        }
                        if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
                          widget.onExitUp?.call();
                          return KeyEventResult.handled;
                        }
                        if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                          _entry();
                          return KeyEventResult.handled;
                        }
                        return KeyEventResult.ignored;
                      },
                    ),
                    const SizedBox(width: 8),
                    TvButton(
                      label: '刷新',
                      icon: CupertinoIcons.refresh,
                      iconOnly: true,
                      compact: true,
                      focusNode: refresh,
                      onPressed: () => ref.invalidate(provider),
                      onKeyEvent: (event) {
                        if (!isDirectionEvent(event)) {
                          return KeyEventResult.ignored;
                        }
                        if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
                          link.requestFocus();
                          return KeyEventResult.handled;
                        }
                        if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                          _entry();
                          return KeyEventResult.handled;
                        }
                        return KeyEventResult.ignored;
                      },
                    ),
                  ],
                ],
              ),
            ),
          if (!widget.embedded && (!widget.navigationRoot || showLinkInput))
            const SizedBox(height: 18),
          if (!widget.navigationRoot || showLinkInput)
            Row(
              children: [
                Expanded(
                  child: Focus(
                    onKeyEvent: (_, event) {
                      if (isDirectionEvent(event) &&
                          (event.logicalKey == LogicalKeyboardKey.arrowLeft ||
                              event.logicalKey == LogicalKeyboardKey.arrowUp) &&
                          widget.onExitUp != null) {
                        widget.onExitUp!();
                        return KeyEventResult.handled;
                      }
                      if (event is KeyDownEvent &&
                          event.logicalKey == LogicalKeyboardKey.arrowDown) {
                        open.requestFocus();
                        return KeyEventResult.handled;
                      }
                      return KeyEventResult.ignored;
                    },
                    child: TextField(
                      key: const Key('content-input'),
                      controller: input,
                      focusNode: entry,
                      maxLength: 256,
                      maxLines: 1,
                      decoration: InputDecoration(
                        counterText: '',
                        hintText: widget.live ? '直播间链接或房间号' : '番剧／影视链接或 ss 号',
                      ),
                      onSubmitted: (_) => unawaited(_openId()),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                TvButton(
                  key: const Key('content-open'),
                  label: '打开',
                  focusNode: open,
                  autofocus: !widget.navigationRoot,
                  onPressed: () => unawaited(_openId()),
                  onKeyEvent: (event) {
                    if (!isDirectionEvent(event)) return KeyEventResult.ignored;
                    if (event.logicalKey == LogicalKeyboardKey.arrowLeft &&
                        widget.onExitUp != null) {
                      widget.onExitUp!();
                      return KeyEventResult.handled;
                    }
                    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                      entry.requestFocus();
                      return KeyEventResult.handled;
                    }
                    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                      unawaited(grid.restore());
                      return KeyEventResult.handled;
                    }
                    return KeyEventResult.ignored;
                  },
                ),
                if (!widget.navigationRoot) const SizedBox(width: 8),
                if (!widget.navigationRoot)
                  TvButton(
                    label: '刷新',
                    focusNode: refresh,
                    onPressed: () => ref.invalidate(provider),
                    onKeyEvent: (event) {
                      if (!isDirectionEvent(event)) {
                        return KeyEventResult.ignored;
                      }
                      if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
                        open.requestFocus();
                        return KeyEventResult.handled;
                      }
                      if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                        _entry();
                        return KeyEventResult.handled;
                      }
                      return KeyEventResult.ignored;
                    },
                  ),
              ],
            ),
          const SizedBox(height: 16),
          Expanded(
            child: state.when(
              loading: () => const Center(child: CupertinoActivityIndicator()),
              error: (error, _) => TvStatePanel(
                title: widget.live ? '直播列表暂不可用' : '列表暂不可用',
                message:
                    '${error is AppFailure ? error.message : '请稍后重试'}。也可以在上方直接打开链接或编号。',
                icon: CupertinoIcons.exclamationmark_circle,
                actionLabel: '重试',
                onAction: () => ref.invalidate(provider),
              ),
              data: (data) => data.items.isEmpty
                  ? const Center(child: Text('暂无内容'))
                  : TvGrid(
                      showViewCount: false,
                      poster: !widget.live,
                      reducedMotion: reduced,
                      items: data.items,
                      memory: ref.watch(focusMemoryProvider),
                      memoryKey: '$scope:content:${widget.live}',
                      controller: grid,
                      onSelected: (video) async {
                        await context.push<void>(
                          widget.live
                              ? PlaybackTarget.live(roomId: video.id).location
                              : '/season/${video.id}',
                        );
                        if (mounted) await grid.restore();
                      },
                      onExitLeft: () => widget.onExitUp?.call(),
                      onExitUp: () => open.requestFocus(),
                      onLoadMore: () => ref.read(provider.notifier).loadMore(),
                      hasMore: data.nextPage != null,
                      loadingMore: data.loadingMore,
                      loadMoreFailed: data.failure != null,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
