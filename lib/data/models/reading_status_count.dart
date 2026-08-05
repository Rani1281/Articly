import 'package:cloud_firestore/cloud_firestore.dart';

class ReadingStatusCount {
  const ReadingStatusCount({
    required this.unread,
    required this.reading,
    required this.read,
  });

  const ReadingStatusCount.zeros({
    this.unread = 0,
    this.reading = 0,
    this.read = 0,
  });

  final int unread;
  final int reading;
  final int read;

  /// returns the total amount of items counted so far
  int total() => unread + reading + read;

  Map<String, dynamic> toFirestore() {
    return {
      'readingStatusCount': {
        'unread': unread,
        'reading': reading,
        'read': read,
      },
    };
  }

  factory ReadingStatusCount.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data();
    final counts = data?['readingStatusCount'];
    return ReadingStatusCount(
      unread: counts?['unread'] as int? ?? 0,
      reading: counts?['reading'] as int? ?? 0,
      read: counts?['read'] as int? ?? 0,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ReadingStatusCount &&
        other.unread == unread &&
        other.reading == reading &&
        other.read == read;
  }

  @override
  int get hashCode => Object.hash(unread, reading, read);
}
