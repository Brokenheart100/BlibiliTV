import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/tv_theme.dart';

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
        color: context.tvColors.panel,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: context.tvColors.line),
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
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: Theme.of(context).brightness == Brightness.light
            ? const [Color(0xFFF5F7FA), Color(0xFFECEFF5), Color(0xFFF0EAF1)]
            : const [Color(0xFF17243C), Color(0xFF10121D), Color(0xFF21192D)],
        stops: [0, .55, 1],
      ),
    ),
    child: child,
  );
}
