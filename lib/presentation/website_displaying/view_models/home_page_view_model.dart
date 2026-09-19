import 'dart:async';

import 'package:articly/data/models/reading_status_count.dart';
import 'package:articly/data/models/saved_item.dart';
import 'package:articly/data/services/shared_preferences_service.dart';
import 'package:articly/utils/command.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

import '../../../domain/providers/user_provider.dart';

class HomePageViewModel extends ChangeNotifier {
  HomePageViewModel({
    required UserProvider provider,
    required SharedPreferencesService prefsService,
  }) : _provider = provider,
       _prefsService = prefsService {
    // listen to the provider to re-process items after they have changed
    _provider.addListener(() => processItems());
  }

  final UserProvider _provider;
  UserProvider get provider => _provider;
  final SharedPreferencesService _prefsService;

  bool loadedData = false;

  OrderType _orderBy = OrderType.creationDate;
  OrderType get orderBy => _orderBy;

  bool _isDescending = true;
  bool get isDescending => _isDescending;

  ReadingStatusFilterType _filter = ReadingStatusFilterType.none;
  ReadingStatusFilterType get filter => _filter;

  List<String> _selectedTagIds = [];
  List<String> get selectedTagIds => List.unmodifiable(_selectedTagIds);

  bool get hasActiveFilter =>
      _filter != ReadingStatusFilterType.none || _selectedTagIds.isNotEmpty;

  int get activeFilterCount =>
      (_filter != ReadingStatusFilterType.none ? 1 : 0) +
      _selectedTagIds.length;

  bool _isGridView = false;
  bool get isGridView => _isGridView;

  List<SavedItem> _items = [];
  List<SavedItem> get items => _items;

  ReadingStatusCount get readingStatusCount => _provider.readingStatusCount;

  final log = Logger('HomePageViewModel');

  static const tabs = ['all', 'unread', 'reading', 'read'];

  final processItemsCommand = Command();

  int processItemsCallCount = 0;

  Future<void> processItems({bool reload = false}) async {
    if (processItemsCommand.running && !reload) return;

    processItemsCallCount++;
    log.info("$processItemsCallCount'th call to processItems");

    String? error;
    processItemsCommand.start();
    notifyListeners();

    if (!loadedData || reload) {
      error = await loadData(reload: reload);
    }

    _selectedTagIds.removeWhere((id) => !_provider.tags.containsKey(id));
    _items = _provider.items.values.toList();

    filterItems();
    sortItems();

    processItemsCommand.finish(error);
    notifyListeners();
  }

  Future<String?> loadData({bool reload = false}) async {
    _orderBy = OrderType.values.firstWhere(
      (type) => type.name == _prefsService.getOrderBy(),
      orElse: () => OrderType.creationDate,
    );
    _isDescending = _prefsService.getIsDescending() ?? true;

    _isGridView = _prefsService.getIsGridView() ?? false;

    loadedData = true;

    // don't notify listeners because that will call `processItems` again
    return await _provider.load(reload: reload, notify: false);
  }

  void sortItems() {
    // return if the previous ordering is the same as the current
    if (_items.length <= 1) return;

    int Function(SavedItem, SavedItem) comparator;

    switch (_orderBy) {
      case OrderType.creationDate:
        comparator = (a, b) => _isDescending
            ? b.createdAt.compareTo(a.createdAt)
            : a.createdAt.compareTo(b.createdAt);
        break;
      case OrderType.name:
        comparator = (a, b) {
          final nameA = a.title.toLowerCase();
          final nameB = b.title.toLowerCase();
          return _isDescending
              ? nameB.compareTo(nameA)
              : nameA.compareTo(nameB);
        };
        break;
    }

    if (_selectedTagIds.isNotEmpty) {
      _items.sort((a, b) {
        final aMatches = a.tags
            .where((id) => _selectedTagIds.contains(id))
            .length;
        final bMatches = b.tags
            .where((id) => _selectedTagIds.contains(id))
            .length;
        final matchCompare = bMatches.compareTo(aMatches);
        if (matchCompare != 0) {
          return matchCompare;
        }
        return comparator(a, b);
      });
    } else {
      _items.sort(comparator);
    }
  }

  void sortByCreationDate() {
    if (_isDescending) {
      _items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } else {
      _items.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    }
  }

  void sortByName() {
    if (_isDescending) {
      _items.sort((a, b) {
        final nameA = a.title.toLowerCase();
        final nameB = b.title.toLowerCase();
        return nameB.compareTo(nameA);
      });
    } else {
      _items.sort((a, b) {
        final nameA = a.title.toLowerCase();
        final nameB = b.title.toLowerCase();
        return nameA.compareTo(nameB);
      });
    }
  }

  // Filter items by status and/or selected tags
  void filterItems() {
    if (_filter != ReadingStatusFilterType.none) {
      _items = _items
          .where((item) => item.readingStatus.name == _filter.name)
          .toList();
    }

    if (_selectedTagIds.isNotEmpty) {
      _items = _items
          .where((item) => item.tags.any((id) => _selectedTagIds.contains(id)))
          .toList();
    }
  }

  void applyFilters({
    required ReadingStatusFilterType filter,
    required List<String> tagIds,
  }) {
    _filter = filter;
    _selectedTagIds = List.from(tagIds);
    processItems();
  }

  void setSelectedTagIds(List<String> tagIds) {
    _selectedTagIds = List.from(tagIds);
    processItems();
  }

  void removeTagFromFilter(String tagId) {
    if (_selectedTagIds.remove(tagId)) {
      processItems();
    }
  }

  void clearTagFilter() {
    if (_selectedTagIds.isEmpty) return;
    _selectedTagIds.clear();
    processItems();
  }

  void clearStatusFilter() {
    if (_filter == ReadingStatusFilterType.none) return;
    _filter = ReadingStatusFilterType.none;
    processItems();
  }

  void clearFilter() {
    if (_filter == ReadingStatusFilterType.none && _selectedTagIds.isEmpty) {
      return;
    }
    _filter = ReadingStatusFilterType.none;
    _selectedTagIds.clear();
    processItems();
  }

  void setFilter(ReadingStatusFilterType newFilter) {
    if (newFilter == _filter) return;
    _filter = newFilter;
    processItems();
  }

  // ! DELETE
  // void switchTab(int tabIndex) {
  //   final value = ReadingStatusFilterType.values[tabIndex];
  //   if (value == _filter) return;
  //
  //   _filter = value;
  //   processItems();
  // }

  Future<void> setOrderBy(OrderType value) async {
    if (value == _orderBy) return;

    _orderBy = value;
    processItems();

    await _prefsService.setOrderBy(value.name);
  }

  void setSorting(OrderType orderBy, bool isDescending) {
    bool changedOne = false;
    if (orderBy != _orderBy) {
      _orderBy = orderBy;
      unawaited(_prefsService.setOrderBy(orderBy.name));
      changedOne = true;
    }
    if (isDescending != _isDescending) {
      _isDescending = isDescending;
      unawaited(_prefsService.setIsDescending(isDescending));
      changedOne = true;
    }

    if (changedOne) {
      unawaited(processItems());
    }
  }

  // ! DELETE
  // Future<void> switchIsDescending() async {
  //   _isDescending = !_isDescending;
  //   notifyListeners();
  //
  //   await _prefsService.setIsDescending(_isDescending);
  // }

  Future<void> setIsGridView(bool value) async {
    if (value == _isGridView) return;

    _isGridView = value;
    notifyListeners();

    await _prefsService.setIsGridView(value);
  }

  void clearItems() {
    _items.clear();
  }
}

enum OrderType { creationDate, name }

enum ReadingStatusFilterType { none, unread, reading, read }

enum ViewType { list, grid }
