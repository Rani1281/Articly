import 'package:articly/data/models/tag.dart';
import 'package:articly/data/repositories/saved_items_repository.dart';
import 'package:articly/data/repositories/tags_repository.dart';
import 'package:articly/data/repositories/user_repository.dart';
import 'package:articly/data/services/auth_service.dart';
import 'package:articly/domain/providers/user_provider.dart';
import 'package:articly/presentation/tags_management/widgets/confirm_delete_dialog.dart';
import 'package:articly/presentation/tags_management/widgets/manage_tags_page.dart';
import 'package:articly/presentation/tags_management/widgets/tag_tile.dart';
import 'package:articly/theme/app_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:logging/logging.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

class MockUserRepository extends Mock implements UserRepository {}

class MockSavedItemsRepository extends Mock implements SavedItemsRepository {}

class MockAuthService extends Mock implements AuthService {}

class MockUser extends Mock implements User {}

class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}

/// An in-memory repository that faithfully mirrors Firestore TagsRepository behavior:
/// - Assigns random unique document IDs
/// - Checks for duplicate normalized names in the database
class InMemoryTagsRepository extends Fake implements TagsRepository {
  final Map<String, Tag> _db = {};
  int _counter = 0;

  @override
  Logger get log => Logger('InMemoryTagsRepository');

  @override
  Future<Map<String, Tag>> load() async {
    return Map<String, Tag>.from(_db);
  }

  @override
  Future<String> create(Tag tag) async {
    final normalized = Tag.normalize(tag.name);
    if (normalized.isEmpty) {
      throw Exception('Tag name cannot be empty.');
    }

    final exists = _db.values.any((t) => t.normalizeName() == normalized);
    if (exists) {
      throw Exception('A tag with this name already exists.');
    }

    _counter++;
    final id = tag.id.isNotEmpty ? tag.id : 'random_tag_id_$_counter';
    final newTag = tag.copyWith(id: id);
    _db[id] = newTag;
    return id;
  }

  @override
  Future<void> update(Tag tag) async {
    if (tag.id.isEmpty) {
      throw Exception('Tag id is empty.');
    }
    _db[tag.id] = tag;
  }

  @override
  Future<void> delete(String id) async {
    if (id.isEmpty) {
      throw Exception('Tag id is empty.');
    }
    _db.remove(id);
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late MockUserRepository mockUserRepo;
  late MockSavedItemsRepository mockSavedItemsRepo;
  late MockAuthService mockAuthService;
  late MockUser mockUser;
  late MockFirebaseFirestore mockFirestore;
  late InMemoryTagsRepository inMemoryTagsRepo;
  late UserProvider userProvider;

  setUp(() {
    mockUserRepo = MockUserRepository();
    mockSavedItemsRepo = MockSavedItemsRepository();
    mockAuthService = MockAuthService();
    mockUser = MockUser();
    mockFirestore = MockFirebaseFirestore();
    inMemoryTagsRepo = InMemoryTagsRepository();

    when(() => mockAuthService.user).thenReturn(mockUser);
    when(() => mockUser.uid).thenReturn('test_uid');

    userProvider = UserProvider(
      userRepo: mockUserRepo,
      savedItemsRepo: mockSavedItemsRepo,
      authService: mockAuthService,
      tagsRepo: inMemoryTagsRepo,
      db: mockFirestore,
    );
  });

  Widget createTestWidget() {
    return MaterialApp(
      theme: AppTheme.light,
      home: ChangeNotifierProvider<UserProvider>.value(
        value: userProvider,
        child: const ManageTagsPage(),
      ),
    );
  }

  group('Tags Management End-to-End Workflow', () {
    testWidgets(
      'Complete workflow: create, validate duplicates, rename, recreate with original name (bug fix), and delete',
      (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // -------------------------------------------------------------------
        // Step 1: Verify Initial Empty State
        // -------------------------------------------------------------------
        expect(find.text('No tags yet'), findsOneWidget);
        expect(find.text('Create a tag'), findsOneWidget);
        expect(find.byType(TagTile), findsNothing);

        // -------------------------------------------------------------------
        // Step 2: Test Discard / Cancel New Tag
        // -------------------------------------------------------------------
        await tester.tap(find.text('Create a tag'));
        await tester.pumpAndSettle();

        expect(find.byType(TextField), findsOneWidget);
        expect(find.text('Enter tag name'), findsOneWidget);

        // Tap cancel/delete button on empty new tag
        await tester.tap(find.byTooltip('Delete tag'));
        await tester.pumpAndSettle();

        expect(find.text('No tags yet'), findsOneWidget);
        expect(find.byType(TextField), findsNothing);

        // -------------------------------------------------------------------
        // Step 3: Create Tag "Flutter"
        // -------------------------------------------------------------------
        await tester.tap(find.text('Create a tag'));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField), 'Flutter');
        await tester.pumpAndSettle();

        await tester.tap(find.byTooltip('Save tag'));
        await tester.pumpAndSettle();

        expect(find.text('Tag created successfully'), findsOneWidget);
        expect(find.text('Flutter'), findsOneWidget);
        expect(find.text('No tags yet'), findsNothing);

        // Dismiss snackbar
        await tester.pump(const Duration(seconds: 4));
        await tester.pumpAndSettle();

        // -------------------------------------------------------------------
        // Step 4: Duplicate Prevention on Creation (Case-insensitive & trimmed)
        // -------------------------------------------------------------------
        await tester.tap(find.text('Create a tag'));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField), '  flutter  ');
        await tester.pumpAndSettle();

        await tester.tap(find.byTooltip('Save tag'));
        await tester.pumpAndSettle();

        expect(
          find.text('A tag with this name already exists'),
          findsOneWidget,
        );

        // Cancel the duplicate creation
        await tester.tap(find.byTooltip('Delete tag'));
        await tester.pumpAndSettle();

        // Dismiss snackbar
        await tester.pump(const Duration(seconds: 4));
        await tester.pumpAndSettle();

        // -------------------------------------------------------------------
        // Step 5: Rename Tag from "Flutter" to "Dart"
        // -------------------------------------------------------------------
        await tester.tap(find.byTooltip('Edit tag'));
        await tester.pumpAndSettle();

        expect(find.byType(TextField), findsOneWidget);
        await tester.enterText(find.byType(TextField), 'Dart');
        await tester.pumpAndSettle();

        await tester.tap(find.byTooltip('Save tag'));
        await tester.pumpAndSettle();

        expect(find.text('Tag updated successfully'), findsOneWidget);
        expect(find.text('Dart'), findsOneWidget);
        expect(find.text('Flutter'), findsNothing);

        // Dismiss snackbar
        await tester.pump(const Duration(seconds: 4));
        await tester.pumpAndSettle();

        // -------------------------------------------------------------------
        // Step 6: CRITICAL BUG FIX VERIFICATION
        // Create a new tag "Flutter" after the previous one was renamed to "Dart".
        // With random IDs, this MUST succeed without any duplicate ID / name collision.
        // -------------------------------------------------------------------
        await tester.tap(find.text('Create a tag'));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField), 'Flutter');
        await tester.pumpAndSettle();

        await tester.tap(find.byTooltip('Save tag'));
        await tester.pumpAndSettle();

        expect(find.text('Tag created successfully'), findsOneWidget);
        // Both tags must now coexist peacefully!
        expect(find.text('Dart'), findsOneWidget);
        expect(find.text('Flutter'), findsOneWidget);

        // Dismiss snackbar
        await tester.pump(const Duration(seconds: 4));
        await tester.pumpAndSettle();

        // -------------------------------------------------------------------
        // Step 7: Duplicate Prevention on Edit
        // Try renaming "Dart" to "Flutter" (which already exists as another tag)
        // -------------------------------------------------------------------
        final dartTile = find.ancestor(
          of: find.text('Dart'),
          matching: find.byType(ListTile),
        );
        final editDartButton = find.descendant(
          of: dartTile,
          matching: find.byTooltip('Edit tag'),
        );
        await tester.tap(editDartButton);
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField), 'flutter');
        await tester.pumpAndSettle();

        await tester.tap(find.byTooltip('Save tag'));
        await tester.pumpAndSettle();

        expect(
          find.text('A tag with this name already exists'),
          findsOneWidget,
        );

        // Revert edit back to "Dart" and save
        await tester.enterText(find.byType(TextField), 'Dart');
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip('Save tag'));
        await tester.pumpAndSettle();

        // Dismiss snackbar
        await tester.pump(const Duration(seconds: 4));
        await tester.pumpAndSettle();

        // -------------------------------------------------------------------
        // Step 8: Delete Tag "Dart"
        // -------------------------------------------------------------------
        final editDartButton2 = find.descendant(
          of: find.ancestor(
            of: find.text('Dart'),
            matching: find.byType(ListTile),
          ),
          matching: find.byTooltip('Edit tag'),
        );
        await tester.tap(editDartButton2);
        await tester.pumpAndSettle();

        await tester.tap(find.byTooltip('Delete tag'));
        await tester.pumpAndSettle();

        // Verify confirmation dialog
        expect(find.byType(ConfirmDeleteDialog), findsOneWidget);
        expect(
          find.text('Are you sure you want to delete "Dart"?'),
          findsOneWidget,
        );

        // Confirm deletion
        final confirmDeleteButton = find.descendant(
          of: find.byType(ConfirmDeleteDialog),
          matching: find.text('Delete'),
        );
        await tester.tap(confirmDeleteButton);
        await tester.pumpAndSettle();

        expect(find.text('Tag deleted successfully'), findsOneWidget);
        expect(find.text('Dart'), findsNothing);
        expect(find.text('Flutter'), findsOneWidget);

        // Dismiss snackbar
        await tester.pump(const Duration(seconds: 4));
        await tester.pumpAndSettle();

        // -------------------------------------------------------------------
        // Step 9: Delete Tag "Flutter" and return to empty state
        // -------------------------------------------------------------------
        await tester.tap(find.byTooltip('Edit tag'));
        await tester.pumpAndSettle();

        await tester.tap(find.byTooltip('Delete tag'));
        await tester.pumpAndSettle();

        final confirmDeleteFlutterButton = find.descendant(
          of: find.byType(ConfirmDeleteDialog),
          matching: find.text('Delete'),
        );
        await tester.tap(confirmDeleteFlutterButton);
        await tester.pumpAndSettle();

        expect(find.text('Tag deleted successfully'), findsOneWidget);
        expect(find.text('Flutter'), findsNothing);
        expect(find.text('No tags yet'), findsOneWidget);
        expect(find.byType(TagTile), findsNothing);
      },
    );
  });
}
