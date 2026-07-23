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
      test('calls load() on construction', () async {
        when(() => mockRepo.fetchItems()).thenAnswer((_) async => {});

        final provider = SavedItemsProvider(repo: mockRepo);

        await provider.load();

        verify(() => mockRepo.fetchItems()).called(1);
        check(provider.loadCommand.completed).isTrue();
      });
    });

    group('load()', () {
      test(
        'initializes loadCommand and notifies listeners on success',
        () async {
          when(() => mockRepo.fetchItems()).thenAnswer((_) async => {});

          final provider = SavedItemsProvider(repo: mockRepo);

          await provider.load();

          check(provider.loadCommand.running).isFalse();
          check(provider.loadCommand.completed).isTrue();
          check(provider.loadCommand.error).isNull();
          check(provider.items).isEmpty();
        },
      );

      test('sets items map on success', () async {
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

        await provider.load();

        check(provider.items.length).equals(2);
        check(provider.items.containsKey('id1')).isTrue();
        check(provider.items.containsKey('id2')).isTrue();
        check(provider.loadCommand.running).isFalse();
        check(provider.loadCommand.completed).isTrue();
        check(provider.loadCommand.error).isNull();
      });

      test('sets error and finishes loadCommand on failure', () async {
        when(() => mockRepo.fetchItems()).thenThrow(Exception('Network error'));

        final provider = SavedItemsProvider(repo: mockRepo);

        await provider.load();

        check(provider.loadCommand.running).isFalse();
        check(provider.loadCommand.completed).isFalse();
        check(provider.loadCommand.hasError).isTrue();
        check(provider.loadCommand.error).isNotNull();
        check(provider.loadCommand.error!).contains('Something went wrong');
        check(provider.items).isEmpty();
      });
    });

    group('save()', () {
      late SavedItemsProvider provider;

      setUp(() async {
        when(() => mockRepo.fetchItems()).thenAnswer((_) async => {});
        provider = SavedItemsProvider(repo: mockRepo);
        await provider.load();
      });

      test('initializes saveCommand and notifies listeners on start', () async {
        when(() => mockRepo.addItem(any())).thenAnswer((_) async => 'new-id');

        final item = SavedItem(
          type: ItemType.webpage,
          readingStatus: ReadingStatus.unread,
        );

        await provider.add(item);

        check(provider.saveCommand.running).isFalse();
        check(provider.saveCommand.completed).isTrue();
        check(provider.saveCommand.error).isNull();
      });

      test(
        'adds new item with its generated Firestore id on success',
        () async {
          when(
            () => mockRepo.addItem(any()),
          ).thenAnswer((_) async => 'firestore-id-123');

          final item = SavedItem(
            type: ItemType.webpage,
            readingStatus: ReadingStatus.unread,
            uri: Uri.parse('https://example.com'),
          );

          await provider.add(item);

          check(provider.items.length).equals(1);
          check(provider.items.containsKey('firestore-id-123')).isTrue();
          check(
            provider.items['firestore-id-123']!.uri,
          ).equals(Uri.parse('https://example.com'));
          check(provider.saveCommand.completed).isTrue();
          check(provider.saveCommand.error).isNull();
        },
      );

      test('sets error and finishes saveCommand on failure', () async {
        when(() => mockRepo.addItem(any())).thenThrow(Exception('Save failed'));

        final item = SavedItem(
          type: ItemType.webpage,
          readingStatus: ReadingStatus.unread,
        );

        await provider.add(item);

        check(provider.saveCommand.running).isFalse();
        check(provider.saveCommand.completed).isFalse();
        check(provider.saveCommand.hasError).isTrue();
        check(provider.saveCommand.error).isNotNull();
        check(provider.saveCommand.error!).contains('Something went wrong');
        check(provider.items).isEmpty();
      });
    });

    group('edit()', () {
      //   test('initializes editCommand and notifies listeners on start', () async {
      //     when(
      //       () => mockRepo.updateItem(any()),
      //     ).thenAnswer((_) => Future.value());
      //     when(() => mockRepo.fetchItems()).thenAnswer((_) async => {});

      //     final provider = SavedItemsProvider(repo: mockRepo);
      //     await provider.load();

      //     final item = SavedItem(
      //       id: 'item-id',
      //       type: ItemType.webpage,
      //       readingStatus: ReadingStatus.unread,
      //     );

      //     var notified = false;
      //     provider.addListener(() {
      //       notified = true;
      //     });

      //     // Do not await, so it stays running
      //     final future = provider.edit(item);

      //     // Should be in running state
      //     check(provider.editCommand.running).isTrue();
      //     check(provider.editCommand.completed).isFalse();
      //     check(provider.editCommand.error).isNull();
      //     check(notified).isTrue();

      //     // Complete the mock
      //     completer.complete();
      //     await future;
      //   });

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

      test('updates items map and finalizes editCommand on success', () async {
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

        await provider.edit(item);

        check(provider.items.length).equals(1);
        check(provider.items.containsKey('item-id-abc')).isTrue();
        check(provider.items['item-id-abc']!.title).equals('Updated Title');
        check(
          provider.items['item-id-abc']!.uri,
        ).equals(Uri.parse('https://example.com'));
        check(provider.editCommand.running).isFalse();
        check(provider.editCommand.completed).isTrue();
        check(provider.editCommand.error).isNull();
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

        await provider.edit(item);

        check(provider.editCommand.running).isFalse();
        check(provider.editCommand.completed).isFalse();
        check(provider.editCommand.hasError).isTrue();
        check(
          provider.editCommand.error,
        ).equals('Something went wrong. Please try again later');
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
        'finalizes deleteCommand\'s fields right and notifies listeners',
        () async {
          when(() => mockRepo.deleteItem('id1')).thenAnswer((_) async => {});

          final provider = SavedItemsProvider(repo: mockRepo);

          int countNotified = 0;
          provider.addListener(() => countNotified++);

          await provider.delete('id1');

          check(provider.deleteCommand.running).isFalse();
          check(provider.deleteCommand.completed).isTrue();
          check(provider.deleteCommand.error).isNull();
          check(provider.items).isEmpty();
          check(countNotified).equals(2);
        },
      );

      test('calls deleteItem on the repository', () async {
        final provider = SavedItemsProvider(repo: mockRepo);
        await provider.delete('id1');

        verify(() => mockRepo.deleteItem('id1')).called(1);
      });

      test(
        'on success, removes the item with the deleted id in the items map, and success in command',
        () async {
          when(() => mockRepo.deleteItem('id1')).thenAnswer((_) async => {});
          await provider.delete('id1');

          print(provider.items);

          check(provider.items.length).equals(1);
          check(provider.items.containsKey('id1')).isFalse();

          check(provider.deleteCommand.completed).isTrue();
          check(provider.deleteCommand.error).isNull();
        },
      );

      test(
        'on fail, sets the command fields with an error and notifies listeners',
        () async {
          when(
            () => mockRepo.deleteItem('id1'),
          ).thenThrow(Exception('Network error'));
          final provider = SavedItemsProvider(repo: mockRepo);
          await provider.delete('id1');

          check(provider.deleteCommand.running).isFalse();
          check(provider.deleteCommand.error).isNotNull();
          check(provider.deleteCommand.completed).isFalse();
        },
      );
    });
  });
}
