import 'package:articly/theme/app_bar_theme.dart';
import 'package:flutter/material.dart';

class AppTheme {
  static Color seedColor = Colors.blue;
  // static const Color darkSeedColor = Color.fromARGB(255, 0, 0, 0);

  static ColorScheme get lightScheme =>
      ColorScheme.fromSeed(seedColor: seedColor, brightness: Brightness.light);

  static ColorScheme get darkScheme =>
      ColorScheme.fromSeed(seedColor: seedColor, brightness: Brightness.dark);

  static ThemeData light = ThemeData(
    brightness: Brightness.light,
    // scaffoldBackgroundColor: AppColors.scaffoldBackgroundColor,
    // scaffoldBackgroundColor: Color(0xFFFAF7F2),
    appBarTheme: appBarThemeLight,
    useMaterial3: true,
    // colorScheme: ColorScheme.fromSeed(
    //   seedColor: Color(0xFF1A6B6B),
    //   brightness: Brightness.light,
    // ).copyWith(secondary: Color(0xFFE8A020), onSecondary: Color(0xFF1C1A17)),
    colorScheme: lightScheme,
  );

  static ThemeData dark = ThemeData(
    brightness: Brightness.dark,
    // scaffoldBackgroundColor: Color(0xFF12100E),
    appBarTheme: appBarThemeDark,
    useMaterial3: true,
    // colorScheme: ColorScheme.fromSeed(
    //   seedColor: Color(0xFF1A6B6B),
    //   brightness: Brightness.dark,
    // ).copyWith(secondary: Color(0xFFFFBD4F), onSecondary: Color(0xFF2A1F00)),
    colorScheme: darkScheme,
  );
}
