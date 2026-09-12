import 'package:articly/data/models/tag.dart';
import 'package:articly/domain/providers/user_provider.dart';
import 'package:articly/presentation/website_saving/view_models/add_tags_view_model.dart';
import 'package:articly/presentation/website_saving/widgets/add_tags_dialog.dart';
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
    List<String> initialSelectedTagIds = const [],
    AddTagsViewModel? viewModel,
    ValueChanged<List<String>?>? onDone,
  }) {
    return ChangeNotifierProvider<UserProvider>.value(
      value: fakeProvider,
      child: MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                key: const ValueKey('openDialogButton'),
                onPressed: () async {
                  final result = await showDialog<List<String>>(
                    context: context,
                    builder: (context) => AddTagsDialog(
                      initialSelectedTagIds: initialSelectedTagIds,
                      viewModel: viewModel,
                    ),
                  );
                  onDone?.call(result);
                },
                child: const Text('Open Dialog'),
              );
            },
          ),
        ),
      ),
    );
  }

  group('AddTagsDialog', () {
    testWidgets(
      'renders all tags alphabetically sorted and allows selecting/unselecting',
      (tester) async {
        List<String>? dialogResult;

        await tester.pumpWidget(
          createWidgetUnderTest(
            initialSelectedTagIds: ['t_apple'],
            onDone: (res) => dialogResult = res,
          ),
        );

        // Open dialog
        await tester.tap(find.byKey(const ValueKey('openDialogButton')));
        await tester.pumpAndSettle();

        expect(find.text('Attach Tags'), findsOneWidget);
        expect(
          find.byKey(const ValueKey('createTagButtonInDialog')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('manageTagsButtonInDialog')),
          findsOneWidget,
        );

        // Verify sorted order: Apple, Mango, Zebra
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

        // Apple is initially selected
        final appleCheckbox = tester.widget<Checkbox>(
          find.byKey(const ValueKey('tag_checkbox_t_apple')),
        );
        check(appleCheckbox.value).isNotNull().isTrue();

        // Tap Mango to select it as well (order: Apple, Mango)
        await tester.tap(find.byKey(const ValueKey('tag_item_t_mango')));
        await tester.pumpAndSettle();

        final mangoCheckbox = tester.widget<Checkbox>(
          find.byKey(const ValueKey('tag_checkbox_t_mango')),
        );
        check(mangoCheckbox.value).isNotNull().isTrue();

        // Done button shows count
        expect(find.text('Done (2)'), findsOneWidget);

        // Tap Done
        await tester.tap(find.byKey(const ValueKey('doneAddTagsButton')));
        await tester.pumpAndSettle();

        // Verify returned result preserves selection order
        check(dialogResult).isNotNull();
        check(dialogResult!).deepEquals(['t_apple', 't_mango']);
      },
    );

    testWidgets('real-time search filters the tags list', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.tap(find.byKey(const ValueKey('openDialogButton')));
      await tester.pumpAndSettle();

      expect(find.text('Apple'), findsOneWidget);
      expect(find.text('Mango'), findsOneWidget);
      expect(find.text('Zebra'), findsOneWidget);

      // Enter search text "zeb"
      await tester.enterText(
        find.byKey(const ValueKey('tagSearchField')),
        'zeb',
      );
      await tester.pumpAndSettle();

      expect(find.text('Zebra'), findsOneWidget);
      expect(find.text('Apple'), findsNothing);
      expect(find.text('Mango'), findsNothing);

      // Search for something non-matching
      await tester.enterText(
        find.byKey(const ValueKey('tagSearchField')),
        'xyz',
      );
      await tester.pumpAndSettle();

      expect(find.text('No tags matching "xyz"'), findsOneWidget);
    });

    testWidgets('Cancel button pops dialog returning null', (tester) async {
      List<String>? dialogResult = ['sentinel'];

      await tester.pumpWidget(
        createWidgetUnderTest(
          initialSelectedTagIds: ['t_apple'],
          onDone: (res) => dialogResult = res,
        ),
      );

      await tester.tap(find.byKey(const ValueKey('openDialogButton')));
      await tester.pumpAndSettle();

      // Tap Cancel
      await tester.tap(find.byKey(const ValueKey('cancelAddTagsButton')));
      await tester.pumpAndSettle();

      check(dialogResult).isNull();
    });
  });
}
