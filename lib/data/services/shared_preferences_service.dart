import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesService {
  SharedPreferencesService({required this.prefs});

  final SharedPreferences prefs;

  static const _themeKey = 'theme_mode';
  static const _orderByKey = 'orderBy';
  static const _isDescendingKey = 'descending';
  static const _filterKey = 'filter';

  String? getTheme() {
    return prefs.getString(_themeKey);
  }

  Future<bool?> setTheme(String value) async {
    return await prefs.setString(_themeKey, value);
  }

  String? getOrderBy() {
    return prefs.getString(_orderByKey);
  }

  Future<bool?> setOrderBy(String value) async {
    return await prefs.setString(_orderByKey, value);
  }

  bool? getIsDescending() {
    return prefs.getBool(_isDescendingKey);
  }

  Future<bool?> setIsDescending(bool value) async {
    return await prefs.setBool(_isDescendingKey, value);
  }

  String? getFilter() {
    return prefs.getString(_filterKey);
  }

  Future<bool?> setFilter(String value) async {
    return await prefs.setString(_filterKey, value);
  }
}
