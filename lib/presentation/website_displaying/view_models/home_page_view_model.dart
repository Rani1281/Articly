import 'package:articly/data/models/saved_item.dart';
import 'package:articly/data/repositories/saved_items_repository.dart';
import 'package:articly/utils/command.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

class HomePageViewModel extends ChangeNotifier {
  HomePageViewModel({SavedItemsRepository? repo})
    : _repo = repo ?? SavedItemsRepository() {
    load = Command(_load);
  }

  final SavedItemsRepository _repo;
  Map<String, SavedItem> _items = {};
  Map<String, SavedItem> get items => _items;

  late final Command load;

  final log = Logger('HomePageViewModel');

  // Loads the user's saved items
  Future<void> _load() async {
    log.info('Loading started...');
    String? error;
    load.start();
    notifyListeners();
    try {
      _items = await _repo.fetchItems();
      log.finest('Successfully loaded all user saved items!');
    } catch (e) {
      log.shout('An error occurred: $e');
      error =
          'Something went wrong. Please check your internet connection and try again';
    } finally {
      load.finish(error);
      notifyListeners();
    }
  }
}
