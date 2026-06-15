import 'package:articly/theme/app_bar_theme.dart';
import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData light = ThemeData(
    brightness: Brightness.light,
    // scaffoldBackgroundColor: AppColors.scaffoldBackgroundColor,
    scaffoldBackgroundColor: Color(0xFFFAF7F2), // same as "surface"
    appBarTheme: appBarTheme,
    useMaterial3: true,
    colorScheme: lightColorScheme,
  );

  static ThemeData dark = ThemeData(
    brightness: Brightness.dark,
    // scaffoldBackgroundColor: AppColors.scaffoldBackgroundColor,
    scaffoldBackgroundColor: Color(0xFF12100E),
    appBarTheme: appBarTheme,
    useMaterial3: true,
    colorScheme: darkColorScheme,
  );

  static const ColorScheme lightColorScheme = ColorScheme(
    brightness: Brightness.light,

    // Primary — Deep Teal (interactive, links, key UI elements)
    primary: Color(0xFF1A6B6B),
    onPrimary: Color(0xFFFAF7F2),
    primaryContainer: Color(0xFFB2DFDF),
    onPrimaryContainer: Color(0xFF002020),

    // Secondary — Amber / Golden Honey (accents, CTAs, reminders)
    secondary: Color(0xFFE8A020),
    onSecondary: Color(0xFF1C1A17),
    secondaryContainer: Color(0xFFFFE0A0),
    onSecondaryContainer: Color(0xFF2A1F00),

    // Tertiary — Terracotta (badges, tags, fun elements)
    tertiary: Color(0xFFC05C3A),
    onTertiary: Color(0xFFFAF7F2),
    tertiaryContainer: Color(0xFFFFD5C2),
    onTertiaryContainer: Color(0xFF3A1000),

    // Error
    error: Color(0xFFB3261E),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFF9DEDC),
    onErrorContainer: Color(0xFF410E0B),

    // Surfaces & Background — Warm parchment tones
    // background: Color(0xFFFAF7F2),
    // onBackground: Color(0xFF1C1A17),
    surface: Color(0xFFFAF7F2),
    onSurface: Color(0xFF1C1A17),

    // surfaceVariant: Color(0xFFF0EBE1),
    onSurfaceVariant: Color(0xFF7A7267),

    // Outlines
    outline: Color(0xFFB5AFA6),
    outlineVariant: Color(0xFFD9D3CA),

    // Misc
    shadow: Color(0xFF1C1A17),
    scrim: Color(0xFF000000),
    inverseSurface: Color(0xFF1E1B18),
    onInverseSurface: Color(0xFFEDE8DF),
    inversePrimary: Color(0xFF80CBCB),
  );

  static const ColorScheme darkColorScheme = ColorScheme(
    brightness: Brightness.dark,

    // Primary — Lighter teal for dark backgrounds
    primary: Color(0xFF80CBCB),
    onPrimary: Color(0xFF003737),
    primaryContainer: Color(0xFF004F4F),
    onPrimaryContainer: Color(0xFFB2DFDF),

    // Secondary — Amber, slightly softened for dark
    secondary: Color(0xFFFFBD4F),
    onSecondary: Color(0xFF2A1F00),
    secondaryContainer: Color(0xFF3D2E00),
    onSecondaryContainer: Color(0xFFFFE0A0),

    // Tertiary — Terracotta, lightened for dark
    tertiary: Color(0xFFFFAB8A),
    onTertiary: Color(0xFF3A1000),
    tertiaryContainer: Color(0xFF5C2010),
    onTertiaryContainer: Color(0xFFFFD5C2),

    // Error
    error: Color(0xFFF2B8B5),
    onError: Color(0xFF601410),
    errorContainer: Color(0xFF8C1D18),
    onErrorContainer: Color(0xFFF9DEDC),

    // Surfaces & Background — Warm near-black
    // background: Color(0xFF12100E),
    // onBackground: Color(0xFFEDE8DF),
    surface: Color(0xFF12100E),
    onSurface: Color(0xFFEDE8DF),

    // surfaceVariant: Color(0xFF1E1B18),
    onSurfaceVariant: Color(0xFFB5AFA6),

    // Outlines
    outline: Color(0xFF7A7267),
    outlineVariant: Color(0xFF3A3530),

    // Misc
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    inverseSurface: Color(0xFFEDE8DF),
    onInverseSurface: Color(0xFF1C1A17),
    inversePrimary: Color(0xFF1A6B6B),
  );
}
