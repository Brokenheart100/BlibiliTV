import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/providers/repository_providers.dart';
import '../../../../app/providers/ui_providers.dart';
import '../../../../domain/entities/app_models.dart';
import '../../../../domain/library/personal_home.dart';
import '../../../core/images/tv_image_cache.dart';
import '../../../core/theme/tv_theme.dart';
import '../../../core/widgets/tv_button.dart';
import '../../../core/widgets/tv_grid.dart';
import '../../../core/widgets/tv_pill_tabs.dart';
import '../../../core/widgets/tv_video_card.dart';
import '../../../core/widgets/liquid_glass_card.dart';
import '../../../core/widgets/tv_state_panel.dart';
import '../../../core/focus/focus_memory.dart';
import '../../settings/view_models/settings_view_model.dart';
import '../view_models/personal_home_view_model.dart';

class PersonalHomeController {
  VoidCallback? _entry;
  void focusEntry() => _entry?.call();
}

class PersonalHomeView extends ConsumerStatefulWidget {
  const PersonalHomeView({
    required this.session,
    required this.controller,
    required this.logoutNode,
    required this.onLogout,
    required this.busy,
    super.key,
  });
  final Session session;
  final PersonalHomeController controller;
  final FocusNode logoutNode;
  final VoidCallback onLogout;
  final bool busy;
  @override
  ConsumerState<PersonalHomeView> createState() => _PersonalHomeViewState();
}

class _PersonalHomeViewState extends ConsumerState<PersonalHomeView> {
  final tabs = [
    for (final section in PersonalSection.values)
      FocusNode(debugLabel: 'personal-tab-${section.name}'),
  ];
  final refresh = FocusNode(debugLabel: 'personal-refresh');
  final empty = FocusNode(debugLabel: 'personal-empty');
  final grid = TvGridController();
  PersonalSection section = PersonalSection.submissions;
  void _entry() => tabs[section.index].requestFocus();
  @override
  void initState() {
    super.initState();
    widget.controller._entry = _entry;
  }

  @override
  void dispose() {
    if (widget.controller._entry == _entry) widget.controller._entry = null;
    for (final node in [...tabs, refresh, empty]) {
      node.dispose();
    }
    super.dispose();
  }

  void _left() => TvShellScope.maybeOf(context)?.focusNavigation();
  PersonalCollectionProvider get provider => personalCollectionProvider(
    scopeKey: widget.session.scopeKey,
    section: section,
  );
  void _content() {
    if (ref.read(provider).value?.items.isNotEmpty == true) {
      unawaited(grid.restore());
    } else if (empty.context != null) {
      empty.requestFocus();
    } else {
      refresh.requestFocus();
    }
  }

  KeyEventResult _tabKey(KeyEvent event, int index) {
    if (!isDirectionEvent(event)) return KeyEventResult.ignored;
    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowLeft:
        if (index == 0) {
          _left();
        } else {
          tabs[index - 1].requestFocus();
        }
      case LogicalKeyboardKey.arrowRight:
        if (index == tabs.length - 1) {
          refresh.requestFocus();
        } else {
          tabs[index + 1].requestFocus();
        }
      case LogicalKeyboardKey.arrowDown:
        _content();
      case LogicalKeyboardKey.arrowUp:
        widget.logoutNode.requestFocus();
      default:
        return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  Future<void> _refresh() async {
    ref.invalidate(personalProfileProvider(widget.session.scopeKey));
    if (ref.read(provider).hasError) {
      ref.invalidate(provider);
    } else {
      await ref.read(provider.notifier).refresh();
    }
  }

  Future<void> _open(PersonalItem item) async {
    switch (item) {
      case PersonalFolder():
        await context.push<void>(
          '/library/folder/${item.id}',
          extra: item.title,
        );
      case PersonalVideo():
        if (item.unavailableReason != null) return;
        await context.push<void>('/video/${item.video.id}');
      case PersonalSeason():
        final scope = widget.session.scopeKey;
        await showDialog<void>(
          context: context,
          builder: (_) => Consumer(
            builder: (context, ref, _) {
              final valid = ref.watch(sessionProvider).value?.scopeKey == scope;
              return AlertDialog(
                title: Text(valid ? item.title : '账号已变化'),
                content: Text(
                  valid
                      ? [
                          item.subtitle,
                          item.progress,
                          item.badge,
                          '番剧与影视播放尚未开放。',
                        ].where((value) => value.isNotEmpty).join('\n')
                      : '请返回查看当前账号的内容。',
                ),
                actions: [
                  TvButton(
                    label: '返回列表',
                    autofocus: true,
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              );
            },
          ),
        );
    }
    if (mounted) await grid.restore();
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    final profile = ref.watch(personalProfileProvider(session.scopeKey));
    final value = ref.watch(provider);
    final reduced =
        ref.watch(settingsViewModelProvider).value?.settings.reducedMotion ??
        false;
    final poster =
        section == PersonalSection.bangumi || section == PersonalSection.drama;
    final avatar = profile.value?.avatarUrl;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Semantics(
                label: '我的头像',
                image: true,
                child: ClipOval(
                  child: SizedBox(
                    key: const Key('account-avatar'),
                    width: 72,
                    height: 72,
                    child: avatar == null
                        ? Icon(
                            CupertinoIcons.person_crop_circle_fill,
                            size: 64,
                            color: context.tvColors.accent,
                          )
                        : CachedNetworkImage(
                            imageUrl: avatar,
                            cacheManager: TvImageCache.manager,
                            memCacheWidth: 160,
                            memCacheHeight: 160,
                            fit: BoxFit.cover,
                            placeholder: (_, _) => Icon(
                              CupertinoIcons.person_crop_circle,
                              size: 64,
                              color: context.tvColors.muted,
                            ),
                            errorWidget: (_, _, _) => Icon(
                              CupertinoIcons.person_crop_circle,
                              size: 64,
                              color: context.tvColors.muted,
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.value?.name ?? session.displayName ?? '我的账号',
                      key: const Key('account-status'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'UID ${session.ownerKey.replaceFirst('user:', '')} · 我的主页',
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
                key: const Key('account-primary'),
                label: widget.busy ? '处理中…' : '退出登录',
                focusNode: widget.logoutNode,
                icon: CupertinoIcons.square_arrow_right,
                compact: true,
                onPressed: widget.onLogout,
                onKeyEvent: (event) {
                  if (!isDirectionEvent(event)) return KeyEventResult.ignored;
                  if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                    _entry();
                  } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
                    _left();
                  } else {
                    return KeyEventResult.ignored;
                  }
                  return KeyEventResult.handled;
                },
              ),
            ],
          ),
          if (profile.hasError)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                '头像资料暂未更新，可刷新重试',
                style: TextStyle(color: context.tvColors.muted, fontSize: 12),
              ),
            ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: TvCapsuleTabs<PersonalSection>(
                  key: const Key('personal-pill-tabs'),
                  values: PersonalSection.values,
                  selected: section,
                  nodes: tabs,
                  label: (tab) => tab.label,
                  tabKey: (tab) => ValueKey('personal-${tab.name}'),
                  onKey: _tabKey,
                  onSelected: (tab) => setState(() => section = tab),
                  reducedMotion: reduced,
                ),
              ),
              const SizedBox(width: 10),
              TvButton(
                key: const Key('personal-refresh'),
                label: '刷新',
                icon: CupertinoIcons.refresh,
                iconOnly: true,
                compact: true,
                focusNode: refresh,
                onPressed: () => unawaited(_refresh()),
                onKeyEvent: (event) {
                  if (!isDirectionEvent(event)) return KeyEventResult.ignored;
                  if (event.logicalKey == LogicalKeyboardKey.arrowLeft ||
                      event.logicalKey == LogicalKeyboardKey.arrowUp) {
                    _entry();
                  } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                    _content();
                  } else {
                    return KeyEventResult.ignored;
                  }
                  return KeyEventResult.handled;
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (value.value?.loading == true)
            const LinearProgressIndicator(minHeight: 2),
          if (value.value?.failure != null)
            Text(
              value.value!.failure!.message,
              style: TextStyle(color: context.tvColors.muted),
            ),
          Expanded(
            child: value.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => TvStatePanel(
                title: '${section.label}暂不可用',
                message: '请稍后刷新重试。',
                actionLabel: '重试',
                focusNode: empty,
                onAction: () => unawaited(_refresh()),
              ),
              data: (state) => state.items.isEmpty
                  ? TvStatePanel(
                      title: '还没有${section.label}',
                      message: section == PersonalSection.submissions
                          ? '公开发布的投稿会显示在这里。'
                          : '在 B 站添加后，可在这里刷新查看。',
                      actionLabel: '刷新',
                      focusNode: empty,
                      onAction: () => unawaited(_refresh()),
                    )
                  : TvItemGrid<PersonalItem>(
                      key: ValueKey('${session.scopeKey}:${section.name}'),
                      items: state.items,
                      itemKey: (item) => item.key,
                      itemBuilder: (context, item, bindings) {
                        if (item is PersonalVideo) {
                          final video = item.video.copyWith(
                            creatorAvatarUrl:
                                item.video.creatorAvatarUrl ??
                                (section == PersonalSection.submissions
                                    ? avatar
                                    : null),
                          );
                          return TvVideoCard(
                            key: ValueKey('personal-item-${item.key}'),
                            video: video,
                            onPressed: bindings.onPressed,
                            onFocus: bindings.onFocus,
                            onKey: bindings.onKey,
                            onAttach: bindings.onAttach,
                            onDetach: bindings.onDetach,
                            reducedMotion: bindings.reducedMotion,
                          );
                        }
                        return _PersonalCard(
                          key: ValueKey('personal-item-${item.key}'),
                          item: item,
                          bindings: bindings,
                        );
                      },
                      memory: ref.read(focusMemoryProvider),
                      memoryKey: '${session.scopeKey}:personal:${section.name}',
                      controller: grid,
                      reducedMotion: reduced,
                      onSelected: _open,
                      onExitLeft: _left,
                      onExitUp: _entry,
                      onLoadMore: () =>
                          ref.read(provider.notifier).refresh(more: true),
                      hasMore: state.cursor != null,
                      loadingMore: state.loading,
                      artworkAspectRatio: poster ? 2 / 3 : 16 / 9,
                      minItemWidth: poster ? 150 : 214,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PersonalCard extends StatefulWidget {
  const _PersonalCard({required this.item, required this.bindings, super.key});
  final PersonalItem item;
  final GridItemBindings bindings;
  @override
  State<_PersonalCard> createState() => _PersonalCardState();
}

class _PersonalCardState extends State<_PersonalCard> {
  late final node = FocusNode(debugLabel: 'personal-item-${widget.item.key}');
  bool focused = false;
  @override
  void initState() {
    super.initState();
    widget.bindings.onAttach(node);
  }

  @override
  void dispose() {
    widget.bindings.onDetach(node);
    node.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Focus(
    canRequestFocus: false,
    skipTraversal: true,
    onKeyEvent: (_, event) => widget.bindings.onKey(event),
    child: LiquidGlassCard(
      focused: focused,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          focusNode: node,
          onTap: widget.bindings.onPressed,
          borderRadius: BorderRadius.circular(14),
          onFocusChange: (value) {
            setState(() => focused = value);
            if (value) widget.bindings.onFocus();
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SizedBox.expand(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: widget.item.coverUrl == null
                        ? Icon(
                            widget.item is PersonalFolder
                                ? CupertinoIcons.folder
                                : CupertinoIcons.play_rectangle,
                            size: 44,
                            color: context.tvColors.accent,
                          )
                        : CachedNetworkImage(
                            imageUrl: widget.item.coverUrl!,
                            cacheManager: TvImageCache.manager,
                            memCacheWidth: 640,
                            fit: BoxFit.cover,
                            placeholder: (_, _) =>
                                const Center(child: Icon(CupertinoIcons.photo)),
                            errorWidget: (_, _, _) =>
                                const Center(child: Icon(CupertinoIcons.photo)),
                          ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 9, 8, 2),
                child: Text(
                  widget.item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: context.tvColors.text,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                child: Text(
                  widget.item.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, color: context.tvColors.muted),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
