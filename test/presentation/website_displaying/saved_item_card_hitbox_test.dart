import 'package:articly/data/models/saved_item.dart';
import 'package:articly/domain/providers/user_provider.dart';
import 'package:articly/presentation/website_displaying/widgets/saved_item_card.dart';
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

  setUp(() async {
    mockProvider = MockUserProvider();
    when(() => mockProvider.tags).thenReturn({});
    when(() => mockProvider.items).thenReturn({});
    when(() => mockProvider.addListener(any())).thenReturn(null);
    when(() => mockProvider.removeListener(any())).thenReturn(null);

    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    themeModel = ThemeModel(prefs: prefs);
  });

  testWidgets(
    'options icon button in SavedItemCard has an enlarged touch target/hitbox',
    (tester) async {
      final item = SavedItem(
        id: 'test_item',
        type: ItemType.webpage,
        readingStatus: ReadingStatus.unread,
        title: 'Article with Options',
        uri: Uri.parse('https://example.com'),
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<UserProvider>.value(value: mockProvider),
            ChangeNotifierProvider<ThemeModel>.value(value: themeModel),
          ],
          child: MaterialApp(
            home: Scaffold(body: SavedItemCard(isGridView: false, item: item)),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final iconButtonFinder = find.widgetWithIcon(IconButton, Icons.more_vert);
      expect(iconButtonFinder, findsOneWidget);

      final iconButton = tester.widget<IconButton>(iconButtonFinder);
      check(iconButton.padding).equals(const EdgeInsets.all(8.0));
      check(iconButton.constraints?.minWidth).equals(36.0);
      check(iconButton.constraints?.minHeight).equals(36.0);

      // Icon itself retains default size
      final icon = tester.widget<Icon>(find.byIcon(Icons.more_vert));
      check(icon.size).isNull(); // Default Icon size (24)
    },
  );
}
