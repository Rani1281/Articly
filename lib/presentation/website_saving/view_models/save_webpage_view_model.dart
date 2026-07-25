import 'package:articly/domain/providers/saved_items_provider.dart';
import 'package:articly/utils/command.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

import '../../../data/models/saved_item.dart';

class SaveWebpageViewModel extends ChangeNotifier {
  SaveWebpageViewModel(this._provider);

  final SavedItemsProvider _provider;

  String? _urlError;
  String? get urlError => _urlError;

  String? _titleError;
  String? get titleError => _titleError;

  String? _notesError;
  String? get notesError => _notesError;

  static const int titleMaxChars = 200;
  static const int urlMaxChars = 2048;
  static const int notesMaxChars = 10000;

  final Command saveCommand = Command();

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
  bool validateFields(Uri? uri, String? title, String? notes) {
    _clearErrors();

    if (uri == null || uri.toString().isEmpty) {
      _urlError = 'Url is required';
      return false;
    }

    if (uri.toString().length > urlMaxChars) {
      _urlError = 'Url is too long';
      return false;
    }

    if (!isUrlValid(uri)) {
      _urlError = 'Invalid url';
      return false;
    }

    if (title != null && title.length > titleMaxChars) {
      _titleError = 'Title is too long';
      return false;
    }

    if (notes != null && notes.length > notesMaxChars) {
      _notesError = 'Notes are too long';
      return false;
    }

    return true;
  }

  void _clearErrors() {
    _urlError = null;
    _titleError = null;
    _notesError = null;
  }

  Future<void> saveWebpage({
    required SavedItem savedItem,
    required bool isEdit,
  }) async {
    // first check the validity without starting the command yet because this is not an async operation
    final isValid = validateFields(
      savedItem.uri,
      savedItem.title,
      savedItem.notes,
    );

    if (!isValid) {
      log.info('Some info is invalid, so not saving the webpage');
      notifyListeners();
      return Future.value();
    }

    String? error;
    saveCommand.start();
    notifyListeners();

    if (!isEdit) {
      error = await _provider.add(savedItem);
    } else {
      error = await _provider.edit(savedItem);
    }

    saveCommand.finish(error);
    notifyListeners();
  }
}
