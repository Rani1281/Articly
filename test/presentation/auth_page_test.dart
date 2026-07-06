import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

// TODO: Adjust the import paths according to your project structure
import 'package:articly/presentation/authentication/widgets/auth_page.dart';
import 'package:articly/presentation/authentication/view_models/auth_page_model.dart';
import 'package:articly/presentation/authentication/widgets/forgot_password_page.dart';
import 'package:articly/theme/theme_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 1. Create a Mock class for the ViewModel
class MockAuthPageModel extends Mock implements AuthPageModel {}

void main() {
  late MockAuthPageModel mockViewModel;
  late SharedPreferences prefs;

  // Register a fallback value for VoidCallback (required by mocktail for Listenable)
  setUpAll(() {
    registerFallbackValue(() {});
  });

  setUp(() async {
    mockViewModel = MockAuthPageModel();
    prefs = await SharedPreferences.getInstance();

    // Stub Listenable methods required by ListenableBuilder
    when(() => mockViewModel.addListener(any())).thenAnswer((_) {});
    when(() => mockViewModel.removeListener(any())).thenAnswer((_) {});

    // Provide default stubs to ensure safe rendering for initial states
    when(() => mockViewModel.isLogin).thenReturn(true);
    when(() => mockViewModel.isPasswordVisible).thenReturn(false);
    when(() => mockViewModel.isConfirmPasswordVisible).thenReturn(false);
    when(() => mockViewModel.error).thenReturn(null);
    when(() => mockViewModel.isRunning).thenReturn(false);
    when(() => mockViewModel.isRunningGoogle).thenReturn(false);
  });

  /// Helper function to wrap the target widget in a MaterialApp
  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: ChangeNotifierProvider<ThemeModel>(
        create: (_) => ThemeModel(prefs: prefs),
        child: AuthPage(viewModel: mockViewModel),
      ),
    );
  }

  group('AuthPage Widget Tests', () {
    // ----------------------------------------------------------------------
    // RENDERING
    // ----------------------------------------------------------------------

    testWidgets('Login mode renders correctly', (tester) async {
      // Arrange
      when(() => mockViewModel.isLogin).thenReturn(true);

      // Act
      await tester.pumpWidget(createWidgetUnderTest());

      // Assert
      expect(find.text('Welcome back'), findsOneWidget);
      // "Login" text shows in the AppBar and the Action Button
      expect(find.text('Login'), findsNWidgets(2));
      expect(find.text('Don\'t have an account?'), findsOneWidget);
      expect(find.text('Register'), findsOneWidget); // Toggle button

      expect(find.byKey(const Key('emailField')), findsOneWidget);
      expect(find.byKey(const Key('passwordField')), findsOneWidget);
      expect(find.byKey(const ValueKey('GoogleSignInButton')), findsOneWidget);

      // Verify non-login fields are absent
      expect(find.byKey(const Key('usernameField')), findsNothing);
      expect(find.byKey(const Key('confirmPasswordField')), findsNothing);
    });

    testWidgets('Register mode renders correctly', (tester) async {
      // Arrange
      when(() => mockViewModel.isLogin).thenReturn(false);

      // Act
      await tester.pumpWidget(createWidgetUnderTest());

      // Assert
      expect(find.text('Create your account'), findsOneWidget);
      // "Register" shows in the AppBar
      expect(find.text('Register'), findsOneWidget);
      expect(find.text('Already have an account?'), findsOneWidget);
      expect(find.text('Login'), findsOneWidget); // Toggle button

      expect(find.byKey(const Key('usernameField')), findsOneWidget);
      expect(find.byKey(const Key('emailField')), findsOneWidget);
      expect(find.byKey(const Key('passwordField')), findsOneWidget);
      expect(find.byKey(const Key('confirmPasswordField')), findsOneWidget);
      expect(find.byKey(const Key('actionButton')), findsOneWidget);

      // Forgot password should not exist in register mode
      expect(find.text('Forgot password?'), findsNothing);
    });

    // ----------------------------------------------------------------------
    // TOGGLES & VISIBILITY
    // ----------------------------------------------------------------------

    testWidgets('Toggle Login → Register calls ViewModel', (tester) async {
      // Arrange
      when(() => mockViewModel.isLogin).thenReturn(true);
      when(() => mockViewModel.toggleForm()).thenReturn(null);

      // Act
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.tap(find.text('Register'));
      await tester.pump();

      // Assert
      verify(() => mockViewModel.toggleForm()).called(1);
    });

    testWidgets('Toggle Register → Login calls ViewModel', (tester) async {
      // Arrange
      when(() => mockViewModel.isLogin).thenReturn(false);
      when(() => mockViewModel.toggleForm()).thenReturn(null);

      // Act
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.tap(find.text('Login'));
      await tester.pump();

      // Assert
      verify(() => mockViewModel.toggleForm()).called(1);
    });

    testWidgets('Password visibility toggle calls ViewModel', (tester) async {
      // Arrange
      when(() => mockViewModel.isLogin).thenReturn(true);
      when(() => mockViewModel.togglePasswordVisibility()).thenReturn(null);

      // Act
      await tester.pumpWidget(createWidgetUnderTest());
      final passwordField = find.byKey(const Key('passwordField'));
      final iconButton = find.descendant(
        of: passwordField,
        matching: find.byType(IconButton),
      );

      await tester.tap(iconButton);
      await tester.pump();

      // Assert
      verify(() => mockViewModel.togglePasswordVisibility()).called(1);
    });

    testWidgets('Confirm password visibility toggle calls ViewModel', (
      testers,
    ) async {
      // Arrange
      when(() => mockViewModel.isLogin).thenReturn(false);
      when(
        () => mockViewModel.toggleConfirmPasswordVisibility(),
      ).thenReturn(null);

      await testers.pumpWidget(createWidgetUnderTest());
      // Pump to ensure Register mode is shown with the confirm password field
      when(() => mockViewModel.isLogin).thenReturn(false);
      await testers.pump();

      final confirmField = find.byKey(const Key('confirmPasswordField'));
      expect(confirmField, findsOneWidget);
      final iconButton = find.descendant(
        of: confirmField,
        matching: find.byType(IconButton),
      );

      await testers.tap(iconButton);
      await testers.pump();

      // Assert
      verify(() => mockViewModel.toggleConfirmPasswordVisibility()).called(1);
    });

    // ----------------------------------------------------------------------
    // SUBMISSIONS & NAVIGATION
    // ----------------------------------------------------------------------

    testWidgets(
      'Submit button calls ViewModel with correct values (Register Mode)',
      (tester) async {
        // Arrange
        when(() => mockViewModel.isLogin).thenReturn(false);
        when(
          () => mockViewModel.submit(
            username: any(named: 'username'),
            email: any(named: 'email'),
            password: any(named: 'password'),
            confirmPassword: any(named: 'confirmPassword'),
          ),
        ).thenAnswer((_) async {});

        // Act
        await tester.pumpWidget(createWidgetUnderTest());

        await tester.enterText(
          find.byKey(const Key('usernameField')),
          'johndoe',
        );
        await tester.enterText(
          find.byKey(const Key('emailField')),
          'test@test.com',
        );
        await tester.enterText(
          find.byKey(const Key('passwordField')),
          'password123',
        );
        await tester.enterText(
          find.byKey(const Key('confirmPasswordField')),
          'password123',
        );

        await tester.tap(find.byKey(const Key('actionButton')));
        await tester.pump();

        // Assert
        verify(
          () => mockViewModel.submit(
            username: 'johndoe',
            email: 'test@test.com',
            password: 'password123',
            confirmPassword: 'password123',
          ),
        ).called(1);
      },
    );

    testWidgets('Google button calls ViewModel', (tester) async {
      // Arrange
      when(() => mockViewModel.isLogin).thenReturn(true);
      when(() => mockViewModel.continueWithGoogle()).thenAnswer((_) async {});

      // Act
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.tap(find.byKey(const ValueKey('GoogleSignInButton')));
      await tester.pump();

      // Assert
      verify(() => mockViewModel.continueWithGoogle()).called(1);
    });

    // ----------------------------------------------------------------------
    // STATES (Loading & Errors)
    // ----------------------------------------------------------------------

    testWidgets('Error message displayed when error exists', (tester) async {
      // Arrange
      when(() => mockViewModel.isLogin).thenReturn(true);
      when(
        () => mockViewModel.error,
      ).thenReturn('Invalid credentials. Please try again.');

      // Act
      await tester.pumpWidget(createWidgetUnderTest());

      // Assert
      expect(
        find.text('Invalid credentials. Please try again.'),
        findsOneWidget,
      );
    });

    testWidgets('Login loading indicator shown', (tester) async {
      // Arrange
      when(() => mockViewModel.isLogin).thenReturn(true);
      when(() => mockViewModel.isRunning).thenReturn(true);

      // Act
      await tester.pumpWidget(createWidgetUnderTest());

      // Assert
      final actionButton = find.byKey(const Key('actionButton'));

      // The button text 'Login' is replaced with a CircularProgressIndicator
      expect(
        find.descendant(
          of: actionButton,
          matching: find.byType(CircularProgressIndicator),
        ),
        findsOneWidget,
      );
    });

    testWidgets('Google loading indicator shown', (tester) async {
      // Arrange
      when(() => mockViewModel.isLogin).thenReturn(true);
      when(() => mockViewModel.isRunningGoogle).thenReturn(true);

      // Act
      await tester.pumpWidget(createWidgetUnderTest());

      // Assert
      final googleButton = find.byKey(const ValueKey('GoogleSignInButton'));

      expect(
        find.descendant(
          of: googleButton,
          matching: find.byType(CircularProgressIndicator),
        ),
        findsOneWidget,
      );
      // Ensure the text hides while loading
      expect(find.text('Continue with Google'), findsNothing);
    });
  });
}
