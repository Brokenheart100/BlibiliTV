import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';

import '../../../../app/providers/auth_providers.dart';
import '../../../../app/providers/repository_providers.dart';
import '../../../../app/providers/ui_providers.dart';
import '../../../core/theme/tv_theme.dart';
import '../../../core/widgets/glass_panel.dart';
import '../../../core/widgets/tv_button.dart';
import '../view_models/qr_login_view_model.dart';

class QrLoginPage extends ConsumerStatefulWidget {
  const QrLoginPage({required this.pageId, required this.returnTo, super.key});
  final String pageId, returnTo;
  @override
  ConsumerState<QrLoginPage> createState() => _QrLoginPageState();
}

class _QrLoginPageState extends ConsumerState<QrLoginPage> {
  final primary = FocusNode(debugLabel: 'qr-primary');
  final back = FocusNode(debugLabel: 'qr-back');
  bool returned = false;
  QrLoginViewModelProvider get provider =>
      qrLoginViewModelProvider(pageId: widget.pageId);
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_begin()));
  }

  Future<void> _begin() async {
    await ref.read(sessionProvider.future);
    if (mounted &&
        !ref.read(sessionProvider).requireValue.isAuthenticated &&
        ref.read(appForegroundProvider)) {
      await ref.read(provider.notifier).start();
    }
  }

  void _back() {
    ref.read(provider.notifier).cancel();
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/library');
    }
  }

  KeyEventResult _key(KeyEvent event, bool isPrimary) {
    if (!isDirectionEvent(event)) return KeyEventResult.ignored;
    if (const [
      LogicalKeyboardKey.arrowUp,
      LogicalKeyboardKey.arrowDown,
      LogicalKeyboardKey.arrowLeft,
      LogicalKeyboardKey.arrowRight,
    ].contains(event.logicalKey)) {
      (isPrimary ? back : primary).requestFocus();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  void dispose() {
    primary.dispose();
    back.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final result = ref.watch(provider);
    final session = ref.watch(sessionProvider).value;
    ref.listen(appForegroundProvider, (_, foreground) {
      final vm = ref.read(provider.notifier);
      if (foreground) {
        unawaited(vm.resume());
      } else {
        vm.pause();
      }
    });
    ref.listen(provider, (previous, next) {
      if (next.phase == QrPhase.completed && next.effectId != 0 && !returned) {
        returned = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) context.go(safeLoginReturn(widget.returnTo));
        });
      }
      if (next.phase == QrPhase.failed || next.phase == QrPhase.expired) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) primary.requestFocus();
        });
      }
    });
    final title = switch (result.phase) {
      QrPhase.idle => session?.isAuthenticated == true ? '账号已登录' : '准备登录',
      QrPhase.creating => '正在准备二维码',
      QrPhase.waiting => '用手机，连接你的大屏',
      QrPhase.scanned => '已扫码，请在手机上确认',
      QrPhase.completed => '登录成功',
      QrPhase.expired => '二维码已过期',
      QrPhase.paused => '扫码已暂停',
      QrPhase.failed => '暂时无法登录',
    };
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: LayoutBuilder(
              builder: (context, size) {
                final qrSize = (size.maxHeight - 72).clamp(160.0, 250.0);
                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1050),
                    child: GlassPanel(
                      padding: const EdgeInsets.all(28),
                      child: Row(
                        children: [
                          Container(
                            width: qrSize,
                            height: qrSize,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: result.challenge != null
                                ? PrettyQrView.data(
                                    key: const Key('login-qr'),
                                    data: result.challenge!.url,
                                  )
                                : Icon(
                                    result.phase == QrPhase.creating
                                        ? CupertinoIcons.ellipsis
                                        : CupertinoIcons.qrcode,
                                    size: 84,
                                    color: const Color(0xFF202535),
                                  ),
                          ),
                          const SizedBox(width: 32),
                          Expanded(
                            child: SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'MAMBA TV  /  BILIBILI',
                                    style: TextStyle(
                                      fontSize: 11,
                                      letterSpacing: 2,
                                      color: context.tvColors.accent,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    title,
                                    key: const Key('login-status'),
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineMedium,
                                  ),
                                  const SizedBox(height: 14),
                                  Text(
                                    '打开哔哩哔哩手机端扫一扫，\n在手机上确认后即可登录。',
                                    style: TextStyle(
                                      height: 1.7,
                                      color: context.tvColors.muted,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  if (result.challenge != null)
                                    Text(
                                      '${result.remainingSeconds} 秒后过期',
                                      key: const Key('login-countdown'),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: context.tvColors.accent,
                                      ),
                                    ),
                                  if (result.failure != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 10),
                                      child: Text(
                                        result.failure!.message,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.amber,
                                        ),
                                      ),
                                    ),
                                  const SizedBox(height: 24),
                                  TvButton(
                                    key: const Key('qr-refresh'),
                                    label: session?.isAuthenticated == true
                                        ? '返回账号页'
                                        : result.phase == QrPhase.creating
                                        ? '正在获取…'
                                        : result.challenge == null
                                        ? '重新获取二维码'
                                        : '刷新二维码',
                                    focusNode: primary,
                                    autofocus: true,
                                    icon: CupertinoIcons.refresh,
                                    onKeyEvent: (e) => _key(e, true),
                                    onPressed: () {
                                      if (session?.isAuthenticated == true) {
                                        context.go(
                                          safeLoginReturn(widget.returnTo),
                                        );
                                      } else if (result.phase !=
                                          QrPhase.creating) {
                                        unawaited(
                                          ref.read(provider.notifier).start(),
                                        );
                                      }
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                  TvButton(
                                    key: const Key('qr-back'),
                                    label: '以游客继续探索',
                                    focusNode: back,
                                    onKeyEvent: (e) => _key(e, false),
                                    onPressed: _back,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
