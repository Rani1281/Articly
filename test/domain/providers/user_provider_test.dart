import 'package:articly/data/models/reading_status_count.dart';
import 'package:articly/data/models/saved_item.dart';
import 'package:articly/data/repositories/saved_items_repository.dart';
import 'package:articly/data/repositories/user_repository.dart';
import 'package:articly/data/services/auth_service.dart';
import 'package:articly/domain/providers/user_provider.dart';
import 'package:checks/checks.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class MockUserRepository extends Mock implements UserRepository {}

class MockSavedItemsRepository extends Mock implements SavedItemsRepository {}

class MockAuthService extends Mock implements AuthService {}

class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}

class MockUser extends Mock implements User {}

void main() {
  late MockUserRepository mockUserRepo;
  late MockSavedItemsRepository mockSavedItemsRepo;
  late MockAuthService mockAuthService;
  late MockFirebaseFirestore mockFirebaseFirestore;
  late UserProvider provider;
  late User mockUser;

  setUpAll(() {
    registerFallbackValue(ReadingStatusCount());
    registerFallbackValue(
      SavedItem(
        type: ItemType.webpage,
        uri: Uri.parse(''),
        readingStatus: ReadingStatus.unread,
      ),
    );
  });

  setUp(() {
    mockUserRepo = MockUserRepository();
    mockSavedItemsRepo = MockSavedItemsRepository();
    mockAuthService = MockAuthService();
    mockFirebaseFirestore = MockFirebaseFirestore();
    mockUser = MockUser();

    when(() => mockAuthService.user).thenReturn(mockUser);
    when(() => mockUser.uid).thenReturn('user123');

    provider = UserProvider(
      userRepo: mockUserRepo,
      savedItemsRepo: mockSavedItemsRepo,
      authService: mockAuthService,
      db: mockFirebaseFirestore,
    );
  });

  group('SavedItemsProvider', () {
    group('load()', () {
      test(
        'returns null and notifies listeners if the counts are equal (when notify = true)',
        () async {
          final items = {
            '1': SavedItem(
              type: ItemType.webpage,
              readingStatus: ReadingStatus.unread,
              uri: Uri.parse(''),
            ),
            '2': SavedItem(
              type: ItemType.webpage,
              readingStatus: ReadingStatus.read,
              uri: Uri.parse(''),
            ),
          };

          final counts = ReadingStatusCount(
            counts: {'unread': 1, 'reading': 0, 'read': 1},
          );

          when(
            () => mockSavedItemsRepo.fetchItems(),
          ).thenAnswer((_) async => items);
          when(
            () => mockUserRepo.fetchReadingStatusCount(),
          ).thenAnswer((_) async => counts);

          int notifiedCount = 0;
          provider.addListener(() => notifiedCount++);

          final result = await provider.load();

          check(result).isNull();
          check(notifiedCount).equals(1);
        },
      );

      test(
        'if the counts are not equal, counts the items, sets the counts, calls '
        'userRepo.setReadingStatusCounts, returns null and notifies listeners  (when notify = true)',
        () async {
          final items = {
            '1': SavedItem(
              type: ItemType.webpage,
              readingStatus: ReadingStatus.unread,

              uri: Uri.parse(''),
            ),
            '2': SavedItem(
              type: ItemType.webpage,
              readingStatus: ReadingStatus.reading,
              uri: Uri.parse(''),
            ),
            '3': SavedItem(
              type: ItemType.webpage,
              readingStatus: ReadingStatus.read,
              uri: Uri.parse(''),
            ),
          };

          // missing 1
          final counts = ReadingStatusCount(
            counts: {'unread': 1, 'reading': 0, 'read': 1},
          );

          when(
            () => mockSavedItemsRepo.fetchItems(),
          ).thenAnswer((_) async => items);
          when(
            () => mockUserRepo.fetchReadingStatusCount(),
          ).thenAnswer((_) async => counts);
          when(
            () => mockUserRepo.setReadingStatusCounts(
              any<ReadingStatusCount>(),
              forceSync: true,
            ),
          ).thenAnswer((_) async => VoidCallbackAction());

          int notifiedCount = 0;
          provider.addListener(() => notifiedCount++);

          final result = await provider.load();

          // check(
          //   provider.readingStatusCount.counts,
          // ).equals();
          expect(
            provider.readingStatusCount.counts,
            equals({'unread': 1, 'reading': 1, 'read': 1}),
          );
          verify(
            () => mockUserRepo.setReadingStatusCounts(
              any<ReadingStatusCount>(),
              forceSync: true,
            ),
          ).called(1);
          check(result).isNull();
          check(notifiedCount).equals(1);
        },
      );

      test('does not notify listeners if notify is set to false', () async {
        when(() => mockSavedItemsRepo.fetchItems()).thenAnswer((_) async => {});
        when(
          () => mockUserRepo.fetchReadingStatusCount(),
        ).thenAnswer((_) async => ReadingStatusCount());

        int notifiedCount = 0;
        provider.addListener(() => notifiedCount++);

        final result = await provider.load(notify: false);

        check(result).isNull();
        check(notifiedCount).equals(0);
      });
    });

    group('save()', () {
      setUp(() async {
        when(() => mockSavedItemsRepo.fetchItems()).thenAnswer((_) async => {});
        when(
          () => mockUserRepo.fetchReadingStatusCount(),
        ).thenAnswer((_) async => ReadingStatusCount());
        await provider.load();
      });

      test(
        'adds new item with its generated Firestore id, increments the right reading status, and notifies listeners, '
        'and returns null on success',
        () async {
          when(
            () => mockSavedItemsRepo.addItem(any()),
          ).thenAnswer((_) async => 'firestore-id-123');

          when(
            () =>
                mockUserRepo.setReadingStatusCounts(any<ReadingStatusCount>()),
          ).thenAnswer((_) async {});

          int notifyCount = 0;
          provider.addListener(() => notifyCount++);

          final item = SavedItem(
            type: ItemType.webpage,
            readingStatus: ReadingStatus.unread,
            uri: Uri.parse('https://example.com'),
          );

          final result = await provider.addItem(item);

          check(provider.items.length).equals(1);
          check(provider.items.containsKey('firestore-id-123')).isTrue();
          check(
            provider.items['firestore-id-123']!.uri,
          ).equals(Uri.parse('https://example.com'));
          check(result).isNull();
          check(notifyCount).equals(1);

          check(provider.readingStatusCount.unread).equals(1);
        },
      );

      test('returns an error on failure', () async {
        when(
          () => mockSavedItemsRepo.addItem(any()),
        ).thenThrow(Exception('Save failed'));

        final item = SavedItem(
          type: ItemType.webpage,
          readingStatus: ReadingStatus.unread,
          uri: Uri.parse(''),
        );

        final result = await provider.addItem(item);

        check(result!).contains('Something went wrong');
        check(provider.items).isEmpty();
      });
    });

    group('edit()', () {
      setUp(() async {
        registerFallbackValue(
          SavedItem(
            type: ItemType.webpage,
            readingStatus: ReadingStatus.unread,
            uri: Uri.parse(''),
          ),
        );

        when(() => mockSavedItemsRepo.fetchItems()).thenAnswer(
          (_) async => {
            'item-id-abc': SavedItem(
              type: ItemType.webpage,
              readingStatus: ReadingStatus.unread,
              uri: Uri.parse('https://something.com'),
              title: 'Hello',
            ),
          },
        );
        when(
          () => mockUserRepo.fetchReadingStatusCount(),
        ).thenAnswer((_) async => ReadingStatusCount());
        await provider.load();
      });

      test(
        'updates items map and returns null on success. Changes the count correctly',
        () async {
          when(
            () => mockSavedItemsRepo.updateItem(any()),
          ).thenAnswer((_) async {});
          when(
            () => mockSavedItemsRepo.fetchItems(),
          ).thenAnswer((_) async => {});

          when(
            () =>
                mockUserRepo.setReadingStatusCounts(any<ReadingStatusCount>()),
          ).thenAnswer((_) async {});

          final item = SavedItem(
            id: 'item-id-abc',
            type: ItemType.webpage,
            readingStatus: ReadingStatus.reading,
            uri: Uri.parse('https://example.com'),
            title: 'Updated Title',
          );

          // item before:
          check(provider.items.length).equals(1);
          check(provider.items.containsKey('item-id-abc')).isTrue();
          check(provider.items['item-id-abc']!.title).equals('Hello');
          check(
            provider.items['item-id-abc']!.uri,
          ).equals(Uri.parse('https://something.com'));

          final result = await provider.editItem(item);

          // item after:
          check(provider.items.length).equals(1);
          check(provider.items.containsKey('item-id-abc')).isTrue();
          check(provider.items['item-id-abc']!.title).equals('Updated Title');
          check(
            provider.items['item-id-abc']!.uri,
          ).equals(Uri.parse('https://example.com'));
          check(result).isNull();

          check(provider.readingStatusCount.unread).equals(0);
          check(provider.readingStatusCount.reading).equals(1);
        },
      );

      test('does not change items map and sets error on failure', () async {
        when(
          () => mockSavedItemsRepo.updateItem(any()),
        ).thenThrow(Exception('Update failed'));

        final item = SavedItem(
          id: 'item-id-def',
          type: ItemType.webpage,
          readingStatus: ReadingStatus.unread,
          uri: Uri.parse(''),
        );

        check(provider.items.length).equals(1);

        final result = await provider.editItem(item);

        check(result!).contains('Something went wrong');
        check(provider.items.length).equals(1);
      });
    });

    group('delete()', () {
      // first load fake items
      setUp(() async {
        registerFallbackValue(
          SavedItem(
            type: ItemType.webpage,
            readingStatus: ReadingStatus.unread,
            uri: Uri.parse(''),
          ),
        );

        final item1 = SavedItem(
          type: ItemType.webpage,
          readingStatus: ReadingStatus.unread,
          uri: Uri.parse(''),
        );
        final item2 = SavedItem(
          type: ItemType.webpage,
          readingStatus: ReadingStatus.read,
          uri: Uri.parse(''),
        );

        when(
          () => mockSavedItemsRepo.fetchItems(),
        ).thenAnswer((_) async => {'id1': item1, 'id2': item2});
        when(
          () => mockUserRepo.fetchReadingStatusCount(),
        ).thenAnswer((_) async => ReadingStatusCount());
        await provider.load();
      });

      test(
        'deletes the item and notifies listeners once, and changes reading counts correctly',
        () async {
          when(
            () => mockSavedItemsRepo.deleteItem('id1'),
          ).thenAnswer((_) async => {});

          int countNotified = 0;
          provider.addListener(() => countNotified++);

          await provider.deleteItem('id1');

          check(provider.items.length).equals(1);
          check(provider.items.containsKey('id1')).isFalse();
          check(countNotified).equals(1);

          check(
            provider.readingStatusCount.unread,
          ).equals(0); // gets decremented
          check(provider.readingStatusCount.read).equals(1); // stays the same
        },
      );

      test('on fail, returns an error and notifies listeners', () async {
        when(
          () => mockSavedItemsRepo.deleteItem('id1'),
        ).thenThrow(Exception('Network error'));

        int countNotified = 0;
        provider.addListener(() => countNotified++);

        final result = await provider.deleteItem('id1');

        check(result).isA<String>();
        check(result!).contains('Something went wrong');
        check(countNotified).equals(1);
      });
    });
  });
}
