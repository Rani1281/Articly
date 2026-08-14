import 'package:articly/data/models/saved_item.dart';
import 'package:articly/domain/providers/user_provider.dart';
import 'package:articly/presentation/website_displaying/view_models/saved_item_view_model.dart';
import 'package:checks/checks.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

// class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}
//
// class MockFirebaseAuth extends Mock implements FirebaseAuth {}
//
// class MockCollectionReference extends Mock
//     implements CollectionReference<Map<String, dynamic>> {}

class MockUserProvider extends Mock implements UserProvider {}

void main() {
  group('SavedItemViewModel', () {
    // final mockFirebaseAuth = MockFirebaseAuth();
    // final mockFirebaseFirestore = MockFirebaseFirestore();

    // final mockItemsCollection = MockCollectionReference();

    // final mockRepo = SavedItemsRepository(mockItemsCollection);
    final provider = MockUserProvider();

    group('constructor', () {
      test('correctly builds the object from a SavedItem', () {
        final item = SavedItem(
          id: 'item-1',
          type: ItemType.webpage,
          readingStatus: ReadingStatus.reading,
          uri: Uri.parse('https://example.com'),
          title: 'Test Title',
          notes: 'Test Notes',
        );

        final viewModel = SavedItemViewModel(
          currentItem: item,
          provider: provider,
        );

        check(viewModel.currentItem).equals(item);
        check(viewModel.title).equals('Test Title');
        check(viewModel.uri).equals(Uri.parse('https://example.com'));
        check(viewModel.notes).equals('Test Notes');
        check(viewModel.isVisible).isTrue();
      });
    });

    group('currentItem setter', () {
      test(
        'sets currentItem, updates title, uri, and notes, and notifies listeners',
        () {
          final item = SavedItem(
            id: 'item-1',
            type: ItemType.webpage,
            readingStatus: ReadingStatus.reading,
            uri: Uri.parse('https://example.com'),
            title: 'Original Title',
            notes: 'Original Notes',
          );

          final viewModel = SavedItemViewModel(
            currentItem: item,
            provider: provider,
          );

          final newItem = SavedItem(
            id: 'item-2',
            type: ItemType.webpage,
            readingStatus: ReadingStatus.read,
            uri: Uri.parse('https://new-example.com'),
            title: 'New Title',
            notes: 'New Notes',
          );

          viewModel.currentItem = newItem;

          check(viewModel.currentItem).equals(newItem);
          check(viewModel.title).equals('New Title');
          check(viewModel.uri).equals(Uri.parse('https://new-example.com'));
          check(viewModel.notes).equals('New Notes');
        },
      );
    });

    group('deleteItem()', () {
      test(
        'returns if the id is null (not call _provider.delete nor notify listeners)',
        () async {
          int notifiedCount = 0;

          final viewModel = SavedItemViewModel(
            currentItem: SavedItem(
              type: ItemType.webpage,
              readingStatus: ReadingStatus.unread,
              uri: Uri.parse(''),
            ),
            provider: provider,
          );

          viewModel.addListener(() => notifiedCount++);

          await viewModel.deleteItem();

          check(notifiedCount).equals(0);
        },
      );

      test(
        'returns if the id is empty (doesn\'t call _provider.delete nor notify listeners)',
        () async {
          int notifiedCount = 0;

          final viewModel = SavedItemViewModel(
            currentItem: SavedItem(
              id: '',
              type: ItemType.webpage,
              readingStatus: ReadingStatus.unread,
              uri: Uri.parse(''),
            ),
            provider: provider,
          );

          viewModel.addListener(() => notifiedCount++);

          await viewModel.deleteItem();

          check(notifiedCount).equals(0);
          verifyNever(() => provider.deleteItem(''));
        },
      );

      test(
        'on success, sets the visibility to false and notifies listeners',
        () async {
          final id = '123';
          when(() => provider.deleteItem(id)).thenAnswer((_) async => null);

          int notifiedCount = 0;

          final viewModel = SavedItemViewModel(
            currentItem: SavedItem(
              id: id,
              type: ItemType.webpage,
              readingStatus: ReadingStatus.unread,
              uri: Uri.parse(''),
            ),
            provider: provider,
          );

          viewModel.addListener(() => notifiedCount++);

          await viewModel.deleteItem();

          check(viewModel.isVisible).isFalse();
          check(notifiedCount).equals(2);
        },
      );

      test(
        'on fail (has error), resets the visibility to true, and sets the command fields',
        () async {
          final id = '123';
          when(() => provider.deleteItem(id)).thenAnswer((_) async => 'ERROR');

          int notifiedCount = 0;

          final viewModel = SavedItemViewModel(
            currentItem: SavedItem(
              id: id,
              type: ItemType.webpage,
              readingStatus: ReadingStatus.unread,
              uri: Uri.parse(''),
            ),
            provider: provider,
          );

          viewModel.addListener(() => notifiedCount++);

          await viewModel.deleteItem();

          check(viewModel.isVisible).isTrue();
          check(notifiedCount).equals(2);
          check(viewModel.deleteItemCommand.error).equals('ERROR');
          check(viewModel.deleteItemCommand.completed).isFalse();
        },
      );
    });
  });
}
