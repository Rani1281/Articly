import 'package:articly/data/models/tag.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logging/logging.dart';

class TagsRepository {
  TagsRepository(CollectionReference<Map<String, dynamic>> tagsCollection)
    : _tagsCollection = tagsCollection;

  final CollectionReference<Map<String, dynamic>> _tagsCollection;

  final log = Logger('TagsRepository');

  /// Returns a map where the key is the Firestore id and the value is the tag (unordered)
  Future<Map<String, Tag>> load() async {
    final querySnap = await _tagsCollection.get();

    return Map<String, Tag>.fromEntries(
      querySnap.docs.map(
        (docSnap) => MapEntry(docSnap.id, Tag.fromFirestore(docSnap)),
      ),
    );
  }

  /// Creates a new tag document in the user's tag collection with a random id (or the provided id).
  /// Before creating a new document, checks in the database that no tag with the same normalized name already exists.
  Future<String> create(Tag tag) async {
    final normalized = Tag.normalize(tag.name);
    if (normalized.isEmpty) {
      throw Exception('Tag name cannot be empty.');
    }

    final querySnap = await _tagsCollection.get();
    final exists = querySnap.docs.any((doc) {
      final existingName = doc.data()['name'] as String? ?? '';
      return Tag.normalize(existingName) == normalized;
    });
    if (exists) {
      throw Exception('A tag with this name already exists.');
    }

    final docRef = tag.id.isNotEmpty
        ? _tagsCollection.doc(tag.id)
        : _tagsCollection.doc();
    await docRef.set(tag.toFirestore());
    return docRef.id;
  }

  /// Receives a tag and updates the document that has the id from the tag object.
  Future<void> update(Tag tag) async {
    if (tag.id.isEmpty) {
      throw Exception(
        'Can\'t proceed to updating the tag in Firestore because the id is empty.',
      );
    }
    await _tagsCollection.doc(tag.id).update(tag.toFirestore(isEdit: true));
  }

  /// Deletes the tag document that has the received id.
  Future<void> delete(String id) async {
    if (id.isEmpty) {
      throw Exception(
        'Can\'t proceed to deleting the tag in Firestore because the id is empty.',
      );
    }
    await _tagsCollection.doc(id).delete();
  }
}
