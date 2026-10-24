import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers/ui_providers.dart';

class LifecycleBridge extends ConsumerStatefulWidget {
  const LifecycleBridge({required this.child, super.key});
  final Widget child;
  @override
  ConsumerState<LifecycleBridge> createState() => _LifecycleBridgeState();
}

class _LifecycleBridgeState extends ConsumerState<LifecycleBridge>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) => ref
      .read(appForegroundProvider.notifier)
      .update(state == AppLifecycleState.resumed);
  @override
  Widget build(BuildContext context) => widget.child;
}
