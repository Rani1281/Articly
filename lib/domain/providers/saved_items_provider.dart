import 'package:articly/data/models/saved_item.dart';
import 'package:articly/data/repositories/saved_items_repository.dart';
import 'package:articly/utils/command.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

class SavedItemsProvider extends ChangeNotifier {
  SavedItemsProvider({SavedItemsRepository? repo})
    : _repo = repo ?? SavedItemsRepository();

  Map<String, SavedItem> _items = {};
  Map<String, SavedItem> get items => _items;

  final SavedItemsRepository _repo;

  final log = Logger('SavedItemsProvider');

  // Loads the user's saved items, return error or null
  Future<String?> load({bool notify = true}) async {
    String? error;

    try {
      _items = await _repo.fetchItems();
      log.finest('Successfully loaded all user saved items!');
    } catch (e) {
      log.shout('An error occurred: $e');
      error =
          'Something went wrong. Please check your internet connection and try again';
    }

    if (notify) {
      notifyListeners();
    }
    return error;
  }

  /// Create a new item, return error or null
  Future<String?> add(SavedItem item) async {
    String? error;

    try {
      final id = await _repo.addItem(item);
      // create a new item that has the new id
      final newItem = item.copyWith(id: id);
      _items[id] = newItem;
      log.finest('Successfully saved item in Firestore and in memory!');
    } catch (e) {
      log.shout('An error occurred: $e');
      error =
          'Something went wrong. Please check your internet connection and try again';
    }

    notifyListeners();
    return error;
  }

  /// Edit an existing item
  Future<String?> edit(SavedItem item) async {
    String? error;

    try {
      await _repo.updateItem(item);
      // if update item succeeds, the id must be non null
      _items[item.id!] = item;
      log.finest('Successfully edited the item in Firestore and in memory!');
    } catch (e) {
      log.shout('An error occurred: $e');
      error = 'Something went wrong. Please try again later';
    }

    notifyListeners();
    return error;
  }

  /// Delete an item by its id, returns an error message.
  /// Notifies listeners only when finished
  Future<String?> delete(String id) async {
    String? error;

    try {
      await _repo.deleteItem(id);
      // delete in memory after in Firestore in case of failure
      _items.remove(id);
      log.finest(
        'Successfully removed the item "$id" in Firestore and in memory!',
      );
    } catch (e) {
      log.shout('An error occurred: $e');
      error = 'Something went wrong. Please try again later';
    }

    notifyListeners();
    return error;
  }
}
