/// Bounded numeric diagnostics; no text, content IDs, accounts or URLs.
class OverlayMetrics {
  int created = 0, disposed = 0, active = 0, maximum = 0;
  int clockSamples = 0, captionChanges = 0, admittedDanmaku = 0, cleared = 0;
  int maximumDanmaku = 0, activeSchedulers = 0, lastPositionMs = 0;
  int lowLoadTransitions = 0, disabledTransitions = 0;
  int canvasFps = 0, density = 0, slowFramePercent = 0;
  int canvasDrawTickMs = 0, renderedDanmaku = 0, maximumRenderedDanmaku = 0;
  final loadWindows = <Map<String, num>>[];
  Map<String, Object> snapshot() => {
    'created': created,
    'disposed': disposed,
    'active': active,
    'maximum': maximum,
    'clockSamples': clockSamples,
    'captionChanges': captionChanges,
    'admittedDanmaku': admittedDanmaku,
    'cleared': cleared,
    'maximumDanmaku': maximumDanmaku,
    'activeSchedulers': activeSchedulers,
    'lowLoadTransitions': lowLoadTransitions,
    'disabledTransitions': disabledTransitions,
    'canvasFps': canvasFps,
    'density': density,
    'slowFramePercent': slowFramePercent,
    'canvasDrawTickMs': canvasDrawTickMs,
    'renderedDanmaku': renderedDanmaku,
    'maximumRenderedDanmaku': maximumRenderedDanmaku,
    'loadWindows': List<Map<String, num>>.of(loadWindows),
  };
}
