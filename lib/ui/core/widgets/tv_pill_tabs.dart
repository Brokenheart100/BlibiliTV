import 'package:flutter/material.dart';

import '../../../domain/discovery/home_feed.dart';
import '../theme/tv_theme.dart';

/// Equal-width TV targets stay inside one rounded rail at smaller window sizes.
class TvPillTabs extends StatelessWidget {
  const TvPillTabs({
    required this.selected,
    required this.nodes,
    required this.onSelected,
    required this.onKey,
    this.reducedMotion = false,
    super.key,
  });
  final HomeFeed selected;
  final List<FocusNode> nodes;
  final ValueChanged<HomeFeed> onSelected;
  final KeyEventResult Function(KeyEvent, int) onKey;
  final bool reducedMotion;
  @override
  Widget build(BuildContext context) => TvCapsuleTabs<HomeFeed>(
    key: const Key('home-pill-tabs'),
    values: HomeFeed.values,
    selected: selected,
    nodes: nodes,
    label: (feed) => feed.label,
    tabKey: (feed) => ValueKey(
      'feed-${feed == HomeFeed.recommendation ? "recommendation" : feed.section}',
    ),
    onSelected: onSelected,
    onKey: onKey,
    reducedMotion: reducedMotion,
  );
}

/// A shared capsule rail with distinct selected and keyboard focus states.
class TvCapsuleTabs<T> extends StatelessWidget {
  const TvCapsuleTabs({
    required this.values,
    required this.selected,
    required this.nodes,
    required this.label,
    required this.tabKey,
    required this.onSelected,
    required this.onKey,
    this.reducedMotion = false,
    super.key,
  });
  final List<T> values;
  final T selected;
  final List<FocusNode> nodes;
  final String Function(T) label;
  final Key Function(T) tabKey;
  final ValueChanged<T> onSelected;
  final KeyEventResult Function(KeyEvent, int) onKey;
  final bool reducedMotion;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final colors = context.tvColors;
      return Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: colors.tabSurface,
          borderRadius: BorderRadius.circular(40),
          boxShadow: [
            BoxShadow(
              color: colors.shadow,
              blurRadius: 18,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            for (var index = 0; index < values.length; index++)
              Expanded(
                child: ListenableBuilder(
                  listenable: nodes[index],
                  builder: (context, _) {
                    final focused = nodes[index].hasFocus;
                    final active = selected == values[index];
                    return Semantics(
                      button: true,
                      inMutuallyExclusiveGroup: true,
                      selected: active,
                      child: Focus(
                        canRequestFocus: false,
                        skipTraversal: true,
                        onKeyEvent: (_, event) => onKey(event, index),
                        child: AnimatedContainer(
                          duration: Duration(
                            milliseconds: reducedMotion ? 0 : 120,
                          ),
                          decoration: BoxDecoration(
                            color: active
                                ? colors.tabSelected
                                : focused
                                ? colors.selected
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(32),
                            border: Border.all(
                              color: focused
                                  ? colors.accent
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              key: tabKey(values[index]),
                              focusNode: nodes[index],
                              borderRadius: BorderRadius.circular(32),
                              onTap: () => onSelected(values[index]),
                              child: SizedBox(
                                height: 42,
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: constraints.maxWidth < 650
                                        ? 5
                                        : 12,
                                  ),
                                  child: Center(
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        label(values[index]),
                                        style: TextStyle(
                                          fontSize: constraints.maxWidth < 650
                                              ? 15
                                              : 18,
                                          fontWeight: FontWeight.w700,
                                          color: active || focused
                                              ? colors.accent
                                              : colors.muted,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      );
    },
  );
}
