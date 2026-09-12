import 'package:articly/data/models/tag.dart';
import 'package:articly/domain/providers/user_provider.dart';
import 'package:articly/presentation/website_saving/view_models/add_tags_view_model.dart';
import 'package:checks/checks.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeUserProvider extends ChangeNotifier implements UserProvider {
  FakeUserProvider(this._testTags);

  Map<String, Tag> _testTags;

  @override
  Map<String, Tag> get tags => _testTags;

  void setTags(Map<String, Tag> newTags) {
    _testTags = newTags;
    notifyListeners();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late FakeUserProvider provider;
  late AddTagsViewModel viewModel;

  final tagFlutter = Tag(id: 't1', name: 'Flutter');
  final tagDart = Tag(id: 't2', name: 'Dart');
  final tagAndroid = Tag(id: 't3', name: 'Android Dev');
  final tagApple = Tag(id: 't4', name: 'Apple / iOS');

  setUp(() {
    provider = FakeUserProvider({
      't1': tagFlutter,
      't2': tagDart,
      't3': tagAndroid,
      't4': tagApple,
    });
    viewModel = AddTagsViewModel(provider: provider);
  });

  tearDown(() {
    viewModel.dispose();
  });

  group('AddTagsViewModel', () {
    test('initializes with empty selection by default', () {
      check(viewModel.selectedTagIds).isEmpty();
      check(viewModel.searchQuery).isEmpty();
    });

    test('initializes with provided initialSelectedTagIds', () {
      final customVm = AddTagsViewModel(
        provider: provider,
        initialSelectedTagIds: ['t2', 't1'],
      );
      check(customVm.selectedTagIds).deepEquals(['t2', 't1']);
      customVm.dispose();
    });

    test(
      'toggleTag adds unselected tag and removes selected tag, preserving order',
      () {
        int notifyCount = 0;
        viewModel.addListener(() => notifyCount++);

        // Select t3, then t1
        viewModel.toggleTag('t3');
        check(viewModel.isTagSelected('t3')).isTrue();
        check(viewModel.selectedTagIds).deepEquals(['t3']);

        viewModel.toggleTag('t1');
        check(viewModel.isTagSelected('t1')).isTrue();
        check(viewModel.selectedTagIds).deepEquals(['t3', 't1']);

        // Unselect t3
        viewModel.toggleTag('t3');
        check(viewModel.isTagSelected('t3')).isFalse();
        check(viewModel.selectedTagIds).deepEquals(['t1']);

        check(notifyCount).equals(3);
      },
    );

    test('selectTag and unselectTag work as expected', () {
      viewModel.selectTag('t2');
      check(viewModel.isTagSelected('t2')).isTrue();

      // Duplicate select does not re-add
      viewModel.selectTag('t2');
      check(viewModel.selectedTagIds).deepEquals(['t2']);

      viewModel.unselectTag('t2');
      check(viewModel.isTagSelected('t2')).isFalse();
      check(viewModel.selectedTagIds).isEmpty();
    });

    test('sortedTags sorts tags alphabetically by name (case-insensitive)', () {
      final sorted = viewModel.sortedTags;
      final names = sorted.map((t) => t.name).toList();
      check(
        names,
      ).deepEquals(['Android Dev', 'Apple / iOS', 'Dart', 'Flutter']);
    });

    test('filteredTags returns all sorted tags when search query is empty', () {
      final filtered = viewModel.filteredTags;
      check(filtered.length).equals(4);
      check(filtered[0].name).equals('Android Dev');
      check(filtered[3].name).equals('Flutter');
    });

    test('filteredTags filters by partial name match and normalized name', () {
      // Direct substring
      viewModel.setSearchQuery('dev');
      check(viewModel.filteredTags.map((t) => t.id)).deepEquals(['t3']);

      // Case-insensitive
      viewModel.setSearchQuery('FLUTTER');
      check(viewModel.filteredTags.map((t) => t.id)).deepEquals(['t1']);

      // Normalized search with slash/space
      viewModel.setSearchQuery('apple_ios');
      check(viewModel.filteredTags.map((t) => t.id)).deepEquals(['t4']);

      viewModel.setSearchQuery('apple ios');
      check(viewModel.filteredTags.map((t) => t.id)).deepEquals(['t4']);
    });

    test('clearSearchQuery resets search query and shows all tags', () {
      viewModel.setSearchQuery('flutter');
      check(viewModel.filteredTags.length).equals(1);

      viewModel.clearSearchQuery();
      check(viewModel.searchQuery).isEmpty();
      check(viewModel.filteredTags.length).equals(4);
    });

    test(
      'retains existing selections and removes deleted tags on provider update',
      () {
        viewModel.toggleTag('t1');
        viewModel.toggleTag('t2');
        check(viewModel.selectedTagIds).deepEquals(['t1', 't2']);

        // Simulate deleting 't2' and adding 't5' in provider
        final tagPython = Tag(id: 't5', name: 'Python');
        provider.setTags({
          't1': tagFlutter,
          't3': tagAndroid,
          't4': tagApple,
          't5': tagPython,
        });

        // 't1' is retained, 't2' was removed because it was deleted
        check(viewModel.selectedTagIds).deepEquals(['t1']);
        // 't5' is now visible in sortedTags
        check(viewModel.sortedTags.any((t) => t.id == 't5')).isTrue();
      },
    );
  });
}
