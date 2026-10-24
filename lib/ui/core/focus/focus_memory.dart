import 'package:flutter/widgets.dart';

class GridBookmark {
  const GridBookmark(this.id, this.index, this.offset);
  final String id;
  final int index;
  final double offset;
}

/// UI-only state. Nodes belong to mounted widgets, never repositories/VMs.
class FocusMemory {
  final _bookmarks = <String, GridBookmark>{};
  GridBookmark? read(String key) => _bookmarks[key];
  void save(String key, GridBookmark bookmark) => _bookmarks[key] = bookmark;
  void clear() => _bookmarks.clear();
}

class TvShellScope extends InheritedWidget {
  const TvShellScope({
    required this.focusNavigation,
    required this.registerContent,
    required this.unregisterContent,
    required super.child,
    super.key,
  });
  final VoidCallback focusNavigation;
  final void Function(int index, VoidCallback callback) registerContent;
  final void Function(int index, VoidCallback callback) unregisterContent;
  static TvShellScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<TvShellScope>();
  @override
  bool updateShouldNotify(TvShellScope oldWidget) => false;
}
