import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/app_models.dart';
import '../settings/view_models/settings_view_model.dart';

import '../../core/focus/focus_memory.dart';
import '../../core/theme/tv_theme.dart';
import '../../core/widgets/tv_button.dart';
import '../../core/widgets/tv_dialog.dart';
import '../../core/widgets/glass_panel.dart';

class TvShell extends StatefulWidget {
  const TvShell({required this.navigationShell, super.key});
  final StatefulNavigationShell navigationShell;
  @override
  State<TvShell> createState() => _TvShellState();
}

class _TvShellState extends State<TvShell> {
  final nodes = List.generate(5, (i) => FocusNode(debugLabel: 'nav-$i'));
  final themeNode = FocusNode(debugLabel: 'nav-theme');
  final entries = <int, VoidCallback>{};
  bool confirming = false;
  static const labels = ['发现', '搜索', '我的', '设置', '历史记录'];
  // Keep route identities stable while changing the visible/focus order.
  static const navigationOrder = [0, 4, 1, 2, 3];
  static const icons = [
    CupertinoIcons.compass,
    CupertinoIcons.search,
    CupertinoIcons.person_crop_circle,
    CupertinoIcons.gear_alt,
    CupertinoIcons.clock,
  ];
  @override
  void dispose() {
    themeNode.dispose();
    for (final node in nodes) {
      node.dispose();
    }
    super.dispose();
  }

  Future<void> _exit() async {
    if (confirming) return;
    confirming = true;
    try {
      final confirmed = await showTvConfirmation(
        context,
        title: '退出 MambaTV？',
        message: '下次打开，再发现更多好内容。',
        confirmLabel: '退出',
      );
      if (confirmed) await SystemNavigator.pop();
    } finally {
      confirming = false;
    }
  }

  void _selectBranch(int index) {
    widget.navigationShell.goBranch(index);
    // A newly created branch route requests its own scope. Keep the remote on
    // the selected navigation item until the user explicitly moves right.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) nodes[index].requestFocus();
    });
  }

  KeyEventResult _key(int index, KeyEvent event) {
    if (!isDirectionEvent(event)) return KeyEventResult.ignored;
    final position = navigationOrder.indexOf(index);
    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowUp:
        nodes[navigationOrder[(position - 1).clamp(0, nodes.length - 1)]]
            .requestFocus();
      case LogicalKeyboardKey.arrowDown:
        if (position == navigationOrder.length - 1) {
          themeNode.requestFocus();
        } else {
          nodes[navigationOrder[position + 1]].requestFocus();
        }
      case LogicalKeyboardKey.arrowRight:
        entries[widget.navigationShell.currentIndex]?.call();
      case LogicalKeyboardKey.arrowLeft:
        break;
      default:
        return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: false,
    onPopInvokedWithResult: (didPop, result) {
      if (!didPop) unawaited(_exit());
    },
    child: TvShellScope(
      focusNavigation: () =>
          nodes[widget.navigationShell.currentIndex].requestFocus(),
      registerContent: (index, callback) => entries[index] = callback,
      unregisterContent: (index, callback) {
        if (entries[index] == callback) entries.remove(index);
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: SafeArea(
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 0, 12),
                child: SizedBox(
                  key: const Key('icon-navigation-rail'),
                  width: 76,
                  child: GlassPanel(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 16,
                    ),
                    child: Column(
                      children: [
                        Semantics(
                          label: 'MambaTV',
                          child: Icon(
                            CupertinoIcons.play_circle_fill,
                            color: context.tvColors.accent,
                            size: 30,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Expanded(
                          child: SingleChildScrollView(
                            child: Column(
                              children: [
                                for (final i in navigationOrder)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: Builder(
                                      builder: (itemContext) => SizedBox(
                                        width: double.infinity,
                                        child: TvButton(
                                          key: ValueKey('nav-$i'),
                                          label: labels[i],
                                          icon: icons[i],
                                          iconOnly: true,
                                          compact: true,
                                          focusNode: nodes[i],
                                          autofocus: i == 0,
                                          selected:
                                              widget
                                                  .navigationShell
                                                  .currentIndex ==
                                              i,
                                          onFocusChange: (focused) {
                                            if (focused) {
                                              unawaited(
                                                Scrollable.ensureVisible(
                                                  itemContext,
                                                  alignment: .5,
                                                ),
                                              );
                                            }
                                          },
                                          onKeyEvent: (event) => _key(i, event),
                                          onPressed: () => _selectBranch(i),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Consumer(
                          builder: (context, ref, _) {
                            final settings = ref
                                .watch(settingsViewModelProvider)
                                .value;
                            final light =
                                Theme.of(context).brightness ==
                                Brightness.light;
                            return SizedBox(
                              width: double.infinity,
                              child: TvButton(
                                key: const Key('nav-theme'),
                                label: light ? '切换至深色模式' : '切换至浅色模式',
                                icon: light
                                    ? CupertinoIcons.moon
                                    : CupertinoIcons.sun_max,
                                iconOnly: true,
                                compact: true,
                                focusNode: themeNode,
                                onPressed: () {
                                  if (settings == null || settings.saving) {
                                    return;
                                  }
                                  unawaited(
                                    ref
                                        .read(
                                          settingsViewModelProvider.notifier,
                                        )
                                        .savePreferences(
                                          settings.settings.copyWith(
                                            theme: light
                                                ? AppTheme.dark
                                                : AppTheme.light,
                                          ),
                                        ),
                                  );
                                },
                                onKeyEvent: (event) {
                                  if (!isDirectionEvent(event)) {
                                    return KeyEventResult.ignored;
                                  }
                                  if (event.logicalKey ==
                                      LogicalKeyboardKey.arrowUp) {
                                    nodes[navigationOrder.last].requestFocus();
                                  } else if (event.logicalKey ==
                                      LogicalKeyboardKey.arrowRight) {
                                    entries[widget.navigationShell.currentIndex]
                                        ?.call();
                                  } else if (event.logicalKey !=
                                          LogicalKeyboardKey.arrowDown &&
                                      event.logicalKey !=
                                          LogicalKeyboardKey.arrowLeft) {
                                    return KeyEventResult.ignored;
                                  }
                                  return KeyEventResult.handled;
                                },
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(child: widget.navigationShell),
            ],
          ),
        ),
      ),
    ),
  );
}
