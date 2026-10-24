import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/providers/repository_providers.dart';
import '../../../../domain/entities/app_models.dart';
import '../../../core/focus/focus_memory.dart';
import '../../../core/theme/tv_theme.dart';
import '../../../core/widgets/glass_panel.dart';
import '../../../core/widgets/tv_button.dart';
import '../../../core/widgets/tv_dialog.dart';

class AccountPage extends ConsumerStatefulWidget {
  const AccountPage({super.key});
  @override
  ConsumerState<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends ConsumerState<AccountPage> {
  final primary = FocusNode(debugLabel: 'account-primary');
  final secondary = FocusNode(debugLabel: 'account-secondary');
  TvShellScope? shell;
  bool busy = false;
  void _entry() => primary.requestFocus();
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    shell = TvShellScope.maybeOf(context);
    shell?.registerContent(2, _entry);
  }

  @override
  void dispose() {
    shell?.unregisterContent(2, _entry);
    primary.dispose();
    secondary.dispose();
    super.dispose();
  }

  KeyEventResult _key(KeyEvent event, bool first) {
    if (!isDirectionEvent(event)) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      shell?.focusNavigation();
    } else if (event.logicalKey == LogicalKeyboardKey.arrowDown ||
        event.logicalKey == LogicalKeyboardKey.arrowUp) {
      (first ? secondary : primary).requestFocus();
    } else {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  Future<void> _logout() async {
    final confirmed = await showTvConfirmation(
      context,
      title: '退出当前账号？',
      message: '本机将停止使用此账号并清除登录凭据。',
      confirmLabel: '退出登录',
    );
    if (!confirmed || !mounted || busy) return;
    setState(() => busy = true);
    try {
      await ref.read(sessionRepositoryProvider).logout();
    } finally {
      if (mounted) {
        setState(() => busy = false);
        primary.requestFocus();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(sessionProvider);
    final session =
        state.value ?? const Session(status: SessionStatus.restoring);
    final auth = session.isAuthenticated;
    final recover =
        session.status == SessionStatus.offline ||
        session.status == SessionStatus.storageFailure;
    final title = auth
        ? (session.displayName ?? '已登录')
        : switch (session.status) {
            SessionStatus.restoring => '正在恢复账号',
            SessionStatus.expired => '重新登录，继续你的故事',
            SessionStatus.offline => '账号已保留，等待网络恢复',
            SessionStatus.storageFailure => '安全存储需要处理',
            _ => '你的观看故事，从这里开始',
          };
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('我的', style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: 8),
          const Text('让喜欢的内容，跟随你的账号', style: TextStyle(color: TvColors.muted)),
          const SizedBox(height: 28),
          Expanded(
            child: SingleChildScrollView(
              child: GlassPanel(
                padding: const EdgeInsets.all(28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      auth
                          ? CupertinoIcons.person_crop_circle_fill
                          : CupertinoIcons.person_crop_circle,
                      size: 56,
                      color: TvColors.accent,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      title,
                      key: const Key('account-status'),
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      session.notice ??
                          (auth
                              ? '账号已在本机安全保存，收藏与历史列表将在后续开放。'
                              : '游客可浏览和播放公开视频。登录后可按账号保存播放位置。'),
                      style: const TextStyle(color: TvColors.muted),
                    ),
                    const SizedBox(height: 26),
                    TvButton(
                      key: const Key('account-primary'),
                      focusNode: primary,
                      label: busy
                          ? '处理中…'
                          : auth
                          ? '退出登录'
                          : recover
                          ? '重新校验账号'
                          : '扫码登录',
                      icon: auth
                          ? CupertinoIcons.square_arrow_right
                          : CupertinoIcons.qrcode,
                      onKeyEvent: (e) => _key(e, true),
                      onPressed: () {
                        if (busy) return;
                        if (auth) {
                          unawaited(_logout());
                        } else if (recover) {
                          unawaited(
                            ref
                                .read(sessionRepositoryProvider)
                                .revalidate(force: true),
                          );
                        } else if (session.status != SessionStatus.restoring) {
                          unawaited(
                            context.push<void>('/login?returnTo=%2Flibrary'),
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    TvButton(
                      key: const Key('account-secondary'),
                      focusNode: secondary,
                      label: recover ? '清除本机登录' : '继续发现好内容',
                      onKeyEvent: (e) => _key(e, false),
                      onPressed: () {
                        if (recover) {
                          unawaited(_logout());
                        } else {
                          context.go('/home');
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
