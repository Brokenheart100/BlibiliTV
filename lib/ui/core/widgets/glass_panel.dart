import 'dart:ui';

import 'package:flutter/material.dart';

/// Bounded blur for navigation and playback chrome, never every grid item.
class GlassPanel extends StatelessWidget {
  const GlassPanel({
    required this.child,
    this.radius = 26,
    this.blur = true,
    this.padding = EdgeInsets.zero,
    super.key,
  });
  final Widget child;
  final double radius;
  final bool blur;
  final EdgeInsetsGeometry padding;
  @override
  Widget build(BuildContext context) {
    final panel = DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xC0212430),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: Colors.white.withValues(alpha: .10)),
      ),
      child: Padding(padding: padding, child: child),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: blur
          ? BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: panel,
            )
          : panel,
    );
  }
}

class TvBackdrop extends StatelessWidget {
  const TvBackdrop({required this.child, super.key});
  final Widget child;
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF17243C), Color(0xFF10121D), Color(0xFF21192D)],
        stops: [0, .55, 1],
      ),
    ),
    child: child,
  );
}
