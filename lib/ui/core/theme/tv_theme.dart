import 'package:flutter/material.dart';

abstract final class TvColors {
  static const background = Color(0xFF0B0C12);
  static const surface = Color(0xFF1C1E29);
  static const muted = Color(0xFF989DAD);
  static const accent = Color(0xFF89ADFF);
  static const line = Color(0x24FFFFFF);
}

abstract final class TvSpacing {
  static const small = 8.0, medium = 12.0, large = 20.0, page = 28.0;
}

ThemeData tvTheme() => ThemeData(
  brightness: Brightness.dark,
  useMaterial3: true,
  scaffoldBackgroundColor: Colors.transparent,
  colorScheme: ColorScheme.fromSeed(
    seedColor: TvColors.accent,
    brightness: Brightness.dark,
    surface: TvColors.surface,
  ),
  fontFamilyFallback: const ['Microsoft YaHei', 'Noto Sans CJK SC'],
  splashFactory: NoSplash.splashFactory,
  highlightColor: Colors.transparent,
  dialogTheme: DialogThemeData(
    backgroundColor: const Color(0xFF242631),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
  ),
  textTheme: const TextTheme(
    headlineLarge: TextStyle(
      fontSize: 34,
      fontWeight: FontWeight.w700,
      letterSpacing: -.7,
    ),
    headlineMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
    titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
    titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
    bodyLarge: TextStyle(fontSize: 16, height: 1.45),
    bodyMedium: TextStyle(fontSize: 14, height: 1.4),
    bodySmall: TextStyle(fontSize: 12, color: TvColors.muted),
  ),
  inputDecorationTheme: const InputDecorationTheme(
    filled: true,
    fillColor: TvColors.surface,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
    ),
    focusedBorder: OutlineInputBorder(
      borderSide: BorderSide(color: TvColors.accent, width: 2),
      borderRadius: BorderRadius.all(Radius.circular(12)),
    ),
  ),
);
