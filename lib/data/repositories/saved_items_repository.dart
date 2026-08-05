import 'package:articly/data/models/saved_item.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logging/logging.dart';

class SavedItemsRepository {
  SavedItemsRepository(
    CollectionReference<Map<String, dynamic>> savedItemsCollection,
    // FirebaseAuth? auth,
  ) : _savedItemsCollection = savedItemsCollection;

  final CollectionReference<Map<String, dynamic>> _savedItemsCollection;

  final log = Logger('SavedItemsRepository');

  // Returns the id of the added document
  Future<String> addItem(SavedItem item) async {
    // final user = _auth.currentUser;
    // if (user == null) {
    //   throw Exception(
    //     'The user is not authenticated, so can\'t save the item under his name',
    //   );
    // }
    //
    // final docRef = await _db
    //     .collection(usersCollection)
    //     .doc(user.uid)
    //     .collection(savedItemsCollection)
    //     .add(item.toFirestore());

    final docRef = await _savedItemsCollection.add(item.toFirestore());
    return docRef.id;
  }

  /// Returns a result map where the key is the Firestore id and the value is the saved item, sorted by createdAt (oldest dates first). For example:
  ///
  /// ``{'123': SavedItem(...), '456': SavedItem(...)}``
  Future<Map<String, SavedItem>> fetchItems() async {
    // final user = _auth.currentUser;
    // if (user == null) {
    //   throw Exception(
    //     'The user is not authenticated, so can\'t save the item under his name',
    //   );
    // }
    //
    // final querySnap = await _db
    //     .collection(usersCollection)
    //     .doc(user.uid)
    //     .collection(savedItemsCollection)
    //     .get();
    // Note: this won't create a user document if it doesn't exist yet.

    final querySnap = await _savedItemsCollection.get();

    return Map<String, SavedItem>.fromEntries(
      querySnap.docs.map(
        (querySnap) =>
            MapEntry(querySnap.id, SavedItem.fromFirestore(querySnap, null)),
      ),
    );
  }

  Future<void> updateItem(SavedItem item) async {
    // final user = _auth.currentUser;
    // if (user == null) {
    //   throw Exception(
    //     'The user is not authenticated, so can\'t save the item under his name',
    //   );
    // }

    if (item.id == null || item.id!.isEmpty) {
      throw Exception(
        'Can\'t proceed to updating the item in Firestore because the id of the item is null or empty.',
      );
    }
    //
    // await _db
    //     .collection(usersCollection)
    //     .doc(user.uid)
    //     .collection(savedItemsCollection)
    //     .doc(item.id)
    //     .update(item.toFirestore(isEdit: true));
    // isEdit = true to not change createdAt

    await _savedItemsCollection
        .doc(item.id)
        .update(item.toFirestore(isEdit: true));
  }

  /// Receives the items Firestore id
  Future<void> deleteItem(String id) async {
    // final user = _auth.currentUser;
    // if (user == null) {
    //   throw Exception(
    //     'The user is not authenticated, so can\'t delete the item under his name',
    //   );
    // }

    if (id.isEmpty) {
      throw Exception(
        'Can\'t proceed to updating the item in Firestore because the id of the item is empty.',
      );
    }

    // await _db
    //     .collection(usersCollection)
    //     .doc(user.uid)
    //     .collection(savedItemsCollection)
    //     .doc(id)
    //     .delete();

    await _savedItemsCollection.doc(id).delete();
  }
}
