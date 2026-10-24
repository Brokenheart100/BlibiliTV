import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/tv_button.dart';

class PreviewPage extends StatelessWidget {
  const PreviewPage({
    required this.title,
    required this.message,
    required this.icon,
    super.key,
  });
  final String title, message;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 64,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(title, style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 14),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 26),
              TvButton(
                key: const Key('preview-back'),
                label: '返回浏览',
                autofocus: true,
                icon: Icons.arrow_back,
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/home');
                  }
                },
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
