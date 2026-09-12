import 'package:articly/data/models/saved_item.dart';
import 'package:articly/data/models/tag.dart';
import 'package:articly/domain/providers/user_provider.dart';
import 'package:articly/presentation/website_saving/view_models/save_webpage_view_model.dart';
import 'package:articly/presentation/website_saving/widgets/save_webpage_screen.dart';
import 'package:articly/theme/theme_model.dart';
import 'package:checks/checks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockUserProvider extends Mock implements UserProvider {}

void main() {
  late MockUserProvider mockProvider;
  late ThemeModel themeModel;

  final tagTech = Tag(id: 't_tech', name: 'Technology');
  final tagNews = Tag(id: 't_news', name: 'News');

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

  setUp(() async {
    mockProvider = MockUserProvider();
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    themeModel = ThemeModel(prefs: prefs);

    when(
      () => mockProvider.tags,
    ).thenReturn({'t_tech': tagTech, 't_news': tagNews});
    when(() => mockProvider.addListener(any())).thenReturn(null);
    when(() => mockProvider.removeListener(any())).thenReturn(null);
  });

  Widget createWidgetUnderTest({
    SaveWebpageViewModel? viewModel,
    SavedItem? currentItem,
    bool isEdit = false,
  }) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<UserProvider>.value(value: mockProvider),
        ChangeNotifierProvider<ThemeModel>.value(value: themeModel),
      ],
      child: MaterialApp(
        home: SaveWebpageScreen(
          viewModel: viewModel,
          currentItem: currentItem,
          isEdit: isEdit,
        ),
      ),
    );
  }

  group('SaveWebpageScreen Tags Section', () {
    testWidgets('shows Attach tags trigger when no tags are selected', (
      tester,
    ) async {
      final vm = SaveWebpageViewModel(mockProvider);

      await tester.pumpWidget(createWidgetUnderTest(viewModel: vm));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('addTagsTrigger')), findsOneWidget);
      expect(find.text('Attach tags...'), findsOneWidget);
      expect(find.byKey(const ValueKey('editTagsButton')), findsNothing);
    });

    testWidgets('shows tag chips and Edit button when tags are selected', (
      tester,
    ) async {
      final vm = SaveWebpageViewModel(
        mockProvider,
        initialTags: ['t_tech', 't_news'],
      );

      await tester.pumpWidget(createWidgetUnderTest(viewModel: vm));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('addTagsTrigger')), findsNothing);
      expect(find.byKey(const ValueKey('editTagsButton')), findsOneWidget);
      expect(find.byKey(const ValueKey('tag_chip_t_tech')), findsOneWidget);
      expect(find.byKey(const ValueKey('tag_chip_t_news')), findsOneWidget);
      expect(find.text('Technology'), findsOneWidget);
      expect(find.text('News'), findsOneWidget);
    });

    testWidgets('deleting tag chip removes it from selectedTagIds', (
      tester,
    ) async {
      final vm = SaveWebpageViewModel(
        mockProvider,
        initialTags: ['t_tech', 't_news'],
      );

      await tester.pumpWidget(createWidgetUnderTest(viewModel: vm));
      await tester.pumpAndSettle();

      check(vm.selectedTagIds).deepEquals(['t_tech', 't_news']);

      // Find delete icon on t_tech chip
      final chipDeleteIcon = find.descendant(
        of: find.byKey(const ValueKey('tag_chip_t_tech')),
        matching: find.byIcon(Icons.clear),
      );
      await tester.tap(chipDeleteIcon);
      await tester.pumpAndSettle();

      check(vm.selectedTagIds).deepEquals(['t_news']);
      expect(find.byKey(const ValueKey('tag_chip_t_tech')), findsNothing);
      expect(find.byKey(const ValueKey('tag_chip_t_news')), findsOneWidget);
    });

    testWidgets('pre-populates tags when editing existing SavedItem', (
      tester,
    ) async {
      final item = SavedItem(
        id: 'item_1',
        type: ItemType.webpage,
        readingStatus: ReadingStatus.reading,
        uri: Uri.parse('https://example.com'),
        title: 'Tech Article',
        tags: ['t_tech'],
      );

      await tester.pumpWidget(
        createWidgetUnderTest(currentItem: item, isEdit: true),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('tag_chip_t_tech')), findsOneWidget);
      expect(find.text('Technology'), findsOneWidget);
    });
  });
}
