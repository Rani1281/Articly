import 'package:articly/data/services/shared_preferences_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SharedPreferences prefs;
  late SharedPreferencesService service;

  setUpAll(() async {
    WidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    service = SharedPreferencesService(prefs: prefs);
  });

  group('Theme', () {
    test('setTheme sets the value for getTheme to read', () async {
      await prefs.clear();
      const value = 'dark';

      await service.setTheme(value);

      final result = service.getTheme();

      expect(result, value);
    });

    test('setOrderBy sets the value for getOrderBy to read', () async {
      await prefs.clear();
      const value = 'creationDate';

      await service.setOrderBy(value);

      final result = service.getOrderBy();

      expect(result, value);
    });

    test('setIsDescending sets the value for getTheme to read', () async {
      await prefs.clear();
      const value = true;

      await service.setIsDescending(value);

      final result = service.getIsDescending();

      expect(result, value);
    });
  });
}
