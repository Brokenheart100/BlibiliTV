import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/result.dart';
import '../../../../domain/overlays/overlays.dart';
import '../../../core/widgets/tv_button.dart';
import '../../../core/widgets/glass_panel.dart';
import '../../../core/theme/tv_theme.dart';
import '../view_models/overlay_view_models.dart';

class OverlaySettingsDialog extends ConsumerWidget {
  const OverlaySettingsDialog({
    required this.videoId,
    required this.partId,
    required this.scopeKey,
    super.key,
  });
  final String videoId, partId, scopeKey;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p =
        ref.watch(overlaySettingsViewModelProvider).value ??
        const OverlayPreferences();
    final subtitles = subtitleViewModelProvider(
      videoId: videoId,
      partId: partId,
      scopeKey: scopeKey,
    );
    final localOnly = partId.isEmpty;
    final sub = localOnly
        ? const AsyncData(SubtitleState())
        : ref.watch(subtitles);
    final dmProvider = danmakuViewModelProvider(
      videoId: videoId,
      partId: partId,
      scopeKey: scopeKey,
    );
    final dm = p.danmaku && !localOnly
        ? ref.watch(dmProvider)
        : const AsyncData(DanmakuState());
    Future<void> save(OverlayPreferences next) async {
      final result = await ref
          .read(overlaySettingsViewModelProvider.notifier)
          .savePreferences(next);
      if (context.mounted && result is ResultFailure<void>) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(result.failure.message)));
      }
    }

    Widget item(
      String key,
      String label,
      VoidCallback action, {
      bool autofocus = false,
    }) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Builder(
        builder: (itemContext) => TvButton(
          key: Key(key),
          label: label,
          autofocus: autofocus,
          onPressed: action,
          onFocusChange: (focused) {
            if (focused) {
              unawaited(Scrollable.ensureVisible(itemContext, alignment: .5));
            }
          },
        ),
      ),
    );
    return Dialog(
      backgroundColor: Colors.transparent,
      child: SizedBox(
        width: 660,
        height: MediaQuery.sizeOf(context).height * .82,
        child: GlassPanel(
          child: FocusTraversalGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(
                      CupertinoIcons.captions_bubble,
                      color: context.tvColors.text,
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        '观看增强',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    TvButton(
                      key: const Key('overlay-close'),
                      label: '完成',
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        item(
                          'overlay-subtitle-toggle',
                          '字幕 · ${p.subtitles ? "开启" : "关闭"}',
                          () => unawaited(
                            save(p.copyWith(subtitles: !p.subtitles)),
                          ),
                          autofocus: true,
                        ),
                        if (p.subtitles) ...[
                          if (!localOnly && sub.isLoading)
                            const Text('正在读取字幕轨道'),
                          if (!localOnly &&
                              sub.hasValue &&
                              sub.value!.tracks.isEmpty)
                            Padding(
                              padding: const EdgeInsets.all(8),
                              child: Text(
                                '当前分 P 没有可用字幕；部分轨道需要登录',
                                style: TextStyle(color: context.tvColors.muted),
                              ),
                            ),
                          if (!localOnly)
                            item(
                              'overlay-subtitle-off',
                              '${sub.value?.selected == null ? "✓ " : ""}本次关闭轨道',
                              () => unawaited(
                                ref.read(subtitles.notifier).select(null),
                              ),
                            ),
                          for (final track
                              in sub.value?.tracks ?? <SubtitleTrack>[])
                            item(
                              'overlay-track-${track.id}',
                              '${sub.value?.selected == track.id ? "✓ " : ""}${track.title}${track.ai ? " · AI" : ""}',
                              () => unawaited(
                                ref.read(subtitles.notifier).select(track.id),
                              ),
                            ),
                          if (sub.hasError || sub.value?.failure != null)
                            item(
                              'overlay-subtitle-retry',
                              '字幕加载失败 · 重试',
                              () => ref.invalidate(subtitles),
                            ),
                          item(
                            'overlay-font-size',
                            '文字大小 · ${p.fontSize.round()}',
                            () => unawaited(
                              save(
                                p.copyWith(
                                  fontSize: p.fontSize >= 32
                                      ? 20
                                      : p.fontSize + 4,
                                ),
                              ),
                            ),
                          ),
                          item(
                            'overlay-subtitle-position',
                            '字幕位置 · 距底部 ${p.subtitleBottom.round()}',
                            () => unawaited(
                              save(
                                p.copyWith(
                                  subtitleBottom: p.subtitleBottom >= 135
                                      ? 45
                                      : p.subtitleBottom + 45,
                                ),
                              ),
                            ),
                          ),
                          item(
                            'overlay-language',
                            '字幕优先语言 · ${p.language}',
                            () {
                              const languages = ['zh', 'en', 'ja', 'ko'];
                              unawaited(
                                save(
                                  p.copyWith(
                                    language:
                                        languages[(languages.indexOf(
                                                  p.language,
                                                ) +
                                                1) %
                                            languages.length],
                                  ),
                                ),
                              );
                            },
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: item(
                                  'overlay-offset-minus',
                                  '字幕提前 0.1 秒',
                                  () => unawaited(
                                    save(
                                      p.copyWith(
                                        offsetMs: (p.offsetMs - 100).clamp(
                                          -5000,
                                          5000,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: item(
                                  'overlay-offset-plus',
                                  '字幕延后 0.1 秒',
                                  () => unawaited(
                                    save(
                                      p.copyWith(
                                        offsetMs: (p.offsetMs + 100).clamp(
                                          -5000,
                                          5000,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          item(
                            'overlay-offset-reset',
                            '字幕偏移 ${(p.offsetMs / 1000).toStringAsFixed(1)} 秒 · 重置',
                            () => unawaited(save(p.copyWith(offsetMs: 0))),
                          ),
                        ],
                        const Divider(height: 24),
                        item(
                          'overlay-danmaku-toggle',
                          '弹幕 · ${p.danmaku ? "开启" : "关闭"}',
                          () =>
                              unawaited(save(p.copyWith(danmaku: !p.danmaku))),
                        ),
                        if (p.danmaku) ...[
                          if (dm.isLoading || dm.value?.loading == true)
                            const Text('正在读取分段弹幕'),
                          if (dm.hasError || dm.value?.failure != null)
                            item('overlay-danmaku-retry', '弹幕加载失败 · 重试', () {
                              if (dm.hasError) {
                                ref.invalidate(dmProvider);
                              } else {
                                ref
                                    .read(dmProvider.notifier)
                                    .moveTo(0, retry: true);
                              }
                            }),
                          item(
                            'overlay-density',
                            '弹幕密度 · ${p.density == 20 ? "低负载" : "标准"}',
                            () => unawaited(
                              save(
                                p.copyWith(density: p.density == 20 ? 40 : 20),
                              ),
                            ),
                          ),
                          item(
                            'overlay-opacity',
                            '文字透明度 · ${(p.opacity * 100).round()}%',
                            () => unawaited(
                              save(
                                p.copyWith(
                                  opacity: p.opacity >= 1
                                      ? .4
                                      : (p.opacity + .2).clamp(.2, 1),
                                ),
                              ),
                            ),
                          ),
                          item(
                            'overlay-area',
                            '弹幕区域 · ${(p.area * 100).round()}%',
                            () => unawaited(
                              save(
                                p.copyWith(
                                  area: p.area >= .75 ? .25 : p.area + .25,
                                ),
                              ),
                            ),
                          ),
                          item(
                            'overlay-scroll',
                            '滚动弹幕 · ${p.scroll ? "显示" : "隐藏"}',
                            () =>
                                unawaited(save(p.copyWith(scroll: !p.scroll))),
                          ),
                          item(
                            'overlay-top',
                            '顶部弹幕 · ${p.top ? "显示" : "隐藏"}',
                            () => unawaited(save(p.copyWith(top: !p.top))),
                          ),
                          item(
                            'overlay-bottom',
                            '底部弹幕 · ${p.bottom ? "显示" : "隐藏"}',
                            () =>
                                unawaited(save(p.copyWith(bottom: !p.bottom))),
                          ),
                          item(
                            'overlay-keywords',
                            '本机关键词屏蔽 · ${p.keywords.length} 条',
                            () => unawaited(_keywords(context, ref, p)),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _keywords(
    BuildContext context,
    WidgetRef ref,
    OverlayPreferences p,
  ) async {
    final controller = TextEditingController(text: p.keywords.join('\n'));
    final value = await showDialog<String>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: const Text('关键词屏蔽 · 每行一个，最多 30 条'),
        content: SizedBox(
          width: 480,
          child: TextField(
            key: const Key('overlay-keywords-input'),
            controller: controller,
            autofocus: true,
            maxLength: 2400,
            minLines: 3,
            maxLines: 6,
          ),
        ),
        actions: [
          TvButton(label: '取消', onPressed: () => Navigator.pop(dialog)),
          TvButton(
            label: '保存',
            onPressed: () => Navigator.pop(dialog, controller.text),
          ),
        ],
      ),
    );
    // The dialog's reverse transition still references its controller briefly.
    await Future<void>.delayed(const Duration(milliseconds: 350));
    controller.dispose();
    if (value != null && context.mounted) {
      final next = value
          .split('\n')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty && e.length <= 80)
          .toSet()
          .take(30)
          .toList();
      final result = await ref
          .read(overlaySettingsViewModelProvider.notifier)
          .savePreferences(p.copyWith(keywords: next));
      if (context.mounted && result is ResultFailure<void>) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(result.failure.message)));
      }
    }
  }
}
