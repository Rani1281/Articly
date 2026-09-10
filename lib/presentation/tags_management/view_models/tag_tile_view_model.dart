import 'package:articly/data/models/tag.dart';
import 'package:articly/domain/providers/user_provider.dart';
import 'package:articly/utils/command.dart';
import 'package:flutter/material.dart';

class TagTileViewModel extends ChangeNotifier {
  TagTileViewModel({
    Tag? tag,
    bool isEditMode = false,
    required UserProvider provider,
  }) : _tag = tag,
       _isEditMode = isEditMode,
       _provider = provider;

  final UserProvider _provider;

  Tag? _tag;
  Tag? get tag => _tag;
  set tag(Tag? value) {
    _tag = value;
    notifyListeners();
  }

  bool _isEditMode;
  bool get isEditMode => _isEditMode;
  set isEditMode(bool value) {
    if (_isEditMode == value) return;
    _isEditMode = value;
    notifyListeners();
  }

  void toggleEditMode() {
    _isEditMode = !_isEditMode;
    notifyListeners();
  }

  void setEditMode(bool value) {
    isEditMode = value;
  }

  final Command createTagCommand = Command();
  final Command editTagCommand = Command();
  final Command deleteTagCommand = Command();

  String? validationError;

  /// Validates the tag name before creation or editing.
  /// Checks:
  /// - Not null / not empty
  /// - Doesn't contain newline characters
  /// - Length is between 1 to 40 characters
  /// - Not already existent (normalized, case-insensitive)
  String? validateTagName(String? input) {
    validationError = null;

    if (input == null || input.trim().isEmpty) {
      validationError = 'Tag name cannot be empty';
      return validationError;
    }

    if (input.contains('\n') || input.contains('\r')) {
      validationError = 'Tag name cannot contain newlines';
      return validationError;
    }

    final trimmed = input.trim();

    if (trimmed.length > 40) {
      validationError = 'Tag name must be between 1 and 40 characters';
      return validationError;
    }

    final normalized = Tag.normalize(trimmed);
    final isDuplicate = _provider.tags.values.any(
      (t) => t.normalizeName() == normalized && t.id != _tag?.id,
    );
    if (isDuplicate) {
      validationError = 'A tag with this name already exists';
      return validationError;
    }

    return null;
  }

  String? validate(String? input) => validateTagName(input);

  /// Creates a new tag with the given name.
  Future<String?> createTag(String newName) async {
    createTagCommand.start();
    notifyListeners();

    final validationErr = validateTagName(newName);
    if (validationErr != null) {
      createTagCommand.problem(validationErr);
      notifyListeners();
      return validationErr;
    }

    final trimmed = newName.trim();
    final error = await _provider.createTag(trimmed);

    if (error == null) {
      _tag = _provider.tags.values.cast<Tag?>().firstWhere(
        (t) => t?.normalizeName() == Tag.normalize(trimmed),
        orElse: () => null,
      );
      _isEditMode = false;
      createTagCommand.successful();
    } else {
      createTagCommand.problem(error);
    }

    notifyListeners();
    return error;
  }

  /// Edits an existing tag's name.
  Future<String?> editTag(String newName) async {
    editTagCommand.start();
    notifyListeners();

    if (_tag == null) {
      const err = 'No tag to edit';
      editTagCommand.problem(err);
      notifyListeners();
      return err;
    }

    final validationErr = validateTagName(newName);
    if (validationErr != null) {
      editTagCommand.problem(validationErr);
      notifyListeners();
      return validationErr;
    }

    // in case they're the same name
    final trimmed = newName.trim();
    if (trimmed == _tag!.name) {
      _isEditMode = false;
      editTagCommand.successful();
      notifyListeners();
      return null;
    }

    final error = await _provider.editTag(_tag!.id, trimmed);

    if (error == null) {
      _tag = _provider.tags[_tag!.id] ?? _tag!.copyWith(name: trimmed);
      _isEditMode = false;
      editTagCommand.successful();
    } else {
      editTagCommand.problem(error);
    }

    notifyListeners();
    return error;
  }

  /// Deletes a tag by id (defaults to the current tag's id).
  Future<String?> deleteTag([String? tagId]) async {
    deleteTagCommand.start();
    notifyListeners();

    final id = tagId ?? _tag?.id;
    if (id == null || id.isEmpty) {
      const err = 'No tag to delete';
      deleteTagCommand.problem(err);
      notifyListeners();
      return err;
    }

    final error = await _provider.deleteTag(id);

    if (error == null) {
      _tag = null;
      deleteTagCommand.successful();
    } else {
      deleteTagCommand.problem(error);
    }

    notifyListeners();
    return error;
  }
}
