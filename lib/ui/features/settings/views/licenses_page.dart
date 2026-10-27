import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/tv_theme.dart';
import '../../../core/widgets/tv_button.dart';
import '../view_models/licenses_view_model.dart';

class LicensesPage extends ConsumerStatefulWidget {
  const LicensesPage({super.key});
  @override
  ConsumerState<LicensesPage> createState() => _LicensesPageState();
}

class _LicensesPageState extends ConsumerState<LicensesPage> {
  final back = FocusNode(debugLabel: 'licenses-back');
  final reader = FocusNode(debugLabel: 'licenses-reader');
  final nodes = <int, FocusNode>{};
  final listScroll = ScrollController(), textScroll = ScrollController();
  int selected = 0;
  bool reading = false;
  @override
  void dispose() {
    back.dispose();
    reader.dispose();
    listScroll.dispose();
    textScroll.dispose();
    for (final node in nodes.values) {
      node.dispose();
    }
    super.dispose();
  }

  Future<void> focusItem(int index, int count) async {
    if (index < 0) {
      back.requestFocus();
      return;
    }
    if (count == 0) return;
    index = index.clamp(0, count - 1);
    if (listScroll.hasClients) {
      listScroll.jumpTo(
        (index * 68.0).clamp(0, listScroll.position.maxScrollExtent),
      );
    }
    await WidgetsBinding.instance.endOfFrame;
    if (mounted) nodes[index]?.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final notices = ref.watch(licenseNoticesProvider);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Row(
                children: [
                  TvButton(
                    key: const Key('licenses-back'),
                    label: '返回',
                    autofocus: true,
                    focusNode: back,
                    onPressed: () => Navigator.pop(context),
                    onKeyEvent: (e) {
                      if (isDirectionEvent(e) &&
                          e.logicalKey == LogicalKeyboardKey.arrowDown) {
                        unawaited(
                          focusItem(selected, notices.value?.length ?? 0),
                        );
                        return KeyEventResult.handled;
                      }
                      return KeyEventResult.ignored;
                    },
                  ),
                  const SizedBox(width: 20),
                  const Expanded(
                    child: Text(
                      '开源许可',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '上下选择组件，确认或向右阅读；阅读时上下滚动，向左返回列表。',
                style: TextStyle(color: context.tvColors.muted),
              ),
              const SizedBox(height: 18),
              Expanded(
                child: notices.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (_, _) => Center(
                    child: TvButton(
                      label: '重新读取许可',
                      onPressed: () => ref.invalidate(licenseNoticesProvider),
                    ),
                  ),
                  data: (values) {
                    if (values.isEmpty) {
                      return const Center(child: Text('此构建没有读取到许可文本'));
                    }
                    final current = selected.clamp(0, values.length - 1);
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          width: MediaQuery.sizeOf(context).width * .30,
                          child: ListView.builder(
                            controller: listScroll,
                            itemExtent: 68,
                            itemCount: values.length,
                            itemBuilder: (context, i) => Padding(
                              padding: const EdgeInsets.only(
                                right: 16,
                                bottom: 10,
                              ),
                              child: TvButton(
                                key: ValueKey('license-$i'),
                                label: values[i].packages,
                                selected: current == i,
                                focusNode: nodes.putIfAbsent(
                                  i,
                                  () => FocusNode(debugLabel: 'license-$i'),
                                ),
                                onFocusChange: (focused) {
                                  if (focused) {
                                    setState(() => selected = i);
                                    if (textScroll.hasClients) {
                                      textScroll.jumpTo(0);
                                    }
                                  }
                                },
                                onPressed: reader.requestFocus,
                                onKeyEvent: (e) {
                                  if (!isDirectionEvent(e)) {
                                    return KeyEventResult.ignored;
                                  }
                                  if (e.logicalKey ==
                                      LogicalKeyboardKey.arrowDown) {
                                    unawaited(focusItem(i + 1, values.length));
                                  } else if (e.logicalKey ==
                                      LogicalKeyboardKey.arrowUp) {
                                    unawaited(focusItem(i - 1, values.length));
                                  } else if (e.logicalKey ==
                                      LogicalKeyboardKey.arrowRight) {
                                    reader.requestFocus();
                                  } else if (e.logicalKey ==
                                      LogicalKeyboardKey.arrowLeft) {
                                    back.requestFocus();
                                  } else {
                                    return KeyEventResult.ignored;
                                  }
                                  return KeyEventResult.handled;
                                },
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Focus(
                            key: const Key('license-reader'),
                            focusNode: reader,
                            onFocusChange: (v) => setState(() => reading = v),
                            onKeyEvent: (_, e) {
                              if (!isDirectionEvent(e)) {
                                return KeyEventResult.ignored;
                              }
                              if (e.logicalKey ==
                                  LogicalKeyboardKey.arrowLeft) {
                                unawaited(focusItem(current, values.length));
                                return KeyEventResult.handled;
                              }
                              if ((e.logicalKey ==
                                          LogicalKeyboardKey.arrowDown ||
                                      e.logicalKey ==
                                          LogicalKeyboardKey.arrowUp) &&
                                  textScroll.hasClients) {
                                textScroll.jumpTo(
                                  (textScroll.offset +
                                          (e.logicalKey ==
                                                  LogicalKeyboardKey.arrowDown
                                              ? 180
                                              : -180))
                                      .clamp(
                                        0,
                                        textScroll.position.maxScrollExtent,
                                      ),
                                );
                                return KeyEventResult.handled;
                              }
                              return KeyEventResult.ignored;
                            },
                            child: Container(
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: context.tvColors.surface,
                                border: Border.all(
                                  color: reading
                                      ? context.tvColors.accent
                                      : context.tvColors.line,
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: SingleChildScrollView(
                                controller: textScroll,
                                child: Text(
                                  '${values[current].packages}\n\n${values[current].text}',
                                  key: const Key('license-text'),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
