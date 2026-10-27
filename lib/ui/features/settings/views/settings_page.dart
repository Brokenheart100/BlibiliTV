import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/providers/maintenance_providers.dart';
import '../../../../domain/entities/app_models.dart';
import '../../../core/focus/focus_memory.dart';
import '../../../core/theme/tv_theme.dart';
import '../../../core/widgets/tv_button.dart';
import '../../../core/widgets/tv_dialog.dart';
import '../../../core/widgets/tv_state_panel.dart';
import '../view_models/settings_view_model.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});
  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  final nodes = List.generate(13, (i) => FocusNode(debugLabel: 'setting-$i'));
  final scroll = ScrollController();
  TvShellScope? shell;
  void _entry() {
    if (scroll.hasClients) scroll.jumpTo(0);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) nodes.first.requestFocus();
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    shell = TvShellScope.maybeOf(context);
    shell?.registerContent(3, _entry);
  }

  @override
  void dispose() {
    shell?.unregisterContent(3, _entry);
    scroll.dispose();
    for (final node in nodes) {
      node.dispose();
    }
    super.dispose();
  }

  KeyEventResult _key(int i, KeyEvent event) {
    if (!isDirectionEvent(event)) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      shell?.focusNavigation();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowDown ||
        event.logicalKey == LogicalKeyboardKey.arrowUp) {
      nodes[(i + (event.logicalKey == LogicalKeyboardKey.arrowDown ? 1 : -1))
              .clamp(0, nodes.length - 1)]
          .requestFocus();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _save(AppSettings settings) => unawaited(
    ref.read(settingsViewModelProvider.notifier).savePreferences(settings),
  );
  @override
  Widget build(BuildContext context) {
    final result = ref.watch(settingsViewModelProvider);
    final version = ref.watch(installedAppVersionProvider).value ?? '版本读取中';
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('设置', style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: 5),
          Text('让大屏，更合你的习惯', style: TextStyle(color: context.tvColors.muted)),
          const SizedBox(height: 24),
          if (result.value?.message != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                result.value!.message!,
                key: const Key('settings-message'),
                maxLines: 2,
                style: TextStyle(color: context.tvColors.accent),
              ),
            ),
          Expanded(
            child: result.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => TvStatePanel(
                title: '设置暂不可用',
                message: '无法读取本地设置，请重试。',
                actionLabel: '重试',
                focusNode: nodes.first,
                onAction: () => ref.invalidate(settingsViewModelProvider),
              ),
              data: (data) {
                final s = data.settings;
                Widget row(
                  int i,
                  String key,
                  String title,
                  String description,
                  String label,
                  FutureOr<void> Function() action,
                ) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Builder(
                    builder: (rowContext) => Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: context.tvColors.surface,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium,
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  description,
                                  style: TextStyle(
                                    color: context.tvColors.muted,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          SizedBox(
                            width: 150,
                            child: TvButton(
                              key: ValueKey(key),
                              label: label,
                              focusNode: nodes[i],
                              onKeyEvent: (e) => _key(i, e),
                              onFocusChange: (focused) {
                                if (focused) {
                                  unawaited(
                                    Scrollable.ensureVisible(
                                      rowContext,
                                      alignment: .5,
                                    ),
                                  );
                                }
                              },
                              onPressed: () {
                                if (!data.saving) {
                                  action();
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
                const rates = [.5, .75, 1.0, 1.25, 1.5, 2.0];
                const qualities = [0, 16, 32, 64, 80, 112, 116];
                const qualityNames = {
                  0: '自动',
                  16: '360P',
                  32: '480P',
                  64: '720P',
                  80: '1080P',
                  112: '1080P+',
                  116: '1080P60',
                };
                return ListView(
                  controller: scroll,
                  children: [
                    row(
                      0,
                      'setting-motion',
                      '减少动态效果',
                      '关闭卡片缩放，让界面更平静。',
                      s.reducedMotion ? '已开启' : '已关闭',
                      () => _save(s.copyWith(reducedMotion: !s.reducedMotion)),
                    ),
                    row(
                      1,
                      'setting-resume',
                      '记住播放位置',
                      '按当前账号保留本地记录，退出账号不会合并访客记录。',
                      s.resumePlayback ? '已开启' : '已关闭',
                      () =>
                          _save(s.copyWith(resumePlayback: !s.resumePlayback)),
                    ),
                    row(
                      2,
                      'setting-rate',
                      '默认播放速度',
                      '确认切换；进入新视频时应用。',
                      '${s.defaultRate}×',
                      () => _save(
                        s.copyWith(
                          defaultRate:
                              rates[(rates.indexOf(s.defaultRate) + 1) %
                                  rates.length],
                        ),
                      ),
                    ),
                    row(
                      3,
                      'setting-quality',
                      '默认清晰度',
                      '确认切换；权限不足时会提示并使用可用画质。',
                      qualityNames[s.defaultQuality] ?? '自动',
                      () => _save(
                        s.copyWith(
                          defaultQuality:
                              qualities[(qualities.indexOf(s.defaultQuality) +
                                      1) %
                                  qualities.length],
                        ),
                      ),
                    ),
                    row(
                      4,
                      'setting-auto-next',
                      '分 P 自动连播',
                      '当前分 P 播放结束后继续下一 P。',
                      s.autoNext ? '已开启' : '已关闭',
                      () => _save(s.copyWith(autoNext: !s.autoNext)),
                    ),
                    row(
                      5,
                      'setting-sync',
                      '同步 B 站观看进度',
                      '登录并开启后，每持续播放 30 秒向 B 站上报进度。',
                      s.syncHistory ? '已开启' : '已关闭',
                      () async {
                        final accepted =
                            s.syncHistory ||
                            await showTvConfirmation(
                              context,
                              title: '开启观看进度同步？',
                              message: '之后的播放会更新当前登录账号的 B 站历史。访客记录不会上传。',
                              confirmLabel: '开启同步',
                            );
                        if (mounted && accepted) {
                          _save(s.copyWith(syncHistory: !s.syncHistory));
                        }
                      },
                    ),
                    row(
                      6,
                      'setting-cache',
                      '封面与临时缓存',
                      '保留账号、偏好、搜索和观看记录。',
                      '清理缓存',
                      () async {
                        if (await showTvConfirmation(
                          context,
                          title: '清理临时缓存？',
                          message: '将清理封面和接口缓存，之后按需重新加载。',
                          confirmLabel: '清理',
                        )) {
                          if (mounted) {
                            await ref
                                .read(settingsViewModelProvider.notifier)
                                .clearCaches();
                          }
                        }
                      },
                    ),
                    row(
                      7,
                      'setting-account',
                      '账号管理',
                      '查看当前登录状态或退出登录。',
                      '管理账号',
                      () => context.go('/library'),
                    ),
                    row(8, 'about', '关于 MambaTV', version, '查看', () async {
                      await showTvConfirmation(
                        context,
                        title: 'MambaTV $version',
                        message: '为电视设计的第三方视频客户端。\n支持公开视频、本地续播与账号个人列表。',
                        confirmLabel: '知道了',
                      );
                    }),
                    row(
                      9,
                      'setting-licenses',
                      '开源许可',
                      '查看第三方组件、字体与引擎的许可文本。',
                      '查看许可',
                      () async {
                        await context.push<void>('/settings/licenses');
                        if (mounted) nodes[9].requestFocus();
                      },
                    ),
                    row(
                      10,
                      'setting-overlays',
                      '字幕与弹幕',
                      '语言、大小、位置、屏蔽和默认开关。',
                      '观看增强',
                      () async {
                        await context.push<void>('/settings/overlays');
                        if (mounted) nodes[10].requestFocus();
                      },
                    ),
                    row(
                      11,
                      'setting-theme',
                      '外观',
                      '浅色、跟随系统或深色；自动记住你的选择。',
                      switch (s.theme) {
                        AppTheme.light => '浅色',
                        AppTheme.dark => '深色',
                        AppTheme.system => '跟随系统',
                      },
                      () => _save(
                        s.copyWith(
                          theme:
                              AppTheme.values[(s.theme.index + 1) %
                                  AppTheme.values.length],
                        ),
                      ),
                    ),
                    row(
                      12,
                      'setting-logs',
                      '诊断日志',
                      '查看本次运行的网络与状态记录。',
                      '查看日志',
                      () async {
                        await context.push<void>('/settings/logs');
                        if (mounted) nodes[12].requestFocus();
                      },
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
