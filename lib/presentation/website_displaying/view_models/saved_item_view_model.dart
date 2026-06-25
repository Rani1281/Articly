import 'package:articly/utils/command.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
import 'package:url_launcher/url_launcher.dart';

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

  final Command openUrlCommand = Command();

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

    final success = await launchUrl(uri!);

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
}
