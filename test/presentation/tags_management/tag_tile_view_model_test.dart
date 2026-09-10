import 'package:articly/data/models/tag.dart';
import 'package:articly/domain/providers/user_provider.dart';
import 'package:articly/presentation/tags_management/view_models/tag_tile_view_model.dart';
import 'package:checks/checks.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class MockUserProvider extends Mock implements UserProvider {}

void main() {
  late MockUserProvider mockUserProvider;

  setUp(() {
    mockUserProvider = MockUserProvider();
  });

  group('TagTileViewModel', () {
    group('Validation', () {
      test('rejects empty or whitespace input', () {
        when(() => mockUserProvider.tags).thenReturn({});
        final vm = TagTileViewModel(provider: mockUserProvider);

        check(vm.validateTagName(null)).isNotNull();
        check(vm.validateTagName('')).isNotNull();
        check(vm.validateTagName('   ')).isNotNull();
      });

      test('rejects newlines or carriage returns', () {
        when(() => mockUserProvider.tags).thenReturn({});
        final vm = TagTileViewModel(provider: mockUserProvider);

        check(vm.validateTagName('tag\nname')).isNotNull();
        check(vm.validateTagName('tag\rname')).isNotNull();
      });

      test('rejects tag names longer than 40 characters', () {
        when(() => mockUserProvider.tags).thenReturn({});
        final vm = TagTileViewModel(provider: mockUserProvider);

        final longName = 'a' * 41;
        check(vm.validateTagName(longName)).isNotNull();
      });

      test('rejects duplicate tag names (case insensitive)', () {
        when(
          () => mockUserProvider.tags,
        ).thenReturn({'random_id_1': Tag(id: 'random_id_1', name: 'Flutter')});
        final vm = TagTileViewModel(provider: mockUserProvider);

        check(vm.validateTagName('FLUTTER')).isNotNull();
        check(vm.validateTagName('flutter')).isNotNull();
        check(vm.validateTagName('  Flutter  ')).isNotNull();
      });

      test('allows same name when editing the existing tag', () {
        final existingTag = Tag(id: 'random_id_1', name: 'Flutter');
        when(
          () => mockUserProvider.tags,
        ).thenReturn({'random_id_1': existingTag});
        final vm = TagTileViewModel(
          tag: existingTag,
          provider: mockUserProvider,
        );

        check(vm.validateTagName('Flutter')).isNull();
        check(vm.validateTagName('flutter')).isNull();
      });

      test('rejects renaming a tag to an already existing other tag name', () {
        final tagToEdit = Tag(id: 'random_id_1', name: 'Dart');
        final otherTag = Tag(id: 'random_id_2', name: 'Flutter');
        when(
          () => mockUserProvider.tags,
        ).thenReturn({'random_id_1': tagToEdit, 'random_id_2': otherTag});
        final vm = TagTileViewModel(tag: tagToEdit, provider: mockUserProvider);

        check(vm.validateTagName('Flutter')).isNotNull();
        check(vm.validateTagName('flutter')).isNotNull();
      });

      test('accepts valid tag name', () {
        when(() => mockUserProvider.tags).thenReturn({});
        final vm = TagTileViewModel(provider: mockUserProvider);

        check(vm.validateTagName('Dart')).isNull();
        check(vm.validateTagName('Machine Learning')).isNull();
      });
    });

    group('createTag', () {
      test(
        'creates tag successfully and exits edit mode with random id',
        () async {
          final tagsMap = <String, Tag>{};
          final createdTag = Tag(id: 'random_id_abc', name: 'Flutter');
          when(() => mockUserProvider.tags).thenReturn(tagsMap);
          when(() => mockUserProvider.createTag('Flutter')).thenAnswer((
            _,
          ) async {
            tagsMap['random_id_abc'] = createdTag;
            return null;
          });

          final vm = TagTileViewModel(
            isEditMode: true,
            provider: mockUserProvider,
          );

          final error = await vm.createTag('Flutter');

          check(error).isNull();
          check(vm.createTagCommand.completed).isTrue();
          check(vm.isEditMode).isFalse();
          check(vm.tag?.name).equals('Flutter');
          check(vm.tag?.id).equals('random_id_abc');
        },
      );

      test('fails with validation error if name is invalid', () async {
        when(() => mockUserProvider.tags).thenReturn({});
        final vm = TagTileViewModel(
          isEditMode: true,
          provider: mockUserProvider,
        );

        final error = await vm.createTag('');

        check(error).isNotNull();
        check(vm.createTagCommand.completed).isFalse();
        check(vm.createTagCommand.hasError).isTrue();
        verifyNever(() => mockUserProvider.createTag(any()));
      });
    });

    group('editTag', () {
      test('edits tag successfully and exits edit mode', () async {
        final initialTag = Tag(id: 'flutter', name: 'Flutter');
        final updatedTag = Tag(id: 'flutter', name: 'Flutter Dev');

        when(() => mockUserProvider.tags).thenReturn({'flutter': updatedTag});
        when(
          () => mockUserProvider.editTag('flutter', 'Flutter Dev'),
        ).thenAnswer((_) async => null);

        final vm = TagTileViewModel(
          tag: initialTag,
          isEditMode: true,
          provider: mockUserProvider,
        );

        final error = await vm.editTag('Flutter Dev');

        check(error).isNull();
        check(vm.editTagCommand.completed).isTrue();
        check(vm.isEditMode).isFalse();
        check(vm.tag?.name).equals('Flutter Dev');
      });

      test('returns immediately if name was not changed', () async {
        final initialTag = Tag(id: 'flutter', name: 'Flutter');
        when(() => mockUserProvider.tags).thenReturn({'flutter': initialTag});

        final vm = TagTileViewModel(
          tag: initialTag,
          isEditMode: true,
          provider: mockUserProvider,
        );

        final error = await vm.editTag('Flutter');

        check(error).isNull();
        check(vm.isEditMode).isFalse();
        verifyNever(() => mockUserProvider.editTag(any(), any()));
      });
    });

    group('deleteTag', () {
      test('deletes tag successfully and resets tag attribute', () async {
        final initialTag = Tag(id: 'flutter', name: 'Flutter');
        when(
          () => mockUserProvider.deleteTag('flutter'),
        ).thenAnswer((_) async => null);

        final vm = TagTileViewModel(
          tag: initialTag,
          provider: mockUserProvider,
        );

        final error = await vm.deleteTag();

        check(error).isNull();
        check(vm.deleteTagCommand.completed).isTrue();
        check(vm.tag).isNull();
      });
    });
  });
}
