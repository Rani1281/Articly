import 'package:articly/main.dart';
import 'package:articly/domain/providers/saved_items_provider.dart';
import 'package:articly/theme/theme_model.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setupFirebaseCoreMocks();

  setUpAll(() async {
    await Firebase.initializeApp();
  });

  testWidgets('MyApp shows the auth page', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ThemeModel>(create: (_) => ThemeModel()),
          ChangeNotifierProvider<SavedItemsProvider>(create: (_) => SavedItemsProvider()),
        ],
        child: const MyApp(),
      ),
    );

    // Wait for the auth stream to emit and settle on AuthPage
    await tester.pumpAndSettle();

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Login'), findsWidgets);
  });
}
