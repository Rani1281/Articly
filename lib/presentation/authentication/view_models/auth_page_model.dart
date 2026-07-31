import 'package:articly/data/services/auth_service.dart';
import 'package:articly/domain/string_extension.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

class AuthPageModel extends ChangeNotifier {
  AuthPageModel({AuthService? service}) : _service = service ?? AuthService();

  final AuthService _service;

  bool _disposed = false;

  bool _isLogin = true;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  String? _error;
  bool _isRunning = false;
  bool _isRunningGoogle = false;

  final log = Logger('AuthPageModel');

  bool get isLogin => _isLogin;
  bool get isPasswordVisible => _isPasswordVisible;
  bool get isConfirmPasswordVisible => _isConfirmPasswordVisible;
  String? get error => _error;
  bool get isRunning => _isRunning;
  bool get isRunningGoogle => _isRunningGoogle;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _notify() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  void toggleForm() {
    _isLogin = !isLogin;
    _error = null;
    _isPasswordVisible = false;
    _isConfirmPasswordVisible = false;
    _isRunning = false;
    _isRunningGoogle = false;
    _notify();
  }

  void togglePasswordVisibility() {
    _isPasswordVisible = !_isPasswordVisible;
    _notify();
  }

  void toggleConfirmPasswordVisibility() {
    _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
    _notify();
  }

  Future<void> submit({
    required String username,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    log.info('Action button pressed. Validating fields...');

    _isRunning = true;
    _error = null; // clear the error
    _notify();

    final String? message = validateFields(
      username: username,
      email: email,
      password: password,
      confirmPassword: confirmPassword,
    );

    if (message != null) {
      _error = message;
      _isRunning = false;
      log.warning('Details are not valid. Problem: $message');
      _notify();
      return Future.value();
    }

    _error = await authenticate(
      username: username,
      email: email,
      password: password,
    );
    if (_disposed) return;
    _isRunning = false;
    _notify();
  }

  String? validateFields({
    required String username,
    required String email,
    required String password,
    required String confirmPassword,
  }) {
    // check email and password
    final String? emailMsg = validateEmail(email);
    if (emailMsg != null) return emailMsg;

    final String? passwordMsg = validatePassword(password);
    if (passwordMsg != null) return passwordMsg;

    // Handle additional fields to validate during registration
    if (!isLogin) {
      final String? usernameMsg = validateUsername(username);
      if (usernameMsg != null) return usernameMsg;

      final String? confirmPasswordMsg = validateConfirmPassword(
        confirmPassword,
        password,
      );
      if (confirmPasswordMsg != null) return confirmPasswordMsg;
    }

    return null;
  }

  Future<String?> authenticate({
    required String username,
    required String email,
    required String password,
  }) async {
    log.info('Authentication with Firebase started...');
    try {
      if (isLogin) {
        final user = await _service.login(email, password);
        if (user != null) {
          log.fine('User was successfully logged in!');
        }
      } else {
        final user = await _service.register(email, password);
        await _service.updateUsername(username);
        if (user != null) {
          log.fine('User was successfully created, and username was updated!');
        }
      }
      return null;
    } on CustomAuthException catch (e) {
      log.shout(
        'A Firebase Auth exception occurred: ${e.errorMessage}.\nCode: ${e.code}',
      );
      return e.displayMessage;
    } catch (e) {
      log.shout('An error has occurred: ${e.toString()}');
      return 'Something went wrong, please check your details or try again later';
    }
  }

  Future<void> continueWithGoogle() async {
    log.info('Google Authentication started...');
    _isRunningGoogle = true;
    _error = null;
    _notify();

    try {
      final user = await _service.signInWithGoogle();
      if (user != null) {
        log.fine('Google authentication was successful!');
      }
    } on CustomAuthException catch (e) {
      log.shout(
        'A Firebase Auth exception occurred: ${e.errorMessage}.\nCode: ${e.code}',
      );
      _error = e.displayMessage;
    } catch (e) {
      log.shout('An error occurred: ${e.toString()}');
      _error =
          'Something went wrong, please check your details or try again later';
    }
    if (_disposed) return;
    _isRunningGoogle = false;
    _notify();
  }

  // ! <--- Validation Methods --->

  String? validateUsername(String username) {
    if (username.isEmpty) {
      return 'Username is required';
    }
    if (username.length > 50) {
      return 'Username is too long';
    }
    return null;
  }

  String? validateEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (email.isEmpty) {
      return 'Email is required';
    }
    if (!_isLogin && !emailRegex.hasMatch(email)) {
      return 'The email is invalid';
    }
    return null;
  }

  String? validatePassword(String password) {
    if (password.isEmpty) {
      return 'Password is required';
    }
    if (!_isLogin) {
      if (password.length < 6) {
        return 'Password must contain at least 6 characters';
      }
      if (!password.hasLetter) {
        return 'Password must contain at least one letter';
      }
      if (!password.hasNumber) {
        return 'Password must have at least one number';
      }
      // else if (!password.hasSymbol) {
      //   return 'Password must have at least one symbol';
      // }
      // TODO: after scaling a bit consider adding this
    }
    return null;
  }

  // Only called in !isLogin
  String? validateConfirmPassword(String confirmPassword, String password) {
    if (confirmPassword.isEmpty) {
      return 'Password confirmation is required';
    }
    if (confirmPassword != password) {
      return 'The password does not match the original one';
    }
    return null;
  }
}
