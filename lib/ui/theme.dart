import 'package:flutter/material.dart';

import 'alpona.dart';

/// The app theme: alpona's earth, rice and turmeric, leaf green for
/// controls, and Hind Siliguri for Bangla and Latin alike.
ThemeData alponaTheme(Brightness brightness) {
  final light = brightness == Brightness.light;
  final scheme = light
      ? const ColorScheme(
          brightness: Brightness.light,
          primary: Alpona.leaf,
          onPrimary: Color(0xFFFFFFFF),
          primaryContainer: Color(0xFFD3E8D7),
          onPrimaryContainer: Color(0xFF0E2A16),
          secondary: Alpona.earth,
          onSecondary: Alpona.rice,
          secondaryContainer: Color(0xFFF6DDD3),
          onSecondaryContainer: Color(0xFF3B140A),
          tertiary: Color(0xFF8A5A00),
          onTertiary: Color(0xFFFFFFFF),
          error: Color(0xFFB3261E),
          onError: Color(0xFFFFFFFF),
          surface: Color(0xFFFAF5EC),
          onSurface: Alpona.soot,
          onSurfaceVariant: Color(0xFF5E4B40),
          surfaceContainerLowest: Color(0xFFFFFDF8),
          surfaceContainerLow: Color(0xFFF6EFE3),
          surfaceContainer: Color(0xFFF1E8DA),
          surfaceContainerHigh: Color(0xFFEBE1D1),
          surfaceContainerHighest: Color(0xFFE5DAC8),
          outline: Color(0xFF9C8878),
          outlineVariant: Color(0xFFE2D5C3),
        )
      : const ColorScheme(
          brightness: Brightness.dark,
          primary: Color(0xFF8CC79A),
          onPrimary: Color(0xFF0E2A16),
          primaryContainer: Color(0xFF1F4A2B),
          onPrimaryContainer: Color(0xFFD3E8D7),
          secondary: Color(0xFFE08A6F),
          onSecondary: Color(0xFF3B140A),
          secondaryContainer: Color(0xFF5C2414),
          onSecondaryContainer: Color(0xFFF6DDD3),
          tertiary: Alpona.turmeric,
          onTertiary: Color(0xFF2E1E00),
          error: Color(0xFFF2B8B5),
          onError: Color(0xFF601410),
          surface: Color(0xFF1C1310),
          onSurface: Color(0xFFF3EADC),
          onSurfaceVariant: Color(0xFFCDB9A8),
          surfaceContainerLowest: Color(0xFF160F0C),
          surfaceContainerLow: Color(0xFF251A15),
          surfaceContainer: Color(0xFF2A1E18),
          surfaceContainerHigh: Color(0xFF33251E),
          surfaceContainerHighest: Color(0xFF3D2D25),
          outline: Color(0xFF8F7A6B),
          outlineVariant: Color(0xFF3E2F26),
        );

  // One generous size for every row, ranked by weight, not by size.
  const rowSize = 16.0;
  final base = ThemeData(
    colorScheme: scheme,
    fontFamily: 'HindSiliguri',
  ).textTheme;
  final text = base.copyWith(
    displaySmall: base.displaySmall?.copyWith(
      fontSize: 38,
      fontWeight: FontWeight.w600,
      height: 1.2,
    ),
    titleSmall: base.titleSmall?.copyWith(
      fontSize: rowSize,
      fontWeight: FontWeight.w700,
      color: scheme.secondary,
    ),
    titleMedium: base.titleMedium?.copyWith(
      fontSize: rowSize,
      fontWeight: FontWeight.w500,
    ),
    bodyLarge: base.bodyLarge?.copyWith(fontSize: rowSize, height: 1.35),
    bodyMedium: base.bodyMedium?.copyWith(fontSize: rowSize, height: 1.35),
    labelLarge: base.labelLarge?.copyWith(
      fontSize: 15,
      fontWeight: FontWeight.w600,
    ),
  );

  return ThemeData(
    colorScheme: scheme,
    fontFamily: 'HindSiliguri',
    textTheme: text,
    scaffoldBackgroundColor: scheme.surface,
    listTileTheme: ListTileThemeData(
      titleTextStyle: text.titleMedium?.copyWith(color: scheme.onSurface),
      subtitleTextStyle: text.bodyMedium?.copyWith(
        color: scheme.onSurfaceVariant,
      ),
    ),
    cardTheme: CardThemeData(
      color: scheme.surfaceContainerLowest,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: scheme.outlineVariant),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        textStyle: text.labelLarge?.copyWith(fontSize: rowSize),
      ),
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: scheme.primary,
      selectionColor: scheme.primary.withValues(alpha: 0.25),
    ),
  );
}
