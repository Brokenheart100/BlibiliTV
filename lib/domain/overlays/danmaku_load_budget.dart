/// Reduces admission and animation cost without removing visible comments.
class DanmakuLoadBudget {
  DanmakuLoadBudget(this.density, {this.adaptive = true});
  final bool adaptive;
  int density;
  int _badWindows = 0;

  void resetMeasurements() => _badWindows = 0;

  /// Called once per 120 measured frames, after startup and controls settle.
  bool observeWindow(double slowFraction) {
    if (!adaptive) return false;
    _badWindows = slowFraction > .1 ? _badWindows + 1 : 0;
    if (_badWindows < 2) return false;
    _badWindows = 0;
    if (density > 10) {
      density = density > 20 ? 20 : 10;
      return true;
    }
    return false;
  }
}
