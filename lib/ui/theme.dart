import 'package:flutter/material.dart';

import 'brand.dart';

/// The app theme: clear sky blue on airy white, coral for now, and Noto
/// Sans Bengali for Bangla and Latin alike.
ThemeData skyTheme(Brightness brightness) {
  final light = brightness == Brightness.light;
  final scheme = light
      ? const ColorScheme(
          brightness: Brightness.light,
          primary: Sky.blue,
          onPrimary: Color(0xFFFFFFFF),
          primaryContainer: Color(0xFFD3E4FA),
          onPrimaryContainer: Color(0xFF0B2A57),
          secondary: Color(0xFF2B5A9E),
          onSecondary: Color(0xFFFFFFFF),
          secondaryContainer: Color(0xFFDCE8F8),
          onSecondaryContainer: Color(0xFF0E2A52),
          tertiary: Color(0xFFB4431F),
          onTertiary: Color(0xFFFFFFFF),
          error: Color(0xFFB3261E),
          onError: Color(0xFFFFFFFF),
          surface: Sky.ground,
          onSurface: Sky.ink,
          onSurfaceVariant: Color(0xFF4A5A73),
          surfaceContainerLowest: Color(0xFFFFFFFF),
          surfaceContainerLow: Color(0xFFEFF5FD),
          surfaceContainer: Color(0xFFE9F0F9),
          surfaceContainerHigh: Color(0xFFE3EBF6),
          surfaceContainerHighest: Color(0xFFD9E3F1),
          outline: Color(0xFF7B8BA4),
          outlineVariant: Color(0xFFDCE5F1),
        )
      : const ColorScheme(
          brightness: Brightness.dark,
          primary: Sky.blueNight,
          onPrimary: Color(0xFF08264D),
          primaryContainer: Color(0xFF1C3D6B),
          onPrimaryContainer: Color(0xFFD6E6FC),
          secondary: Color(0xFFA3BEE6),
          onSecondary: Color(0xFF0E2A52),
          secondaryContainer: Color(0xFF203A60),
          onSecondaryContainer: Color(0xFFDCE8F8),
          tertiary: Sky.coral,
          onTertiary: Color(0xFF3A1004),
          error: Color(0xFFF2B8B5),
          onError: Color(0xFF601410),
          surface: Sky.groundNight,
          onSurface: Sky.inkNight,
          onSurfaceVariant: Color(0xFFA9B7CC),
          surfaceContainerLowest: Color(0xFF0B121D),
          surfaceContainerLow: Color(0xFF152033),
          surfaceContainer: Color(0xFF19263B),
          surfaceContainerHigh: Color(0xFF1F2D44),
          surfaceContainerHighest: Color(0xFF27364F),
          outline: Color(0xFF7E8DA6),
          outlineVariant: Color(0xFF2A3850),
        );

  // One generous size for every row, ranked by weight, not by size.
  const rowSize = 16.0;
  final base = ThemeData(
    colorScheme: scheme,
    fontFamily: 'NotoSansBengali',
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
    fontFamily: 'NotoSansBengali',
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
