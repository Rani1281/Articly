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

        verify(() => mockRepo.fetchItems()).called(2);
        check(provider.loadCommand.completed).isTrue();
      });
    });

    group('load()', () {
      test('initializes loadCommand and notifies listeners on success', () async {
        when(() => mockRepo.fetchItems()).thenAnswer((_) async => {});

        final provider = SavedItemsProvider(repo: mockRepo);

        await provider.load();

        check(provider.loadCommand.running).isFalse();
        check(provider.loadCommand.completed).isTrue();
        check(provider.loadCommand.error).isNull();
        check(provider.items).isEmpty();
      });

      test('sets items map on success', () async {
        final item1 = SavedItem(
          type: ItemType.webpage,
          readingStatus: ReadingStatus.unread,
        );
        final item2 = SavedItem(
          type: ItemType.webpage,
          readingStatus: ReadingStatus.read,
        );
        when(() => mockRepo.fetchItems()).thenAnswer(
          (_) async => {'id1': item1, 'id2': item2},
        );

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
        when(() => mockRepo.saveItem(any())).thenAnswer((_) async => 'new-id');

        final item = SavedItem(
          type: ItemType.webpage,
          readingStatus: ReadingStatus.unread,
        );

        await provider.save(item);

        check(provider.saveCommand.running).isFalse();
        check(provider.saveCommand.completed).isTrue();
        check(provider.saveCommand.error).isNull();
      });

      test('adds new item with its generated Firestore id on success', () async {
        when(() => mockRepo.saveItem(any())).thenAnswer((_) async => 'firestore-id-123');

        final item = SavedItem(
          type: ItemType.webpage,
          readingStatus: ReadingStatus.unread,
          uri: Uri.parse('https://example.com'),
        );

        await provider.save(item);

        check(provider.items.length).equals(1);
        check(provider.items.containsKey('firestore-id-123')).isTrue();
        check(provider.items['firestore-id-123']!.uri)
            .equals(Uri.parse('https://example.com'));
        check(provider.saveCommand.completed).isTrue();
        check(provider.saveCommand.error).isNull();
      });

      test('sets error and finishes saveCommand on failure', () async {
        when(() => mockRepo.saveItem(any())).thenThrow(Exception('Save failed'));

        final item = SavedItem(
          type: ItemType.webpage,
          readingStatus: ReadingStatus.unread,
        );

        await provider.save(item);

        check(provider.saveCommand.running).isFalse();
        check(provider.saveCommand.completed).isFalse();
        check(provider.saveCommand.hasError).isTrue();
        check(provider.saveCommand.error).isNotNull();
        check(provider.saveCommand.error!).contains('Something went wrong');
        check(provider.items).isEmpty();
      });
    });
  });
}
