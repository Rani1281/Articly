import 'package:articly/theme/theme_model.dart';
import 'package:checks/checks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  // Sets up a clean slate for SharedPreferences memory mock before every test
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  group('ThemeModel Tests', () {
    test(
      'Constructor calls load when built and sets the value of the theme mode',
      () async {
        // Arrange
        // Inject a 'dark' value into the mock preferences.
        SharedPreferences.setMockInitialValues({'theme_mode': 'dark'});
        final prefs = await SharedPreferences.getInstance();

        // Act
        // Passing no future implicitly tests the `SharedPreferences.getInstance()` fallback.
        final model = ThemeModel(prefs: prefs);

        // Assert
        // 1. Initial state should be system
        check(model.themeMode).equals(ThemeMode.dark);

        // Act
        model.load();

        // Assert
        // 2. If it successfully reads 'dark', we know the default prefs future successfully hooked up to getInstance()
        check(model.themeMode).equals(ThemeMode.dark);
      },
    );

    test(
      'load sets the correct ThemeMode based on SharedPreferences string',
      () async {
        // Arrange
        final prefs = await SharedPreferences.getInstance();
        final model = ThemeModel(prefs: prefs);

        // Act & Assert (Light)
        await prefs.setString('theme_mode', 'light');
        model.load();
        check(model.themeMode).equals(ThemeMode.light);

        // Act & Assert (Dark)
        await prefs.setString('theme_mode', 'dark');
        model.load();
        check(model.themeMode).equals(ThemeMode.dark);

        // Act & Assert (System)
        await prefs.setString('theme_mode', 'system');
        model.load();
        check(model.themeMode).equals(ThemeMode.system);
      },
    );

    test(
      'load sets ThemeMode to system if no value exists in SharedPreferences',
      () async {
        // Arrange
        final prefs = await SharedPreferences.getInstance();
        final model = ThemeModel(prefs: prefs);

        // Manually set to dark first to ensure load() actually overwrites it
        await model.setThemeMode(ThemeMode.dark);
        await prefs.remove('theme_mode'); // Clear out value

        // Act
        model.load();

        // Assert
        check(model.themeMode).equals(ThemeMode.system);
      },
    );

    test(
      'setThemeMode updates state, SharedPreferences, and notifies listeners',
      () async {
        // Arrange
        final prefs = await SharedPreferences.getInstance();
        final model = ThemeModel(prefs: prefs);

        bool listenerCalled = false;
        model.addListener(() {
          listenerCalled = true;
        });

        // Act
        await model.setThemeMode(ThemeMode.dark);

        // Assert
        check(model.themeMode).equals(ThemeMode.dark);
        check(prefs.getString('theme_mode')).equals('dark');
        check(listenerCalled).isTrue();
      },
    );

    // We use testWidgets to easily provide a real BuildContext without needing Mocktail/Mockito
    testWidgets('isDark returns true when theme is dark, false when light', (
      tester,
    ) async {
      final prefs = await SharedPreferences.getInstance();
      // Arrange
      final model = ThemeModel(prefs: prefs);
      await tester.pumpWidget(Builder(builder: (context) => const SizedBox()));
      final BuildContext context = tester.element(find.byType(SizedBox));

      // Act & Assert (Dark mode)
      await model.setThemeMode(ThemeMode.dark);
      check(model.isDark(context)).isTrue();

      // Act & Assert (Light mode)
      await model.setThemeMode(ThemeMode.light);
      check(model.isDark(context)).isFalse();
    });

    testWidgets(
      'isDark returns correct boolean based on MediaQuery when theme is system',
      (tester) async {
        final prefs = await SharedPreferences.getInstance();
        // Arrange
        final model = ThemeModel(prefs: prefs);
        await model.setThemeMode(ThemeMode.system);

        // Act & Assert (System detects Dark platform brightness)
        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(platformBrightness: Brightness.dark),
            child: Builder(builder: (context) => const SizedBox()),
          ),
        );
        var context = tester.element(find.byType(SizedBox));
        check(model.isDark(context)).isTrue();

        // Act & Assert (System detects Light platform brightness)
        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(platformBrightness: Brightness.light),
            child: Builder(builder: (context) => const SizedBox()),
          ),
        );
        context = tester.element(find.byType(SizedBox));
        check(model.isDark(context)).isFalse();
      },
    );
  });
}
