import 'package:articly/data/models/saved_item.dart';
import 'package:articly/domain/providers/saved_items_provider.dart';
import 'package:articly/presentation/website_saving/view_models/save_webpage_view_model.dart';
import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

/// A mock implementation of [SavedItemsProvider] for testing.
class MockSavedItemsProvider extends Mock implements SavedItemsProvider {}

void main() {
  late SaveWebpageViewModel viewModel;
  late SavedItemsProvider itemsProvider;

  setUpAll(() {
    registerFallbackValue(
      SavedItem(
        type: ItemType.webpage,
        readingStatus: ReadingStatus.unread,
        uri: Uri(),
        title: '',
        notes: '',
      ),
    );
  });

  setUp(() {
    itemsProvider = MockSavedItemsProvider();
    viewModel = SaveWebpageViewModel(itemsProvider);
  });

  tearDown(() {
    viewModel.dispose();
  });

  group('isUrlValid', () {
    test('returns true for a normal url', () {
      final result = viewModel.isUrlValid(
        Uri(scheme: 'https', host: 'example.com', path: 'page'),
      );
      check(result).isTrue();
    });
    test('returns false when uri is null', () {
      final result = viewModel.isUrlValid(null);
      check(result).isFalse();
    });
    test('returns false when the uri has no scheme', () {
      final result = viewModel.isUrlValid(Uri(host: 'example.com'));
      check(result).isFalse();
    });
    test('returns false when the scheme is not http or https', () {
      final result = viewModel.isUrlValid(
        Uri(scheme: 'invalid-scheme', host: 'example.com'),
      );
      check(result).isFalse();
    });
    test('returns false when host is empty', () {
      final result = viewModel.isUrlValid(Uri(scheme: 'https'));
      check(result).isFalse();
    });
  });

  group('validateFields', () {
    test('Initially clears all errors', () {
      // invalid
      final _ = viewModel.validateFields(
        Uri.parse('localhost:55505'),
        'Title',
        'Notes',
      );

      check(viewModel.urlError).isNotNull();

      // should be valid
      final _ = viewModel.validateFields(
        Uri.parse('https://www.example.com'),
        'Title',
        'Notes',
      );

      // notified because of "clear()"
      check(viewModel.urlError).isNull();
      check(viewModel.titleError).isNull();
      check(viewModel.notesError).isNull();
    });

    test('if url is empty or null, sets urlError and returns false', () {
      bool result = viewModel.validateFields(Uri.parse(''), 'Title', 'Notes');

      check(result).isFalse();
      check(viewModel.urlError).equals('Url is required');

      result = viewModel.validateFields(null, 'Title', 'Notes');

      check(result).isFalse();
      check(viewModel.urlError).equals('Url is required');
    });

    test(
      'if the url exceeds its max length, sets urlError and returns false',
      () {
        final result = viewModel.validateFields(
          Uri.parse('https://${'s' * 2048}.com'),
          'Title',
          'Notes',
        );

        check(result).isFalse();
        check(viewModel.urlError).equals('Url is too long');
      },
    );

    test(
      'after both pass, if the format of the url is invalid, sets urlError, notifies listeners and returns false',
      () {
        final result = viewModel.validateFields(
          Uri.parse('invalid-example.com'),
          'Title',
          'Notes',
        );

        check(result).isFalse();
        check(viewModel.urlError).equals('Invalid url');
      },
    );

    test('returns false, sets titleError when title exceeds max length', () {
      final longTitle = 'A' * (SaveWebpageViewModel.titleMaxChars + 1);

      final result = viewModel.validateFields(
        Uri.parse('https://example.com'),
        longTitle,
        'Notes',
      );

      check(result).isFalse();
      check(viewModel.titleError).equals('Title is too long');
      check(viewModel.urlError).isNull();
    });

    test(
      'returns false, sets notesError, and notifies listeners when notes exceed max length',
      () {
        final longNotes = 'B' * (SaveWebpageViewModel.notesMaxChars + 1);

        final result = viewModel.validateFields(
          Uri.parse('https://example.com'),
          'Title',
          longNotes,
        );

        check(result).isFalse();
        check(viewModel.notesError).equals('Notes are too long');
        check(viewModel.urlError).isNull();
        check(viewModel.titleError).isNull();
      },
    );

    test('returns true and clears errors when all fields are valid', () {
      final result = viewModel.validateFields(
        Uri.parse('https://example.com'),
        'Title',
        'Notes',
      );

      check(result).isTrue();
      check(viewModel.urlError).isNull();
      check(viewModel.titleError).isNull();
      check(viewModel.notesError).isNull();
    });
  });

  group('saveWebpage', () {
    test(
      'initializes and finalizes saveCommand fields correctly and notifies listeners with valid values',
      () async {
        int notifyCount = 0;
        viewModel.addListener(() => notifyCount++);

        final savedItem = SavedItem(
          type: ItemType.webpage,
          readingStatus: ReadingStatus.unread,
          uri: Uri.parse('https://example.com'),
          title: 'Title',
          notes: 'Notes',
          remindReading: false,
          id: '123',
          createdAt: DateTime(2007),
        );

        when(
          () => itemsProvider.add(savedItem),
        ).thenAnswer((_) => Future.value(null));

        when(
          () => itemsProvider.edit(savedItem),
        ).thenAnswer((_) => Future.value(null));

        final future = viewModel.saveWebpage(
          savedItem: savedItem,
          isEdit: false,
        );

        check(notifyCount).equals(1);
        check(viewModel.saveCommand.running).isTrue();
        check(viewModel.saveCommand.completed).isFalse();
        check(viewModel.saveCommand.hasError).isFalse();
        check(viewModel.saveCommand.activated).isTrue();

        await future;

        check(notifyCount).equals(2);
        check(viewModel.saveCommand.running).isFalse();
        check(viewModel.saveCommand.error).isNull();
        check(viewModel.saveCommand.completed).isTrue();
        check(viewModel.saveCommand.activated).isTrue();
      },
    );

    test('if fields are invalid, returns null and notifies listeners', () {
      int notifyCount = 0;
      viewModel.addListener(() => notifyCount++);

      final savedItem = SavedItem(
        type: ItemType.webpage,
        readingStatus: ReadingStatus.unread,
        uri: Uri.parse('localhost:55555'), // invalid
        title: 'Title',
        notes: 'Notes',
        remindReading: false,
        id: '123',
        createdAt: DateTime(2007),
      );

      final result = viewModel.saveWebpage(savedItem: savedItem, isEdit: false);

      check(result).isA<Future<void>>();
      check(viewModel.urlError).isNotNull();
    });

    test(
      'if isEdit, calls provider.edit and not provider.add on the created item',
      () async {
        final savedItem = SavedItem(
          type: ItemType.webpage,
          readingStatus: ReadingStatus.unread,
          uri: Uri.parse('https://example.com'), // invalid
          title: 'Title',
          notes: 'Notes',
          remindReading: false,
          id: '123',
          createdAt: DateTime(2007),
        );

        when(
          () => itemsProvider.add(savedItem),
        ).thenAnswer((_) => Future.value(null));

        when(
          () => itemsProvider.edit(savedItem),
        ).thenAnswer((_) => Future.value(null));

        await viewModel.saveWebpage(savedItem: savedItem, isEdit: false); // add

        verify(() => itemsProvider.add(savedItem)).called(1);
        verifyNever(() => itemsProvider.edit(savedItem));
      },
    );

    test(
      'if not isEdit, calls provider.add and not provider.edit on the created item',
      () async {
        final savedItem = SavedItem(
          type: ItemType.webpage,
          readingStatus: ReadingStatus.unread,
          uri: Uri.parse('https://example.com'), // invalid
          title: 'Title',
          notes: 'Notes',
          remindReading: false,
          id: '123',
          createdAt: DateTime(2007),
        );

        when(
          () => itemsProvider.add(savedItem),
        ).thenAnswer((_) => Future.value(null));

        when(
          () => itemsProvider.edit(savedItem),
        ).thenAnswer((_) => Future.value(null));

        await viewModel.saveWebpage(savedItem: savedItem, isEdit: true); // edit

        verify(() => itemsProvider.edit(savedItem)).called(1);
        verifyNever(() => itemsProvider.add(savedItem));
      },
    );
  });
}
