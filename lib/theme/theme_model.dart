import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeModel extends ChangeNotifier {
  ThemeModel({required this.prefs}) {
    load();
  }

  final SharedPreferences prefs;

  static const _themeKey = 'theme_mode';

  ThemeMode _themeMode = ThemeMode.system;

  final log = Logger('ThemeModel');

  ThemeMode get themeMode => _themeMode;

  void load() {
    final value = prefs.getString(_themeKey);

    if (value == null) {
      log.info(
        'No value inside SharedPreferences field "theme_mode", so setting the theme mode to system default',
      );
      _themeMode = ThemeMode.system;
      return;
    }

    _themeMode = ThemeMode.values.firstWhere(
      (mode) => mode.name == value,
      orElse: () => ThemeMode.system,
    );
    log.info('Theme mode assigned: $_themeMode');
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    await prefs.setString(_themeKey, mode.name);

    notifyListeners();
  }

  // Uses "context" in case of the user being in "system" mode
  bool isDark(BuildContext context) {
    switch (_themeMode) {
      case ThemeMode.dark:
        return true;

      case ThemeMode.light:
        return false;

      case ThemeMode.system:
        return MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    }
  }
}
