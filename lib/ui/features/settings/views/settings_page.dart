import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  final nodes = List.generate(
    3,
    (index) => FocusNode(debugLabel: 'setting-$index'),
  );
  TvShellScope? shell;
  void _entry() => nodes.first.requestFocus();
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    shell = TvShellScope.maybeOf(context);
    shell?.registerContent(3, _entry);
  }

  @override
  void dispose() {
    shell?.unregisterContent(3, _entry);
    for (final node in nodes) {
      node.dispose();
    }
    super.dispose();
  }

  KeyEventResult _key(int index, KeyEvent event) {
    if (!isDirectionEvent(event)) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      shell?.focusNavigation();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      nodes[(index + 1).clamp(0, 2)].requestFocus();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      nodes[(index - 1).clamp(0, 2)].requestFocus();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final result = ref.watch(settingsViewModelProvider);
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('设置', style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: 5),
          const Text('让大屏，更合你的习惯', style: TextStyle(color: TvColors.muted)),
          const SizedBox(height: 24),
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
              data: (data) => ListView(
                children: [
                  _settingRow(
                    context,
                    '减少动态效果',
                    '关闭卡片缩放，让界面更平静。',
                    TvButton(
                      key: const Key('setting-motion'),
                      focusNode: nodes[0],
                      label: data.settings.reducedMotion ? '已开启' : '已关闭',
                      onKeyEvent: (e) => _key(0, e),
                      onPressed: () {
                        if (!data.saving) {
                          unawaited(
                            ref
                                .read(settingsViewModelProvider.notifier)
                                .savePreferences(
                                  data.settings.copyWith(
                                    reducedMotion: !data.settings.reducedMotion,
                                  ),
                                ),
                          );
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 14),
                  _settingRow(
                    context,
                    '记住播放位置',
                    '为之后的继续观看保留偏好。',
                    TvButton(
                      key: const Key('setting-resume'),
                      focusNode: nodes[1],
                      label: data.settings.resumePlayback ? '已开启' : '已关闭',
                      onKeyEvent: (e) => _key(1, e),
                      onPressed: () {
                        if (!data.saving) {
                          unawaited(
                            ref
                                .read(settingsViewModelProvider.notifier)
                                .savePreferences(
                                  data.settings.copyWith(
                                    resumePlayback:
                                        !data.settings.resumePlayback,
                                  ),
                                ),
                          );
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TvButton(
                      key: const Key('about'),
                      label: '关于 MambaTV',
                      icon: Icons.info_outline,
                      focusNode: nodes[2],
                      onKeyEvent: (e) => _key(2, e),
                      onPressed: () => unawaited(
                        showTvConfirmation(
                          context,
                          title: 'MambaTV 预览',
                          message: '为电视设计的第三方视频客户端。\n支持公开视频播放、本地续播和扫码账号管理。',
                          confirmLabel: '知道了',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (data.message != null)
                    Text(
                      data.message!,
                      key: const Key('settings-message'),
                      style: const TextStyle(color: TvColors.accent),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _settingRow(
    BuildContext context,
    String title,
    String description,
    Widget control,
  ) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: TvColors.surface,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 5),
              Text(
                description,
                style: const TextStyle(color: TvColors.muted, fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        control,
      ],
    ),
  );
}
