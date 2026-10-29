import 'package:flutter/material.dart';
import 'package:cue/cue.dart';

import '../../../domain/discovery/home_feed.dart';
import '../theme/tv_theme.dart';
import 'liquid_glass_card.dart';

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

/// A shared capsule rail; the selected pill travels independently of focus.
class TvCapsuleTabs<T> extends StatefulWidget {
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
  State<TvCapsuleTabs<T>> createState() => _TvCapsuleTabsState<T>();
}

class _TvCapsuleTabsState<T> extends State<TvCapsuleTabs<T>>
    with SingleTickerProviderStateMixin {
  late final position = CueValueAnimator<double>(
    selectedIndex,
    vsync: this,
    motion: const CueMotion.smooth(stiffness: 420),
  );
  double get selectedIndex => widget.values
      .indexOf(widget.selected)
      .clamp(0, widget.values.length - 1)
      .toDouble();
  bool get reduced =>
      widget.reducedMotion || MediaQuery.disableAnimationsOf(context);
  @override
  void initState() {
    super.initState();
    // Initialize before the first update can interrupt a transition.
    position;
  }

  void _target() {
    if (reduced) {
      position.value = selectedIndex;
    } else {
      position.animateTo(selectedIndex);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (reduced) position.value = selectedIndex;
  }

  @override
  void didUpdateWidget(covariant TvCapsuleTabs<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selected != widget.selected ||
        oldWidget.values.length != widget.values.length ||
        oldWidget.reducedMotion != widget.reducedMotion) {
      _target();
    }
  }

  @override
  void dispose() {
    position.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final colors = context.tvColors;
      final width = (constraints.maxWidth - 13) / widget.values.length;
      return LiquidGlassCard(
        radius: 40,
        padding: const EdgeInsets.all(5),
        child: Stack(
          children: [
            AnimatedBuilder(
              animation: position,
              builder: (context, _) => Positioned(
                left: width * position.value,
                width: width,
                top: 0,
                bottom: 0,
                child: IgnorePointer(
                  child: DecoratedBox(
                    key: const Key('capsule-selection'),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          colors.tabSelected.withValues(alpha: .88),
                          colors.tabSelected.withValues(alpha: .55),
                        ],
                      ),
                      border: Border.all(
                        color: colors.accent.withValues(alpha: .28),
                      ),
                      borderRadius: BorderRadius.circular(32),
                    ),
                  ),
                ),
              ),
            ),
            Row(
              children: [
                for (var index = 0; index < widget.values.length; index++)
                  Expanded(
                    child: ListenableBuilder(
                      listenable: widget.nodes[index],
                      builder: (context, _) {
                        final focused = widget.nodes[index].hasFocus;
                        final active = widget.selected == widget.values[index];
                        return Semantics(
                          button: true,
                          inMutuallyExclusiveGroup: true,
                          selected: active,
                          child: Focus(
                            canRequestFocus: false,
                            skipTraversal: true,
                            onKeyEvent: (_, event) =>
                                widget.onKey(event, index),
                            child: AnimatedContainer(
                              duration: Duration(
                                milliseconds: reduced ? 0 : 100,
                              ),
                              decoration: BoxDecoration(
                                color: focused && !active
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
                                  key: widget.tabKey(widget.values[index]),
                                  focusNode: widget.nodes[index],
                                  borderRadius: BorderRadius.circular(32),
                                  onTap: () =>
                                      widget.onSelected(widget.values[index]),
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
                                            widget.label(widget.values[index]),
                                            style: TextStyle(
                                              fontSize:
                                                  constraints.maxWidth < 650
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
          ],
        ),
      );
    },
  );
}
