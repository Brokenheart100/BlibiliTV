import 'dart:convert';

import '../../domain/overlays/overlays.dart';
import '../services/local/local_stores.dart';

class LocalOverlayPreferences implements OverlayPreferencesRepository {
  LocalOverlayPreferences(this.store);
  final PreferencesStore store;
  static const key = 'app.overlays.v1';
  @override
  Future<OverlayPreferences> load() async {
    try {
      final raw = await store.read(key);
      if (raw == null) return const OverlayPreferences();
      final map = jsonDecode(raw) as Map<String, dynamic>;
      T pick<T>(String key, T fallback) =>
          map[key] is T ? map[key] as T : fallback;
      double bounded(String key, double fallback, double min, double max) {
        final value = map[key];
        return value is num && value.isFinite
            ? value.toDouble().clamp(min, max)
            : fallback;
      }

      return OverlayPreferences(
        subtitles: pick('subtitles', true),
        language: pick('language', 'zh'),
        fontSize: bounded('fontSize', 24, 18, 36),
        subtitleBottom: bounded('subtitleBottom', 45, 20, 160),
        offsetMs: bounded('offsetMs', 0, -5000, 5000).round(),
        danmaku: pick('danmaku', false),
        opacity: bounded('opacity', .8, .2, 1),
        area: bounded('area', .5, .25, .75),
        density: pick('density', 40) <= 20 ? 20 : 40,
        top: pick('top', true),
        bottom: pick('bottom', true),
        scroll: pick('scroll', true),
        keywords:
            (map['keywords'] is List
                    ? (map['keywords'] as List)
                          .whereType<String>()
                          .where((s) => s.isNotEmpty && s.length <= 80)
                          .take(30)
                    : <String>[])
                .toList(),
      );
    } catch (_) {
      return const OverlayPreferences();
    }
  }

  @override
  Future<void> save(OverlayPreferences p) => store.write(
    key,
    jsonEncode({
      'subtitles': p.subtitles,
      'language': p.language,
      'fontSize': p.fontSize,
      'subtitleBottom': p.subtitleBottom,
      'offsetMs': p.offsetMs,
      'danmaku': p.danmaku,
      'opacity': p.opacity,
      'area': p.area,
      'density': p.density,
      'top': p.top,
      'bottom': p.bottom,
      'scroll': p.scroll,
      'keywords': p.keywords
          .take(30)
          .where((s) => s.isNotEmpty && s.length <= 80)
          .toList(),
    }),
  );
}
