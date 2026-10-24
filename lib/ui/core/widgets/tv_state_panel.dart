import 'package:flutter/material.dart';

import '../theme/tv_theme.dart';
import 'tv_button.dart';

class TvStatePanel extends StatelessWidget {
  const TvStatePanel({
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
    this.focusNode,
    this.icon = Icons.explore_outlined,
    super.key,
  });
  final String title, message, actionLabel;
  final VoidCallback onAction;
  final FocusNode? focusNode;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 42, color: TvColors.accent),
            const SizedBox(height: 16),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: TvColors.muted),
            ),
            const SizedBox(height: 20),
            TvButton(
              label: actionLabel,
              onPressed: onAction,
              focusNode: focusNode,
            ),
          ],
        ),
      ),
    ),
  );
}
