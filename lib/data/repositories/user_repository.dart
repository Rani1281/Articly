import 'package:articly/data/models/reading_status_count.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logging/logging.dart';

class UserRepository {
  UserRepository(DocumentReference<Map<String, dynamic>> userDoc)
    : _userDoc = userDoc;

  final DocumentReference<Map<String, dynamic>> _userDoc;

  final log = Logger('UserRepository');

  /// Fetches the user's reading count from Firestore and return an object of the counts.
  ///
  ///  If the user document doesn't exist, returns an empty object.
  Future<ReadingStatusCount> fetchReadingStatusCount() async {
    try {
      final docSnap = await _userDoc.get();

      if (!docSnap.exists) {
        return ReadingStatusCount();
      }

      return ReadingStatusCount.fromFirestore(docSnap, null);
    } catch (e) {
      log.severe(
        'An error occurred when trying to fetch the user reading counts:\n$e',
      );
    }

    return ReadingStatusCount();
  }

  /// Sets the value of the reading status counts in the user document.
  /// Use this method after counting them manually.
  Future<void> setReadingStatusCounts(
    ReadingStatusCount counts, {
    bool forceSync = false,
  }) async {
    try {
      await _userDoc.set({
        'readingStatusCount': counts.counts,
      }, SetOptions(merge: true));
      if (forceSync) {
        await setAreCountsSynced(true);
      }
      log.finest('Set the user readingStatus counts and is synced');
    } catch (e) {
      log.severe(
        'An error occurred while trying to set the new reading counts, raising flag:\n$e',
      );
      await setAreCountsSynced(false);
    }
  }

  Future<void> setAreCountsSynced(bool value) async {
    await _userDoc
        .set({'areCountsSynced': value}, SetOptions(merge: true))
        .onError((e, _) => log.severe('Failed to set areCountsSynced.\n$e'));
  }

  // takes in previousStatus and newStatus and increments the new reading status
  // while decrementing the previous (useful during editing). previousStatus can
  // be null to not decrement anything (useful when creating items). Also, the
  // newStatus can be null, which would lead to just decrementing the value from
  // the previous status (useful when deleting items).

  // /// Decrements the previous one, and increments the new one.
  // /// For adding a new item, don't pass `previousStatus`.
  // /// For deleting an item, don't pass `newStatus`.
  // /// For editing an item, pass both.
  // Future<void> changeCounts(
  //   ReadingStatus? previousStatus,
  //   ReadingStatus? newStatus,
  // ) async {
  //   await _userDoc.update({
  //     if (previousStatus != null)
  //       'readingStatusCount.${previousStatus.name}': FieldValue.increment(-1),
  //     if (newStatus != null)
  //       'readingStatusCount.${newStatus.name}': FieldValue.increment(1),
  //   });
  // }
}
