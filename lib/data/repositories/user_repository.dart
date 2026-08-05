import 'package:articly/data/models/reading_status_count.dart';
import 'package:articly/data/models/saved_item.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserRepository {
  UserRepository(DocumentReference<Map<String, dynamic>> userDoc)
    : _userDoc = userDoc;

  final DocumentReference<Map<String, dynamic>> _userDoc;

  /// Fetches the user's reading count from Firestore and return a ReadingStatusCount object.
  ///
  ///  If the user document doesn't exist, returns the object with zeros.
  Future<ReadingStatusCount> fetchReadingStatusCount() async {
    final docSnap = await _userDoc.get();

    if (!docSnap.exists) {
      return ReadingStatusCount.zeros();
    }

    return ReadingStatusCount.fromFirestore(docSnap, null);
  }

  /// Sets the value of the reading status counts in the user document.
  /// Use this method after counting them manually.
  Future<void> setReadingStatusCounts(ReadingStatusCount counts) async {
    await _userDoc.set(counts.toFirestore());
  }

  // takes in previousStatus and newStatus and increments the new reading status
  // while decrementing the previous (useful during editing). previousStatus can
  // be null to not decrement anything (useful when creating items). Also, the
  // newStatus can be null, which would lead to just decrementing the value from
  // the previous status (useful when deleting items).

  /// Decrements the previous one, and increments the new one.
  /// For adding a new item, don't pass `previousStatus`.
  /// For deleting an item, don't pass `newStatus`.
  /// For editing an item, pass both.
  Future<void> changeCounts(
    ReadingStatus? previousStatus,
    ReadingStatus? newStatus,
  ) async {
    await _userDoc.update({
      if (previousStatus != null)
        'readingStatusCount.${previousStatus.name}': FieldValue.increment(-1),
      if (newStatus != null)
        'readingStatusCount.${newStatus.name}': FieldValue.increment(1),
    });
  }
}
