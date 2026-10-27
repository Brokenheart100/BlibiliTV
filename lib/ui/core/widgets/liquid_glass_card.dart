import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/tv_theme.dart';

/// Clipped, shared backdrop blur with a translucent body and refractive rim.
/// Place non-overlapping grid cards under one [BackdropGroup] to share the blur.
class LiquidGlassCard extends StatelessWidget {
  const LiquidGlassCard({
    required this.child,
    this.focused = false,
    this.radius = 20,
    this.padding = const EdgeInsets.all(5),
    super.key,
  });

  final Widget child;
  final bool focused;
  final double radius;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final colors = context.tvColors;
    final light = Theme.of(context).brightness == Brightness.light;
    final shape = BorderRadius.circular(radius);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: shape,
        boxShadow: [
          BoxShadow(
            color: colors.shadow,
            blurRadius: focused ? 16 : 9,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: shape,
        child: BackdropFilter.grouped(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: shape,
              // The rim catches light at opposite corners like curved glass.
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  focused ? colors.accent : Colors.white.withValues(alpha: .52),
                  colors.line,
                  focused
                      ? colors.accent.withValues(alpha: .65)
                      : Colors.white.withValues(alpha: light ? .65 : .18),
                ],
                stops: const [0, .5, 1],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(1.5),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(radius - 1.5),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      colors.surface.withValues(alpha: light ? .86 : .82),
                      colors.surface.withValues(alpha: light ? .60 : .57),
                      colors.accent.withValues(alpha: light ? .10 : .09),
                    ],
                    stops: const [0, .65, 1],
                  ),
                ),
                child: Padding(padding: padding, child: child),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
