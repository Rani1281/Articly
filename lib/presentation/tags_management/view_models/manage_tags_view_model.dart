import 'package:articly/data/models/tag.dart';
import 'package:articly/domain/providers/user_provider.dart';
import 'package:articly/utils/command.dart';
import 'package:flutter/material.dart';

class ManageTagsViewModel extends ChangeNotifier {
  ManageTagsViewModel({required UserProvider provider}) : _provider = provider {
    _provider.addListener(_onProviderChanged);
    _updateSortedTags();
  }

  final UserProvider _provider;
  UserProvider get provider => _provider;

  final Command getTagsCommand = Command();

  List<Tag> _tags = [];
  List<Tag> get tags => _tags;

  void _updateSortedTags() {
    final list = _provider.tags.values.toList();
    list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    _tags = list;
  }

  void _onProviderChanged() {
    _updateSortedTags();
    notifyListeners();
  }

  /// Starts the command and notifies listeners, gets the tags data from the user provider,
  /// finishes the command considering errors and exceptions, and returns the data sorted alphabetically (A-Z).
  Future<List<Tag>> getTags({bool reload = false}) async {
    getTagsCommand.start();
    notifyListeners();

    String? error;
    try {
      if (!_provider.isLoaded || reload) {
        error = await _provider.load(reload: reload, notify: false);
      }
      _updateSortedTags();
      if (error == null) {
        getTagsCommand.successful();
      } else {
        getTagsCommand.problem(error);
      }
    } catch (e) {
      error = e.toString();
      getTagsCommand.problem(error);
    }

    notifyListeners();
    return _tags;
  }

  @override
  void dispose() {
    _provider.removeListener(_onProviderChanged);
    super.dispose();
  }
}
