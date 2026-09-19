import 'package:articly/data/models/tag.dart';
import 'package:articly/domain/providers/user_provider.dart';
import 'package:articly/presentation/website_displaying/view_models/home_page_view_model.dart';
import 'package:articly/presentation/website_displaying/widgets/filter_dialog.dart';
import 'package:checks/checks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

class FakeUserProvider extends ChangeNotifier implements UserProvider {
  FakeUserProvider(this._testTags);

  final Map<String, Tag> _testTags;

  @override
  Map<String, Tag> get tags => _testTags;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  final tagZebra = Tag(id: 't_zebra', name: 'Zebra');
  final tagApple = Tag(id: 't_apple', name: 'Apple');
  final tagMango = Tag(id: 't_mango', name: 'Mango');

  late FakeUserProvider fakeProvider;

  setUp(() {
    fakeProvider = FakeUserProvider({
      't_zebra': tagZebra,
      't_apple': tagApple,
      't_mango': tagMango,
    });
  });

  Widget createWidgetUnderTest({
    ReadingStatusFilterType currentStatus = ReadingStatusFilterType.none,
    List<String> currentTagIds = const [],
    ValueChanged<FilterDialogResult?>? onResult,
  }) {
    return ChangeNotifierProvider<UserProvider>.value(
      value: fakeProvider,
      child: MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                key: const ValueKey('openFilterDialogButton'),
                onPressed: () async {
                  final result = await showFilterDialog(
                    context: context,
                    currentStatus: currentStatus,
                    currentTagIds: currentTagIds,
                  );
                  onResult?.call(result);
                },
                child: const Text('Open Filter Dialog'),
              );
            },
          ),
        ),
      ),
    );
  }

  group('FilterDialog', () {
    testWidgets('renders status choices and alphabetically sorted tags', (
      tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.tap(find.byKey(const ValueKey('openFilterDialogButton')));
      await tester.pumpAndSettle();

      expect(find.text('Filter Items'), findsOneWidget);
      expect(find.text('Reading Status'), findsOneWidget);
      expect(find.byKey(const ValueKey('filterChip_all')), findsOneWidget);
      expect(find.byKey(const ValueKey('filterChip_unread')), findsOneWidget);
      expect(find.byKey(const ValueKey('filterChip_reading')), findsOneWidget);
      expect(find.byKey(const ValueKey('filterChip_read')), findsOneWidget);

      // Verify sorted tags: Apple, Mango, Zebra
      final tagTexts = tester
          .widgetList<Text>(
            find.descendant(
              of: find.byType(ListView),
              matching: find.byType(Text),
            ),
          )
          .map((t) => t.data)
          .toList();

      check(tagTexts).deepEquals(['Apple', 'Mango', 'Zebra']);
    });

    testWidgets(
      'allows selecting reading status and tags, then applies filters',
      (tester) async {
        FilterDialogResult? dialogResult;

        await tester.pumpWidget(
          createWidgetUnderTest(
            currentStatus: ReadingStatusFilterType.none,
            currentTagIds: const [],
            onResult: (res) => dialogResult = res,
          ),
        );

        await tester.tap(find.byKey(const ValueKey('openFilterDialogButton')));
        await tester.pumpAndSettle();

        // Select Unread
        await tester.tap(find.byKey(const ValueKey('filterChip_unread')));
        await tester.pumpAndSettle();

        // Select Apple and Zebra tags
        await tester.tap(find.byKey(const ValueKey('filter_tag_item_t_apple')));
        await tester.tap(find.byKey(const ValueKey('filter_tag_item_t_zebra')));
        await tester.pumpAndSettle();

        expect(find.text('2 selected'), findsOneWidget);

        // Tap Apply
        await tester.tap(find.byKey(const ValueKey('applyFilterButton')));
        await tester.pumpAndSettle();

        check(dialogResult).isNotNull();
        check(dialogResult!.status).equals(ReadingStatusFilterType.unread);
        check(dialogResult!.tagIds).deepEquals(['t_apple', 't_zebra']);
      },
    );

    testWidgets('filters tags by search query in real time', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.tap(find.byKey(const ValueKey('openFilterDialogButton')));
      await tester.pumpAndSettle();

      expect(find.text('Apple'), findsOneWidget);
      expect(find.text('Mango'), findsOneWidget);
      expect(find.text('Zebra'), findsOneWidget);

      // Search for "man"
      await tester.enterText(
        find.byKey(const ValueKey('filterTagSearchField')),
        'man',
      );
      await tester.pumpAndSettle();

      expect(find.text('Mango'), findsOneWidget);
      expect(find.text('Apple'), findsNothing);
      expect(find.text('Zebra'), findsNothing);
    });

    testWidgets('reset button resets status to none and clears selected tags', (
      tester,
    ) async {
      FilterDialogResult? dialogResult;

      await tester.pumpWidget(
        createWidgetUnderTest(
          currentStatus: ReadingStatusFilterType.reading,
          currentTagIds: ['t_apple'],
          onResult: (res) => dialogResult = res,
        ),
      );

      await tester.tap(find.byKey(const ValueKey('openFilterDialogButton')));
      await tester.pumpAndSettle();

      expect(find.text('1 selected'), findsOneWidget);

      // Tap Reset
      await tester.tap(find.byKey(const ValueKey('resetFilterButton')));
      await tester.pumpAndSettle();

      expect(find.text('1 selected'), findsNothing);

      // Tap Apply after reset
      await tester.tap(find.byKey(const ValueKey('applyFilterButton')));
      await tester.pumpAndSettle();

      check(dialogResult).isNotNull();
      check(dialogResult!.status).equals(ReadingStatusFilterType.none);
      check(dialogResult!.tagIds).isEmpty();
    });

    testWidgets('cancel button dismisses without returning a result', (
      tester,
    ) async {
      FilterDialogResult? dialogResult = const FilterDialogResult(
        status: ReadingStatusFilterType.read,
        tagIds: ['sentinel'],
      );

      await tester.pumpWidget(
        createWidgetUnderTest(
          currentStatus: ReadingStatusFilterType.unread,
          onResult: (res) => dialogResult = res,
        ),
      );

      await tester.tap(find.byKey(const ValueKey('openFilterDialogButton')));
      await tester.pumpAndSettle();

      // Tap Cancel
      await tester.tap(find.byKey(const ValueKey('cancelFilterButton')));
      await tester.pumpAndSettle();

      check(dialogResult).isNull();
    });
  });
}
