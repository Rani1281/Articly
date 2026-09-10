import 'package:articly/data/models/reading_status_count.dart';
import 'package:articly/data/models/tag.dart';
import 'package:articly/data/repositories/saved_items_repository.dart';
import 'package:articly/data/repositories/tags_repository.dart';
import 'package:articly/data/repositories/user_repository.dart';
import 'package:articly/data/services/auth_service.dart';
import 'package:articly/domain/providers/user_provider.dart';
import 'package:checks/checks.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class MockUserRepository extends Mock implements UserRepository {}

class MockSavedItemsRepository extends Mock implements SavedItemsRepository {}

class MockTagsRepository extends Mock implements TagsRepository {}

class MockAuthService extends Mock implements AuthService {}

class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}

class MockUser extends Mock implements User {}

void main() {
  late MockUserRepository mockUserRepo;
  late MockSavedItemsRepository mockSavedItemsRepo;
  late MockTagsRepository mockTagsRepo;
  late MockAuthService mockAuthService;
  late MockFirebaseFirestore mockFirebaseFirestore;
  late UserProvider provider;
  late User mockUser;

  setUpAll(() {
    registerFallbackValue(Tag(id: 'fallback', name: 'fallback'));
    registerFallbackValue(ReadingStatusCount());
  });

  setUp(() {
    mockUserRepo = MockUserRepository();
    mockSavedItemsRepo = MockSavedItemsRepository();
    mockTagsRepo = MockTagsRepository();
    mockAuthService = MockAuthService();
    mockFirebaseFirestore = MockFirebaseFirestore();
    mockUser = MockUser();

    when(() => mockAuthService.user).thenReturn(mockUser);
    when(() => mockUser.uid).thenReturn('user123');

    provider = UserProvider(
      userRepo: mockUserRepo,
      savedItemsRepo: mockSavedItemsRepo,
      tagsRepo: mockTagsRepo,
      authService: mockAuthService,
      db: mockFirebaseFirestore,
    );
  });

  group('UserProvider - Tags', () {
    group('createTag', () {
      test(
        'creates tag, updates in-memory map, notifies listeners, returns null',
        () async {
          when(
            () => mockTagsRepo.create(any()),
          ).thenAnswer((_) async => 'tag_123');

          int notifyCount = 0;
          provider.addListener(() => notifyCount++);

          final error = await provider.createTag('Flutter');

          check(error).isNull();
          check(provider.tags.containsKey('tag_123')).isTrue();
          check(provider.tags['tag_123']?.name).equals('Flutter');
          check(provider.tags['tag_123']?.id).equals('tag_123');
          check(notifyCount).equals(1);
          verify(() => mockTagsRepo.create(any())).called(1);
        },
      );

      test('returns error if tag already exists in memory', () async {
        when(
          () => mockTagsRepo.create(any()),
        ).thenAnswer((_) async => 'tag_123');

        await provider.createTag('Flutter');
        final error = await provider.createTag('flutter');

        check(error).isNotNull();
        check(error!).contains('already exists');
        verify(() => mockTagsRepo.create(any())).called(1);
      });

      test('returns error if repository throws exception', () async {
        when(
          () => mockTagsRepo.create(any()),
        ).thenThrow(Exception('A tag with this name already exists.'));

        final error = await provider.createTag('Flutter');

        check(error).isNotNull();
        check(error!).contains('already exists');
      });

      test(
        'allows creating tag with original name after renaming it',
        () async {
          when(
            () => mockTagsRepo.create(any()),
          ).thenAnswer((_) async => 'tag_1');
          when(() => mockTagsRepo.update(any())).thenAnswer((_) async {});

          // 1. Create tag "Flutter"
          await provider.createTag('Flutter');
          check(provider.tags['tag_1']?.name).equals('Flutter');

          // 2. Rename tag "Flutter" to "Dart"
          await provider.editTag('tag_1', 'Dart');
          check(provider.tags['tag_1']?.name).equals('Dart');

          // 3. Create a new tag "Flutter" -> should succeed!
          when(
            () => mockTagsRepo.create(any()),
          ).thenAnswer((_) async => 'tag_2');
          final error = await provider.createTag('Flutter');
          check(error).isNull();
          check(provider.tags.containsKey('tag_2')).isTrue();
          check(provider.tags['tag_2']?.name).equals('Flutter');
        },
      );
    });

    group('editTag', () {
      test('updates tag name, updates in memory, notifies listeners', () async {
        when(
          () => mockTagsRepo.create(any()),
        ).thenAnswer((_) async => 'tag_123');
        when(() => mockTagsRepo.update(any())).thenAnswer((_) async {});

        await provider.createTag('Flutter');

        int notifyCount = 0;
        provider.addListener(() => notifyCount++);

        final error = await provider.editTag('tag_123', 'Flutter Dev');

        check(error).isNull();
        check(provider.tags['tag_123']?.name).equals('Flutter Dev');
        check(notifyCount).equals(1);
        verify(() => mockTagsRepo.update(any())).called(1);
      });

      test(
        'returns error if renaming to an already existing tag name',
        () async {
          when(
            () => mockTagsRepo.create(any()),
          ).thenAnswer((_) async => 'tag_1');
          await provider.createTag('Flutter');

          when(
            () => mockTagsRepo.create(any()),
          ).thenAnswer((_) async => 'tag_2');
          await provider.createTag('Dart');

          final error = await provider.editTag('tag_2', 'Flutter');
          check(error).isNotNull();
          check(error!).contains('already exists');
        },
      );

      test('returns error if tag does not exist in memory', () async {
        final error = await provider.editTag('non_existent', 'Name');
        check(error).isNotNull();
        check(error!).contains('not found');
      });
    });

    group('deleteTag', () {
      test(
        'deletes tag from repository, removes from in-memory map, notifies listeners',
        () async {
          when(
            () => mockTagsRepo.create(any()),
          ).thenAnswer((_) async => 'tag_123');
          when(() => mockTagsRepo.delete(any())).thenAnswer((_) async {});

          await provider.createTag('Flutter');

          int notifyCount = 0;
          provider.addListener(() => notifyCount++);

          final error = await provider.deleteTag('tag_123');

          check(error).isNull();
          check(provider.tags.containsKey('tag_123')).isFalse();
          check(notifyCount).equals(1);
          verify(() => mockTagsRepo.delete('tag_123')).called(1);
        },
      );
    });
  });
}
