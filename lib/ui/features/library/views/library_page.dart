import '../../../../domain/playback/playback_target.dart';

import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/providers/repository_providers.dart';
import '../../../../domain/entities/app_models.dart';
import '../../../../domain/library/library.dart';
import '../../../core/theme/tv_theme.dart';
import '../../../core/focus/focus_memory.dart';
import '../../../core/widgets/liquid_glass_card.dart';
import '../../../core/widgets/creator_avatar.dart';
import '../../../core/widgets/tv_button.dart';
import '../../../core/widgets/tv_dialog.dart';
import '../../../core/widgets/tv_video_card.dart';
import '../view_models/library_view_model.dart';
import 'personal_actions_dialog.dart';

class LibraryPage extends ConsumerStatefulWidget {
  const LibraryPage({
    this.historyOnly = false,
    this.branchIndex,
    this.initialSection = LibrarySection.local,
    this.initialFolderId,
    this.initialFolderTitle,
    super.key,
  });
  final bool historyOnly;
  final int? branchIndex;
  final LibrarySection initialSection;
  final String? initialFolderId, initialFolderTitle;
  @override
  ConsumerState<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends ConsumerState<LibraryPage> {
  LibrarySection section = LibrarySection.local;
  String? folderId, folderTitle, scope;
  final back = FocusNode(debugLabel: 'library-back');
  final refresh = FocusNode(debugLabel: 'library-refresh');
  final clear = FocusNode(debugLabel: 'library-clear');
  final footer = FocusNode(debugLabel: 'library-footer');
  late final tabs = List.generate(
    sections.length,
    (i) => FocusNode(debugLabel: 'library-tab-$i'),
  );
  final rows = <String, List<FocusNode>>{};
  final scroll = ScrollController();
  late final sections = widget.historyOnly
      ? [LibrarySection.local, LibrarySection.remote]
      : [
          LibrarySection.local,
          LibrarySection.remote,
          LibrarySection.folders,
          LibrarySection.watchLater,
        ];
  late final labels = widget.historyOnly
      ? ['本地观看', 'B站历史']
      : ['本地观看', 'B站历史', '收藏夹', '稍后再看'];
  TvShellScope? shell;
  void _entry() => tabs[tabIndex].requestFocus();
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    shell = TvShellScope.maybeOf(context);
    if (widget.branchIndex != null) {
      shell?.registerContent(widget.branchIndex!, _entry);
    }
  }

  late LibraryViewModelProvider provider;
  List<LibraryEntry> items = [];
  @override
  void dispose() {
    if (widget.branchIndex != null) {
      shell?.unregisterContent(widget.branchIndex!, _entry);
    }
    for (final node in [
      back,
      refresh,
      clear,
      footer,
      ...tabs,
      ...rows.values.expand((v) => v),
    ]) {
      node.dispose();
    }
    scroll.dispose();
    super.dispose();
  }

  int get tabIndex =>
      section == LibrarySection.folder ? 2 : sections.indexOf(section);
  void _select(LibrarySection next, {String? id, String? title}) {
    setState(() {
      section = next;
      folderId = id;
      folderTitle = title;
    });
    if (scroll.hasClients) scroll.jumpTo(0);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) tabs[tabIndex].requestFocus();
    });
  }

  Future<void> _focusRow(int index, {int action = 0}) async {
    if (index < 0) {
      tabs[tabIndex].requestFocus();
      return;
    }
    if (items.isEmpty) {
      footer.requestFocus();
      return;
    }
    if (index >= items.length) {
      footer.requestFocus();
      return;
    }
    if (scroll.hasClients) {
      scroll.jumpTo((index * 118.0).clamp(0, scroll.position.maxScrollExtent));
    }
    await WidgetsBinding.instance.endOfFrame;
    if (mounted && index < items.length) {
      rows[items[index].key]?[items[index].folderId == null ? action : 0]
          .requestFocus();
    }
  }

  void _back() {
    if (section == LibrarySection.folder) {
      _select(LibrarySection.folders);
    } else if (widget.branchIndex != null) {
      shell?.focusNavigation();
    } else if (context.canPop()) {
      context.pop();
    } else {
      context.go('/library');
    }
  }

  Future<void> _open(LibraryEntry item) async {
    if (item.folderId != null) {
      _select(
        LibrarySection.folder,
        id: item.folderId,
        title: item.video.title,
      );
      return;
    }
    if (item.unavailableReason != null) return;
    if (item.target != null) {
      await context.push<void>(item.target!.location);
    } else if (section == LibrarySection.local ||
        section == LibrarySection.remote) {
      final parameters = <String, String>{
        if (item.partId != null) 'part': item.partId!,
        if (section == LibrarySection.remote)
          'remote_ms': '${item.position.inMilliseconds}',
      };
      await context.push<void>(
        Uri(
          path: '/player/${item.video.id}',
          queryParameters: parameters,
        ).toString(),
      );
    } else {
      await context.push<void>('/video/${item.video.id}');
    }
    if (!mounted) return;
    await ref.read(provider.notifier).refresh();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) rows[item.key]?.first.requestFocus();
    });
  }

  Future<void> _remove(String? videoId, {PlaybackTarget? target}) async {
    final originalProvider = provider;
    final originalScope = scope;
    final confirmed = await showTvConfirmation(
      context,
      title: videoId == null ? '清空本地观看记录？' : '删除这条本地记录？',
      message: '仅删除本机当前身份的观看记录，不影响B站历史、登录、设置或其他账号。',
      confirmLabel: '删除记录',
    );
    if (!confirmed ||
        !mounted ||
        originalScope != ref.read(sessionProvider).value?.scopeKey) {
      return;
    }
    await ref
        .read(originalProvider.notifier)
        .removeLocal(videoId, target: target);
    if (mounted) refresh.requestFocus();
  }

  Future<void> _manage(LibraryEntry item, String owner) async {
    await showDialog<void>(
      context: context,
      traversalEdgeBehavior: TraversalEdgeBehavior.closedLoop,
      builder: (_) =>
          PersonalActionsDialog(videoId: item.video.id, ownerKey: owner),
    );
    if (mounted) rows[item.key]?.last.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider).value ?? const Session();
    if (scope != session.scopeKey) {
      final initial = scope == null;
      scope = session.scopeKey;
      section = initial ? widget.initialSection : LibrarySection.local;
      folderId = initial ? widget.initialFolderId : null;
      folderTitle = initial ? widget.initialFolderTitle : null;
    }
    provider = libraryViewModelProvider(
      ownerKey: session.ownerKey,
      section: section,
      folderId: folderId,
    );
    final value = ref.watch(provider);
    final allowed = section == LibrarySection.local || session.isAuthenticated;
    final state = value.value;
    items = allowed ? state?.items ?? [] : [];
    final busy = state?.loading == true || state?.mutating == true;
    return PopScope(
      canPop: section != LibrarySection.folder,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && section == LibrarySection.folder) _back();
      },
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Row(
                  children: [
                    TvButton(
                      key: const Key('library-back'),
                      label: widget.branchIndex == null ? '返回' : '返回导航',
                      focusNode: back,
                      autofocus: widget.branchIndex == null,
                      icon: CupertinoIcons.chevron_left,
                      onPressed: _back,
                      onKeyEvent: (e) {
                        if (isDirectionEvent(e) &&
                            e.logicalKey == LogicalKeyboardKey.arrowLeft &&
                            widget.branchIndex != null) {
                          shell?.focusNavigation();
                          return KeyEventResult.handled;
                        }
                        if (e is KeyDownEvent &&
                            e.logicalKey == LogicalKeyboardKey.arrowDown) {
                          tabs[tabIndex].requestFocus();
                          return KeyEventResult.handled;
                        }
                        return KeyEventResult.ignored;
                      },
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Text(
                        folderTitle ??
                            (widget.historyOnly ? '历史记录' : '你的观看与收藏'),
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                    ),
                    TvButton(
                      key: const Key('library-refresh'),
                      label: busy ? '读取中…' : '刷新',
                      focusNode: refresh,
                      onPressed: () {
                        if (!busy) {
                          unawaited(ref.read(provider.notifier).refresh());
                        }
                      },
                    ),
                    if (section == LibrarySection.local) ...[
                      const SizedBox(width: 10),
                      TvButton(
                        key: const Key('library-clear'),
                        label: '清空本地',
                        focusNode: clear,
                        onPressed: () {
                          if (!busy && items.isNotEmpty) {
                            unawaited(_remove(null));
                          }
                        },
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    for (var i = 0; i < sections.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: TvButton(
                          key: ValueKey('library-tab-$i'),
                          label: labels[i],
                          selected: i == tabIndex,
                          focusNode: tabs[i],
                          compact: true,
                          onPressed: () => _select(sections[i]),
                          onKeyEvent: (e) {
                            if (!isDirectionEvent(e)) {
                              return KeyEventResult.ignored;
                            }
                            if (e.logicalKey == LogicalKeyboardKey.arrowDown) {
                              unawaited(_focusRow(0));
                            } else if (e.logicalKey ==
                                LogicalKeyboardKey.arrowUp) {
                              back.requestFocus();
                            } else if (e.logicalKey ==
                                LogicalKeyboardKey.arrowLeft) {
                              if (i == 0 && widget.branchIndex != null) {
                                shell?.focusNavigation();
                              } else {
                                tabs[(i - 1).clamp(0, tabs.length - 1)]
                                    .requestFocus();
                              }
                            } else if (e.logicalKey ==
                                LogicalKeyboardKey.arrowRight) {
                              tabs[(i + 1).clamp(0, tabs.length - 1)]
                                  .requestFocus();
                            } else {
                              return KeyEventResult.ignored;
                            }
                            return KeyEventResult.handled;
                          },
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    section == LibrarySection.local
                        ? '仅保存在这台设备，游客与各账号分别保存。'
                        : '来自当前B站账号，本地续播位置优先。',
                    style: TextStyle(color: context.tvColors.muted),
                  ),
                ),
                if (state?.notice != null)
                  Text(state!.notice!, key: const Key('library-notice')),
                if (state?.failure != null && allowed)
                  Text(
                    state!.failure!.message,
                    key: const Key('library-error'),
                  ),
                const SizedBox(height: 10),
                Expanded(
                  child: !allowed
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('登录后查看账号列表'),
                              const SizedBox(height: 14),
                              TvButton(
                                key: const Key('library-login'),
                                label: '扫码登录',
                                focusNode: footer,
                                onPressed: () => unawaited(
                                  context.push<void>(
                                    '/login?returnTo=%2Flibrary%2Frecords',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      : value.isLoading
                      ? const Center(child: CupertinoActivityIndicator())
                      : ListView.builder(
                          controller: scroll,
                          itemExtent: 118,
                          itemCount: items.length + 1,
                          itemBuilder: (context, index) {
                            if (index == items.length) {
                              return Center(
                                child: TvButton(
                                  key: const Key('library-footer'),
                                  focusNode: footer,
                                  label: busy
                                      ? '读取中…'
                                      : state?.cursor != null
                                      ? '加载更多'
                                      : items.isEmpty
                                      ? (state?.failure != null
                                            ? '重新读取'
                                            : '暂无记录，刷新看看')
                                      : '已显示全部，刷新',
                                  onKeyEvent: (e) {
                                    if (e is KeyDownEvent &&
                                        e.logicalKey ==
                                            LogicalKeyboardKey.arrowUp) {
                                      unawaited(_focusRow(items.length - 1));
                                      return KeyEventResult.handled;
                                    }
                                    return KeyEventResult.ignored;
                                  },
                                  onPressed: () {
                                    if (!busy) {
                                      unawaited(
                                        ref
                                            .read(provider.notifier)
                                            .refresh(
                                              more: state?.cursor != null,
                                            ),
                                      );
                                    }
                                  },
                                ),
                              );
                            }
                            final item = items[index];
                            final focus = rows.putIfAbsent(
                              item.key,
                              () => [
                                FocusNode(
                                  debugLabel: 'library-item-${item.key}',
                                ),
                                FocusNode(
                                  debugLabel: 'library-action-${item.key}',
                                ),
                              ],
                            );
                            KeyEventResult key(int action, KeyEvent e) {
                              if (!isDirectionEvent(e)) {
                                return KeyEventResult.ignored;
                              }
                              if (e.logicalKey ==
                                  LogicalKeyboardKey.arrowDown) {
                                unawaited(_focusRow(index + 1, action: action));
                              } else if (e.logicalKey ==
                                  LogicalKeyboardKey.arrowUp) {
                                unawaited(_focusRow(index - 1, action: action));
                              } else if (e.logicalKey ==
                                  LogicalKeyboardKey.arrowRight) {
                                (item.folderId == null
                                        ? focus.last
                                        : focus.first)
                                    .requestFocus();
                              } else if (e.logicalKey ==
                                  LogicalKeyboardKey.arrowLeft) {
                                (action == 1 ? focus.first : tabs[tabIndex])
                                    .requestFocus();
                              } else {
                                return KeyEventResult.ignored;
                              }
                              return KeyEventResult.handled;
                            }

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: LiquidGlassCard(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 112,
                                      height: 72,
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: TvArtwork(video: item.video),
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            item.video.title,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 6),
                                          Row(
                                            children: [
                                              if (item.folderId == null) ...[
                                                CreatorAvatar(
                                                  name: item.video.creator,
                                                  url: item
                                                      .video
                                                      .creatorAvatarUrl,
                                                ),
                                                const SizedBox(width: 7),
                                              ],
                                              Expanded(
                                                child: Text(
                                                  item.unavailableReason ??
                                                      (item.folderId != null
                                                          ? '${item.count} 个视频'
                                                          : item.target
                                                                is LiveTarget
                                                          ? '直播访问 · ${item.video.creator}'
                                                          : '${item.video.creator}  ·  ${item.position.inMinutes}:${(item.position.inSeconds % 60).toString().padLeft(2, '0')}'),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    color:
                                                        context.tvColors.muted,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    TvButton(
                                      key: ValueKey('library-open-${item.key}'),
                                      focusNode: focus.first,
                                      compact: true,
                                      label: item.folderId != null
                                          ? '打开'
                                          : item.unavailableReason != null
                                          ? '不可用'
                                          : section == LibrarySection.local ||
                                                section == LibrarySection.remote
                                          ? '继续观看'
                                          : '详情',
                                      onKeyEvent: (e) => key(0, e),
                                      onPressed: () => unawaited(_open(item)),
                                    ),
                                    if (item.folderId == null) ...[
                                      const SizedBox(width: 8),
                                      TvButton(
                                        key: ValueKey(
                                          'library-action-${item.key}',
                                        ),
                                        focusNode: focus.last,
                                        compact: true,
                                        label: section == LibrarySection.local
                                            ? '删除'
                                            : '管理',
                                        onKeyEvent: (e) => key(1, e),
                                        onPressed: () {
                                          if (busy) return;
                                          if (section == LibrarySection.local) {
                                            unawaited(
                                              _remove(
                                                item.video.id,
                                                target: item.target,
                                              ),
                                            );
                                          } else if (item.unavailableReason ==
                                              null) {
                                            unawaited(
                                              _manage(item, session.ownerKey),
                                            );
                                          }
                                        },
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
