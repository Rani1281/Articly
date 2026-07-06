import 'package:test/test.dart';
import 'package:checks/checks.dart';
import 'package:mocktail/mocktail.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:articly/data/services/auth_service.dart';

// Import your service here:
// import 'package:articly/services/auth_service.dart';

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockGoogleSignIn extends Mock implements GoogleSignIn {}

class MockUser extends Mock implements User {}

class MockUserCredential extends Mock implements UserCredential {}

class MockGoogleSignInAccount extends Mock implements GoogleSignInAccount {}

class MockGoogleSignInAuthentication extends Mock
    implements GoogleSignInAuthentication {}

class FakeAuthCredential extends Fake implements AuthCredential {}

void main() {
  late AuthService authService;
  late MockFirebaseAuth mockAuth;
  late MockGoogleSignIn mockGoogleSignIn;
  late MockUser mockUser;
  late MockUserCredential mockUserCredential;

  setUpAll(() {
    // Required by mocktail to use `any()` with AuthCredential
    registerFallbackValue(FakeAuthCredential());
  });

  setUp(() {
    mockAuth = MockFirebaseAuth();
    mockGoogleSignIn = MockGoogleSignIn();
    mockUser = MockUser();
    mockUserCredential = MockUserCredential();

    authService = AuthService(auth: mockAuth, googleSignIn: mockGoogleSignIn);
  });

  group('register', () {
    const testEmail = 'test@example.com';
    const testPassword = 'Password123!';

    test('Returns User on successful registration', () async {
      // Arrange
      when(() => mockUserCredential.user).thenReturn(mockUser);
      when(
        () => mockAuth.createUserWithEmailAndPassword(
          email: testEmail,
          password: testPassword,
        ),
      ).thenAnswer((_) async => mockUserCredential);

      // Act
      final result = await authService.register(testEmail, testPassword);

      // Assert
      check(result).equals(mockUser);
      verify(
        () => mockAuth.createUserWithEmailAndPassword(
          email: testEmail,
          password: testPassword,
        ),
      ).called(1);
    });

    test('Throws CustomAuthException on FirebaseAuthException', () async {
      // Arrange
      when(
        () => mockAuth.createUserWithEmailAndPassword(
          email: testEmail,
          password: testPassword,
        ),
      ).thenThrow(FirebaseAuthException(code: 'weak-password'));

      // Act & Assert
      await check(authService.register(testEmail, testPassword))
          .throws<CustomAuthException>((exception) {
        exception
          ..has((e) => e.code, 'code').equals('weak-password')
          ..has((e) => e.displayMessage, 'displayMessage').equals(
            'Your password is too weak. Please choose a stronger password.',
          );
      });
    });

    test('Rethrows generic exception', () async {
      // Arrange
      final genericException = Exception('Something went entirely wrong');
      when(
        () => mockAuth.createUserWithEmailAndPassword(
          email: testEmail,
          password: testPassword,
        ),
      ).thenThrow(genericException);

      // Act & Assert
      await check(authService.register(testEmail, testPassword))
          .throws<Exception>((exception) {
        exception
            .has((e) => e.toString(), 'string')
            .contains('Something went entirely wrong');
      });
    });
  });

  group('login', () {
    const testEmail = 'test@example.com';
    const testPassword = 'Password123!';

    test('Returns User on successful login', () async {
      // Arrange
      when(() => mockUserCredential.user).thenReturn(mockUser);
      when(
        () => mockAuth.signInWithEmailAndPassword(
          email: testEmail,
          password: testPassword,
        ),
      ).thenAnswer((_) async => mockUserCredential);

      // Act
      final result = await authService.login(testEmail, testPassword);

      // Assert
      check(result).equals(mockUser);
      verify(
        () => mockAuth.signInWithEmailAndPassword(
          email: testEmail,
          password: testPassword,
        ),
      ).called(1);
    });
  });

  group('signInWithGoogle', () {
    late MockGoogleSignInAccount mockGoogleAccount;
    late MockGoogleSignInAuthentication mockGoogleAuth;

    setUp(() {
      mockGoogleAccount = MockGoogleSignInAccount();
      mockGoogleAuth = MockGoogleSignInAuthentication();

      // Dynamic stubs if 'initialize' or 'authenticate' are custom extensions
      // or specific package implementations.
      when(() => mockGoogleSignIn.initialize()).thenAnswer((_) async {});
      when(
        () => mockGoogleSignIn.authenticate(),
      ).thenAnswer((_) async => mockGoogleAccount);
      when(() => mockGoogleAccount.authentication).thenReturn(mockGoogleAuth);
      when(() => mockGoogleAuth.idToken).thenReturn('fake_id_token');
    });

    test('Returns User on successful sign-in', () async {
      // Arrange
      when(() => mockUserCredential.user).thenReturn(mockUser);
      when(
        () => mockAuth.signInWithCredential(any()),
      ).thenAnswer((_) async => mockUserCredential);

      // Act
      final result = await authService.signInWithGoogle();

      // Assert
      check(result).equals(mockUser);
      verify(() => mockGoogleSignIn.initialize()).called(1);
      verify(() => mockGoogleSignIn.authenticate()).called(1);
      verify(() => mockAuth.signInWithCredential(any())).called(1);
    });

    test('Throws CustomAuthException on GoogleSignInException', () async {
      // Arrange
      when(() => mockGoogleSignIn.authenticate()).thenThrow(
        GoogleSignInException(
          code: GoogleSignInExceptionCode.unknownError,
          description: 'No internet',
        ),
      );

      // Act & Assert
      await check(authService.signInWithGoogle())
          .throws<CustomAuthException>((exception) {
        exception
          ..has((e) => e.displayMessage, 'displayMessage')
              .equals('Something went wrong')
          ..has((e) => e.code, 'code').equals('unknownError')
          ..has((e) => e.errorMessage, 'errorMessage').equals('No internet');
      });
    });
  });

  group('updateUsername', () {
    test(
      'Calls updateDisplayName when user exists and newUsername is not empty',
      () async {
        // Arrange
        when(() => mockAuth.currentUser).thenReturn(mockUser);
        when(
          () => mockUser.updateDisplayName('NewName'),
        ).thenAnswer((_) async {});

        // Act
        await authService.updateUsername('NewName');

        // Assert
        verify(() => mockUser.updateDisplayName('NewName')).called(1);
      },
    );

    test('Does NOT call updateDisplayName when user is null', () async {
      // Arrange
      when(() => mockAuth.currentUser).thenReturn(null);

      // Act
      await authService.updateUsername('NewName');

      // Assert
      verifyNever(() => mockUser.updateDisplayName(any()));
    });

    test('Does NOT call updateDisplayName when newUsername is empty', () async {
      // Arrange
      when(() => mockAuth.currentUser).thenReturn(mockUser);

      // Act
      await authService.updateUsername('');

      // Assert
      verifyNever(() => mockUser.updateDisplayName(any()));
    });
  });

  group('sendEmailVerification', () {
    test(
      'Calls sendEmailVerification if user exists and email is NOT verified',
      () async {
        // Arrange
        when(() => mockAuth.currentUser).thenReturn(mockUser);
        when(() => mockUser.emailVerified).thenReturn(false);
        when(() => mockUser.sendEmailVerification()).thenAnswer((_) async {});

        // Act
        await authService.sendEmailVerification();

        // Assert
        verify(() => mockUser.sendEmailVerification()).called(1);
      },
    );

    test('Does NOT call sendEmailVerification if user is null', () async {
      // Arrange
      when(() => mockAuth.currentUser).thenReturn(null);

      // Act
      await authService.sendEmailVerification();

      // Assert
      verifyNever(() => mockUser.sendEmailVerification());
    });

    test(
      'Does NOT call sendEmailVerification if email is already verified',
      () async {
        // Arrange
        when(() => mockAuth.currentUser).thenReturn(mockUser);
        when(() => mockUser.emailVerified).thenReturn(true);

        // Act
        await authService.sendEmailVerification();

        // Assert
        verifyNever(() => mockUser.sendEmailVerification());
      },
    );
  });

  group('sendPasswordResetEmail', () {
    const testEmail = 'test@example.com';

    test(
      'Calls sendPasswordResetEmail if user exists and email IS verified',
      () async {
        // Arrange
        when(() => mockAuth.currentUser).thenReturn(mockUser);
        when(() => mockUser.emailVerified).thenReturn(true);
        when(
          () => mockAuth.sendPasswordResetEmail(email: testEmail),
        ).thenAnswer((_) async {});

        // Act
        await authService.sendPasswordResetEmail(testEmail);

        // Assert
        verify(
          () => mockAuth.sendPasswordResetEmail(email: testEmail),
        ).called(1);
      },
    );

    test('Does NOT call sendPasswordResetEmail if user is null', () async {
      // Arrange
      when(() => mockAuth.currentUser).thenReturn(null);

      // Act
      await authService.sendPasswordResetEmail(testEmail);

      // Assert
      verifyNever(
        () => mockAuth.sendPasswordResetEmail(email: any(named: 'email')),
      );
    });

    test(
      'Does NOT call sendPasswordResetEmail if email is NOT verified',
      () async {
        // Arrange
        when(() => mockAuth.currentUser).thenReturn(mockUser);
        when(() => mockUser.emailVerified).thenReturn(false);

        // Act
        await authService.sendPasswordResetEmail(testEmail);

        // Assert
        verifyNever(
          () => mockAuth.sendPasswordResetEmail(email: any(named: 'email')),
        );
      },
    );
  });

  group('getProfilePicture', () {
    test('Returns photo URL if user exists and URL is valid', () {
      // Arrange
      const validUrl = 'https://example.com/photo.jpg';
      when(() => mockAuth.currentUser).thenReturn(mockUser);
      when(() => mockUser.photoURL).thenReturn(validUrl);

      // Act
      final result = authService.getProfilePicture();

      // Assert
      check(result).equals(validUrl);
    });

    test('Returns null if user exists but URL is empty', () {
      // Arrange
      when(() => mockAuth.currentUser).thenReturn(mockUser);
      when(() => mockUser.photoURL).thenReturn('');

      // Act
      final result = authService.getProfilePicture();

      // Assert
      check(result).isNull();
    });

    test('Returns null if user is null', () {
      // Arrange
      when(() => mockAuth.currentUser).thenReturn(null);

      // Act
      final result = authService.getProfilePicture();

      // Assert
      check(result).isNull();
    });
  });
}
