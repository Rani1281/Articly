
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:checks/checks.dart';

// Update these imports to match your project's actual path
import 'package:articly/presentation/authentication/widgets/auth_button.dart';
import 'package:articly/presentation/authentication/widgets/cooldown_widget.dart';

/// A handy extension to cleanly use standard Flutter Finders with `package:checks`
extension FinderChecks on Subject<Finder> {
  Subject<int> get matchCount =>
      has((f) => f.evaluate().length, 'matched widget count');

  void findsOneWidget() => matchCount.equals(1);
  void findsNothing() => matchCount.equals(0);
}

void main() {
  group('ResendEmailButton Widget Tests', () {
    const int testCooldown = 3;

    // Helper method to setup the testing environment (Arrange)
    Widget buildTestWidget({required VoidCallback onResend}) {
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: CooldownAuthButton(
              text: 'Resend email',
              onResend: onResend,
              cooldownSeconds: testCooldown,
            ),
          ),
        ),
      );
    }

    testWidgets('1. Initial rendering: the button should be clickable', (
      WidgetTester tester,
    ) async {
      // Arrange
      await tester.pumpWidget(buildTestWidget(onResend: () {}));

      final authButton = tester.widget<AuthButton>(find.byType(AuthButton));

      // Assert
      check(authButton.onPressed).isNotNull();
    });

    testWidgets('2. Lifecycle: Timer UI, disabling, layout bounds, and re-enabling', (
      WidgetTester tester,
    ) async {
      // --- ARRANGE ---
      int resendCallCount = 0; // Using a stub instead of a mock package
      await tester.pumpWidget(
        buildTestWidget(onResend: () => resendCallCount++),
      );

      final buttonFinder = find.byType(AuthButton);

      // If the button starts unclickable (once you fix the initial render requirement),
      // we must fast-forward the initial cooldown before we can click it to test the loop.
      if (tester.widget<AuthButton>(buttonFinder).onPressed == null) {
        await tester.pumpAndSettle();
      }

      // --- ACT (Clicking the active button) ---
      await tester.tap(buttonFinder);
      await tester.pump();

      // --- ASSERT (Cooldown starts, function triggered) ---
      check(resendCallCount).equals(1);

      AuthButton authButton = tester.widget<AuthButton>(buttonFinder);
      check(
        authButton.onPressed,
      ).isNull(); // Disables again for the same amount of time

      // --- ASSERT (Send function isn't called when disabled) ---
      await tester.tap(buttonFinder);
      await tester.pump();
      check(resendCallCount).equals(1); // Call count remains unchanged

      // --- ASSERT (Correct UI elements during countdown) ---
      final timerTextFinder = find.text('Try again in $testCooldown seconds');
      check(timerTextFinder).findsOneWidget();
      check(find.text('Resend email')).findsOneWidget();

      // --- ASSERT (Text is shown below the button during countdown) ---
      final buttonRect = tester.getRect(buttonFinder);
      final timerTextRect = tester.getRect(timerTextFinder);
      // The `top` Y-coordinate of the text should be strictly greater than the `bottom` Y-coordinate of the button
      check(timerTextRect.top).isGreaterThan(buttonRect.bottom);

      // --- ACT (Wait for the appropriate amount of time to pass) ---
      // We wait exactly `testCooldown` seconds
      await tester.pump(const Duration(seconds: testCooldown));

      // --- ASSERT (Clickable again, correct UI) ---
      authButton = tester.widget<AuthButton>(buttonFinder);
      check(authButton.onPressed).isNotNull(); // Clickable again
      check(
        find.textContaining('Try again in'),
      ).findsNothing(); // Timer is gone

      // --- ACT & ASSERT (After the second click, it disables again) ---
      await tester.tap(buttonFinder);
      await tester.pump();

      check(resendCallCount).equals(2); // Function is called successfully

      authButton = tester.widget<AuthButton>(buttonFinder);
      check(authButton.onPressed).isNull(); // Disabled again immediately
      check(find.text('Try again in $testCooldown seconds')).findsOneWidget();

      // Always allow the remaining timers to safely flush out to prevent memory/timer leaks in the test runner
      await tester.pumpAndSettle();
    });
  });
}
