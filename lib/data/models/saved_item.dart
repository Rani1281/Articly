import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logging/logging.dart';

class SavedItem {
  final ItemType type;
  // final String? url; // for webpage
  final ReadingStatus readingStatus;
  final Uri? uri;
  final String? title;
  final String? notes;
  final bool? remindReading;
  final DateTime? createdAt; // only use when retrieving data

  final log = Logger('SavedItem');

  SavedItem({
    required this.type,
    required this.readingStatus,
    this.uri,
    this.title,
    this.notes,
    this.remindReading,
    this.createdAt, // only pass this during fromFirestore
  });

  Map<String, dynamic> toFirestore() {
    return {
      'type': type.name,
      if (uri != null && uri!.toString().isNotEmpty) 'url': uri.toString(),
      'readingStatus': readingStatus.name,
      if (title != null && title!.isNotEmpty) 'title': title,
      if (notes != null && notes!.isNotEmpty) 'notes': notes,
      if (remindReading != null) 'remindReading': remindReading,
      // Only use this field on creation. If it's for updating, don't set this field:
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  factory SavedItem.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data();
    final url = data?['url'] as String?;
    Uri? uri;
    if (url != null) {
      try {
        uri = Uri.parse(url);
      } on FormatException catch (e) {
        Logger('SavedItem').severe(
          'Couldn\'t parse the given url from Firestore.\nUrl:$url\nError: $e',
        );
      }
    }
    return SavedItem(
      type: ItemType.values.firstWhere(
        (type) => type.name == data?['type'] as String?,
        orElse: () => ItemType.webpage,
      ),
      readingStatus: ReadingStatus.values.firstWhere(
        (status) => status.name == data?['readingStatus'] as String?,
        orElse: () => ReadingStatus.unread,
      ),
      uri: uri,
      title: data?['title'] as String?,
      notes: data?['notes'] as String?,
      remindReading: data?['remindReading'] as bool?,
      createdAt: (data?['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}

enum ItemType { webpage } // TODO: Later add support for other types also

enum ReadingStatus { unread, reading, read }
