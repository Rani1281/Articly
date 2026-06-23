import 'package:articly/data/models/saved_item.dart';
import 'package:articly/data/repositories/saved_items_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:checks/checks.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockUser extends Mock implements User {}

class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}

class MockCollectionReference extends Mock
    implements CollectionReference<Map<String, dynamic>> {}

class MockDocumentReference extends Mock
    implements DocumentReference<Map<String, dynamic>> {}

class MockQuerySnapshot extends Mock
    implements QuerySnapshot<Map<String, dynamic>> {}

class MockQueryDocumentSnapshot extends Mock
    implements QueryDocumentSnapshot<Map<String, dynamic>> {}

void main() {
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

  group('fetchItems', () {
    test('throws an exception if the user is not authenticated', () async {
      when(() => mockAuth.currentUser).thenReturn(null);

      check(repository.fetchItems()).throws<Exception>((exception) {
        exception
            .has((e) => e.toString(), 'message')
            .contains('not authenticated');
      });
    });

    test(
      'returns a Map<String, SavedItem> where keys are Firestore document ids',
      () async {
        final usersCollection = MockCollectionReference();
        final userDoc = MockDocumentReference();
        final savedItemsCollection = MockCollectionReference();
        final querySnapshot = MockQuerySnapshot();
        final doc1 = MockQueryDocumentSnapshot();
        final doc2 = MockQueryDocumentSnapshot();

        when(() => mockAuth.currentUser).thenReturn(mockUser);
        when(() => mockUser.uid).thenReturn('test-uid');
        when(() => mockDb.collection('users')).thenReturn(usersCollection);
        when(() => usersCollection.doc('test-uid')).thenReturn(userDoc);
        when(
          () => userDoc.collection('savedItems'),
        ).thenReturn(savedItemsCollection);
        when(
          () => savedItemsCollection.get(),
        ).thenAnswer((_) async => querySnapshot);
        when(() => querySnapshot.docs).thenReturn([doc1, doc2]);
        when(() => doc1.id).thenReturn('doc-id-1');
        when(() => doc1.data()).thenReturn(<String, dynamic>{
          'type': 'webpage',
          'url': 'https://example.com/1',
          'readingStatus': 'unread',
        });
        when(() => doc2.id).thenReturn('doc-id-2');
        when(() => doc2.data()).thenReturn(<String, dynamic>{
          'type': 'webpage',
          'url': 'https://example.com/2',
          'readingStatus': 'read',
        });

        final result = await repository.fetchItems();

        check(result.length).equals(2);
        check(result.containsKey('doc-id-1')).isTrue();
        check(result.containsKey('doc-id-2')).isTrue();
        check(result['doc-id-1']!.uri).equals(
          Uri.parse('https://example.com/1'),
        );
        check(result['doc-id-1']!.readingStatus).equals(ReadingStatus.unread);
        check(result['doc-id-2']!.uri).equals(
          Uri.parse('https://example.com/2'),
        );
        check(result['doc-id-2']!.readingStatus).equals(ReadingStatus.read);
      },
    );
  });
}
