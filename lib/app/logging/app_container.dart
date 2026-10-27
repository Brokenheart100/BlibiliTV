import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:talker/talker.dart';

import '../providers/infrastructure_providers.dart';
import 'app_talker.dart';
import 'safe_riverpod_observer.dart';

/// Owns and releases the root container when the application is unmounted.
class AppProviderScope extends StatefulWidget {
  const AppProviderScope({required this.child, super.key});
  final Widget child;
  @override
  State<AppProviderScope> createState() => _AppProviderScopeState();
}

class _AppProviderScopeState extends State<AppProviderScope> {
  late final container = createAppContainer();
  @override
  void dispose() {
    container.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      UncontrolledProviderScope(container: container, child: widget.child);
}

/// Main and validation entrypoints share the same diagnostic composition.
ProviderContainer createAppContainer({
  List<Override> overrides = const [],
  Talker? talker,
}) {
  final shared = talker ?? createAppTalker();
  final container = ProviderContainer(
    retry: (_, _) => null,
    observers: [SafeRiverpodObserver(shared)],
    overrides: [
      appTalkerProvider.overrideWith((ref) {
        ref.onDispose(() {
          shared.cleanHistory();
          shared.disable();
        });
        return shared;
      }),
      ...overrides,
    ],
  );
  container.read(appTalkerProvider);
  return container;
}
