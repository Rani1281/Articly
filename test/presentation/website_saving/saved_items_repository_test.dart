import 'package:articly/data/repositories/saved_items_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockUser extends Mock implements User {}

class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}

class MockCollectionReference extends Mock
    implements CollectionReference<Map<String, dynamic>> {}

class MockDocumentReference extends Mock
    implements DocumentReference<Map<String, dynamic>> {}

void main() {
  group('SavedItemsRepository', () {
    late SavedItemsRepository repository;
    late MockFirebaseAuth mockAuth;
    late MockFirebaseFirestore mockDb;
    late MockUser mockUser;

    setUp(() {
      mockAuth = MockFirebaseAuth();
      mockDb = MockFirebaseFirestore();
      mockUser = MockUser();
      repository = SavedItemsRepository(db: mockDb, auth: mockAuth);
    });
  });
}
