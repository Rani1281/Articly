import 'dart:async';

import 'package:articly/data/models/reading_status_count.dart';
import 'package:articly/data/models/saved_item.dart';
import 'package:articly/data/repositories/saved_items_repository.dart';
import 'package:articly/data/repositories/user_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

class UserProvider extends ChangeNotifier {
  UserProvider({
    UserRepository? userRepo,
    SavedItemsRepository? savedItemsRepo,
    FirebaseAuth? auth,
    FirebaseFirestore? db,
  }) {
    _init(
      userRepo: userRepo,
      savedItemsRepo: savedItemsRepo,
      auth: auth,
      db: db,
    );
  }

  Map<String, SavedItem> _items = {};
  Map<String, SavedItem> get items => _items;

  ReadingStatusCount _readingStatusCount = ReadingStatusCount();
  ReadingStatusCount get readingStatusCount => _readingStatusCount;

  late final UserRepository _userRepo;
  late final SavedItemsRepository _savedItemsRepo;
  late final FirebaseAuth _auth;
  // TODO: maybe later switch to AuthService, and do all the authentication via here
  late final FirebaseFirestore _db;

  static const usersCollection = 'users';
  static const savedItemsCollection = 'savedItems';

  final log = Logger('SavedItemsProvider');

  void _init({
    UserRepository? userRepo,
    SavedItemsRepository? savedItemsRepo,
    FirebaseAuth? auth,
    FirebaseFirestore? db,
  }) {
    if (auth != null) {
      _auth = auth;
    } else {
      _auth = FirebaseAuth.instance;
    }

    if (db != null) {
      _db = db;
    } else {
      _db = FirebaseFirestore.instance;
    }

    final user = _auth.currentUser;
    if (user == null) {
      throw Exception(
        'Initialization failed because the user isn\'t logged in...',
      );
    }
    log.info('User is ${user.uid}');

    if (userRepo != null) {
      _userRepo = userRepo;
    } else {
      final userDoc = _db.collection(usersCollection).doc(user.uid);
      _userRepo = UserRepository(userDoc);
    }

    if (savedItemsRepo != null) {
      _savedItemsRepo = savedItemsRepo;
    } else {
      final savedItemsCol = _db
          .collection(usersCollection)
          .doc(user.uid)
          .collection(savedItemsCollection);
      _savedItemsRepo = SavedItemsRepository(savedItemsCol);
    }
  }

  // Loads the user's saved items and reading status counts, and return error or null
  Future<String?> load({bool notify = true}) async {
    String? error;
    try {
      _items = await _savedItemsRepo.fetchItems();
      _readingStatusCount = await _userRepo.fetchReadingStatusCount();

      if (_items.length != _readingStatusCount.total() ||
          !_readingStatusCount.isSynced) {
        // means the count isn't synced
        log.info('Syncing reading status counts...');
        syncReadingStatusCount();
      }
      log.finest('Successfully loaded user data from Firestore!');
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

  /// Syncs the reading status count by counting the items manually.
  /// Then, updates the value in Firestore and returns the counts
  void syncReadingStatusCount() {
    int unreadCount = 0;
    int readingCount = 0;
    int readCount = 0;

    for (var item in _items.entries) {
      final value = item.value;
      switch (value.readingStatus) {
        case ReadingStatus.unread:
          unreadCount++;
          break;
        case ReadingStatus.reading:
          readingCount++;
          break;
        case ReadingStatus.read:
          readCount++;
          break;
      }
    }

    _readingStatusCount = ReadingStatusCount(
      counts: {
        'unread': unreadCount,
        'reading': readingCount,
        'read': readCount,
      },
      isSynced: true,
    );

    // Update Firestore in the background
    _userRepo.setReadingStatusCounts(_readingStatusCount, forceSync: true);
  }

  /// Create a new item, return error or null
  Future<String?> addItem(SavedItem item) async {
    String? error;

    try {
      final id = await _savedItemsRepo.addItem(item);
      // create a new item that has the new id
      final newItem = item.copyWith(id: id);
      _items[id] = newItem;
      // update reading count state
      changeReadingStatusCounts(null, newItem.readingStatus);
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
  Future<String?> editItem(SavedItem item) async {
    String? error;

    try {
      await _savedItemsRepo.updateItem(item);
      // if update item succeeds, the id must be non null
      final prevItem = _items[item.id];
      _items[item.id!] = item;
      // update reading count state
      changeReadingStatusCounts(prevItem?.readingStatus, item.readingStatus);
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
  Future<String?> deleteItem(String id) async {
    String? error;

    try {
      await _savedItemsRepo.deleteItem(id);
      // delete in memory after in Firestore in case of failure
      final prevItem = _items[id];
      _items.remove(id);
      // update reading count state
      changeReadingStatusCounts(prevItem?.readingStatus, null);
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

  // --- Reading Status Related Functionality ---
  void changeReadingStatusCounts(
    ReadingStatus? previousStatus,
    ReadingStatus? newStatus,
  ) {
    // Update app state; decrement previous status and increment new one
    if (previousStatus != null) {
      _readingStatusCount.decrement(previousStatus);
    }
    if (newStatus != null) {
      _readingStatusCount.increment(newStatus);
    }

    // run Firestore write in the background
    unawaited(_userRepo.setReadingStatusCounts(_readingStatusCount));
  }
}
