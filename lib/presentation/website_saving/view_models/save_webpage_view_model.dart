import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

class SaveWebpageViewModel extends ChangeNotifier {
  // bool _remindMe = false;
  // bool get remindMe => _remindMe;
  // set remindMe(bool value) {
  //   _remindMe = value;
  //   notifyListeners();
  // }

  String? _urlError;
  String? get urlError => _urlError;

  String? _titleError;
  String? get titleError => _titleError;

  String? _notesError;
  String? get notesError => _notesError;

  static const int titleMaxChars = 200;
  static const int urlMaxChars = 2048;
  static const int notesMaxChars = 10000;

  final log = Logger('SaveWebpageViewModel');

  // Returns true if the url is formatter correctly: uses "https" or "http" and is not empty
  bool isUrlValid(Uri? uri) {
    if (uri == null ||
        !uri.hasScheme ||
        !(uri.scheme == 'http' || uri.scheme == 'https') ||
        uri.host.isEmpty) {
      return false;
    }

    return true;
  }

  /// Validates all fields. If one is invalid, immediately returns false and updates the value of the error message.
  bool validateFields(String url, String title, String notes) {
    _clearErrors();

    if (url.isEmpty) {
      _urlError = 'Url is required';
      notifyListeners();
      return false;
    }

    if (url.length > urlMaxChars) {
      _urlError = 'Url is too long';
      notifyListeners();
      return false;
    }

    final parsedUri = Uri.tryParse(url);
    if (!isUrlValid(parsedUri)) {
      _urlError = 'Invalid url';
      notifyListeners();
      return false;
    }

    if (title.length > titleMaxChars) {
      _titleError = 'Title is too long';
      notifyListeners();
      return false;
    }

    if (notes.length > notesMaxChars) {
      _notesError = 'Notes are too long';
      notifyListeners();
      return false;
    }

    return true;
  }

  void _clearErrors() {
    _urlError = null;
    _titleError = null;
    _notesError = null;
    notifyListeners();
  }
}
