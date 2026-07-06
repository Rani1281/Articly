// import 'package:articly/data/models/saved_item.dart';
// import 'package:articly/domain/providers/saved_items_provider.dart';
// import 'package:articly/utils/command.dart';
// import 'package:flutter/material.dart';

// class HomePageViewModel extends ChangeNotifier {
//   HomePageViewModel({required SavedItemsProvider provider})
//     : _provider = provider;

//   final SavedItemsProvider _provider;
//   OrderType _orderBy = OrderType.creationDate;
//   bool _isDescending = true;
//   FilterType _filter = FilterType.none;

//   Command get loadCommand => _provider.loadCommand;

//   Future<Map<String, SavedItem>> getItems() {
//     // check if loaded already
//     // TODO: maybe add a "started" attribute
//     if (!loadCommand.running &&
//         !loadCommand.completed &&
//         loadCommand.error == null) {
//       // TODO: load configuration from SharedPreferences
//     }
//   }
// }

// enum OrderType { creationDate, name }

// enum FilterType { none, unread, reading, read }
