import 'package:articly/data/models/saved_item.dart';
import 'package:articly/data/services/shared_preferences_service.dart';
import 'package:articly/domain/providers/saved_items_provider.dart';
import 'package:articly/utils/command.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

class HomePageViewModel extends ChangeNotifier {
  HomePageViewModel({
    required SavedItemsProvider provider,
    required SharedPreferencesService prefsService,
  }) : _provider = provider,
       _prefsService = prefsService {
    // listen to the provider to re-process items after they have changed
    _provider.addListener(() => processItems());
  }

  final SavedItemsProvider _provider;
  SavedItemsProvider get provider => _provider;
  final SharedPreferencesService _prefsService;

  bool loadedData = false;

  OrderType _orderBy = OrderType.creationDate;
  OrderType get orderBy => _orderBy;

  OrderType? _prevOrderBy;

  bool _isDescending = true;
  bool get isDescending => _isDescending;

  FilterType _filter = FilterType.none;

  final log = Logger('HomePageViewModel');

  static const tabs = ['all', 'unread', 'reading', 'read'];

  List<SavedItem> _items = [];
  List<SavedItem> get items => _items;

  final processItemsCommand = Command();

  Future<void> processItems({bool reload = false}) async {
    String? error;
    processItemsCommand.start();
    notifyListeners();

    if (!loadedData || reload) {
      error = await loadData();
      loadedData = true;
    }

    _items = _provider.items.values.toList();

    sortItems();
    filterItems();

    processItemsCommand.finish(error);
    notifyListeners();
  }

  Future<String?> loadData() async {
    _orderBy = OrderType.values.firstWhere(
      (type) => type.name == _prefsService.getOrderBy(),
      orElse: () => OrderType.creationDate,
    );
    _isDescending = _prefsService.getIsDescending() ?? true;

    // don't notify listeners because that will call `processItems` again
    return await _provider.load(notify: false);
  }

  void sortItems() {
    // return if the previous ordering is the same as the current
    if (_items.length <= 1) return;

    if (_prevOrderBy == _orderBy) {
      return;
    }

    switch (_orderBy) {
      case OrderType.creationDate:
        sortByCreationDate();
        break;
      case OrderType.name:
        sortByName();
        break;
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
  void filterItems() {
    if (_filter == FilterType.none) return;

    _items = _items
        .where((item) => item.readingStatus.name == _filter.name)
        .toList();
  }

  void switchTab(int tabIndex) {
    final value = FilterType.values[tabIndex];
    if (value == _filter) return;

    _filter = value;
    notifyListeners();
  }

  Future<void> setOrderBy(OrderType value) async {
    if (value == _orderBy) return;

    _prevOrderBy = _orderBy;
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
