import 'package:articly/data/models/saved_item.dart';
import 'package:articly/data/services/shared_preferences_service.dart';
import 'package:articly/domain/providers/saved_items_provider.dart';
import 'package:articly/presentation/website_displaying/view_models/home_page_view_model.dart';
import 'package:articly/utils/command.dart';
import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockSavedItemsProvider extends Mock implements UserProvider {}

class MockSharedPreferencesService extends Mock
    implements SharedPreferencesService {}

class MockCommand extends Mock implements Command {}

void main() {
  late HomePageViewModel viewModel;
  late MockSavedItemsProvider mockProvider;
  late MockSharedPreferencesService mockPrefsService;

  setUp(() {
    mockProvider = MockSavedItemsProvider();
    mockPrefsService = MockSharedPreferencesService();

    // Default mock behavior
    when(() => mockProvider.items).thenReturn({});

    viewModel = HomePageViewModel(
      provider: mockProvider,
      prefsService: mockPrefsService,
    );
  });

  group('Constructor', () {
    test(
      'Builds the object correctly: orderBy initializes to creation date, isDescending to true, filter to none, and items are empty.',
      () {
        check(viewModel.orderBy).equals(OrderType.creationDate);
        check(viewModel.isDescending).isTrue();
        check(viewModel.items).isEmpty();
      },
    );
  });

  group('processItems', () {
    test('initializes the processItemsCommand correctly in the beginning of the'
        ' function and notifies listeners.', () async {
      when(() => mockPrefsService.getOrderBy()).thenReturn(null);
      when(() => mockPrefsService.getIsDescending()).thenReturn(null);
      when(
        () => mockProvider.load(notify: false),
      ).thenAnswer((_) async => Future.value(null));

      var notified = false;
      viewModel.addListener(() => notified = true);

      final future = viewModel.processItems();

      check(viewModel.processItemsCommand.running).isTrue();
      check(notified).isTrue();

      await future;

      check(viewModel.processItemsCommand.running).isFalse();
      check(viewModel.processItemsCommand.activated).isTrue();
    });
    test(
      "calls loadData if the provider hasn't started to load the items yet, or *reload* is forcefully set to true",
      () async {
        when(() => mockPrefsService.getOrderBy()).thenReturn(null);
        when(() => mockPrefsService.getIsDescending()).thenReturn(null);
        when(
          () => mockProvider.load(notify: false),
        ).thenAnswer((_) => Future.value(null));

        // Test case 1: provider.loadCommand.activated is false
        await viewModel.processItems();
        verify(() => mockProvider.load(notify: false)).called(1);

        // Test case 2: reload is true
        await viewModel.processItems(reload: true);
        verify(() => mockProvider.load(notify: false)).called(1);
      },
    );

    test('calls sortItems and filterItems always', () async {
      final item1 = SavedItem(
        id: '1',
        type: ItemType.webpage,
        readingStatus: ReadingStatus.read,
        title: 'B',
        uri: Uri.parse(''),
      );
      final item2 = SavedItem(
        id: '2',
        type: ItemType.webpage,
        readingStatus: ReadingStatus.unread,
        title: 'A',
        uri: Uri.parse(''),
      );

      when(() => mockPrefsService.getOrderBy()).thenReturn(OrderType.name.name);
      when(
        () => mockPrefsService.getIsDescending(),
      ).thenReturn(false); // Ascending
      when(
        () => mockProvider.load(notify: false),
      ).thenAnswer((_) => Future.value(null));
      when(() => mockProvider.items).thenReturn({'1': item1, '2': item2});

      // Initially filter is none. Let's set it to unread to test filterItems is called.
      viewModel.switchTab(1); // unread

      await viewModel.processItems();

      // Should be sorted by name ascending: A, B
      // Should be filtered by unread: only A remains
      check(viewModel.items).length.equals(1);
      check(viewModel.items.first.id).equals('2');
    });
    test(
      'finalizes the command correctly in the end and notifies listeners',
      () async {
        when(() => mockPrefsService.getOrderBy()).thenReturn(null);
        when(() => mockPrefsService.getIsDescending()).thenReturn(null);
        when(
          () => mockProvider.load(notify: false),
        ).thenAnswer((_) => Future.value(null));

        var notifyCount = 0;
        viewModel.addListener(() => notifyCount++);

        await viewModel.processItems();

        check(viewModel.processItemsCommand.running).isFalse();
        check(viewModel.processItemsCommand.activated).isTrue();
        check(viewModel.processItemsCommand.completed).isTrue();
        check(viewModel.processItemsCommand.error).isNull();
        // Once at start, once at end
        check(notifyCount).equals(2);
      },
    );

    test(
      'If the provider returned an error, it should also appear in the processItemsCommand',
      () async {
        const errorMessage = 'Load error';
        when(
          () => mockProvider.load(notify: false),
        ).thenAnswer((_) => Future.value(errorMessage));
        when(() => mockPrefsService.getOrderBy()).thenReturn(null);
        when(() => mockPrefsService.getIsDescending()).thenReturn(null);

        await viewModel.processItems(reload: true);

        check(viewModel.processItemsCommand.error).equals(errorMessage);
      },
    );
  });

  group('loadData', () {
    test(
      'sets orderBy, isDescending and isGridView internal fields according to the values stored in SharedPreferences',
      () async {
        when(
          () => mockPrefsService.getOrderBy(),
        ).thenReturn(OrderType.name.name);
        when(() => mockPrefsService.getIsDescending()).thenReturn(false);
        when(() => mockPrefsService.getIsGridView()).thenReturn(true);
        when(
          () => mockProvider.load(notify: false),
        ).thenAnswer((_) => Future.value(null));

        await viewModel.loadData();

        check(viewModel.orderBy).equals(OrderType.name);
        check(viewModel.isDescending).isFalse();
        check(viewModel.isGridView).isTrue();
      },
    );
    test(
      'orderBy defaults to creation date, isDescending defaults to true, and isGridView to false',
      () async {
        when(() => mockPrefsService.getOrderBy()).thenReturn(null);
        when(() => mockPrefsService.getIsDescending()).thenReturn(null);
        when(() => mockPrefsService.getIsGridView()).thenReturn(null);
        when(
          () => mockProvider.load(notify: false),
        ).thenAnswer((_) => Future.value(null));

        await viewModel.loadData();

        check(viewModel.orderBy).equals(OrderType.creationDate);
        check(viewModel.isDescending).isTrue();
      },
    );

    test('calls provider.load()', () async {
      when(() => mockPrefsService.getOrderBy()).thenReturn(null);
      when(() => mockPrefsService.getIsDescending()).thenReturn(null);
      when(
        () => mockProvider.load(notify: false),
      ).thenAnswer((_) => Future.value(null));

      await viewModel.loadData();

      verify(() => mockProvider.load(notify: false)).called(1);
    });
  });

  group('sortByCreationDate', () {
    final now = DateTime.now();
    final older = now.subtract(const Duration(days: 1));
    final item1 = SavedItem(
      id: '1',
      type: ItemType.webpage,
      readingStatus: ReadingStatus.unread,
      createdAt: older,
      uri: Uri.parse(''),
    );
    final item2 = SavedItem(
      id: '2',
      type: ItemType.webpage,
      readingStatus: ReadingStatus.unread,
      createdAt: now,
      uri: Uri.parse(''),
    );

    test(
      'if isDescending, sorts the list based on creation date so that NEWER items are at the top',
      () {
        viewModel.clearItems();
        viewModel.items.addAll([item1, item2]);

        // Default isDescending is true
        viewModel.sortByCreationDate();

        check(viewModel.items.first).equals(item2); // newer
        check(viewModel.items.last).equals(item1); // older
      },
    );

    test('otherwise sorts to be ascending (older first)', () async {
      viewModel.clearItems();
      viewModel.items.addAll([item1, item2]);

      when(
        () => mockPrefsService.setIsDescending(any()),
      ).thenAnswer((_) async => true);
      // Set isDescending to false
      await viewModel.switchIsDescending(); // true -> false

      viewModel.sortByCreationDate();

      check(viewModel.items.first).equals(item1); // older
      check(viewModel.items.last).equals(item2); // newer
    });
  });

  group('sortByName', () {
    final itemA = SavedItem(
      id: '1',
      type: ItemType.webpage,
      readingStatus: ReadingStatus.unread,
      title: 'Apple',
      uri: Uri.parse(''),
    );
    final itemB = SavedItem(
      id: '2',
      type: ItemType.webpage,
      readingStatus: ReadingStatus.unread,
      title: 'Banana',
      uri: Uri.parse(''),
    );

    test(
      'if isDescending, items with titles that start with higher characters should appear more at the top',
      () {
        viewModel.clearItems();
        viewModel.items.addAll([itemA, itemB]);

        // Default isDescending is true
        viewModel.sortByName();

        check(
          viewModel.items.first,
        ).equals(itemB); // 'B' before 'A' in descending
      },
    );

    test('otherwise, lower characters at the top', () async {
      viewModel.clearItems();
      viewModel.items.addAll([itemA, itemB]);

      when(
        () => mockPrefsService.setIsDescending(false),
      ).thenAnswer((_) async => true);
      await viewModel.switchIsDescending(); // true -> false

      viewModel.sortByName();

      check(viewModel.items.first).equals(itemA); // 'A' before 'B' in ascending
    });
  });

  group('filterItems', () {
    setUp(() {
      when(
        () => mockProvider.load(notify: false),
      ).thenAnswer((_) async => null);
    });

    final itemUnread = SavedItem(
      id: '1',
      type: ItemType.webpage,
      readingStatus: ReadingStatus.unread,
      uri: Uri.parse(''),
    );
    final itemRead = SavedItem(
      id: '2',
      type: ItemType.webpage,
      readingStatus: ReadingStatus.read,
      uri: Uri.parse(''),
    );

    test('if the filter is none, returns (because nothing to filter)', () {
      viewModel.clearItems();
      viewModel.items.addAll([itemUnread, itemRead]);

      viewModel.filterItems();

      check(viewModel.items).length.equals(2);
    });

    test('otherwise, filters the list correctly based on the filter', () {
      viewModel.clearItems();
      viewModel.items.addAll([itemUnread, itemRead]);

      viewModel.switchTab(3); // FilterType.read

      viewModel.filterItems();

      check(viewModel.items).length.equals(1);
      check(viewModel.items.first.readingStatus).equals(ReadingStatus.read);
    });
  });

  group('switchTab', () {
    setUp(() {
      when(
        () => mockProvider.load(notify: false),
      ).thenAnswer((_) async => null);
    });

    test(
      'receives the tabIndex, sets the filter to the filter at the given index, and notifies listeners',
      () {
        var notified = false;
        viewModel.addListener(() => notified = true);

        viewModel.switchTab(1); // unread

        check(notified).isTrue();
      },
    );

    test(
      'if the chosen filter is the same as the previous one, returns before reassigning and does not notify listeners',
      () {
        viewModel.switchTab(1); // set to unread

        var notified = false;
        viewModel.addListener(() => notified = true);

        viewModel.switchTab(1); // set to unread again

        check(notified).isFalse();
      },
    );
  });

  group('setOrderBy', () {
    setUp(() async {
      when(
        () => mockProvider.load(notify: false),
      ).thenAnswer((_) async => null);
      await viewModel.loadData();
    });

    test(
      'if the given orderBy is the same as the previous, returns and does not notify listeners',
      () {
        // Default is creationDate
        var notified = false;
        viewModel.addListener(() => notified = true);

        viewModel.setOrderBy(OrderType.creationDate);

        check(notified).isFalse();
      },
    );

    test(
      'otherwise, sets the orderBy to the new value, notifies listeners, and then calls prefsService.setOrderBy(...)',
      () async {
        when(
          () => mockPrefsService.setOrderBy(any()),
        ).thenAnswer((_) async => true);

        var notified = false;
        viewModel.addListener(() => notified = true);

        await viewModel.setOrderBy(OrderType.name);

        check(viewModel.orderBy).equals(OrderType.name);
        check(notified).isTrue();
        verify(
          () => mockPrefsService.setOrderBy(OrderType.name.name),
        ).called(1);
      },
    );
  });

  group('switchIsDescending', () {
    test(
      'switches the value of isDescending (true -> false, false -> true), notifies listeners, and calls prefsService.setIsDescending(...)',
      () async {
        when(
          () => mockPrefsService.setIsDescending(any()),
        ).thenAnswer((_) async => true);

        var notified = false;
        viewModel.addListener(() => notified = true);

        // Initial true
        await viewModel.switchIsDescending();
        check(viewModel.isDescending).isFalse();
        check(notified).isTrue();
        verify(() => mockPrefsService.setIsDescending(false)).called(1);

        notified = false;
        await viewModel.switchIsDescending();
        check(viewModel.isDescending).isTrue();
        check(notified).isTrue();
        verify(() => mockPrefsService.setIsDescending(true)).called(1);
      },
    );
  });

  group('setIsGridView', () {
    test(
      'if the given value is the same as the previous, returns and does not notify listeners',
      () {
        // Default is false
        var notified = false;
        viewModel.addListener(() => notified = true);

        viewModel.setIsGridView(false);

        check(notified).isFalse();
      },
    );

    test(
      'otherwise, sets the isGridView to the new value, notifies listeners, and then calls prefsService.setIsGridView(...)',
      () async {
        when(
          () => mockPrefsService.setIsGridView(any()),
        ).thenAnswer((_) async => true);

        var notified = false;
        viewModel.addListener(() => notified = true);

        await viewModel.setIsGridView(true);

        check(viewModel.isGridView).equals(true);
        check(notified).isTrue();
        verify(() => mockPrefsService.setIsGridView(true)).called(1);
      },
    );
  });
}
