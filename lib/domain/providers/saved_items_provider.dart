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

  final Command loadCommand = Command();
  final Command saveCommand = Command();
  final Command editCommand = Command();
  final Command deleteCommand = Command();

  final log = Logger('SavedItemsProvider');

  // Loads the user's saved items
  Future<void> load() async {
    log.info('Loading started...');
    String? error;
    loadCommand.start();
    notifyListeners();
    try {
      _items = await _repo.fetchItems();
      log.finest('Successfully loaded all user saved items!');
    } catch (e) {
      log.shout('An error occurred: $e');
      error =
          'Something went wrong. Please check your internet connection and try again';
    } finally {
      loadCommand.finish(error);
      notifyListeners();
    }
  }

  /// Create a new item
  Future<void> save(SavedItem item) async {
    log.info('Saving started...');
    String? error;
    saveCommand.start();
    notifyListeners();

    try {
      final id = await _repo.saveItem(item);
      _items[id] = item;
      log.finest('Successfully saved item in Firestore and in memory!');
    } catch (e) {
      log.shout('An error occurred: $e');
      error =
          'Something went wrong. Please check your internet connection and try again';
    } finally {
      saveCommand.finish(error);
      notifyListeners();
    }
  }

  /// Edit an existing item
  Future<void> edit(SavedItem item) async {
    log.info('Editing started...');
    String? error;
    editCommand.start();
    notifyListeners();

    try {
      await _repo.updateItem(item);
      // if update item succeeds, the id must be non null
      _items[item.id!] = item;
      log.finest('Successfully edited the item in Firestore and in memory!');
    } catch (e) {
      log.shout('An error occurred: $e');
      error = 'Something went wrong. Please try again later';
    } finally {
      editCommand.finish(error);
      notifyListeners();
    }
  }

  /// Delete an item by its id
  Future<void> delete(String id) async {
    log.info('Deleting started...');
    String? error;
    deleteCommand.start();
    notifyListeners();

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
    } finally {
      deleteCommand.finish(error);
      notifyListeners();
    }
  }
}
