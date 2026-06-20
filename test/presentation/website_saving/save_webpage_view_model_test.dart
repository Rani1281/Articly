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
  late MockSavedItemsRepository mockRepo;

  setUpAll(() {
    registerFallbackValue(
      SavedItem(
        type: ItemType.webpage,
        readingStatus: ReadingStatus.unread,
        url: '',
        title: '',
        notes: '',
      ),
    );
  });

  setUp(() {
    mockRepo = MockSavedItemsRepository();
    viewModel = SaveWebpageViewModel(repo: mockRepo);
  });

  tearDown(() {
    viewModel.dispose();
  });

  group('remindMe setter', () {
    test('notifies listeners when the value changes', () {
      var notifiedCount = 0;
      viewModel.addListener(() {
        notifiedCount++;
      });

      viewModel.remindMe = true;

      check(notifiedCount).equals(1);
    });
  });

  group('validateUrl', () {
    test('returns "Url is required" when input is null', () {
      final result = viewModel.validateUrl(null);
      check(result).equals('Url is required');
    });

    test('returns "Url is required" when input is empty', () {
      final result = viewModel.validateUrl('');
      check(result).equals('Url is required');
    });

    test('returns "Url is required" when input is only whitespace', () {
      final result = viewModel.validateUrl('   ');
      check(result).equals('Url is required');
    });

    test('returns "Url is too long" when length exceeds urlMaxChars', () {
      final longUrl = 'https://example.com/${'a' * SaveWebpageViewModel.urlMaxChars}';
      final result = viewModel.validateUrl(longUrl);
      check(result).equals('Url is too long');
    });

    test('returns "Invalid url" for malformed URLs', () {
      check(viewModel.validateUrl('not-a-url')).equals('Invalid url');
      check(viewModel.validateUrl('ftp://example.com')).equals('Invalid url');
      check(viewModel.validateUrl('http://')).equals('Invalid url');
    });

    test('returns null for valid http and https URLs', () {
      final validUrls = <String>[
        'https://example.com',
        'https://example.com/page',
        'http://example.com',
        'http://example.com/path',
      ];

      for (final url in validUrls) {
        check(viewModel.validateUrl(url)).isNull();
      }
    });
  });

  group('validateFields', () {
    test(
      'returns false, sets urlError, and notifies listeners when URL is invalid',
      () {
        var notified = false;
        viewModel.addListener(() {
          notified = true;
        });

        final result = viewModel.validateFields('invalid', 'Title', 'Notes');

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

  group('saveWebpage', () {
    test(
      'stops and returns when fields are invalid without calling the repo',
      () async {
        await viewModel.saveWebpage(
          url: 'invalid-url',
          readingStatus: ReadingStatus.unread,
          title: 'Title',
          notes: 'Notes',
        );

        check(viewModel.isSaving).isFalse();
        check(viewModel.isSavingSuccessful).isFalse();
        verifyZeroInteractions(mockRepo);
      },
    );

    test('on success, sets isSavingSuccessful to true', () async {
      when(
        () => mockRepo.saveItem(any()),
      ).thenAnswer((_) async => 'users/uid/savedItems/123');

      await viewModel.saveWebpage(
        url: 'https://example.com',
        readingStatus: ReadingStatus.unread,
        title: 'Title',
        notes: 'Notes',
      );

      check(viewModel.isSavingSuccessful).isTrue();
      check(viewModel.isSaving).isFalse();
      check(viewModel.savingError).isNull();
    });

    test('on error, sets error message and keeps isSavingSuccessful false', () async {
      when(
        () => mockRepo.saveItem(any()),
      ).thenThrow(Exception('Firestore error'));

      await viewModel.saveWebpage(
        url: 'https://example.com',
        readingStatus: ReadingStatus.unread,
        title: 'Title',
        notes: 'Notes',
      );

      check(viewModel.isSavingSuccessful).isFalse();
      check(viewModel.savingError)
          .equals(
            "Something wen't wrong. Please check you internet connection and try again later.",
          );
      check(viewModel.isSaving).isFalse();
    });
  });
}
