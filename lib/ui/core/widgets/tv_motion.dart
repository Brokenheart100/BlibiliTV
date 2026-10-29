import 'package:cue/cue.dart';
import 'package:flutter/widgets.dart';

/// Shared short, interruptible motion; the existing focus nodes stay in charge.
class TvFocusMotion extends StatelessWidget {
  const TvFocusMotion({
    required this.focused,
    required this.child,
    this.reducedMotion = false,
    this.scale = 1.025,
    super.key,
  });
  final bool focused, reducedMotion;
  final double scale;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final reduced = reducedMotion || MediaQuery.disableAnimationsOf(context);
    return Cue.onToggle(
      debugLabel: 'TV focus',
      toggled: focused,
      motion: reduced ? CueMotion.none : const CueMotion.smooth(stiffness: 420),
      acts: [Act.scale(to: reduced ? 1 : scale)],
      child: child,
    );
  }
}

/// One entrance per scene, without animating images or backdrop blur per frame.
class TvSceneMotion extends StatelessWidget {
  const TvSceneMotion({required this.child, super.key});
  final Widget child;

  @override
  Widget build(BuildContext context) => Cue.onMount(
    debugLabel: 'TV scene',
    motion: MediaQuery.disableAnimationsOf(context)
        ? CueMotion.none
        : const CueMotion.easeOut(Duration(milliseconds: 180)),
    acts: [Act.fadeIn(), Act.translateY(from: 6)],
    child: child,
  );
}
