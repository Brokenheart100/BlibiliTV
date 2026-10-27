import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:talker_flutter/talker_flutter.dart';

import '../../../../app/providers/infrastructure_providers.dart';
import '../../../core/theme/tv_theme.dart';
import '../../../core/widgets/tv_button.dart';
import '../../../core/widgets/tv_dialog.dart';

enum _LogFilter {
  all('全部'),
  http('网络'),
  state('状态'),
  errors('错误');

  const _LogFilter(this.label);
  final String label;
  bool accepts(TalkerData log) => switch (this) {
    all => true,
    http => const [
      TalkerKey.httpRequest,
      TalkerKey.httpResponse,
      TalkerKey.httpError,
    ].contains(log.key),
    state => log.key?.startsWith('riverpod') == true,
    errors => const [
      LogLevel.warning,
      LogLevel.error,
      LogLevel.critical,
    ].contains(log.logLevel),
  };
}

/// Official Talker stream/history with TV controls instead of touch-only tools.
class DiagnosticsPage extends ConsumerStatefulWidget {
  const DiagnosticsPage({super.key});
  @override
  ConsumerState<DiagnosticsPage> createState() => _DiagnosticsPageState();
}

class _DiagnosticsPageState extends ConsumerState<DiagnosticsPage> {
  final toolbar = List.generate(
    4,
    (i) => FocusNode(debugLabel: 'logs-toolbar-$i'),
  );
  final reader = FocusNode(debugLabel: 'logs-reader');
  final rows = <int, FocusNode>{};
  final listScroll = ScrollController(), textScroll = ScrollController();
  _LogFilter filter = _LogFilter.all;
  List<TalkerData>? frozen;
  TalkerData? selected;
  int selectedIndex = 0;

  @override
  void dispose() {
    for (final node in [...toolbar, reader, ...rows.values]) {
      node.dispose();
    }
    listScroll.dispose();
    textScroll.dispose();
    super.dispose();
  }

  List<TalkerData> _visible(Talker talker) =>
      (frozen ?? talker.history).where(filter.accepts).toList();

  void _select(Talker talker, TalkerData log, int index) {
    if (identical(selected, log) && frozen != null) return;
    setState(() {
      frozen ??= List.of(talker.history);
      selected = log;
      selectedIndex = index;
    });
    if (textScroll.hasClients) textScroll.jumpTo(0);
  }

  Future<void> _focusRow(Talker talker, int index) async {
    final values = _visible(talker);
    if (index < 0 || values.isEmpty) {
      toolbar.first.requestFocus();
      return;
    }
    index = index.clamp(0, values.length - 1);
    _select(talker, values[index], index);
    if (listScroll.hasClients) {
      listScroll.jumpTo(
        (index * 64.0).clamp(0, listScroll.position.maxScrollExtent),
      );
    }
    await WidgetsBinding.instance.endOfFrame;
    if (mounted) rows[index]?.requestFocus();
  }

  KeyEventResult _toolbarKey(Talker talker, int index, KeyEvent event) {
    if (!isDirectionEvent(event)) return KeyEventResult.ignored;
    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowLeft:
        toolbar[(index - 1).clamp(0, 3)].requestFocus();
      case LogicalKeyboardKey.arrowRight:
        toolbar[(index + 1).clamp(0, 3)].requestFocus();
      case LogicalKeyboardKey.arrowDown:
        unawaited(_focusRow(talker, selectedIndex));
      case LogicalKeyboardKey.arrowUp:
        break;
      default:
        return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  String _detail(TalkerData log) {
    final message = log.message ?? '';
    try {
      return const JsonEncoder.withIndent('  ').convert(jsonDecode(message));
    } on FormatException {
      return message;
    }
  }

  @override
  Widget build(BuildContext context) {
    final talker = ref.watch(appTalkerProvider);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: TalkerBuilder(
            talker: talker,
            builder: (context, history) {
              final values = _visible(talker);
              final current = values.contains(selected)
                  ? selected
                  : values.lastOrNull;
              Widget action(
                int index,
                String key,
                String label,
                VoidCallback onPressed,
              ) => TvButton(
                key: ValueKey(key),
                label: label,
                compact: true,
                focusNode: toolbar[index],
                autofocus: index == 0,
                onKeyEvent: (event) => _toolbarKey(talker, index, event),
                onPressed: onPressed,
              );
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      action(0, 'logs-back', '返回', () {
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.go('/settings');
                        }
                      }),
                      const SizedBox(width: 20),
                      const Expanded(
                        child: Text(
                          '诊断日志',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(
                        '${values.length} 条',
                        style: TextStyle(color: context.tvColors.muted),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      action(
                        1,
                        'logs-filter',
                        '筛选：${filter.label}',
                        () => setState(() {
                          filter =
                              _LogFilter.values[(filter.index + 1) %
                                  _LogFilter.values.length];
                          selected = null;
                          selectedIndex = 0;
                          if (listScroll.hasClients) listScroll.jumpTo(0);
                        }),
                      ),
                      const SizedBox(width: 10),
                      action(
                        2,
                        'logs-live',
                        frozen == null ? '暂停更新' : '继续更新',
                        () => setState(() {
                          frozen = frozen == null ? List.of(history) : null;
                          selected = null;
                          selectedIndex = 0;
                          if (listScroll.hasClients) listScroll.jumpTo(0);
                        }),
                      ),
                      const SizedBox(width: 10),
                      action(3, 'logs-clear', '清空日志', () async {
                        if (await showTvConfirmation(
                          context,
                          title: '清空诊断日志？',
                          message: '仅清空本次运行的日志，不影响账号与观看记录。',
                          confirmLabel: '清空',
                        )) {
                          talker.cleanHistory();
                          if (mounted) {
                            setState(() {
                              selected = null;
                              frozen = null;
                              selectedIndex = 0;
                            });
                          }
                        }
                      }),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    talker.settings.enabled
                        ? '仅本机最近 200 条；上下选择，向右阅读，向左返回列表。'
                        : '当前构建未启用诊断日志。',
                    maxLines: 2,
                    style: TextStyle(
                      fontSize: 12,
                      color: context.tvColors.muted,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: values.isEmpty
                        ? const Center(child: Text('暂无符合条件的日志'))
                        : Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                flex: 2,
                                child: ListView.builder(
                                  controller: listScroll,
                                  itemExtent: 64,
                                  itemCount: values.length,
                                  itemBuilder: (context, index) {
                                    final log = values[index];
                                    return Padding(
                                      padding: const EdgeInsets.only(
                                        right: 12,
                                        bottom: 8,
                                      ),
                                      child: TvButton(
                                        key: ValueKey('log-$index'),
                                        label:
                                            '${log.displayTime()} · ${log.title ?? "日志"}',
                                        selected: identical(current, log),
                                        focusNode: rows.putIfAbsent(
                                          index,
                                          () => FocusNode(
                                            debugLabel: 'log-$index',
                                          ),
                                        ),
                                        onFocusChange: (focused) {
                                          if (focused) {
                                            _select(talker, log, index);
                                          }
                                        },
                                        onPressed: () {
                                          _select(talker, log, index);
                                          reader.requestFocus();
                                        },
                                        onKeyEvent: (event) {
                                          if (!isDirectionEvent(event)) {
                                            return KeyEventResult.ignored;
                                          }
                                          if (event.logicalKey ==
                                              LogicalKeyboardKey.arrowDown) {
                                            unawaited(
                                              _focusRow(talker, index + 1),
                                            );
                                          } else if (event.logicalKey ==
                                              LogicalKeyboardKey.arrowUp) {
                                            unawaited(
                                              _focusRow(talker, index - 1),
                                            );
                                          } else if (event.logicalKey ==
                                              LogicalKeyboardKey.arrowRight) {
                                            _select(talker, log, index);
                                            reader.requestFocus();
                                          } else if (event.logicalKey ==
                                              LogicalKeyboardKey.arrowLeft) {
                                            toolbar.first.requestFocus();
                                          } else {
                                            return KeyEventResult.ignored;
                                          }
                                          return KeyEventResult.handled;
                                        },
                                      ),
                                    );
                                  },
                                ),
                              ),
                              Expanded(
                                flex: 3,
                                child: Focus(
                                  focusNode: reader,
                                  onFocusChange: (_) => setState(() {}),
                                  onKeyEvent: (_, event) {
                                    if (!isDirectionEvent(event)) {
                                      return KeyEventResult.ignored;
                                    }
                                    if (event.logicalKey ==
                                        LogicalKeyboardKey.arrowLeft) {
                                      unawaited(
                                        _focusRow(talker, selectedIndex),
                                      );
                                    } else if (event.logicalKey ==
                                            LogicalKeyboardKey.arrowUp ||
                                        event.logicalKey ==
                                            LogicalKeyboardKey.arrowDown) {
                                      if (textScroll.hasClients) {
                                        textScroll.jumpTo(
                                          (textScroll.offset +
                                                  (event.logicalKey ==
                                                          LogicalKeyboardKey
                                                              .arrowDown
                                                      ? 120
                                                      : -120))
                                              .clamp(
                                                0,
                                                textScroll
                                                    .position
                                                    .maxScrollExtent,
                                              ),
                                        );
                                      }
                                    } else {
                                      return KeyEventResult.ignored;
                                    }
                                    return KeyEventResult.handled;
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: context.tvColors.surface,
                                      borderRadius: BorderRadius.circular(18),
                                      border: Border.all(
                                        color: reader.hasFocus
                                            ? context.tvColors.accent
                                            : context.tvColors.line,
                                        width: 2,
                                      ),
                                    ),
                                    child: SingleChildScrollView(
                                      controller: textScroll,
                                      child: Text(
                                        current == null ? '' : _detail(current),
                                        key: const Key('logs-detail'),
                                        style: TextStyle(
                                          fontSize: 14,
                                          height: 1.45,
                                          color: context.tvColors.text,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
