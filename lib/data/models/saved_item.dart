import 'package:cloud_firestore/cloud_firestore.dart';

class SavedItem {
  final ItemType type;
  final String? url; // for webpage
  final ReadingStatus readingStatus;
  final String? title;
  final String? notes;
  final bool? remindReading;
  final DateTime? createdAt; // only use when retrieving data

  SavedItem({
    required this.type,
    this.url,
    required this.readingStatus,
    this.title,
    this.notes,
    this.remindReading,
    this.createdAt, // only pass this during fromFirestore
  });

  Map<String, dynamic> toFirestore() {
    return {
      'type': type.name,
      'url': ?url,
      'readingStatus': readingStatus.name,
      'title': ?title,
      'notes': ?notes,
      'remindReading': ?remindReading,
      // Only use this field on creation. If it's for updating, don't set this field:
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  factory SavedItem.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data();
    return SavedItem(
      type: ItemType.values.firstWhere(
        (type) => type.name == data?['type'] as String?,
        orElse: () => ItemType.webpage,
      ),
      readingStatus: ReadingStatus.values.firstWhere(
        (status) => status.name == data?['readingStatus'] as String?,
        orElse: () => ReadingStatus.unread,
      ),
      url: data?['url'] as String?,
      title: data?['title'] as String?,
      notes: data?['notes'] as String?,
      remindReading: data?['remindReading'] as bool?,
      createdAt: (data?['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}

enum ItemType { webpage } // TODO: Later add support for other types also

enum ReadingStatus { unread, reading, read }
