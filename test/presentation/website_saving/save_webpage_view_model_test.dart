import 'package:articly/data/models/saved_item.dart';
import 'package:articly/data/repositories/saved_items_repository.dart';
import 'package:articly/presentation/website_saving/view_models/save_webpage_view_model.dart';
import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

/// A mock implementation of [SavedItemsRepository] for testing.
class MockSavedItemsRepository extends Mock implements SavedItemsRepository {}

void main() {
  late SaveWebpageViewModel viewModel;

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
    viewModel = SaveWebpageViewModel();
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
    test('Initially clears all errors and notifies listeners', () {
      bool notified = false;
      viewModel.addListener(() {
        notified = true;
      });

      // should be valid
      final _ = viewModel.validateFields(
        'https://www.example.com',
        'Title',
        'Notes',
      );

      // notified because of "clear()"
      check(notified).isTrue();

      // intentionally pass invalid arguments to set an error message
      final _ = viewModel.validateFields('', '', ''); // 1
      final _ = viewModel.validateFields(
        'https://www.example.com',
        'H' * 202,
        '',
      ); // 2
      final _ = viewModel.validateFields(
        'https://www.example.com',
        '',
        'N' * 10002,
      ); // 3

      // these ones should pass
      final valid = viewModel.validateFields(
        'https://www.example.com',
        'Title',
        'Notes',
      ); // 4

      check(valid).isTrue();

      check(viewModel.urlError).isNull();
      check(viewModel.titleError).isNull();
      check(viewModel.notesError).isNull();
    });

    test(
      'if url is empty, sets urlError, notifies listeners, and returns false',
      () {
        var notified = false;
        viewModel.addListener(() {
          notified = true;
        });

        final result = viewModel.validateFields('', 'Title', 'Notes');

        check(result).isFalse();
        check(viewModel.urlError).equals('Url is required');
        check(notified).isTrue();
      },
    );
    test(
      'if the url exceeds its max length, sets urlError, notifies listeners, and returns false',
      () {
        var notified = false;
        viewModel.addListener(() {
          notified = true;
        });

        final result = viewModel.validateFields(
          'https://${'s' * 2048}.com',
          'Title',
          'Notes',
        );

        check(result).isFalse();
        check(viewModel.urlError).equals('Url is too long');
        check(notified).isTrue();
      },
    );

    test(
      'after both pass, if the format of the url is invalid, sets urlError, notifies listeners and returns false',
      () {
        var notified = false;
        viewModel.addListener(() {
          notified = true;
        });

        final result = viewModel.validateFields(
          'invalid-example.com',
          'Title',
          'Notes',
        );

        check(result).isFalse();
        check(viewModel.urlError).equals('Invalid url');
        check(notified).isTrue();
      },
    );

    test(
      'returns false, sets titleError, and notifies listeners when title exceeds max length',
      () {
        final longTitle = 'A' * (SaveWebpageViewModel.titleMaxChars + 1);
        var notified = false;
        viewModel.addListener(() {
          notified = true;
        });

        final result = viewModel.validateFields(
          'https://example.com',
          longTitle,
          'Notes',
        );

        check(result).isFalse();
        check(viewModel.titleError).equals('Title is too long');
        check(viewModel.urlError).isNull();
        check(notified).isTrue();
      },
    );

    test(
      'returns false, sets notesError, and notifies listeners when notes exceed max length',
      () {
        final longNotes = 'B' * (SaveWebpageViewModel.notesMaxChars + 1);
        var notified = false;
        viewModel.addListener(() {
          notified = true;
        });

        final result = viewModel.validateFields(
          'https://example.com',
          'Title',
          longNotes,
        );

        check(result).isFalse();
        check(viewModel.notesError).equals('Notes are too long');
        check(viewModel.urlError).isNull();
        check(viewModel.titleError).isNull();
        check(notified).isTrue();
      },
    );

    test('returns true and clears errors when all fields are valid', () {
      final result = viewModel.validateFields(
        'https://example.com',
        'Title',
        'Notes',
      );

      check(result).isTrue();
      check(viewModel.urlError).isNull();
      check(viewModel.titleError).isNull();
      check(viewModel.notesError).isNull();
    });
  });
}
