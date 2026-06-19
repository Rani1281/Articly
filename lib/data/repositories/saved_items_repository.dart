import 'package:articly/data/models/saved_item.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logging/logging.dart';

class SavedItemsRepository {
  SavedItemsRepository({FirebaseFirestore? db, FirebaseAuth? auth})
    : _db = db ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  final usersCollection = 'users';
  final savedItemsCollection = 'savedItems';

  final log = Logger('SavedItemsRepository');

  // Returns the path where the item was saved
  Future<String> saveItem(SavedItem item) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception(
        'The user is not authenticated, so can\'t save the item under his name',
      );
    }

    final docRef = await _db
        .collection(usersCollection)
        .doc(user.uid)
        .collection(savedItemsCollection)
        .add(item.toFirestore());

    return docRef.path;
  }
}
