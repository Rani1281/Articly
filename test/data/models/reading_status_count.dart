import 'package:articly/data/models/reading_status_count.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockDocumentSnapshot extends Mock
    implements DocumentSnapshot<Map<String, dynamic>> {}

void main() {
  late MockDocumentSnapshot mockDocumentSnapshot;

  setUpAll(() {
    mockDocumentSnapshot = MockDocumentSnapshot();

    when(() => mockDocumentSnapshot.data()).thenReturn({});
  });

  group('constructor', () {
    test('correctly builds ReadingStatusCount object with normal values', () {
      final map = {'unread': 1, 'reading': 2, 'read': 3};
      final counts = ReadingStatusCount(counts: map, isSynced: false);

      expect(counts.counts, equals(map));
      expect(counts.isSynced, false);
    });
    test('initializes the counts with zeros if not passed a value', () {
      final counts = ReadingStatusCount();

      expect(counts.counts, equals({'unread': 0, 'reading': 0, 'read': 0}));
      expect(counts.isSynced, true);
    });
  });

  group('fromFirestore factory', () {
    test('correctly builds ReadingStatusCount object with normal values', () {
      final userData = {
        'readingStatusCount': {'unread': 1, 'reading': 2, 'read': 3},
        'areCountsSynced': false,
      };
      when(() => mockDocumentSnapshot.data()).thenReturn(userData);

      final counts = ReadingStatusCount.fromFirestore(
        mockDocumentSnapshot,
        null,
      );

      expect(counts.counts, equals({'unread': 1, 'reading': 2, 'read': 3}));
      expect(counts.isSynced, false);
    });

    test('correctly converts a counts map from double or string to int', () {
      final userData = {
        'readingStatusCount': {'unread': 1.5, 'reading': 2.3, 'read': 3.6},
        'areCountsSynced': false,
      };
      when(() => mockDocumentSnapshot.data()).thenReturn(userData);

      final counts = ReadingStatusCount.fromFirestore(
        mockDocumentSnapshot,
        null,
      );

      expect(counts.counts, equals({'unread': 1, 'reading': 2, 'read': 3}));
      expect(counts.isSynced, false);
    });

    test(
      'if no data from Firestore, initializes the object with the correct default values',
      () {
        when(() => mockDocumentSnapshot.data()).thenReturn({});

        final counts = ReadingStatusCount.fromFirestore(
          mockDocumentSnapshot,
          null,
        );

        expect(counts.counts, equals({'unread': 0, 'reading': 0, 'read': 0}));
        expect(counts.isSynced, true);
      },
    );
  });
}
