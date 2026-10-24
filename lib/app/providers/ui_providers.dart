import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../ui/core/focus/focus_memory.dart';

part 'ui_providers.g.dart';

@Riverpod(keepAlive: true)
FocusMemory focusMemory(Ref ref) => FocusMemory();

@Riverpod(keepAlive: true)
class AppForeground extends _$AppForeground {
  @override
  bool build() => true;
  void update(bool foreground) => state = foreground;
}
