import 'package:articly/data/models/tag.dart';
import 'package:articly/data/repositories/tags_repository.dart';
import 'package:checks/checks.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

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
class MockDocumentSnapshot extends Mock
    implements DocumentSnapshot<Map<String, dynamic>> {}

void main() {
  late TagsRepository repository;
  late MockCollectionReference mockTagsCollection;

  setUp(() {
    mockTagsCollection = MockCollectionReference();
    repository = TagsRepository(mockTagsCollection);
  });

  group('TagsRepository', () {
    group('load', () {
      test('returns Map<String, Tag> of all tags in collection', () async {
        final mockQuerySnapshot = MockQuerySnapshot();
        final docSnap1 = MockQueryDocumentSnapshot();
        final docSnap2 = MockQueryDocumentSnapshot();

        when(
          () => mockTagsCollection.get(),
        ).thenAnswer((_) async => mockQuerySnapshot);
        when(() => mockQuerySnapshot.docs).thenReturn([docSnap1, docSnap2]);

        when(() => docSnap1.id).thenReturn('flutter');
        when(() => docSnap1.data()).thenReturn({'name': 'Flutter'});

        when(() => docSnap2.id).thenReturn('dart');
        when(() => docSnap2.data()).thenReturn({'name': 'Dart'});

        final result = await repository.load();

        check(result.length).equals(2);
        check(result['flutter']?.name).equals('Flutter');
        check(result['dart']?.name).equals('Dart');
      });
    });

    group('create', () {
      test('throws exception if tag name is empty', () async {
        final tag = Tag(name: '   ');
        await check(repository.create(tag)).throws<Exception>();
      });

      test(
        'throws exception if tag with same name already exists in database',
        () async {
          final mockQuerySnapshot = MockQuerySnapshot();
          final docSnap = MockQueryDocumentSnapshot();

          when(
            () => mockTagsCollection.get(),
          ).thenAnswer((_) async => mockQuerySnapshot);
          when(() => mockQuerySnapshot.docs).thenReturn([docSnap]);
          when(() => docSnap.data()).thenReturn({'name': 'Flutter'});

          final tag = Tag(name: 'flutter');

          await check(repository.create(tag)).throws<Exception>();
          verifyNever(() => mockTagsCollection.doc(any()));
        },
      );

      test(
        'creates tag document with auto-generated id if it does not exist yet',
        () async {
          final mockQuerySnapshot = MockQuerySnapshot();
          final mockDocRef = MockDocumentReference();

          when(
            () => mockTagsCollection.get(),
          ).thenAnswer((_) async => mockQuerySnapshot);
          when(() => mockQuerySnapshot.docs).thenReturn([]);
          when(() => mockTagsCollection.doc()).thenReturn(mockDocRef);
          when(() => mockDocRef.id).thenReturn('random_id_123');
          when(() => mockDocRef.set(any())).thenAnswer((_) async {});

          final tag = Tag(name: 'Flutter');

          final id = await repository.create(tag);
          check(id).equals('random_id_123');
          verify(() => mockDocRef.set(any())).called(1);
        },
      );

      test('creates tag document with specified id if provided', () async {
        final mockQuerySnapshot = MockQuerySnapshot();
        final mockDocRef = MockDocumentReference();

        when(
          () => mockTagsCollection.get(),
        ).thenAnswer((_) async => mockQuerySnapshot);
        when(() => mockQuerySnapshot.docs).thenReturn([]);
        when(() => mockTagsCollection.doc('custom_id')).thenReturn(mockDocRef);
        when(() => mockDocRef.id).thenReturn('custom_id');
        when(() => mockDocRef.set(any())).thenAnswer((_) async {});

        final tag = Tag(id: 'custom_id', name: 'Flutter');

        final id = await repository.create(tag);
        check(id).equals('custom_id');
        verify(() => mockDocRef.set(any())).called(1);
      });
    });

    group('update', () {
      test('throws exception if tag id is empty', () async {
        final tag = Tag(id: '', name: 'Empty');
        await check(repository.update(tag)).throws<Exception>();
      });

      test('updates tag document in Firestore', () async {
        final mockDocRef = MockDocumentReference();
        when(() => mockTagsCollection.doc('flutter')).thenReturn(mockDocRef);
        when(() => mockDocRef.update(any())).thenAnswer((_) async {});

        final tag = Tag(id: 'flutter', name: 'Flutter Dev');
        await repository.update(tag);

        verify(() => mockDocRef.update(any())).called(1);
      });
    });

    group('delete', () {
      test('throws exception if id is empty', () async {
        await check(repository.delete('')).throws<Exception>();
      });

      test('deletes document in Firestore', () async {
        final mockDocRef = MockDocumentReference();
        when(() => mockTagsCollection.doc('flutter')).thenReturn(mockDocRef);
        when(() => mockDocRef.delete()).thenAnswer((_) async {});

        await repository.delete('flutter');

        verify(() => mockDocRef.delete()).called(1);
      });
    });
  });
}
