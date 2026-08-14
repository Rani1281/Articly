import 'package:articly/data/models/saved_item.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logging/logging.dart';

class SavedItemsRepository {
  SavedItemsRepository(
    CollectionReference<Map<String, dynamic>> savedItemsCollection,
  ) : _savedItemsCollection = savedItemsCollection;

  final CollectionReference<Map<String, dynamic>> _savedItemsCollection;

  final log = Logger('SavedItemsRepository');

  // Returns the id of the added document
  Future<String> addItem(SavedItem item) async {
    final docRef = await _savedItemsCollection.add(item.toFirestore());
    return docRef.id;
  }

  /// Returns a result map where the key is the Firestore id and the value is the saved item, sorted by createdAt (oldest dates first). For example:
  ///
  /// ``{'123': SavedItem(...), '456': SavedItem(...)}``
  Future<Map<String, SavedItem>> fetchItems() async {
    final querySnap = await _savedItemsCollection.get();

    return Map<String, SavedItem>.fromEntries(
      querySnap.docs.map(
        (querySnap) =>
            MapEntry(querySnap.id, SavedItem.fromFirestore(querySnap, null)),
      ),
    );
  }

  Future<void> updateItem(SavedItem item) async {
    if (item.id == null || item.id!.isEmpty) {
      throw Exception(
        'Can\'t proceed to updating the item in Firestore because the id of the item is null or empty.',
      );
    }
    await _savedItemsCollection
        .doc(item.id)
        .update(item.toFirestore(isEdit: true));
  }

  /// Receives the items Firestore id
  Future<void> deleteItem(String id) async {
    if (id.isEmpty) {
      throw Exception(
        'Can\'t proceed to updating the item in Firestore because the id of the item is empty.',
      );
    }
    await _savedItemsCollection.doc(id).delete();
  }
}
