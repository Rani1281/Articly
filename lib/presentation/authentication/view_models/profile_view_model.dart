import 'package:articly/data/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

/// Manages profile state and user account actions.
class ProfileViewModel extends ChangeNotifier {
  ProfileViewModel({AuthService? authService})
    : _authService = authService ?? AuthService();

  final AuthService _authService;
  final log = Logger('ProfileViewModel');

  String? _email;
  String? _username; // can be modified

  bool _isRunningLogout = false;

  String? _errorMessage;
  bool _isRunningName = false;

  String? get email => _email;
  String? get username => _username;

  bool get isRunningLogout => _isRunningLogout;

  String? get errorMessage => _errorMessage;
  bool get isRunningName => _isRunningName;

  // Use in initState to initialize data
  void loadData() {
    _email = _authService.user?.email;
    _username = _authService.user?.displayName;
  }

  Future<void> logOut() async {
    log.info('Logout started...');
    _errorMessage = null;
    _isRunningLogout = true;
    notifyListeners();

    try {
      await _authService.signOut();
      log.fine('Logout was successful!');
    } on CustomAuthException catch (e) {
      log.shout(
        'A Firebase Auth exception occurred: ${e.errorMessage}.\n'
        'Code: ${e.code}',
      );
      _errorMessage = e.displayMessage;
    } catch (e) {
      log.shout('An error has occurred: ${e.toString()}');
      _errorMessage = 'Something went wrong. Please try again later';
    } finally {
      _isRunningLogout = false;
      notifyListeners();
    }
  }

  Future<void> editName(String? newName) async {
    if (newName == null || newName.isEmpty) {
      log.info('The new username is empty or null, so not updating...');
      return Future.value();
    }

    log.info('Edit name started...');
    _errorMessage = null;
    _isRunningName = true;
    notifyListeners();

    try {
      await _authService.updateUsername(newName);
      _username = newName;
      log.fine('username was successfully updated!');
    } on CustomAuthException catch (e) {
      log.shout(
        'A Firebase Auth exception occurred: ${e.errorMessage}.\n'
        'Code: ${e.code}',
      );
      _errorMessage = e.displayMessage;
    } catch (e) {
      log.shout('An error has occurred: ${e.toString()}');
      _errorMessage = 'Something went wrong. Please try again later';
    } finally {
      _isRunningName = false;
      notifyListeners();
    }
  }

  String? validateUsername(String username) {
    if (username.isEmpty) {
      return 'Username is required';
    }
    if (username.length > 50) {
      return 'Username is too long';
    }
    return null;
  }
}
