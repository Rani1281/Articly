import 'package:articly/data/models/saved_item.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:checks/checks.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _MockDocumentSnapshot extends Mock
    implements DocumentSnapshot<Map<String, dynamic>> {}

void main() {
  group('SavedItem', () {
    group('constructor', () {
      test('correctly builds a SavedItem with all given values', () {
        final createdAt = DateTime(2024, 1, 1);
        final item = SavedItem(
          id: 'test-id-123',
          type: ItemType.webpage,
          uri: Uri.parse('https://example.com'),
          readingStatus: ReadingStatus.read,
          title: 'My Title',
          notes: 'My Notes',
          remindReading: true,
          createdAt: createdAt,
        );

        check(item.id).equals('test-id-123');
        check(item.type).equals(ItemType.webpage);
        check(item.uri).equals(Uri.parse('https://example.com'));
        check(item.readingStatus).equals(ReadingStatus.read);
        check(item.title).equals('My Title');
        check(item.notes).equals('My Notes');
        check(item.remindReading).equals(true);
        check(item.createdAt).equals(createdAt);
      });

      test('defaults ungiven optional fields to null', () {
        final item = SavedItem(
          type: ItemType.webpage,
          readingStatus: ReadingStatus.unread,
        );

        check(item.id).isNull();
        check(item.type).equals(ItemType.webpage);
        check(item.uri).isNull();
        check(item.readingStatus).equals(ReadingStatus.unread);
        check(item.title).isNull();
        check(item.notes).isNull();
        check(item.remindReading).isNull();
        check(item.createdAt).isNull();
      });
    });

    group('toFirestore', () {
      test('returns a map with all expected keys and correct types', () {
        final item = SavedItem(
          id: 'test-id',
          type: ItemType.webpage,
          uri: Uri.parse('https://example.com'),
          readingStatus: ReadingStatus.reading,
          title: 'Title',
          notes: 'Notes',
          remindReading: false,
        );

        final result = item.toFirestore();

        check(result.containsKey('id')).isTrue();
        check(result.containsKey('type')).isTrue();
        check(result.containsKey('url')).isTrue();
        check(result.containsKey('readingStatus')).isTrue();
        check(result.containsKey('title')).isTrue();
        check(result.containsKey('notes')).isTrue();
        check(result.containsKey('remindReading')).isTrue();
        check(result.containsKey('createdAt')).isTrue();

        check(result['id']).equals('test-id');
        check(result['type']).equals('webpage');
        check(result['url']).equals('https://example.com');
        check(result['readingStatus']).equals('reading');
        check(result['title']).equals('Title');
        check(result['notes']).equals('Notes');
        check(result['remindReading']).equals(false);
        check(result['createdAt']).isA<FieldValue>();
      });

      test('includes id in the map when it is non-null', () {
        final item = SavedItem(
          id: 'abc-123',
          type: ItemType.webpage,
          readingStatus: ReadingStatus.unread,
        );

        final result = item.toFirestore();

        check(result.containsKey('id')).isTrue();
        check(result['id']).equals('abc-123');
      });

      test('does not include id in the map when it is null', () {
        final item = SavedItem(
          type: ItemType.webpage,
          readingStatus: ReadingStatus.unread,
        );

        final result = item.toFirestore();

        check(result.containsKey('id')).isFalse();
      });

      test('always includes createdAt when isEdit is false', () {
        final item = SavedItem(
          type: ItemType.webpage,
          readingStatus: ReadingStatus.unread,
        );

        final result = item.toFirestore(isEdit: false);

        check(result.containsKey('createdAt')).isTrue();
        check(result['createdAt']).isA<FieldValue>();
      });

      test('does not include createdAt when isEdit is true', () {
        final item = SavedItem(
          type: ItemType.webpage,
          readingStatus: ReadingStatus.unread,
        );

        final result = item.toFirestore(isEdit: true);

        check(result.containsKey('createdAt')).isFalse();
      });

      test('does not include fields that are empty', () {
        final item = SavedItem(
          type: ItemType.webpage,
          readingStatus: ReadingStatus.unread,
          uri: Uri(scheme: ''),
          title: '',
          notes: '',
        );

        final result = item.toFirestore();

        check(result['type']).equals('webpage');
        check(result['readingStatus']).equals('unread');
        check(result.containsKey('createdAt')).isTrue();
        check(result['createdAt']).isA<FieldValue>();
        check(result.containsKey('url')).isFalse();
        check(result.containsKey('title')).isFalse();
        check(result.containsKey('notes')).isFalse();
        check(result.containsKey('remindReading')).isFalse();
      });

      test('does not include fields that are null', () {
        final item = SavedItem(
          type: ItemType.webpage,
          readingStatus: ReadingStatus.unread,
        );

        final result = item.toFirestore();

        check(result['type']).equals('webpage');
        check(result['readingStatus']).equals('unread');
        check(result.containsKey('createdAt')).isTrue();
        check(result['createdAt']).isA<FieldValue>();
        check(result.containsKey('url')).isFalse();
        check(result.containsKey('title')).isFalse();
        check(result.containsKey('notes')).isFalse();
        check(result.containsKey('remindReading')).isFalse();
      });
    });

    group('fromFirestore', () {
      test('correctly builds a SavedItem from a DocumentSnapshot', () {
        final snapshot = _MockDocumentSnapshot();
        final timestamp = Timestamp.fromDate(DateTime(2024, 2, 1));
        final data = <String, dynamic>{
          'type': 'webpage',
          'url': 'https://example.com',
          'readingStatus': 'reading',
          'title': 'My Title',
          'notes': 'My Notes',
          'remindReading': true,
          'createdAt': timestamp,
        };
        when(() => snapshot.id).thenReturn('doc-id-456');
        when(() => snapshot.data()).thenReturn(data);

        final item = SavedItem.fromFirestore(snapshot, null);

        check(item.id).equals('doc-id-456');
        check(item.type).equals(ItemType.webpage);
        check(item.uri).equals(Uri.parse('https://example.com'));
        check(item.readingStatus).equals(ReadingStatus.reading);
        check(item.title).equals('My Title');
        check(item.notes).equals('My Notes');
        check(item.remindReading).equals(true);
        check(item.createdAt).equals(timestamp.toDate());
      });

      test('sets id from snapshot.id', () {
        final snapshot = _MockDocumentSnapshot();
        when(() => snapshot.id).thenReturn('snapshot-id-789');
        when(() => snapshot.data()).thenReturn(<String, dynamic>{});

        final item = SavedItem.fromFirestore(snapshot, null);

        check(item.id).equals('snapshot-id-789');
      });

      test('If the url is not valid, the url will set to null', () {
        final snapshot = _MockDocumentSnapshot();
        final data = <String, dynamic>{'url': '::Not valid URI::'};
        when(() => snapshot.id).thenReturn('doc-id');
        when(() => snapshot.data()).thenReturn(data);

        final item = SavedItem.fromFirestore(snapshot, null);

        check(item.uri).isNull();
      });

      test('falls back on default values when data is missing', () {
        final snapshot = _MockDocumentSnapshot();
        when(() => snapshot.id).thenReturn('doc-id');
        when(() => snapshot.data()).thenReturn(<String, dynamic>{});

        final item = SavedItem.fromFirestore(snapshot, null);

        check(item.id).equals('doc-id');
        check(item.type).equals(ItemType.webpage);
        check(item.readingStatus).equals(ReadingStatus.unread);
        check(item.uri).isNull();
        check(item.title).isNull();
        check(item.notes).isNull();
        check(item.remindReading).isNull();
        check(item.createdAt).isNull();
      });

      test('uses defaults for invalid enum strings', () {
        final snapshot = _MockDocumentSnapshot();
        when(() => snapshot.id).thenReturn('doc-id');
        when(() => snapshot.data()).thenReturn(<String, dynamic>{
          'type': 'unknown',
          'readingStatus': 'unknown',
        });

        final item = SavedItem.fromFirestore(snapshot, null);

        check(item.id).equals('doc-id');
        check(item.type).equals(ItemType.webpage);
        check(item.readingStatus).equals(ReadingStatus.unread);
      });
    });
  });
}
