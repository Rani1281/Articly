import 'package:articly/data/models/saved_item.dart';
import 'package:articly/data/models/tag.dart';
import 'package:articly/domain/providers/user_provider.dart';
import 'package:articly/presentation/website_displaying/widgets/saved_item_details_dialog.dart';
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
  final tagDart = Tag(id: 't_dart', name: 'Dart');
  final tagFlutter = Tag(id: 't_flutter', name: 'Flutter');
  final tagMobile = Tag(id: 't_mobile', name: 'Mobile');

  late FakeUserProvider fakeProvider;

  setUp(() {
    fakeProvider = FakeUserProvider({
      't_dart': tagDart,
      't_flutter': tagFlutter,
      't_mobile': tagMobile,
    });
  });

  Widget createWidgetUnderTest(SavedItem item, {VoidCallback? onOpenUrl}) {
    return ChangeNotifierProvider<UserProvider>.value(
      value: fakeProvider,
      child: MaterialApp(
        home: Scaffold(
          body: SavedItemDetailsDialog(item: item, onOpenUrl: onOpenUrl),
        ),
      ),
    );
  }

  group('SavedItemDetailsDialog', () {
    testWidgets('displays tags as chips at the top in exact selection order', (
      tester,
    ) async {
      final item = SavedItem(
        id: '1',
        type: ItemType.webpage,
        readingStatus: ReadingStatus.reading,
        uri: Uri.parse('https://example.com/flutter-article'),
        title: 'Learn Flutter',
        tags: ['t_mobile', 't_flutter', 't_dart'],
      );

      await tester.pumpWidget(createWidgetUnderTest(item));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('detailsDialogTagsWrap')),
        findsOneWidget,
      );
      expect(find.text('Mobile'), findsOneWidget);
      expect(find.text('Flutter'), findsOneWidget);
      expect(find.text('Dart'), findsOneWidget);

      // Verify chips order
      final chips = tester
          .widgetList<Text>(
            find.descendant(
              of: find.byKey(const ValueKey('detailsDialogTagsWrap')),
              matching: find.byType(Text),
            ),
          )
          .map((t) => t.data)
          .toList();

      check(chips).deepEquals(['Mobile', 'Flutter', 'Dart']);
    });

    testWidgets('skips unknown or deleted tag IDs gracefully', (tester) async {
      final item = SavedItem(
        id: '2',
        type: ItemType.webpage,
        readingStatus: ReadingStatus.unread,
        uri: Uri.parse('https://example.com'),
        title: 'Title',
        tags: ['t_unknown', 't_dart'],
      );

      await tester.pumpWidget(createWidgetUnderTest(item));
      await tester.pumpAndSettle();

      expect(find.text('Dart'), findsOneWidget);
      expect(find.text('t_unknown'), findsNothing);
    });

    testWidgets('does not show tags wrap if item has no tags', (tester) async {
      final item = SavedItem(
        id: '3',
        type: ItemType.webpage,
        readingStatus: ReadingStatus.read,
        uri: Uri.parse('https://example.com'),
        title: 'No Tags Article',
        tags: [],
      );

      await tester.pumpWidget(createWidgetUnderTest(item));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('detailsDialogTagsWrap')), findsNothing);
      expect(find.text('No Tags Article'), findsOneWidget);
    });

    testWidgets('displays title, reading status, and notes', (tester) async {
      final item = SavedItem(
        id: '4',
        type: ItemType.webpage,
        readingStatus: ReadingStatus.unread,
        uri: Uri.parse('https://example.com'),
        title: 'My Custom Title',
        notes: 'Very important article notes',
        tags: ['t_flutter'],
      );

      await tester.pumpWidget(createWidgetUnderTest(item));
      await tester.pumpAndSettle();

      expect(find.text('My Custom Title'), findsOneWidget);
      expect(find.text('unread'), findsOneWidget);
      expect(find.text('Very important article notes'), findsOneWidget);
    });

    testWidgets('calls onOpenUrl when open link button is tapped', (
      tester,
    ) async {
      bool opened = false;
      final item = SavedItem(
        id: '5',
        type: ItemType.webpage,
        readingStatus: ReadingStatus.unread,
        uri: Uri.parse('https://example.com'),
        title: 'Link Test',
      );

      await tester.pumpWidget(
        createWidgetUnderTest(item, onOpenUrl: () => opened = true),
      );
      await tester.pumpAndSettle();

      final openButton = find.byTooltip('Open link');
      expect(openButton, findsOneWidget);
      await tester.tap(openButton);
      await tester.pumpAndSettle();

      check(opened).isTrue();
    });
  });
}
