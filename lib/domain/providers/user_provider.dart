import 'dart:async';

import 'package:articly/data/models/reading_status_count.dart';
import 'package:articly/data/models/saved_item.dart';
import 'package:articly/data/repositories/saved_items_repository.dart';
import 'package:articly/data/repositories/user_repository.dart';
import 'package:articly/data/services/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

class UserProvider extends ChangeNotifier {
  UserProvider({
    UserRepository? userRepo,
    SavedItemsRepository? savedItemsRepo,
    AuthService? authService,
    FirebaseFirestore? db,
  }) {
    _init(
      userRepo: userRepo,
      savedItemsRepo: savedItemsRepo,
      authService: authService,
      db: db,
    );
  }

  String? _email;
  String? _username;
  String? get email => _email;
  String? get username => _username;

  Map<String, SavedItem> _items = {};
  Map<String, SavedItem> get items => _items;

  ReadingStatusCount _readingStatusCount = ReadingStatusCount();
  ReadingStatusCount get readingStatusCount => _readingStatusCount;

  UserRepository? _userRepo;
  SavedItemsRepository? _savedItemsRepo;
  late final AuthService _authService;
  late final FirebaseFirestore _db;

  static const usersCollection = 'users';
  static const savedItemsCollection = 'savedItems';

  final log = Logger('UserProvider');

  void _init({
    UserRepository? userRepo,
    SavedItemsRepository? savedItemsRepo,
    AuthService? authService,
    FirebaseFirestore? db,
  }) {
    _authService = authService ?? AuthService();
    _db = db ?? FirebaseFirestore.instance;

    final user = _authService.user;
    if (user == null) {
      log.info('UserProvider initialized without a logged-in user.');
      _userRepo = userRepo; // probably null
      _savedItemsRepo = savedItemsRepo; // probably null
      return;
    }
    log.info('User is ${user.uid}');

    _userRepo =
        userRepo ??
        UserRepository(_db.collection(usersCollection).doc(user.uid));
    _savedItemsRepo =
        savedItemsRepo ??
        SavedItemsRepository(
          _db
              .collection(usersCollection)
              .doc(user.uid)
              .collection(savedItemsCollection),
        );
  }

  bool _isLoaded = false;
  bool get isLoaded => _isLoaded;

  Future<String?>? _activeLoadFuture;

  // Load all user data: username, email, saved items, reading status counts
  Future<String?> load({bool reload = false, bool notify = true}) async {
    if (!reload) {
      if (_activeLoadFuture != null) {
        return _activeLoadFuture;
      }
      if (_isLoaded) {
        if (notify) {
          notifyListeners();
        }
        return null;
      }
    }

    _activeLoadFuture = _performLoad(notify: notify);
    try {
      return await _activeLoadFuture;
    } finally {
      _activeLoadFuture = null;
    }
  }

  Future<String?> _performLoad({required bool notify}) async {
    String? error;
    try {
      // auth details
      _email = _authService.user?.email;
      _username = _authService.user?.displayName;

      // Firestore data
      _items = await _savedItemsRepo!.fetchItems();
      _readingStatusCount = await _userRepo!.fetchReadingStatusCount();
      if (_items.length != _readingStatusCount.total() ||
          !_readingStatusCount.isSynced) {
        // means the count isn't synced
        log.info('Syncing reading status counts...');
        syncReadingStatusCount();
      }
      _isLoaded = true;
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
    _userRepo!.setReadingStatusCounts(_readingStatusCount, forceSync: true);
  }

  /// Create a new item, return error or null
  Future<String?> addItem(SavedItem item) async {
    String? error;

    try {
      final id = await _savedItemsRepo!.addItem(item);
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
      await _savedItemsRepo!.updateItem(item);
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
      await _savedItemsRepo!.deleteItem(id);
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
    if (previousStatus == newStatus) return;

    // Update app state; decrement previous status and increment new one
    if (previousStatus != null) {
      _readingStatusCount.decrement(previousStatus);
    }
    if (newStatus != null) {
      _readingStatusCount.increment(newStatus);
    }

    // run Firestore write in the background
    unawaited(_userRepo!.setReadingStatusCounts(_readingStatusCount));
  }
}
