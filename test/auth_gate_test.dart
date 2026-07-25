import 'dart:async';
import 'package:checks/context.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:checks/checks.dart';
import 'package:provider/provider.dart';

// TODO: Replace these with your actual application imports
import 'package:articly/main.dart';
import 'package:articly/data/services/auth_service.dart';
import 'package:articly/presentation/authentication/widgets/auth_page.dart';
import 'package:articly/presentation/website_displaying/widgets/home_page.dart';
import 'package:articly/data/models/saved_item.dart';
import 'package:articly/theme/theme_model.dart';
import 'package:articly/domain/providers/saved_items_provider.dart';
import 'package:articly/utils/command.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

// --- 1. Setup Custom Extension for package:checks ---
extension FinderChecks on Subject<Finder> {
  void findsOneWidget() {
    context.expect(() => const ['finds exactly one widget'], (Finder actual) {
      final count = actual.evaluate().length;
      if (count == 1) return null;
      return Rejection(
        actual: ['$count widgets found'],
        which: ['Expected exactly 1 widget matching: ${actual.description}'],
      );
    });
  }
}

// --- 2. Create Fakes ---

// A minimal SavedItemsProvider fake to avoid real Firestore calls in widget tests.
class _FakeSavedItemsProvider extends ChangeNotifier
    implements SavedItemsProvider {
  Command _loadCommand = Command();
  Command _saveCommand = Command();
  Command _editCommand = Command();
  Command _deleteCommand = Command();
  Map<String, SavedItem> _items = {};

  @override
  Command get loadCommand => _loadCommand;
  @override
  Command get saveCommand => _saveCommand;
  @override
  Command get editCommand => _editCommand;
  @override
  Command get deleteCommand => _deleteCommand;
  @override
  Map<String, SavedItem> get items => _items;

  @override
  Future<String?> load({bool notify = false}) async {
    _loadCommand = Command()
      ..start()
      ..finish(null);
    _items = {};
    notifyListeners();
    return null;
  }

  @override
  Future<String?> add(SavedItem item) async {
    _saveCommand = Command()
      ..start()
      ..finish(null);
    _items['test-id'] = item;
    notifyListeners();
    return null;
  }

  @override
  Future<String?> edit(SavedItem item) async {
    _editCommand = Command()
      ..start()
      ..finish(null);
    notifyListeners();
    return null;
  }

  @override
  Future<String?> delete(String id) async {
    _deleteCommand = Command()
      ..start()
      ..finish(null);
    notifyListeners();
    return null;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

/// Fake representation of the FirebaseAuth User.
/// By implementing `User`, Dart accepts this anywhere a FirebaseAuth User is required.
class FakeUser extends Fake implements User {
  FakeUser({required this.emailVerified});

  // We override the exact property that AuthGate needs to check
  @override
  final bool emailVerified;
}

/// Fake AuthService to cleanly control the stream of authentication changes.
class FakeAuthService extends Fake implements AuthService {
  // Must use `User?` here to match `AuthService.authChanges` exactly
  final StreamController<User?> _controller =
      StreamController<User?>.broadcast();

  @override
  Stream<User?> get authChanges => _controller.stream;

  void emitUser(User? user) {
    _controller.add(user);
  }

  void emitError(Object error) {
    _controller.addError(error);
  }

  void close() {
    _controller.close();
  }
}

// --- 3. Widget Tests ---
void main() {
  late FakeAuthService fakeAuthService;
  late SharedPreferences prefs;

  setUp(() async {
    WidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    fakeAuthService = FakeAuthService();
    prefs = await SharedPreferences.getInstance();
  });

  tearDown(() {
    fakeAuthService.close();
  });

  Widget createWidgetUnderTest() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeModel>(
          create: (_) => ThemeModel(prefs: prefs),
        ),
        ChangeNotifierProvider<SavedItemsProvider>(
          create: (_) => _FakeSavedItemsProvider(),
        ),
      ],
      child: MaterialApp(home: AuthGate(authService: fakeAuthService)),
    );
  }

  group('AuthGate Widget Tests', () {
    testWidgets('shows loading indicator when waiting for auth changes', (
      tester,
    ) async {
      // Arrange & Act
      // Pump the widget but don't emit any events to the stream, keeping it in ConnectionState.waiting
      await tester.pumpWidget(createWidgetUnderTest());

      // Assert
      check(find.byType(CircularProgressIndicator)).findsOneWidget();
    });

    testWidgets(
      'shows ErrorPage with correct text and no overflow when stream has error',
      (tester) async {
        // Arrange: Set an aggressively small screen size to test for text overflow
        tester.view.physicalSize = const Size(300, 400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(createWidgetUnderTest());

        // Act: Emit an error state
        fakeAuthService.emitError(Exception('Test Exception'));
        await tester
            .pumpAndSettle(); // Forces layout, catching any RenderFlex overflows

        // Assert
        final expectedText =
            'An error occurred. Please try entering the app later. If this error continues, try to ${kIsWeb ? 'clear the site data off your browser' : 'clear the app data off your device'}.';
        check(find.text(expectedText)).findsOneWidget();
      },
    );

    testWidgets('shows AuthPage when stream emits no user data (null)', (
      tester,
    ) async {
      // Arrange
      await tester.pumpWidget(createWidgetUnderTest());

      // Act: Emit null to simulate no user authenticated
      fakeAuthService.emitUser(null);
      await tester.pumpAndSettle();

      // Assert
      check(find.byType(AuthPage)).findsOneWidget();
    });

    // testWidgets('shows VerifyEmailScreen when user email is not verified', (
    //   tester,
    // ) async {
    //   // Arrange
    //   await tester.pumpWidget(createWidgetUnderTest());

    //   // Act: Emit a user with an unverified email
    //   fakeAuthService.emitUser(FakeUser(emailVerified: false));
    //   await tester.pumpAndSettle();

    //   // Assert
    //   check(find.text('Verify email')).findsOneWidget();
    // });

    testWidgets('shows HomePage when user email is verified', (tester) async {
      // Arrange
      await tester.pumpWidget(createWidgetUnderTest());

      // Act: Emit an authenticated, verified user
      fakeAuthService.emitUser(FakeUser(emailVerified: true));
      await tester.pumpAndSettle();

      // Assert
      check(find.byType(HomePage)).findsOneWidget();
    });
  });
}
