// import 'package:articly/main.dart';
// import 'package:articly/domain/providers/saved_items_provider.dart';
// import 'package:articly/theme/theme_model.dart';
// import 'package:firebase_core_platform_interface/test.dart';
// import 'package:flutter_test/flutter_test.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:provider/provider.dart';
// import 'package:shared_preferences/shared_preferences.dart';
//
// void main() {
//   TestWidgetsFlutterBinding.ensureInitialized();
//   setupFirebaseCoreMocks();
//
//   setUpAll(() async {
//     await Firebase.initializeApp();
//   });
//
//   testWidgets('MyApp shows the auth page', (WidgetTester tester) async {
//     final prefs = await SharedPreferences.getInstance();
//     await tester.pumpWidget(
//       MultiProvider(
//         providers: [
//           ChangeNotifierProvider<ThemeModel>(
//             create: (_) => ThemeModel(prefs: prefs),
//           ),
//           ChangeNotifierProvider<SavedItemsProvider>(
//             create: (_) => SavedItemsProvider(),
//           ),
//         ],
//         child: const MyApp(),
//       ),
//     );
//
//     // Wait for the auth stream to emit and settle on AuthPage
//     await tester.pumpAndSettle();
//
//     expect(find.text('Welcome back'), findsOneWidget);
//     expect(find.text('Login'), findsWidgets);
//   });
// }
