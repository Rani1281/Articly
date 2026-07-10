import 'dart:async';

import 'package:articly/data/models/saved_item.dart';
import 'package:articly/data/repositories/saved_items_repository.dart';
import 'package:articly/domain/providers/saved_items_provider.dart';
import 'package:articly/presentation/website_saving/view_models/save_webpage_view_model.dart';
import 'package:articly/presentation/website_saving/widgets/save_webpage_screen.dart';
import 'package:articly/theme/theme_model.dart';
import 'package:checks/checks.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockSavedItemsRepository extends Mock implements SavedItemsRepository {}

void main() {
  // Initialize mock SharedPreferences so ThemeModel can be created in tests.
  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
    registerFallbackValue(
      SavedItem(type: ItemType.webpage, readingStatus: ReadingStatus.unread),
    );
  });

  group('SaveWebsiteScreen', () {
    // A minimal fake SavedItemsProvider to avoid real Firestore calls.
    SavedItemsProvider createProvider({
      bool shouldFail = false,
      bool neverCompletes = false,
    }) {
      final repo = _MockSavedItemsRepository();

      if (neverCompletes) {
        when(
          () => repo.saveItem(any()),
        ).thenAnswer((_) => Completer<String>().future);
      } else if (shouldFail) {
        when(() => repo.saveItem(any())).thenThrow(Exception('Save failed'));
      } else {
        when(
          () => repo.saveItem(any()),
        ).thenAnswer((_) async => 'users/uid/savedItems/123');
      }
      when(() => repo.updateItem(any())).thenAnswer((_) async {});
      when(() => repo.fetchItems()).thenAnswer((_) async => {});
      when(() => repo.deleteItem(any())).thenAnswer((_) async {});

      return SavedItemsProvider(repo: repo);
    }

    /// Pumps the screen wrapped in the required providers.
    Future<void> pumpScreen(
      WidgetTester tester, {
      SaveWebpageViewModel? viewModel,
      SavedItemsProvider? savedItemsProvider,
    }) async {
      final prefs = await SharedPreferences.getInstance();
      final themeModel = ThemeModel(prefs: prefs);
      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider<ThemeModel>.value(value: themeModel),
              ChangeNotifierProvider<SavedItemsProvider>.value(
                value: savedItemsProvider ?? createProvider(),
              ),
            ],
            child: SaveWebpageScreen(viewModel: viewModel),
          ),
        ),
      );
    }

    testWidgets('renders all widgets correctly', (tester) async {
      // Arrange
      final viewModel = SaveWebpageViewModel();
      await pumpScreen(tester, viewModel: viewModel);

      // Assert
      expect(find.byKey(const ValueKey('urlTextField')), findsOneWidget);
      expect(find.byKey(const ValueKey('statusDropdown')), findsOneWidget);
      expect(find.byKey(const ValueKey('titleTextField')), findsOneWidget);
      expect(find.byKey(const ValueKey('notesTextField')), findsOneWidget);
      expect(find.byKey(const ValueKey('remindMeSwitch')), findsOneWidget);
      expect(find.byKey(const ValueKey('saveButton')), findsOneWidget);
    });

    testWidgets('shows a snack bar when an error appears in savingError', (
      tester,
    ) async {
      // Arrange
      final viewModel = SaveWebpageViewModel();
      final provider = createProvider(shouldFail: true);
      await pumpScreen(
        tester,
        viewModel: viewModel,
        savedItemsProvider: provider,
      );

      // Act - trigger a save that will fail
      await tester.enterText(
        find.byKey(const ValueKey('urlTextField')),
        'https://example.com',
      );
      await tester.tap(find.byKey(const ValueKey('saveButton')));
      await tester.pumpAndSettle();

      // Assert - expect the error snack bar
      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets(
      'shows a circular progress indicator when in the middle of saving',
      (tester) async {
        // Arrange
        final viewModel = SaveWebpageViewModel();
        final provider = createProvider(neverCompletes: true);
        await pumpScreen(
          tester,
          viewModel: viewModel,
          savedItemsProvider: provider,
        );

        // Act - start a save that never completes
        await tester.enterText(
          find.byKey(const ValueKey('urlTextField')),
          'https://example.com',
        );
        await tester.tap(find.byKey(const ValueKey('saveButton')));
        await tester.pump();

        // Assert
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      },
    );

    testWidgets(
      'save button is unpressable when the app is in the middle of saving',
      (tester) async {
        // Arrange
        final viewModel = SaveWebpageViewModel();
        final provider = createProvider(neverCompletes: true);
        await pumpScreen(
          tester,
          viewModel: viewModel,
          savedItemsProvider: provider,
        );

        // Act - start a save that never completes
        await tester.enterText(
          find.byKey(const ValueKey('urlTextField')),
          'https://example.com',
        );
        await tester.tap(find.byKey(const ValueKey('saveButton')));
        await tester.pump();

        // Assert
        final saveButton = tester.widget<GestureDetector>(
          find.byKey(const ValueKey('saveButton')),
        );
        check(saveButton.onTap).isNull();
      },
    );

    testWidgets(
      'automatically pops the page when the operation was successful',
      (tester) async {
        // Arrange - push the screen onto a navigator
        final prefs = await SharedPreferences.getInstance();
        final viewModel = SaveWebpageViewModel();
        final provider = createProvider();
        final homeKey = GlobalKey();
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              key: homeKey,
              builder: (context) => ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MultiProvider(
                        // ignore: always_specify_types
                        providers: [
                          ChangeNotifierProvider<ThemeModel>(
                            create: (_) => ThemeModel(prefs: prefs),
                          ),
                          ChangeNotifierProvider<SavedItemsProvider>.value(
                            value: provider,
                          ),
                        ],
                        child: SaveWebpageScreen(viewModel: viewModel),
                      ),
                    ),
                  );
                },
                child: const Text('Go to save'),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Go to save'));
        await tester.pumpAndSettle();

        // Act - trigger a successful save
        await tester.enterText(
          find.byKey(const ValueKey('urlTextField')),
          'https://example.com',
        );
        await tester.tap(find.byKey(const ValueKey('saveButton')));
        await tester.pumpAndSettle();

        // Assert - should have popped back to the home screen
        expect(find.text('Go to save'), findsOneWidget);
        expect(find.text('Save website'), findsNothing);
      },
    );

    testWidgets(
      'shows an error message below a text field after an error message was '
      'set and rebuild happened',
      (tester) async {
        // Arrange
        final viewModel = SaveWebpageViewModel();
        await pumpScreen(tester, viewModel: viewModel);

        // Act - tap save with an empty URL to trigger validation
        await tester.tap(find.byKey(const ValueKey('saveButton')));
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Url is required'), findsOneWidget);
      },
    );

    testWidgets('url text field maxLength is enforced at 2048 characters', (
      tester,
    ) async {
      // Arrange
      final viewModel = SaveWebpageViewModel();
      await pumpScreen(tester, viewModel: viewModel);

      // Act
      final textField = tester.widget<TextField>(
        find.descendant(
          of: find.byKey(const ValueKey('urlTextField')),
          matching: find.byType(TextField),
        ),
      );

      // Assert
      check(textField.maxLength).equals(SaveWebpageViewModel.urlMaxChars);
    });

    testWidgets('title text field maxLength is enforced at 200 characters', (
      tester,
    ) async {
      // Arrange
      final viewModel = SaveWebpageViewModel();
      await pumpScreen(tester, viewModel: viewModel);

      // Act
      final textField = tester.widget<TextField>(
        find.byKey(const ValueKey('titleTextField')),
      );

      // Assert
      check(textField.maxLength).equals(SaveWebpageViewModel.titleMaxChars);
    });

    testWidgets('notes field maxLength is enforced at 10000 characters', (
      tester,
    ) async {
      // Arrange
      final viewModel = SaveWebpageViewModel();
      await pumpScreen(tester, viewModel: viewModel);

      // Act
      final textField = tester.widget<TextField>(
        find.descendant(
          of: find.byKey(const ValueKey('notesTextField')),
          matching: find.byType(TextField),
        ),
      );

      // Assert
      check(textField.maxLength).equals(SaveWebpageViewModel.notesMaxChars);
    });

    testWidgets(
      'clicking on the suffix icon of the url text field pastes clipboard text',
      (tester) async {
        // Arrange
        final viewModel = SaveWebpageViewModel();
        await pumpScreen(tester, viewModel: viewModel);

        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          (methodCall) async {
            if (methodCall.method == 'Clipboard.getData') {
              return <String, dynamic>{
                'text': 'https://pasted-from-clipboard.com',
              };
            }
            return null;
          },
        );

        addTearDown(() {
          tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
            SystemChannels.platform,
            null,
          );
        });

        // Act - tap the paste icon
        final pasteIcon = find.descendant(
          of: find.byKey(const ValueKey('urlTextField')),
          matching: find.byIcon(Icons.paste_outlined),
        );
        await tester.tap(pasteIcon);
        await tester.pumpAndSettle();

        // Assert
        final textField = tester.widget<TextField>(
          find.descendant(
            of: find.byKey(const ValueKey('urlTextField')),
            matching: find.byType(TextField),
          ),
        );
        check(
          textField.controller!.text,
        ).equals('https://pasted-from-clipboard.com');
      },
    );

    testWidgets('the initial value of the dropdown should be Unread', (
      tester,
    ) async {
      // Arrange
      final viewModel = SaveWebpageViewModel();
      await pumpScreen(tester, viewModel: viewModel);

      // Act
      final dropdown = tester.widget<DropdownButtonFormField<String>>(
        find.descendant(
          of: find.byKey(const ValueKey('statusDropdown')),
          matching: find.byType(DropdownButtonFormField<String>),
        ),
      );

      // Assert
      check(dropdown.initialValue).equals('Unread');
    });
  });
}
