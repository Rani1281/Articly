import 'dart:async' show Completer, unawaited;

import 'package:articly/data/models/saved_item.dart';
import 'package:articly/data/repositories/saved_items_repository.dart';
import 'package:articly/presentation/website_displaying/view_models/home_page_view_model.dart';
import 'package:checks/checks.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class MockSavedItemsRepository extends Mock implements SavedItemsRepository {}

void main() {
  late HomePageViewModel viewModel;
  late MockSavedItemsRepository mockRepo;

  setUp(() {
    mockRepo = MockSavedItemsRepository();
    viewModel = HomePageViewModel(repo: mockRepo);
  });

  group('constructor', () {
    test('creates a Command for the load field', () {
      check(viewModel.load).isNotNull();
    });
  });

  group('_load via load.execute', () {
    test(
      'sets running to true, completed to false, error to null, and notifies listeners before fetching',
      () async {
        final completer = Completer<Map<String, SavedItem>>();
        when(() => mockRepo.fetchItems()).thenAnswer((_) => completer.future);

        final states = <Map<String, dynamic>>[];
        viewModel.addListener(() {
          states.add(<String, dynamic>{
            'running': viewModel.load.running,
            'completed': viewModel.load.completed,
            'error': viewModel.load.error,
            'items': viewModel.items,
          });
        });

        unawaited(viewModel.load.execute());

        await pumpEventQueue();

        check(states).isNotEmpty();
        final firstState = states.first;
        check(firstState['running']).equals(true);
        check(firstState['completed']).equals(false);
        check(firstState['error']).isNull();

        completer.complete(<String, SavedItem>{});
      },
    );

    test(
      'on success, sets items, running to false, completed to true, error to null, and notifies listeners',
      () async {
        final fetchedItems = <String, SavedItem>{
          'id-1': SavedItem(
            type: ItemType.webpage,
            readingStatus: ReadingStatus.unread,
          ),
        };
        when(() => mockRepo.fetchItems()).thenAnswer((_) async => fetchedItems);

        var notified = false;
        viewModel.addListener(() {
          notified = true;
        });

        await viewModel.load.execute();

        check(viewModel.items).equals(fetchedItems);
        check(viewModel.load.running).isFalse();
        check(viewModel.load.completed).isTrue();
        check(viewModel.load.error).isNull();
        check(viewModel.load.hasError).isFalse();
        check(notified).isTrue();
      },
    );

    test(
      'on error, sets running to false, completed to false, error message, and notifies listeners',
      () async {
        when(() => mockRepo.fetchItems()).thenThrow(Exception('Network error'));

        var notified = false;
        viewModel.addListener(() {
          notified = true;
        });

        await viewModel.load.execute();

        check(viewModel.load.running).isFalse();
        check(viewModel.load.completed).isFalse();
        check(viewModel.load.error).equals(
          'Something went wrong. Please check your internet connection and try again',
        );
        check(viewModel.load.hasError).isTrue();
        check(notified).isTrue();
      },
    );
  });
}
