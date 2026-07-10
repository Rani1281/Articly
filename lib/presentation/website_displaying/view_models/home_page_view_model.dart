import 'package:articly/data/models/saved_item.dart';
import 'package:articly/data/services/shared_preferences_service.dart';
import 'package:articly/domain/providers/saved_items_provider.dart';
import 'package:articly/utils/command.dart';
import 'package:flutter/material.dart';

class HomePageViewModel extends ChangeNotifier {
  HomePageViewModel({
    required SavedItemsProvider provider,
    required SharedPreferencesService prefsService,
  }) : _provider = provider,
       _prefsService = prefsService;

  final SavedItemsProvider _provider;
  SavedItemsProvider get provider => _provider;
  final SharedPreferencesService _prefsService;

  OrderType _orderBy = OrderType.creationDate;
  OrderType get orderBy => _orderBy;

  bool _isDescending = true;
  bool get isDescending => _isDescending;

  FilterType _filter = FilterType.none;

  static const tabs = ['all', 'unread', 'reading', 'read'];

  List<SavedItem> _items = [];
  List<SavedItem> get items => _items;

  final processItemsCommand = Command();

  Future<void> processItems({bool reload = false}) async {
    processItemsCommand.start();

    if (!_provider.loadCommand.activated || reload) {
      await _loadData();
    }

    _sortItems();
    _filterItems();

    processItemsCommand.finish(_provider.loadCommand.error);

    notifyListeners();
  }

  Future<void> _loadData() async {
    _orderBy = OrderType.values.firstWhere(
      (type) => type.name == _prefsService.getOrderBy(),
      orElse: () => OrderType.creationDate,
    );
    _isDescending = _prefsService.getIsDescending() ?? true;

    await _provider.load();
    _items = _provider.items.values.toList();
  }

  void _sortItems() {
    if (_items.length <= 1) return;

    switch (_orderBy) {
      case OrderType.creationDate:
        _sortByCreationDate();
        break;
      case OrderType.name:
        _sortByName();
        break;
    }
  }

  void _sortByCreationDate() {
    if (_isDescending) {
      _items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } else {
      _items.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    }
  }

  void _sortByName() {
    if (_isDescending) {
      _items.sort((a, b) {
        final nameA = a.title?.toLowerCase() ?? '';
        final nameB = b.title?.toLowerCase() ?? '';
        return nameB.compareTo(nameA);
      });
    } else {
      _items.sort((a, b) {
        final nameA = a.title?.toLowerCase() ?? '';
        final nameB = b.title?.toLowerCase() ?? '';
        return nameA.compareTo(nameB);
      });
    }
  }

  // Filter by by tab
  void _filterItems() {
    if (_filter == FilterType.none) return;

    _items = _items
        .where((item) => item.readingStatus.name == _filter.name)
        .toList();
  }

  void switchTab(int tabIndex) {
    // will work for "unread, reading, read" but for "all" will set to none
    _filter = FilterType.values[tabIndex];
    notifyListeners();
  }

  Future<void> setOrderBy(OrderType value) async {
    if (value == _orderBy) return;

    _orderBy = value;
    notifyListeners();

    await _prefsService.setOrderBy(value.name);
  }

  Future<void> switchIsDescending() async {
    _isDescending = !_isDescending;
    notifyListeners();

    await _prefsService.setIsDescending(_isDescending);
  }

  void clearItems() {
    _items.clear();
  }
}

enum OrderType { creationDate, name }

enum FilterType { none, unread, reading, read }
