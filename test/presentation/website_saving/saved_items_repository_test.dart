import 'package:articly/data/models/saved_item.dart';
import 'package:articly/data/repositories/saved_items_repository.dart';
import 'package:checks/checks.dart';
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

    group('saveItem', () {
      test('throws an exception when no user is authenticated', () {
        when(() => mockAuth.currentUser).thenReturn(null);

        final item = SavedItem(
          type: ItemType.webpage,
          readingStatus: ReadingStatus.unread,
        );

        expect(
          () async => await repository.saveItem(item),
          throwsA(isA<Exception>()),
        );
      });

      test('returns the document path on success', () async {
        final usersCollection = MockCollectionReference();
        final userDoc = MockDocumentReference();
        final savedItemsCollection = MockCollectionReference();
        final addedDoc = MockDocumentReference();
        const expectedPath = 'users/test-uid/savedItems/abc123';

        when(() => mockAuth.currentUser).thenReturn(mockUser);
        when(() => mockUser.uid).thenReturn('test-uid');
        when(() => mockDb.collection('users')).thenReturn(usersCollection);
        when(() => usersCollection.doc('test-uid')).thenReturn(userDoc);
        when(
          () => userDoc.collection('savedItems'),
        ).thenReturn(savedItemsCollection);
        when(() => savedItemsCollection.add(any())).thenAnswer(
          (_) async => addedDoc,
        );
        when(() => addedDoc.path).thenReturn(expectedPath);

        final item = SavedItem(
          type: ItemType.webpage,
          readingStatus: ReadingStatus.unread,
          url: 'https://example.com',
        );

        final result = await repository.saveItem(item);

        check(result).equals(expectedPath);
      });
    });
  });
}
