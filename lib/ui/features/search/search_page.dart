import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/repository_providers.dart';
import '../../core/focus/focus_memory.dart';
import '../../core/theme/tv_theme.dart';
import '../../core/widgets/tv_button.dart';
import '../../core/widgets/tv_grid.dart';
import '../catalog/views/catalog_page.dart';
import '../catalog/view_models/catalog_view_model.dart';
import 'view_models/search_history_view_model.dart';

class SearchPage extends ConsumerWidget {
  const SearchPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final owner = ref.watch(sessionProvider).value?.ownerKey ?? 'guest';
    return _OwnerSearchPage(key: ValueKey(owner), ownerKey: owner);
  }
}

class _OwnerSearchPage extends ConsumerStatefulWidget {
  const _OwnerSearchPage({required this.ownerKey, super.key});
  final String ownerKey;
  @override
  ConsumerState<_OwnerSearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<_OwnerSearchPage>
    with WidgetsBindingObserver {
  final inputFocus = FocusNode(debugLabel: 'search-input');
  final submitFocus = FocusNode(debugLabel: 'search-submit');
  final firstHistory = FocusNode(debugLabel: 'search-history-first');
  final controller = TextEditingController();
  final results = TvGridController();
  TvShellScope? shell;
  bool keyboardWasVisible = false;
  String get owner => widget.ownerKey;
  void _entry() => inputFocus.requestFocus();
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeMetrics() {
    final visible =
        WidgetsBinding
            .instance
            .platformDispatcher
            .views
            .first
            .viewInsets
            .bottom >
        0;
    if (keyboardWasVisible && !visible && inputFocus.hasFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) submitFocus.requestFocus();
      });
    }
    keyboardWasVisible = visible;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    shell = TvShellScope.maybeOf(context);
    shell?.registerContent(1, _entry);
  }

  @override
  void dispose() {
    shell?.unregisterContent(1, _entry);
    WidgetsBinding.instance.removeObserver(this);
    controller.dispose();
    inputFocus.dispose();
    submitFocus.dispose();
    firstHistory.dispose();
    super.dispose();
  }

  void _submit([String? value]) {
    if (value != null) controller.value = TextEditingValue(text: value);
    if (controller.value.composing.isValid &&
        !controller.value.composing.isCollapsed) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('请先确认输入法候选词')));
      return;
    }
    final query = controller.text.trim();
    if (query.length > 100) return;
    final previous = ref.read(searchQueryProvider(owner));
    final oldProvider = catalogViewModelProvider(
      section: 'search',
      pageId: 'search',
      ownerKey: owner,
      query: previous,
    );
    if (previous == query) {
      if (ref.read(oldProvider).hasValue) {
        unawaited(ref.read(oldProvider.notifier).refresh());
      } else {
        ref.invalidate(oldProvider);
      }
    } else {
      ref.read(oldProvider.notifier).suspend();
      ref.read(searchQueryProvider(owner).notifier).submit(query);
    }
    if (query.isNotEmpty) {
      unawaited(
        ref
            .read(searchHistoryViewModelProvider(owner).notifier)
            .remember(query),
      );
    }
    submitFocus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(searchQueryProvider(owner));
    final historyProvider = searchHistoryViewModelProvider(owner);
    final history = ref.watch(historyProvider);
    final items = history.value?.items ?? const <String>[];
    // Keep the current result scope while the native keyboard temporarily uses
    // the content area; opening/dismissing the IME must not lose pagination.
    ref.watch(
      catalogViewModelProvider(
        section: 'search',
        pageId: 'search',
        ownerKey: owner,
        query: query,
      ).select((_) => null),
    );
    final keyboard = MediaQuery.viewInsetsOf(context).bottom > 0;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 0),
          child: Row(
            children: [
              Expanded(
                child: Focus(
                  canRequestFocus: false,
                  skipTraversal: true,
                  onKeyEvent: (_, event) {
                    if (!isDirectionEvent(event)) return KeyEventResult.ignored;
                    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                      submitFocus.requestFocus();
                      return KeyEventResult.handled;
                    }
                    if (event.logicalKey == LogicalKeyboardKey.arrowLeft &&
                        controller.text.isEmpty) {
                      shell?.focusNavigation();
                      return KeyEventResult.handled;
                    }
                    return KeyEventResult.ignored;
                  },
                  child: TextField(
                    key: ValueKey('search-input-$owner'),
                    focusNode: inputFocus,
                    controller: controller,
                    maxLength: 100,
                    maxLengthEnforcement:
                        MaxLengthEnforcement.truncateAfterCompositionEnds,
                    onSubmitted: (_) => _submit(),
                    textInputAction: TextInputAction.search,
                    decoration: const InputDecoration(
                      counterText: '',
                      hintText: '搜索视频、UP 主或你感兴趣的内容',
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              TvButton(
                key: const Key('search-submit'),
                focusNode: submitFocus,
                label: '搜索',
                onPressed: _submit,
                onKeyEvent: (event) {
                  if (!isDirectionEvent(event)) return KeyEventResult.ignored;
                  if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
                    shell?.focusNavigation();
                    return KeyEventResult.handled;
                  }
                  if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                    inputFocus.requestFocus();
                    return KeyEventResult.handled;
                  }
                  if (event.logicalKey == LogicalKeyboardKey.arrowDown &&
                      items.isNotEmpty) {
                    firstHistory.requestFocus();
                    return KeyEventResult.handled;
                  }
                  return KeyEventResult.ignored;
                },
              ),
            ],
          ),
        ),
        if (!keyboard && items.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 10, 24, 0),
            child: SizedBox(
              height: 44,
              child: Row(
                children: [
                  const Text(
                    '最近搜索',
                    style: TextStyle(color: TvColors.muted, fontSize: 11),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          for (var i = 0; i < items.length; i++)
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Builder(
                                builder: (chipContext) => TvButton(
                                  key: ValueKey('search-history-$i'),
                                  focusNode: i == 0 ? firstHistory : null,
                                  compact: true,
                                  label: items[i],
                                  onPressed: () => _submit(items[i]),
                                  onFocusChange: (focused) {
                                    if (focused) {
                                      unawaited(
                                        Scrollable.ensureVisible(
                                          chipContext,
                                          alignment: .5,
                                        ),
                                      );
                                    }
                                  },
                                  onKeyEvent: (event) {
                                    if (!isDirectionEvent(event)) {
                                      return KeyEventResult.ignored;
                                    }
                                    if (event.logicalKey ==
                                        LogicalKeyboardKey.arrowUp) {
                                      submitFocus.requestFocus();
                                      return KeyEventResult.handled;
                                    }
                                    if (event.logicalKey ==
                                        LogicalKeyboardKey.arrowDown) {
                                      unawaited(results.restore());
                                      return KeyEventResult.handled;
                                    }
                                    return KeyEventResult.ignored;
                                  },
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  TvButton(
                    key: const Key('search-history-clear'),
                    compact: true,
                    label: '清空',
                    onPressed: () {
                      submitFocus.requestFocus();
                      unawaited(ref.read(historyProvider.notifier).clear());
                    },
                  ),
                ],
              ),
            ),
          ),
        if (!keyboard && (history.hasError || history.value?.failure != null))
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    '搜索历史暂不可用，仍可继续搜索',
                    style: TextStyle(color: TvColors.muted, fontSize: 11),
                  ),
                ),
                TvButton(
                  label: '重试历史',
                  compact: true,
                  onPressed: () => ref.invalidate(historyProvider),
                ),
              ],
            ),
          ),
        Expanded(
          child: keyboard
              ? const Center(
                  child: Text(
                    '确认关键词后，按键盘上的搜索键',
                    style: TextStyle(color: TvColors.muted),
                  ),
                )
              : CatalogPage(
                  section: 'search',
                  pageId: 'search',
                  branchIndex: 1,
                  title: '搜索',
                  subtitle: query.isEmpty ? '输入关键词，发现想看的内容' : '“$query”的搜索结果',
                  query: query,
                  registerEntry: false,
                  controller: results,
                  onTop: submitFocus.requestFocus,
                ),
        ),
      ],
    );
  }
}
