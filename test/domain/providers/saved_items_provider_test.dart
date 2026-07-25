import 'package:articly/data/models/saved_item.dart';
import 'package:articly/data/repositories/saved_items_repository.dart';
import 'package:articly/domain/providers/saved_items_provider.dart';
import 'package:checks/checks.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class MockSavedItemsRepository extends Mock implements SavedItemsRepository {}

void main() {
  late MockSavedItemsRepository mockRepo;

  setUpAll(() {
    registerFallbackValue(
      SavedItem(type: ItemType.webpage, readingStatus: ReadingStatus.unread),
    );
  });

  setUp(() {
    mockRepo = MockSavedItemsRepository();
  });

  group('SavedItemsProvider', () {
    group('initialization', () {
      test(
        'calls load() on construction and notifies listeners once after action',
        () async {
          when(() => mockRepo.fetchItems()).thenAnswer((_) async => {});

          final provider = SavedItemsProvider(repo: mockRepo);
          int notifiedCount = 0;
          provider.addListener(() => notifiedCount++);

          await provider.load();

          verify(() => mockRepo.fetchItems()).called(1);
          check(notifiedCount).equals(1);
        },
      );

      test('does not notify listeners if notify is set to false', () async {
        when(() => mockRepo.fetchItems()).thenAnswer((_) async => {});

        final provider = SavedItemsProvider(repo: mockRepo);
        int notifiedCount = 0;
        provider.addListener(() => notifiedCount++);

        await provider.load(notify: false);

        check(notifiedCount).equals(0);
      });
    });

    group('load()', () {
      test('sets items map on success and returns null', () async {
        final item1 = SavedItem(
          type: ItemType.webpage,
          readingStatus: ReadingStatus.unread,
        );
        final item2 = SavedItem(
          type: ItemType.webpage,
          readingStatus: ReadingStatus.read,
        );
        when(
          () => mockRepo.fetchItems(),
        ).thenAnswer((_) async => {'id1': item1, 'id2': item2});

        final provider = SavedItemsProvider(repo: mockRepo);

        final result = await provider.load();

        check(provider.items.length).equals(2);
        check(provider.items.containsKey('id1')).isTrue();
        check(provider.items.containsKey('id2')).isTrue();
        check(result).isNull();
      });

      test(
        'returns error and finishes on failure, while items stay empty',
        () async {
          when(
            () => mockRepo.fetchItems(),
          ).thenThrow(Exception('Network error'));

          final provider = SavedItemsProvider(repo: mockRepo);

          final result = await provider.load();

          check(result).isA<String>();
          check(result!).contains('Something went wrong');
          check(provider.items).isEmpty();
        },
      );
    });

    group('save()', () {
      late SavedItemsProvider provider;

      setUp(() async {
        when(() => mockRepo.fetchItems()).thenAnswer((_) async => {});
        provider = SavedItemsProvider(repo: mockRepo);
        await provider.load();
      });

      test('adds new item with its generated Firestore id, notifies listeners, '
          'and returns null on success', () async {
        when(
          () => mockRepo.addItem(any()),
        ).thenAnswer((_) async => 'firestore-id-123');

        int notifyCount = 0;
        provider.addListener(() => notifyCount++);

        final item = SavedItem(
          type: ItemType.webpage,
          readingStatus: ReadingStatus.unread,
          uri: Uri.parse('https://example.com'),
        );

        final result = await provider.add(item);

        check(provider.items.length).equals(1);
        check(provider.items.containsKey('firestore-id-123')).isTrue();
        check(
          provider.items['firestore-id-123']!.uri,
        ).equals(Uri.parse('https://example.com'));
        check(result).isNull();
        check(notifyCount).equals(1);
      });

      test('returns an error on failure', () async {
        when(() => mockRepo.addItem(any())).thenThrow(Exception('Save failed'));

        final item = SavedItem(
          type: ItemType.webpage,
          readingStatus: ReadingStatus.unread,
        );

        final result = await provider.add(item);

        check(result!).contains('Something went wrong');
        check(provider.items).isEmpty();
      });
    });

    group('edit()', () {
      test('calls _repo.updateItem() with the given item', () async {
        when(() => mockRepo.updateItem(any())).thenAnswer((_) async {});
        when(() => mockRepo.fetchItems()).thenAnswer((_) async => {});

        final provider = SavedItemsProvider(repo: mockRepo);
        await provider.load();

        final item = SavedItem(
          id: 'item-id-456',
          type: ItemType.webpage,
          readingStatus: ReadingStatus.unread,
        );

        await provider.edit(item);

        verify(() => mockRepo.updateItem(item)).called(1);
      });

      test('updates items map and returns null on success', () async {
        when(() => mockRepo.updateItem(any())).thenAnswer((_) async {});
        when(() => mockRepo.fetchItems()).thenAnswer((_) async => {});

        final provider = SavedItemsProvider(repo: mockRepo);
        await provider.load();

        final item = SavedItem(
          id: 'item-id-abc',
          type: ItemType.webpage,
          readingStatus: ReadingStatus.reading,
          uri: Uri.parse('https://example.com'),
          title: 'Updated Title',
        );

        final result = await provider.edit(item);

        check(provider.items.length).equals(1);
        check(provider.items.containsKey('item-id-abc')).isTrue();
        check(provider.items['item-id-abc']!.title).equals('Updated Title');
        check(
          provider.items['item-id-abc']!.uri,
        ).equals(Uri.parse('https://example.com'));
        check(result).isNull();
      });

      test('does not change items map and sets error on failure', () async {
        when(
          () => mockRepo.updateItem(any()),
        ).thenThrow(Exception('Update failed'));
        when(() => mockRepo.fetchItems()).thenAnswer((_) async => {});

        final provider = SavedItemsProvider(repo: mockRepo);
        await provider.load();

        final item = SavedItem(
          id: 'item-id-def',
          type: ItemType.webpage,
          readingStatus: ReadingStatus.unread,
        );

        final result = await provider.edit(item);

        check(result!).contains('Something went wrong');
        check(provider.items).isEmpty();
      });
    });

    group('delete()', () {
      late SavedItemsProvider provider;
      // first load fake items
      setUp(() async {
        final item1 = SavedItem(
          type: ItemType.webpage,
          readingStatus: ReadingStatus.unread,
        );
        final item2 = SavedItem(
          type: ItemType.webpage,
          readingStatus: ReadingStatus.read,
        );

        when(
          () => mockRepo.fetchItems(),
        ).thenAnswer((_) async => {'id1': item1, 'id2': item2});

        provider = SavedItemsProvider(repo: mockRepo);
        await provider.load();
      });

      test(
        'finalizes deleteCommand\'s fields right and notifies listeners once',
        () async {
          when(() => mockRepo.deleteItem('id1')).thenAnswer((_) async => {});

          final provider = SavedItemsProvider(repo: mockRepo);

          int countNotified = 0;
          provider.addListener(() => countNotified++);

          await provider.delete('id1');

          check(provider.items).isEmpty();
          check(countNotified).equals(1);
        },
      );

      test('calls deleteItem on the repository', () async {
        final provider = SavedItemsProvider(repo: mockRepo);
        await provider.delete('id1');

        verify(() => mockRepo.deleteItem('id1')).called(1);
      });

      test(
        'on success, removes the item with the deleted id in the items map, and returns null',
        () async {
          when(() => mockRepo.deleteItem('id1')).thenAnswer((_) async => {});
          final result = await provider.delete('id1');

          check(result).isNull();
          check(provider.items.length).equals(1);
          check(provider.items.containsKey('id1')).isFalse();
        },
      );

      test(
        'on fail, sets the command fields with an error and notifies listeners',
        () async {
          when(
            () => mockRepo.deleteItem('id1'),
          ).thenThrow(Exception('Network error'));
          final provider = SavedItemsProvider(repo: mockRepo);
          final result = await provider.delete('id1');

          check(result).isA<String>();
          check(result!).contains('Something went wrong');
        },
      );
    });
  });
}
