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

  Future<SavedItem?> saveWebpage({
    required ReadingStatus readingStatus,
    required String url,
    required String title,
    required String notes,
    required bool remindMe,
    required String? id,
    required bool isEdit,
    required DateTime createdAt,
  }) async {
    String? error;
    saveCommand.start();
    notifyListeners();

    final isValid = validateFields(url, title, notes);
    if (!isValid) {
      log.warning('Some info is invalid, so not saving the webpage');
      return null;
    }

    final item = SavedItem(
      id: id, // will be set if is edit
      type: ItemType.webpage,
      readingStatus: readingStatus,
      uri: Uri.tryParse(url),
      title: title,
      notes: notes,
      remindReading: remindMe,
      createdAt: createdAt,
    );

    log.info('Created item:\n$item');

    if (!isEdit) {
      error = await _provider.add(item);
    } else {
      error = await _provider.edit(item);
    }

    saveCommand.finish(error);
    notifyListeners();
    return item;
  }
}
