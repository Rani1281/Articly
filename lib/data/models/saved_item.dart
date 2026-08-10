import 'package:articly/config/config.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logging/logging.dart';

class SavedItem {
  final String? id;
  final ItemType type;
  final ReadingStatus readingStatus;
  final Uri uri;
  final String title;
  final String notes;
  final bool remindReading;
  final String? imageUrl;
  final String? faviconUrl;
  final DateTime createdAt;

  final log = Logger('SavedItem');

  SavedItem({
    this.id,
    required this.type,
    required this.uri,
    this.title = defaultTitleName,
    required this.readingStatus,
    this.notes = '',
    this.remindReading = false,
    this.imageUrl,
    this.faviconUrl,
    DateTime? createdAt, // only pass this during fromFirestore
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toFirestore({bool isEdit = false}) {
    return {
      // if (id != null) 'id': id,
      'type': type.name,
      if (uri.toString().isNotEmpty) 'url': uri.toString(),
      'readingStatus': readingStatus.name,
      if (title.isNotEmpty) 'title': title,
      if (notes.isNotEmpty) 'notes': notes,
      'remindReading': remindReading,
      if (imageUrl != null && imageUrl!.isNotEmpty) 'imageUrl': imageUrl,
      if (faviconUrl != null && faviconUrl!.isNotEmpty)
        'faviconUrl': faviconUrl,
      // Only use this field on creation. If it's for updating, don't set this field:
      if (!isEdit) 'createdAt': Timestamp.fromDate(createdAt),
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
      uri: uri ?? Uri.parse(''),
      title: data?['title'] as String? ?? defaultTitleName,
      notes: data?['notes'] as String? ?? '',
      remindReading: data?['remindReading'] as bool? ?? false,
      imageUrl: data?['imageUrl'] as String?,
      faviconUrl: data?['faviconUrl'] as String?,
      createdAt: (data?['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  SavedItem copyWith({
    String? id,
    ItemType? type,
    ReadingStatus? readingStatus,
    Uri? uri,
    String? title,
    String? notes,
    bool? remindReading,
    String? imageUrl,
    String? faviconUrl,
    DateTime? createdAt,
  }) {
    return SavedItem(
      id: id ?? this.id,
      type: type ?? this.type,
      readingStatus: readingStatus ?? this.readingStatus,
      uri: uri ?? this.uri,
      title: title ?? this.title,
      notes: notes ?? this.notes,
      remindReading: remindReading ?? this.remindReading,
      imageUrl: imageUrl ?? this.imageUrl,
      faviconUrl: faviconUrl ?? this.faviconUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'id: $id,\ntype: $type,\nreadingStatus: $readingStatus,\nurl: $uri,'
        '\ntitle: $title,\nnotes: $notes,\nremindReading: $remindReading, '
        '\nimageUrl: $imageUrl, \nfaviconUrl: $faviconUrl';
  }
}

enum ItemType { webpage } // TODO: Later add support for other types also

enum ReadingStatus { unread, reading, read }
