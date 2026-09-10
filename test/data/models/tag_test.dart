import 'package:articly/data/models/tag.dart';
import 'package:checks/checks.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

// ignore: subtype_of_sealed_class
class MockDocumentSnapshot extends Mock
    implements DocumentSnapshot<Map<String, dynamic>> {}

void main() {
  group('Tag Model', () {
    test('constructs correctly with given fields', () {
      final now = DateTime(2025, 1, 1);
      final tag = Tag(id: 'flutter', name: 'Flutter', createdAt: now);

      check(tag.id).equals('flutter');
      check(tag.name).equals('Flutter');
      check(tag.createdAt).equals(now);
    });

    test('normalizes name correctly', () {
      check(Tag.normalize('  Machine   Learning  ')).equals('machine_learning');
      check(Tag.normalize('AI/ML')).equals('ai_ml');
      check(Tag.normalize('FLUTTER')).equals('flutter');

      final tag = Tag(id: 'test', name: 'Web Dev');
      check(tag.normalize_name()).equals('web_dev');
      check(tag.normalizeName()).equals('web_dev');
    });

    test('toFirestore includes createdAt when isEdit is false', () {
      final now = DateTime(2025, 1, 1);
      final tag = Tag(id: 'flutter', name: 'Flutter', createdAt: now);

      final map = tag.toFirestore(isEdit: false);
      check(map['name']).equals('Flutter');
      check(map['createdAt']).isA<Timestamp>();
    });

    test('toFirestore excludes createdAt when isEdit is true', () {
      final now = DateTime(2025, 1, 1);
      final tag = Tag(id: 'flutter', name: 'Flutter', createdAt: now);

      final map = tag.toFirestore(isEdit: true);
      check(map['name']).equals('Flutter');
      check(map.containsKey('createdAt')).isFalse();
    });

    test('fromFirestore parses DocumentSnapshot correctly', () {
      final mockSnapshot = MockDocumentSnapshot();
      final now = DateTime(2025, 1, 1);

      when(() => mockSnapshot.id).thenReturn('flutter');
      when(
        () => mockSnapshot.data(),
      ).thenReturn({'name': 'Flutter', 'createdAt': Timestamp.fromDate(now)});

      final tag = Tag.fromFirestore(mockSnapshot);
      check(tag.id).equals('flutter');
      check(tag.name).equals('Flutter');
      check(tag.createdAt).equals(now);
    });

    test('copyWith updates specified fields', () {
      final tag = Tag(id: 't1', name: 'Tag 1');
      final updated = tag.copyWith(name: 'Tag One');

      check(updated.id).equals('t1');
      check(updated.name).equals('Tag One');
    });

    test('equality and hashCode works', () {
      final tag1 = Tag(id: 't1', name: 'Tag 1');
      final tag2 = Tag(id: 't1', name: 'Tag 1');
      final tag3 = Tag(id: 't2', name: 'Tag 2');

      check(tag1 == tag2).isTrue();
      check(tag1 == tag3).isFalse();
      check(tag1.hashCode).equals(tag2.hashCode);
    });
  });
}
