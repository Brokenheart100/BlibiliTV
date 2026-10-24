import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/repository_providers.dart';
import '../../../domain/entities/app_models.dart';

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
  final nodes = List.generate(4, (i) => FocusNode(debugLabel: 'nav-$i'));
  final entries = <int, VoidCallback>{};
  bool confirming = false;
  static const labels = ['发现', '搜索', '我的', '设置'];
  static const icons = [
    CupertinoIcons.compass,
    CupertinoIcons.search,
    CupertinoIcons.person_crop_circle,
    CupertinoIcons.gear_alt,
  ];
  @override
  void dispose() {
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
    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowUp:
        nodes[(index - 1).clamp(0, 3)].requestFocus();
      case LogicalKeyboardKey.arrowDown:
        nodes[(index + 1).clamp(0, 3)].requestFocus();
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
                  width: MediaQuery.sizeOf(context).width < 800 ? 136 : 156,
                  child: GlassPanel(
                    padding: const EdgeInsets.fromLTRB(10, 24, 10, 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(left: 8),
                          child: Row(
                            children: [
                              Icon(
                                CupertinoIcons.play_circle_fill,
                                color: TvColors.accent,
                                size: 27,
                              ),
                              SizedBox(width: 7),
                              Text(
                                'MAMBA',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 17,
                                  letterSpacing: .6,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.fromLTRB(10, 6, 0, 26),
                          child: Text(
                            '给好内容，一块大屏',
                            style: TextStyle(
                              fontSize: 10,
                              color: TvColors.muted,
                            ),
                          ),
                        ),
                        for (var i = 0; i < labels.length; i++) ...[
                          SizedBox(
                            width: double.infinity,
                            child: TvButton(
                              key: ValueKey('nav-$i'),
                              label: labels[i],
                              icon: icons[i],
                              compact: true,
                              focusNode: nodes[i],
                              autofocus: i == 0,
                              selected:
                                  widget.navigationShell.currentIndex == i,
                              onKeyEvent: (event) => _key(i, event),
                              onPressed: () => _selectBranch(i),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                        const Spacer(),
                        Padding(
                          padding: EdgeInsets.only(left: 10),
                          child: Consumer(
                            builder: (context, ref, _) {
                              final result = ref.watch(sessionProvider);
                              final label = result.isLoading
                                  ? '正在恢复账号'
                                  : switch (result.value?.status) {
                                      SessionStatus.authenticated => '账号已登录',
                                      SessionStatus.expired => '登录需要更新',
                                      SessionStatus.offline => '离线 · 账号保留',
                                      SessionStatus.storageFailure => '存储待处理',
                                      _ => '游客模式',
                                    };
                              return Text(
                                label,
                                style: const TextStyle(
                                  color: TvColors.accent,
                                  fontSize: 11,
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 5),
                        const Padding(
                          padding: EdgeInsets.only(left: 10),
                          child: Text(
                            '方向键移动 · 确认选择',
                            style: TextStyle(
                              fontSize: 9,
                              color: TvColors.muted,
                            ),
                          ),
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
