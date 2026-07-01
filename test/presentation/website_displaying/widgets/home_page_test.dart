import 'package:articly/data/models/saved_item.dart';
import 'package:articly/domain/providers/saved_items_provider.dart';
import 'package:articly/presentation/website_displaying/widgets/home_page.dart';
import 'package:articly/utils/command.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

class FakeSavedItemsProvider extends ChangeNotifier
    implements SavedItemsProvider {
  Command _loadCommand = Command();
  Map<String, SavedItem> _items = {};

  @override
  Command get loadCommand => _loadCommand;

  @override
  Command get saveCommand => Command();

  @override
  Map<String, SavedItem> get items => _items;

  @override
  Future<void> load() async {
    _loadCommand = Command()..start()..finish(null);
    notifyListeners();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;

  void setLoadRunning() {
    _loadCommand = Command()..start();
    notifyListeners();
  }

  void setLoadError(String error) {
    _loadCommand = Command();
    _loadCommand.start();
    _loadCommand.finish(error);
    notifyListeners();
  }

  void setLoadSuccess() {
    _loadCommand = Command();
    _loadCommand.start();
    _loadCommand.finish(null);
    notifyListeners();
  }

  void setItems(Map<String, SavedItem> items) {
    _items = items;
  }
}

void main() {
  late FakeSavedItemsProvider fakeProvider;

  setUp(() {
    fakeProvider = FakeSavedItemsProvider();
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: ChangeNotifierProvider<SavedItemsProvider>.value(
        value: fakeProvider,
        child: const HomePage(),
      ),
    );
  }

  group('HomePage Widget Tests', () {
    testWidgets('Page renders correctly with key elements', (tester) async {
      fakeProvider.setLoadSuccess();

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(SliverAppBar), findsOneWidget);
      expect(find.widgetWithIcon(IconButton, Icons.account_circle), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('Shows spinner when saved items data is loading', (
      tester,
    ) async {
      fakeProvider.setLoadRunning();

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('List shows newly added item on top', (tester) async {
      final item1 = SavedItem(
        type: ItemType.webpage,
        readingStatus: ReadingStatus.unread,
        title: 'Old Item',
        uri: Uri.parse('https://old.com'),
      );
      final item2 = SavedItem(
        type: ItemType.webpage,
        readingStatus: ReadingStatus.unread,
        title: 'New Item',
        uri: Uri.parse('https://new.com'),
      );

      final items = {'1': item1, '2': item2};

      fakeProvider.setItems(items);
      fakeProvider.setLoadSuccess();

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      final titleFinder1 = find.text('Old Item');
      final titleFinder2 = find.text('New Item');

      expect(titleFinder1, findsOneWidget);
      expect(titleFinder2, findsOneWidget);

      final offset1 = tester.getTopLeft(titleFinder1);
      final offset2 = tester.getTopLeft(titleFinder2);

      expect(
        offset2.dy < offset1.dy,
        true,
        reason: 'New Item should appear above Old Item (list is reversed)',
      );
    });
  });
}
