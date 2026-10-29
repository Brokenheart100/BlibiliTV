import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/repository_providers.dart';
import '../../../domain/entities/app_models.dart';
import '../../../domain/discovery/content_search.dart';
import '../../../app/providers/ui_providers.dart';
import '../../core/focus/focus_memory.dart';
import '../../core/theme/tv_theme.dart';
import '../../core/widgets/tv_button.dart';
import '../../core/widgets/tv_grid.dart';
import '../../core/widgets/tv_pill_tabs.dart';
import '../catalog/views/catalog_page.dart';
import '../catalog/view_models/catalog_view_model.dart';
import 'view_models/search_history_view_model.dart';
import 'view_models/content_search_view_model.dart';
import '../settings/view_models/settings_view_model.dart';
import 'content_search_results.dart';

class SearchPage extends ConsumerWidget {
  const SearchPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider).value ?? const Session();
    return _OwnerSearchPage(
      key: ValueKey(session.scopeKey),
      ownerKey: session.ownerKey,
    );
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
  final tabs = [
    for (final category in SearchCategory.values)
      FocusNode(debugLabel: 'search-type-${category.name}'),
  ];
  SearchCategory category = SearchCategory.video;
  final visited = <SearchCategory>{SearchCategory.video};
  TvShellScope? shell;
  bool keyboardWasVisible = false;
  CatalogOptions filters = const CatalogOptions();
  CatalogOptions draftFilters = const CatalogOptions();
  String get owner => widget.ownerKey;
  String get scope => ref.read(sessionProvider).value?.scopeKey ?? '$owner:0';
  bool visible = true;
  bool get active => visible && ref.read(appForegroundProvider);
  CatalogViewModelProvider _videoProvider(String query) =>
      catalogViewModelProvider(
        section: 'search',
        pageId: 'search',
        ownerKey: owner,
        query: query,
        options: filters == const CatalogOptions() ? null : filters,
        forceInitialRefresh: true,
      );
  ContentSearchViewModelProvider _contentProvider(
    SearchCategory type,
    String query,
  ) => contentSearchViewModelProvider(
    category: type,
    query: query,
    scopeKey: scope,
  );
  void _suspend() {
    final query = ref.read(searchQueryProvider(owner));
    for (final type in visited) {
      if (type == SearchCategory.video) {
        ref.read(_videoProvider(query).notifier).suspend();
      } else {
        ref.read(_contentProvider(type, query).notifier).suspend();
      }
    }
  }

  void _resume() {
    if (!active) return;
    final query = ref.read(searchQueryProvider(owner));
    if (category == SearchCategory.video) {
      final provider = _videoProvider(query);
      if (ref.read(provider).hasError) {
        ref.invalidate(provider);
      } else {
        unawaited(ref.read(provider.notifier).resume());
      }
    } else {
      final provider = _contentProvider(category, query);
      if (ref.read(provider).hasError) {
        ref.invalidate(provider);
      } else {
        unawaited(ref.read(provider.notifier).resume());
      }
    }
  }

  void _selectType(SearchCategory next) {
    results.reset();
    final query = ref.read(searchQueryProvider(owner));
    ref
        .read(focusMemoryProvider)
        .forget(
          next == SearchCategory.video
              ? '$owner:search:search:$query:$filters'
              : '$scope:search:${next.name}:$query',
        );
    tabs[next.index].requestFocus();
    if (category == next) {
      _refreshType();
      return;
    }
    final cached = visited.contains(next);
    _suspend();
    setState(() {
      category = next;
      visited.add(next);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        tabs[next.index].requestFocus();
        if (cached) {
          _refreshType();
        } else {
          _resume();
        }
      }
    });
  }

  void _refreshType() {
    final query = ref.read(searchQueryProvider(owner));
    if (category == SearchCategory.video) {
      final provider = _videoProvider(query);
      if (ref.read(provider).hasValue) {
        unawaited(ref.read(provider.notifier).refresh());
      } else {
        ref.invalidate(provider);
      }
    } else {
      final provider = _contentProvider(category, query);
      if (ref.read(provider).hasValue) {
        unawaited(ref.read(provider.notifier).refresh());
      } else {
        ref.invalidate(provider);
      }
    }
  }

  KeyEventResult _tabKey(KeyEvent event, int index) {
    if (!isDirectionEvent(event)) return KeyEventResult.ignored;
    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowLeft:
        if (index == 0) {
          shell?.focusNavigation();
        } else {
          tabs[index - 1].requestFocus();
        }
      case LogicalKeyboardKey.arrowRight:
        tabs[(index + 1).clamp(0, tabs.length - 1)].requestFocus();
      case LogicalKeyboardKey.arrowUp:
        submitFocus.requestFocus();
      case LogicalKeyboardKey.arrowDown:
        final query = ref.read(searchQueryProvider(owner));
        final hasItems = category == SearchCategory.video
            ? ref.read(_videoProvider(query)).value?.items.isNotEmpty == true
            : ref
                      .read(_contentProvider(category, query))
                      .value
                      ?.items
                      .isNotEmpty ==
                  true;
        if (!hasItems) return KeyEventResult.ignored;
        unawaited(results.restore());
      default:
        return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  void _entry() => inputFocus.requestFocus();
  @override
  void initState() {
    super.initState();
    controller.text = ref.read(searchQueryProvider(owner));
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
    visible = TickerMode.valuesOf(context).enabled;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (active) {
        _resume();
      } else {
        _suspend();
      }
    });
  }

  @override
  void dispose() {
    shell?.unregisterContent(1, _entry);
    WidgetsBinding.instance.removeObserver(this);
    controller.dispose();
    inputFocus.dispose();
    submitFocus.dispose();
    firstHistory.dispose();
    for (final node in tabs) {
      node.dispose();
    }
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
    if (previous == query) {
      if (category == SearchCategory.video) {
        final provider = _videoProvider(query);
        if (ref.read(provider).hasValue) {
          unawaited(ref.read(provider.notifier).refresh());
        } else {
          ref.invalidate(provider);
        }
      } else {
        final provider = _contentProvider(category, query);
        if (ref.read(provider).hasValue) {
          unawaited(ref.read(provider.notifier).refresh());
        } else {
          ref.invalidate(provider);
        }
      }
    } else {
      _suspend();
      setState(() {
        visited
          ..clear()
          ..add(category);
      });
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
    for (final type in visited) {
      if (type == SearchCategory.video) {
        ref.watch(_videoProvider(query).select((_) => null));
      } else {
        final provider = _contentProvider(type, query);
        ref.watch(provider.select((_) => null));
        ref.listen(provider, (_, next) {
          if (next.value?.paused == true && category == type && active) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && category == type) _resume();
            });
          }
        });
      }
    }
    ref.listen(appForegroundProvider, (_, foreground) {
      if (foreground && visible) {
        _resume();
      } else {
        _suspend();
      }
    });
    final reduced =
        ref.watch(settingsViewModelProvider).value?.settings.reducedMotion ??
        false;
    final keyboard = MediaQuery.viewInsetsOf(context).bottom > 0;
    return Column(
      children: [
        if (!keyboard && category == SearchCategory.video)
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
            child: Row(
              children: [
                TvButton(
                  key: const Key('search-order'),
                  compact: true,
                  label:
                      '排序 · ${switch (draftFilters.order) {
                        VideoOrder.relevance => "综合",
                        VideoOrder.newest => "最新发布",
                        VideoOrder.mostViewed => "最多播放",
                      }}',
                  onPressed: () => setState(
                    () => draftFilters = draftFilters.copyWith(
                      order:
                          VideoOrder.values[(draftFilters.order.index + 1) %
                              VideoOrder.values.length],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                TvButton(
                  key: const Key('search-duration'),
                  compact: true,
                  label:
                      '时长 · ${const ["全部", "10 分钟以下", "10–30 分钟", "30–60 分钟", "60 分钟以上"][draftFilters.duration]}',
                  onPressed: () => setState(
                    () => draftFilters = draftFilters.copyWith(
                      duration: (draftFilters.duration + 1) % 5,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                TvButton(
                  key: const Key('search-filter-apply'),
                  compact: true,
                  label: draftFilters == filters ? '已应用' : '应用筛选',
                  onPressed: () => setState(() => filters = draftFilters),
                ),
                const SizedBox(width: 10),
                TvButton(
                  key: const Key('search-filter-reset'),
                  compact: true,
                  label: '重置筛选',
                  onPressed: () => setState(() {
                    filters = const CatalogOptions();
                    draftFilters = filters;
                  }),
                ),
              ],
            ),
          ),
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
                      hintText: '搜索视频、番剧、影视或直播',
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
                  if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                    tabs[category.index].requestFocus();
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
                  Text(
                    '最近搜索',
                    style: TextStyle(
                      color: context.tvColors.muted,
                      fontSize: 11,
                    ),
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
                                      tabs[category.index].requestFocus();
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
                Expanded(
                  child: Text(
                    '搜索历史暂不可用，仍可继续搜索',
                    style: TextStyle(
                      color: context.tvColors.muted,
                      fontSize: 11,
                    ),
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
        if (!keyboard)
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 10, 24, 0),
            child: TvCapsuleTabs<SearchCategory>(
              key: const Key('search-type-tabs'),
              values: SearchCategory.values,
              selected: category,
              nodes: tabs,
              label: (type) => type.label,
              tabKey: (type) => ValueKey('search-type-${type.name}'),
              onSelected: _selectType,
              onKey: _tabKey,
              reducedMotion: reduced,
            ),
          ),
        Expanded(
          child: keyboard
              ? Center(
                  child: Text(
                    '确认关键词后，按键盘上的搜索键',
                    style: TextStyle(color: context.tvColors.muted),
                  ),
                )
              : category != SearchCategory.video
              ? ContentSearchResults(
                  key: ValueKey(
                    'content-search-${category.name}-$query-$scope',
                  ),
                  category: category,
                  query: query,
                  scopeKey: scope,
                  controller: results,
                  reducedMotion: reduced,
                  onInput: inputFocus.requestFocus,
                  onTop: () => tabs[category.index].requestFocus(),
                )
              : CatalogPage(
                  forceInitialRefresh: true,
                  compactHeader: true,
                  section: 'search',
                  pageId: 'search',
                  branchIndex: 1,
                  title: '搜索',
                  subtitle: query.isEmpty ? '输入关键词，发现想看的内容' : '“$query”的搜索结果',
                  query: query,
                  options: filters,
                  registerEntry: false,
                  controller: results,
                  onTop: () => tabs[category.index].requestFocus(),
                ),
        ),
      ],
    );
  }
}
