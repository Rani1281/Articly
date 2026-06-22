import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';

class SavedItemViewModel extends ChangeNotifier {
  SavedItemViewModel({
    required this.title,
    required this.uri,
    required this.notes,
  });
  final String? title;
  final Uri? uri;
  final String? notes;
  bool _isExpanded = false;
  bool get isExpanded => _isExpanded;

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
}
