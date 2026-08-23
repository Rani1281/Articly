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

// ignore: subtype_of_sealed_class
class MockCollectionReference extends Mock
    implements CollectionReference<Map<String, dynamic>> {}

// ignore: subtype_of_sealed_class
class MockDocumentReference extends Mock
    implements DocumentReference<Map<String, dynamic>> {}

// ignore: subtype_of_sealed_class
class MockQuerySnapshot extends Mock
    implements QuerySnapshot<Map<String, dynamic>> {}

// ignore: subtype_of_sealed_class
class MockQueryDocumentSnapshot extends Mock
    implements QueryDocumentSnapshot<Map<String, dynamic>> {}

// ignore: subtype_of_sealed_class
class MockQuery extends Mock implements Query<Map<String, dynamic>> {}

void main() {
  late SavedItemsRepository repository;
  late MockCollectionReference mockItemsCollection;

  setUp(() {
    mockItemsCollection = MockCollectionReference();
    repository = SavedItemsRepository(mockItemsCollection);
  });

  group('fetchItems', () {
    test(
      'returns a Map<String, SavedItem> where keys are Firestore document ids',
      () async {
        final mockQuerySnapshot = MockQuerySnapshot();
        final queryDocSnap1 = MockQueryDocumentSnapshot();
        final queryDocSnap2 = MockQueryDocumentSnapshot();

        when(
          () => mockItemsCollection.get(),
        ).thenAnswer((_) async => mockQuerySnapshot);
        when(
          () => mockQuerySnapshot.docs,
        ).thenReturn([queryDocSnap1, queryDocSnap2]);
        when(() => queryDocSnap1.id).thenReturn('doc-id-1');
        when(() => queryDocSnap2.id).thenReturn('doc-id-2');

        when(() => queryDocSnap1.data()).thenReturn({
          'url': 'https://example.com/1',
          'readingStatus': 'unread',
        });
        when(
          () => queryDocSnap2.data(),
        ).thenReturn({'url': 'https://example.com/2', 'readingStatus': 'read'});

        final result = await repository.fetchItems();

        check(result.length).equals(2);
        check(result.containsKey('doc-id-1')).isTrue();
        check(result.containsKey('doc-id-2')).isTrue();
        check(
          result['doc-id-1']!.uri,
        ).equals(Uri.parse('https://example.com/1'));
        check(result['doc-id-1']!.readingStatus).equals(ReadingStatus.unread);
        check(
          result['doc-id-2']!.uri,
        ).equals(Uri.parse('https://example.com/2'));
        check(result['doc-id-2']!.readingStatus).equals(ReadingStatus.read);
      },
    );
  });

  group('saveItem', () {
    test('returns the document id on success', () async {
      final addedDoc = MockDocumentReference();
      final expectedId = '123';

      when(
        () => mockItemsCollection.add(any()),
      ).thenAnswer((_) async => addedDoc);
      when(() => addedDoc.id).thenReturn(expectedId);

      final item = SavedItem(
        type: ItemType.webpage,
        readingStatus: ReadingStatus.unread,
        uri: Uri.parse(''),
      );

      final result = await repository.addItem(item);

      check(result).equals(expectedId);
    });
  });

  group('updateItem', () {
    test('throws an exception if the item id is null', () async {
      final item = SavedItem(
        type: ItemType.webpage,
        readingStatus: ReadingStatus.unread,
        uri: Uri.parse(''),
      );

      expect(
        () async => await repository.updateItem(item),
        throwsA(isA<Exception>()),
      );
    });

    test('throws an exception if the item id is empty', () async {
      final item = SavedItem(
        id: '',
        type: ItemType.webpage,
        readingStatus: ReadingStatus.unread,
        uri: Uri.parse(''),
      );

      expect(
        () async => await repository.updateItem(item),
        throwsA(isA<Exception>()),
      );
    });

    test('updates the item document in Firestore', () async {
      final itemDoc = MockDocumentReference();

      when(() => mockItemsCollection.doc('item-id-123')).thenReturn(itemDoc);
      when(() => itemDoc.update(any())).thenAnswer((_) async {});

      final item = SavedItem(
        id: 'item-id-123',
        type: ItemType.webpage,
        readingStatus: ReadingStatus.unread,
        uri: Uri.parse(''),
      );

      await repository.updateItem(item);

      verify(() => itemDoc.update(any())).called(1);
    });
  });

  group('deleteItem', () {
    test('should throw an exception if the id is empty', () {
      expect(
        () async => await repository.deleteItem(''),
        throwsA(isA<Exception>()),
      );
    });

    test('should call .delete on the document reference', () async {
      final itemDoc = MockDocumentReference();

      when(() => mockItemsCollection.doc('item-id-123')).thenReturn(itemDoc);
      when(() => itemDoc.delete()).thenAnswer((_) async {});

      await repository.deleteItem('item-id-123');

      verify(() => itemDoc.delete()).called(1);
    });
  });
}
