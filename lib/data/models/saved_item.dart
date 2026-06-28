import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logging/logging.dart';

class SavedItem {
  final String? id;
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
    this.id,
    required this.type,
    required this.readingStatus,
    this.uri,
    this.title,
    this.notes,
    this.remindReading,
    this.createdAt, // only pass this during fromFirestore
  });

  Map<String, dynamic> toFirestore({bool isEdit = false}) {
    return {
      if (id != null) 'id': id,
      'type': type.name,
      if (uri != null && uri!.toString().isNotEmpty) 'url': uri.toString(),
      'readingStatus': readingStatus.name,
      if (title != null && title!.isNotEmpty) 'title': title,
      if (notes != null && notes!.isNotEmpty) 'notes': notes,
      if (remindReading != null) 'remindReading': remindReading,
      // Only use this field on creation. If it's for updating, don't set this field:
      if (!isEdit) 'createdAt': FieldValue.serverTimestamp(),
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
      id: snapshot.id,
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

  @override
  String toString() {
    return 'id: $id,\ntype: $type,\nreadingStatus: $readingStatus,\nurl: $uri,\ntitle: $title,\nnotes: $notes,\nremindReading: $remindReading';
  }
}

enum ItemType { webpage } // TODO: Later add support for other types also

enum ReadingStatus { unread, reading, read }
