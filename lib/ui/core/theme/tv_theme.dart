import 'package:flutter/material.dart';

/// Fixed dark colors for chrome painted directly over video.
abstract final class TvColors {
  static const background = Color(0xFF0B0C12);
  static const surface = Color(0xFF1C1E29);
  static const muted = Color(0xFF989DAD);
  static const accent = Color(0xFF89ADFF);
  static const line = Color(0x24FFFFFF);
}

class TvPalette {
  const TvPalette({
    required this.background,
    required this.surface,
    required this.text,
    required this.muted,
    required this.accent,
    required this.line,
    required this.panel,
    required this.button,
    required this.selected,
    required this.focus,
    required this.onFocus,
    required this.tabSurface,
    required this.tabSelected,
    required this.shadow,
  });
  final Color background,
      surface,
      text,
      muted,
      accent,
      line,
      panel,
      button,
      selected,
      focus,
      onFocus,
      tabSurface,
      tabSelected,
      shadow;
  static const dark = TvPalette(
    background: TvColors.background,
    surface: TvColors.surface,
    text: Color(0xFFF5F7FC),
    muted: Color(0xFFA5ABBA),
    accent: TvColors.accent,
    line: TvColors.line,
    panel: Color(0xCC212430),
    button: Color(0x16FFFFFF),
    selected: Color(0xFF38445F),
    focus: Color(0xFFF5F7FC),
    onFocus: TvColors.background,
    tabSurface: Color(0xE5282D38),
    tabSelected: Color(0xFF204F65),
    shadow: Color(0x30000000),
  );
  static const light = TvPalette(
    background: Color(0xFFF1F3F7),
    surface: Color(0xFFFDFEFF),
    text: Color(0xFF242A36),
    muted: Color(0xFF626B7B),
    accent: Color(0xFF007FAE),
    line: Color(0x1A29364B),
    panel: Color(0xDEFFFFFF),
    button: Color(0xB3FFFFFF),
    selected: Color(0xFFD7EEF9),
    focus: Color(0xFFD2F0FA),
    onFocus: Color(0xFF006F98),
    tabSurface: Color(0xF5FFFFFF),
    tabSelected: Color(0xFFC8EEF9),
    shadow: Color(0x160F203B),
  );
}

extension TvThemeContext on BuildContext {
  TvPalette get tvColors => Theme.of(this).brightness == Brightness.light
      ? TvPalette.light
      : TvPalette.dark;
}

abstract final class TvSpacing {
  static const small = 8.0, medium = 12.0, large = 20.0, page = 28.0;
}

ThemeData tvTheme({Brightness brightness = Brightness.dark}) {
  final colors = brightness == Brightness.light
      ? TvPalette.light
      : TvPalette.dark;
  return ThemeData(
    brightness: brightness,
    useMaterial3: true,
    scaffoldBackgroundColor: Colors.transparent,
    colorScheme:
        ColorScheme.fromSeed(
          seedColor: colors.accent,
          brightness: brightness,
          surface: colors.surface,
        ).copyWith(
          primary: colors.accent,
          onSurface: colors.text,
          onSurfaceVariant: colors.muted,
        ),
    fontFamilyFallback: const ['Microsoft YaHei', 'Noto Sans CJK SC'],
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    dialogTheme: DialogThemeData(
      backgroundColor: colors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
    ),
    textTheme: TextTheme(
      headlineLarge: const TextStyle(
        fontSize: 34,
        fontWeight: FontWeight.w700,
        letterSpacing: -.7,
      ),
      headlineMedium: const TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w700,
      ),
      titleLarge: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
      titleMedium: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      bodyLarge: const TextStyle(fontSize: 16, height: 1.45),
      bodyMedium: const TextStyle(fontSize: 14, height: 1.4),
      bodySmall: TextStyle(fontSize: 12, color: colors.muted),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: colors.surface,
      border: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: colors.accent, width: 2),
        borderRadius: const BorderRadius.all(Radius.circular(12)),
      ),
    ),
  );
}
