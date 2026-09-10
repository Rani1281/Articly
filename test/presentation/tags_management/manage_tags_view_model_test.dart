import 'package:articly/data/models/tag.dart';
import 'package:articly/domain/providers/user_provider.dart';
import 'package:articly/presentation/tags_management/view_models/manage_tags_view_model.dart';
import 'package:checks/checks.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class MockUserProvider extends Mock implements UserProvider {}

void main() {
  late MockUserProvider mockUserProvider;

  setUp(() {
    mockUserProvider = MockUserProvider();
  });

  group('ManageTagsViewModel', () {
    test('getTags returns tags sorted alphabetically (A-Z)', () async {
      final tags = {
        'z': Tag(id: 'z', name: 'Zebra'),
        'a': Tag(id: 'a', name: 'Apple'),
        'm': Tag(id: 'm', name: 'Mango'),
      };

      when(() => mockUserProvider.tags).thenReturn(tags);
      when(() => mockUserProvider.isLoaded).thenReturn(true);
      when(() => mockUserProvider.addListener(any())).thenReturn(null);
      when(() => mockUserProvider.removeListener(any())).thenReturn(null);

      final vm = ManageTagsViewModel(provider: mockUserProvider);

      final result = await vm.getTags();

      check(result.length).equals(3);
      check(result[0].name).equals('Apple');
      check(result[1].name).equals('Mango');
      check(result[2].name).equals('Zebra');
      check(vm.getTagsCommand.completed).isTrue();
    });

    test('getTags triggers provider load if provider not loaded', () async {
      when(() => mockUserProvider.tags).thenReturn({});
      when(() => mockUserProvider.isLoaded).thenReturn(false);
      when(
        () => mockUserProvider.load(reload: false, notify: false),
      ).thenAnswer((_) async => null);
      when(() => mockUserProvider.addListener(any())).thenReturn(null);
      when(() => mockUserProvider.removeListener(any())).thenReturn(null);

      final vm = ManageTagsViewModel(provider: mockUserProvider);
      await vm.getTags();

      verify(
        () => mockUserProvider.load(reload: false, notify: false),
      ).called(1);
    });
  });
}
