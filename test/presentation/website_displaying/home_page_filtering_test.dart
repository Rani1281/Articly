import 'package:articly/data/models/reading_status_count.dart';
import 'package:articly/data/models/saved_item.dart';
import 'package:articly/data/models/tag.dart';
import 'package:articly/data/services/shared_preferences_service.dart';
import 'package:articly/domain/providers/user_provider.dart';
import 'package:articly/presentation/website_displaying/view_models/home_page_view_model.dart';
import 'package:articly/presentation/website_displaying/widgets/home_page.dart';
import 'package:articly/theme/theme_model.dart';
import 'package:checks/checks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockUserProvider extends Mock implements UserProvider {}

class MockSharedPreferencesService extends Mock
    implements SharedPreferencesService {}

void main() {
  late MockUserProvider mockProvider;
  late MockSharedPreferencesService mockPrefs;
  late ThemeModel themeModel;
  late HomePageViewModel viewModel;

  final tagTech = Tag(id: 't_tech', name: 'Tech');
  final tagNews = Tag(id: 't_news', name: 'News');

  setUp(() async {
    mockProvider = MockUserProvider();
    mockPrefs = MockSharedPreferencesService();

    when(() => mockPrefs.getOrderBy()).thenReturn(null);
    when(() => mockPrefs.getIsDescending()).thenReturn(null);
    when(() => mockPrefs.getIsGridView()).thenReturn(false);

    when(() => mockProvider.isLoaded).thenReturn(true);
    when(() => mockProvider.load(notify: false)).thenAnswer((_) async => null);
    when(
      () => mockProvider.tags,
    ).thenReturn({'t_tech': tagTech, 't_news': tagNews});
    when(() => mockProvider.items).thenReturn({});
    when(
      () => mockProvider.readingStatusCount,
    ).thenReturn(ReadingStatusCount());
    when(() => mockProvider.addListener(any())).thenReturn(null);
    when(() => mockProvider.removeListener(any())).thenReturn(null);

    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    themeModel = ThemeModel(prefs: prefs);

    viewModel = HomePageViewModel(
      provider: mockProvider,
      prefsService: mockPrefs,
    );
  });

  Widget createWidgetUnderTest() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<UserProvider>.value(value: mockProvider),
        ChangeNotifierProvider<ThemeModel>.value(value: themeModel),
      ],
      child: MaterialApp(home: HomePage(viewModel: viewModel)),
    );
  }

  testWidgets(
    'displays active filter chips when filters are applied and allows deleting them',
    (tester) async {
      final item = SavedItem(
        id: '1',
        type: ItemType.webpage,
        readingStatus: ReadingStatus.unread,
        title: 'Article 1',
        uri: Uri.parse('https://example.com'),
        tags: ['t_tech'],
      );
      when(() => mockProvider.items).thenReturn({'1': item});

      // Apply status and tag filters
      viewModel.applyFilters(
        filter: ReadingStatusFilterType.unread,
        tagIds: ['t_tech'],
      );

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Verify chips in toolbar
      expect(
        find.byKey(const ValueKey('activeStatusFilterChip')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('activeTagFilterChip_t_tech')),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('activeStatusFilterChip')),
          matching: find.text('unread'),
        ),
        findsOneWidget,
      );
      expect(find.text('#Tech'), findsOneWidget);

      // Filter icon has badge with count 2
      expect(find.byKey(const ValueKey('filterIconButton')), findsOneWidget);

      // Tap delete on tag chip
      final tagChipDelete = find.descendant(
        of: find.byKey(const ValueKey('activeTagFilterChip_t_tech')),
        matching: find.byIcon(Icons.close),
      );
      await tester.tap(tagChipDelete);
      await tester.pumpAndSettle();

      // Tag filter removed, status remains
      check(viewModel.selectedTagIds).isEmpty();
      check(viewModel.filter).equals(ReadingStatusFilterType.unread);
      expect(
        find.byKey(const ValueKey('activeTagFilterChip_t_tech')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('activeStatusFilterChip')),
        findsOneWidget,
      );

      // Tap delete on status chip
      final statusChipDelete = find.descendant(
        of: find.byKey(const ValueKey('activeStatusFilterChip')),
        matching: find.byIcon(Icons.close),
      );
      await tester.tap(statusChipDelete);
      await tester.pumpAndSettle();

      // Both filters cleared
      check(viewModel.hasActiveFilter).isFalse();
      expect(
        find.byKey(const ValueKey('activeStatusFilterChip')),
        findsNothing,
      );
    },
  );

  testWidgets(
    'shows filter-aware empty state with clear filters button when active filter yields no items',
    (tester) async {
      when(() => mockProvider.items).thenReturn({});
      viewModel.applyFilters(filter: ReadingStatusFilterType.read, tagIds: []);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(
        find.text('No saved sources match the current filters'),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('clearFilterEmptyStateButton')),
        findsOneWidget,
      );

      // Tap clear filters
      await tester.tap(
        find.byKey(const ValueKey('clearFilterEmptyStateButton')),
      );
      await tester.pumpAndSettle();

      check(viewModel.hasActiveFilter).isFalse();
      expect(find.text('No saved sources yet'), findsOneWidget);
    },
  );
}
