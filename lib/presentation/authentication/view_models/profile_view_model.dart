import 'package:articly/data/services/auth_service.dart';
import 'package:articly/utils/command.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

/// Manages profile state and user account actions.
class ProfileViewModel extends ChangeNotifier {
  ProfileViewModel({AuthService? authService})
    : _authService = authService ?? AuthService();

  final AuthService _authService;
  final log = Logger('ProfileViewModel');

  final Command logoutCommand = Command();
  final Command editUsernameCommand = Command();

  String? get email => _authService.user?.email;
  String? get username => _authService.user?.displayName;

  Future<void> logout() async {
    log.info('Logout started...');
    String? error;
    logoutCommand.start();
    notifyListeners();

    try {
      await _authService.signOut();
      log.fine('Logout was successful!');
    } on CustomAuthException catch (e) {
      log.shout(
        'A Firebase Auth exception occurred: ${e.errorMessage}.\n'
        'Code: ${e.code}',
      );
      error = e.displayMessage;
    } catch (e) {
      log.shout('An error has occurred: ${e.toString()}');
      error = 'Something went wrong. Please try again later';
    } finally {
      logoutCommand.finish(error);
      notifyListeners();
    }
  }

  Future<void> editName(String? newName) async {
    if (newName == null || newName.isEmpty) {
      log.info('The new username is empty or null, so not updating...');
      return Future.value();
    }

    log.info('Edit name started...');
    String? error;
    editUsernameCommand.start();
    notifyListeners();

    try {
      await _authService.updateUsername(newName);
      log.fine('username was successfully updated!');
    } on CustomAuthException catch (e) {
      log.shout(
        'A Firebase Auth exception occurred: ${e.errorMessage}.\n'
        'Code: ${e.code}',
      );
      error = e.displayMessage;
    } catch (e) {
      log.shout('An error has occurred: ${e.toString()}');
      error = 'Something went wrong. Please try again later';
    } finally {
      editUsernameCommand.finish(error);
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
