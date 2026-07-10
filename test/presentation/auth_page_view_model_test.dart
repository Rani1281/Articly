import 'package:articly/presentation/authentication/view_models/auth_page_model.dart';
import 'package:checks/checks.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:articly/data/services/auth_service.dart';
// Adjust the import path for AuthPageModel to match your project

// --- Mocks & Fakes ---

class MockAuthService extends Mock implements AuthService {}

class FakeCustomAuthException extends Fake implements CustomAuthException {
  @override
  final String displayMessage;

  @override
  final String? code;

  @override
  final String? errorMessage;

  FakeCustomAuthException(
    this.displayMessage, {
    this.code = 'test-code',
    this.errorMessage = 'Test error message',
  });
}

// --- Tests ---

void main() {
  group('AuthPageModel - authenticate', () {
    late MockAuthService mockService;
    late AuthPageModel model;

    const testEmail = 'test@example.com';
    const testPassword = 'Password123!';
    const testUsername = 'testuser';
    const genericError =
        'Something went wrong, please check your details or try again later';

    setUp(() {
      mockService = MockAuthService();
      model = AuthPageModel(service: mockService);
    });

    test(
      'Login succeeds: Calls service.login(), returns null, does not call register/updateUsername',
      () async {
        // Arrange
        when(() => mockService.login(any(), any())).thenAnswer((_) async {
          return null;
        });

        // Act
        final result = await model.authenticate(
          username: testUsername,
          email: testEmail,
          password: testPassword,
        );

        // Assert
        check(result).isNull();

        // Verify correct argument forwarding and that only login was called
        verify(() => mockService.login(testEmail, testPassword)).called(1);
        verifyNever(() => mockService.register(any(), any()));
        verifyNever(() => mockService.updateUsername(any()));
      },
    );

    test(
      'Registration succeeds: Calls service.register() and updateUsername(), returns null',
      () async {
        // Arrange
        model.toggleForm(); // Switch to registration mode
        when(() => mockService.register(any(), any())).thenAnswer((_) async {
          return null;
        });
        when(() => mockService.updateUsername(any())).thenAnswer((_) async {});

        // Act
        final result = await model.authenticate(
          username: testUsername,
          email: testEmail,
          password: testPassword,
        );

        // Assert
        check(result).isNull();
        verify(() => mockService.register(testEmail, testPassword)).called(1);
        verify(() => mockService.updateUsername(testUsername)).called(1);
      },
    );

    test(
      'Registration call order: register() is called before updateUsername()',
      () async {
        // Arrange
        model.toggleForm();
        when(() => mockService.register(any(), any())).thenAnswer((_) async {
          return null;
        });
        when(() => mockService.updateUsername(any())).thenAnswer((_) async {});

        // Act
        await model.authenticate(
          username: testUsername,
          email: testEmail,
          password: testPassword,
        );

        // Assert
        verifyInOrder([
          () => mockService.register(testEmail, testPassword),
          () => mockService.updateUsername(testUsername),
        ]);
      },
    );

    test(
      'Login throws CustomAuthException: Returns exception.displayMessage',
      () async {
        // Arrange
        const errorMessage = 'Invalid credentials';
        when(
          () => mockService.login(any(), any()),
        ).thenThrow(FakeCustomAuthException(errorMessage));

        // Act
        final result = await model.authenticate(
          username: testUsername,
          email: testEmail,
          password: testPassword,
        );

        // Assert
        check(result).equals(errorMessage);
      },
    );

    test(
      'Register throws CustomAuthException: Returns exception.displayMessage, does not call updateUsername()',
      () async {
        // Arrange
        model.toggleForm();
        const errorMessage = 'Email already in use';
        when(
          () => mockService.register(any(), any()),
        ).thenThrow(FakeCustomAuthException(errorMessage));

        // Act
        final result = await model.authenticate(
          username: testUsername,
          email: testEmail,
          password: testPassword,
        );

        // Assert
        check(result).equals(errorMessage);
        verify(() => mockService.register(testEmail, testPassword)).called(1);
        verifyNever(() => mockService.updateUsername(any()));
      },
    );

    test(
      'updateUsername() throws CustomAuthException: Returns exception.displayMessage',
      () async {
        // Arrange
        model.toggleForm();
        const errorMessage = 'Username taken';
        when(() => mockService.register(any(), any())).thenAnswer((_) async {
          return null;
        });
        when(
          () => mockService.updateUsername(any()),
        ).thenThrow(FakeCustomAuthException(errorMessage));

        // Act
        final result = await model.authenticate(
          username: testUsername,
          email: testEmail,
          password: testPassword,
        );

        // Assert
        check(result).equals(errorMessage);
      },
    );

    test(
      'Login throws an unexpected exception: Returns the generic error message',
      () async {
        // Arrange
        when(
          () => mockService.login(any(), any()),
        ).thenThrow(Exception('Unexpected failure'));

        // Act
        final result = await model.authenticate(
          username: testUsername,
          email: testEmail,
          password: testPassword,
        );

        // Assert
        check(result).equals(genericError);
      },
    );

    test(
      'Register throws an unexpected exception: Returns the generic error message',
      () async {
        // Arrange
        model.toggleForm();
        when(
          () => mockService.register(any(), any()),
        ).thenThrow(Exception('Unexpected failure'));

        // Act
        final result = await model.authenticate(
          username: testUsername,
          email: testEmail,
          password: testPassword,
        );

        // Assert
        check(result).equals(genericError);
      },
    );

    test(
      'updateUsername() throws an unexpected exception: Returns the generic error message',
      () async {
        // Arrange
        model.toggleForm();
        when(() => mockService.register(any(), any())).thenAnswer((_) async {
          return null;
        });
        when(
          () => mockService.updateUsername(any()),
        ).thenThrow(Exception('Unexpected failure'));

        // Act
        final result = await model.authenticate(
          username: testUsername,
          email: testEmail,
          password: testPassword,
        );

        // Assert
        check(result).equals(genericError);
      },
    );
  });
}
