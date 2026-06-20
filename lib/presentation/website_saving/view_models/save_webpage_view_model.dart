import 'package:articly/data/models/saved_item.dart';
import 'package:articly/data/repositories/saved_items_repository.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

class SaveWebpageViewModel extends ChangeNotifier {
  SaveWebpageViewModel({SavedItemsRepository? repo})
    : _repo = repo ?? SavedItemsRepository();

  final SavedItemsRepository _repo;

  bool _remindMe = false;
  bool get remindMe => _remindMe;
  set remindMe(bool value) {
    _remindMe = value;
    notifyListeners();
  }

  bool _isSaving = false;
  bool get isSaving => _isSaving;

  String? _savingError;
  String? get savingError => _savingError;

  bool _isSavingSuccessful = false;
  bool get isSavingSuccessful => _isSavingSuccessful;

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

  String? validateUrl(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Url is required';
    }

    if (value.length > urlMaxChars) {
      return 'Url is too long';
    }

    final uri = Uri.tryParse(value.trim());

    if (uri == null ||
        !uri.hasScheme ||
        !(uri.scheme == 'http' || uri.scheme == 'https') ||
        uri.host.isEmpty) {
      return 'Invalid url';
    }

    return null;
  }

  /// Validates all fields. If one is invalid, immediately returns false and updates the value of the error message.
  bool validateFields(String url, String title, String notes) {
    _urlError = validateUrl(url);
    if (_urlError != null) {
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

  Future<void> saveWebpage({
    required String url,
    required ReadingStatus readingStatus,
    required String title,
    required String notes,
  }) async {
    log.info('Saving started...');
    _isSaving = true;
    _isSavingSuccessful = false;

    _savingError = null;
    _urlError = null;
    _titleError = null;
    _notesError = null;
    notifyListeners();
    // first clear all errors

    url = url.trim();
    // Title and notes don't trim to maintain how the user typed it.

    final isValid = validateFields(url, title, notes);
    if (!isValid) {
      log.info('Some info is invalid, so not saving the webpage');
      _isSaving = false;
      notifyListeners();
      return Future.value();
    }

    final item = SavedItem(
      type: ItemType.webpage,
      url: url,
      readingStatus: readingStatus,
      title: title,
      notes: notes,
      remindReading: remindMe,
    );

    // TODO: Later save also in memory/local storage

    try {
      final path = await _repo.saveItem(item);
      _isSavingSuccessful = true;
      log.finest('Successfully saved the item in Firestore in: [$path]');
    } catch (e) {
      log.shout('An error occurred: ${e.toString()}');
      // TODO: maybe show custom messages to the user
      _savingError =
          "Something wen't wrong. Please check you internet connection and try again later.";
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }
}
