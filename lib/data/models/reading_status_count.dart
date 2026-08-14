import 'package:articly/data/models/saved_item.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ReadingStatusCount {
  ReadingStatusCount({Map<String, int>? counts, this.isSynced = true})
    : counts = counts ?? {'unread': 0, 'reading': 0, 'read': 0};

  final Map<String, int> counts;

  final bool isSynced;

  int get unread => counts['unread'] ?? 0;
  int get reading => counts['reading'] ?? 0;
  int get read => counts['read'] ?? 0;

  /// returns the total amount of items counted so far
  int total() => unread + reading + read;

  factory ReadingStatusCount.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data();
    final statusData = data?['readingStatusCount'] as Map<String, dynamic>?;

    Map<String, int>? converted;
    if (statusData != null && statusData.isNotEmpty) {
      converted = statusData.map((key, value) => MapEntry(key, value.toInt()));
    }
    return ReadingStatusCount(
      counts: converted,
      isSynced: data?['areCountsSynced'] as bool? ?? true,
    );
  }

  ReadingStatusCount copyWith({Map<String, int>? counts, bool? isSynced}) {
    return ReadingStatusCount(
      counts: counts ?? this.counts,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  void increment(ReadingStatus status) {
    if (counts.containsKey(status.name)) {
      counts[status.name] = counts[status.name]! + 1;
    }
  }

  void decrement(ReadingStatus status) {
    if (counts.containsKey(status.name) && counts[status.name]! > 0) {
      counts[status.name] = counts[status.name]! - 1;
    }
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
