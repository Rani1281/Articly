import 'package:articly/data/models/saved_item.dart';
import 'package:articly/domain/providers/saved_items_provider.dart';
import 'package:articly/utils/command.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
import 'package:url_launcher/url_launcher.dart';

class SavedItemViewModel extends ChangeNotifier {
  SavedItemViewModel({
    required SavedItem currentItem,
    required SavedItemsProvider provider,
  }) : _currentItem = currentItem,
       _provider = provider {
    title = _currentItem.title;
    uri = _currentItem.uri;
    notes = _currentItem.notes;
  }

  SavedItem _currentItem;

  SavedItem get currentItem => _currentItem;

  set currentItem(SavedItem newItem) {
    _currentItem = newItem;
    title = _currentItem.title;
    uri = _currentItem.uri;
    notes = _currentItem.notes;
    notifyListeners();
  }

  late String? title;
  late Uri? uri;
  late String? notes;
  bool _isExpanded = false;
  bool get isExpanded => _isExpanded;

  bool _isVisible = true;
  bool get isVisible => _isVisible;
  set isVisible(bool value) {
    _isVisible = value;
    notifyListeners();
  }

  final SavedItemsProvider _provider;
  Command get deleteItemCommand => _provider.deleteCommand;

  final Command openUrlCommand = Command();

  // SavedItemsProvider getDeleteCommand(BuildContext context) {
  //   return Provider.of<SavedItemsProvider>(context);
  // }

  void toggleExpand() {
    _isExpanded = !_isExpanded;
    notifyListeners();
  }

  final log = Logger('HomePageViewModel');

  Future<void> copyContents() async {
    // Add to a list all existing
    final List<String> parts = [];
    if (title != null && title!.isNotEmpty) {
      parts.add(title!);
    }
    if (notes != null && notes!.isNotEmpty) {
      parts.add(notes!);
    }
    if (uri != null && uri!.toString().isNotEmpty) {
      parts.add('(${uri!.toString()})'); // add inside parentheses
    }

    // split the parts by a blank line
    final String content = parts.join('\n\n');

    await Clipboard.setData(ClipboardData(text: content));

    log.fine('Copied contents into the clipboard');
  }

  // A function that opens the URL in a web browser
  Future<void> openUrl() async {
    openUrlCommand.start();
    notifyListeners();

    if (!isUrlValid(uri)) {
      log.shout('Invalid url: $uri');
      openUrlCommand.finish(
        'Can\'t open the webpage because the url isn\'t valid',
      );
      notifyListeners();
      return Future.value();
    }

    final success = await launchUrl(uri!, mode: LaunchMode.externalApplication);

    if (!success) {
      log.warning('A problem occurred while trying to open the url: $uri');
      openUrlCommand.problem('Can\'t open the url');
      notifyListeners();
      return Future.value();
    }

    openUrlCommand.successful();
    notifyListeners();
  }

  // Returns true if the url is formatter correctly: uses "https" or "http" and is not empty
  bool isUrlValid(Uri? uri) {
    if (uri == null ||
        !uri.hasScheme ||
        !(uri.scheme == 'http' || uri.scheme == 'https') ||
        uri.host.isEmpty) {
      return false;
    }

    return true;
  }

  /// Delete the item in all places (UI, memory, Firestore)
  Future<void> deleteItem(String? itemId) async {
    if (itemId == null || itemId.isEmpty) {
      log.severe(
        'The current item\'s id is null or empty, so can\'t delete it...',
      );
      return Future.value();
    }

    // Make the item no longer visible in the UI
    _isVisible = false;
    notifyListeners();

    await _provider.delete(itemId);

    if (!deleteItemCommand.completed) {
      // revert the changes if failed
      _isVisible = true;
      notifyListeners();
    }
  }
}
