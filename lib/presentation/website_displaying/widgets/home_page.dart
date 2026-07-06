import 'package:articly/domain/providers/saved_items_provider.dart';
import 'package:articly/presentation/authentication/widgets/profile_page.dart';
import 'package:articly/presentation/website_displaying/view_models/saved_item_view_model.dart';
import 'package:articly/presentation/website_displaying/widgets/saved_item_card.dart';
import 'package:articly/presentation/website_saving/widgets/labeled_dropdown.dart';
import 'package:articly/presentation/website_saving/widgets/save_webpage_screen.dart';
import 'package:articly/theme/theme_model.dart';
import 'package:articly/utils/my_action_button.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

// Added SingleTickerProviderStateMixin for the TabController
class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  final _dropdownItems = const ['Creation date', 'Name (A-Z)'];
  String _initialValue = 'Creation date';

  late final ValueNotifier<String> _selectedSortingNotifier;
  late final TabController _tabController;

  // Define the different underline colors for each tab
  final List<Color> _tabIndicatorColors = [
    Colors.blueGrey, // All
    Colors.red, // Unread
    Colors.orange, // Reading
    Colors.green, // Read
  ];

  @override
  void initState() {
    // TODO: set _initialValue to the one returned from SharedPrerences
    // _initialValue = widget.viewModel.orderBy;
    _selectedSortingNotifier = ValueNotifier(_initialValue);

    // Initialize TabController with 4 items
    _tabController = TabController(length: 4, vsync: this);

    // Listen to tab changes to rebuild the UI and update the underline color
    _tabController.addListener(() {
      if (mounted) {
        setState(() {
          // TODO: Update _viewModel.orderBy depending on the _tabController.index
        });
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<SavedItemsProvider>(context, listen: false);

      provider.load();
    });

    super.initState();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    final provider = Provider.of<SavedItemsProvider>(context, listen: false);
    await provider.load();
    if (mounted && provider.loadCommand.hasError && provider.items.isNotEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(provider.loadCommand.error!)));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine the text color based on the current theme so it stays consistent
    final textColor = Theme.of(context).colorScheme.onSurface;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle),
            onPressed: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => ProfilePage()));
            },
          ),
        ],
        // Added the TabBar at the bottom of the normal AppBar
        bottom: TabBar(
          controller: _tabController,
          // Dynamically change indicator color based on current tab index
          indicatorColor: _tabIndicatorColors[_tabController.index],
          // Ensure text color doesn't take the indicator's color
          labelColor: textColor,
          unselectedLabelColor: textColor.withValues(alpha: 0.6),
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Unread'),
            Tab(text: 'Reading'),
            Tab(text: 'Read'),
          ],
        ),
      ),
      body: SelectionArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(15.0),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 450),
                  // ! [ SAVED ITEMS CONSUMER ]
                  child: Consumer<SavedItemsProvider>(
                    builder: (context, provider, child) {
                      if (provider.loadCommand.running &&
                          provider.items.isEmpty) {
                        return SizedBox(
                          height: MediaQuery.of(context).size.height - 200,
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      if (provider.loadCommand.hasError &&
                          provider.items.isEmpty) {
                        return SizedBox(
                          height: MediaQuery.of(context).size.height - 200,
                          child: Center(
                            child: Text(provider.loadCommand.error!),
                          ),
                        );
                      }
                      if (provider.items.isEmpty) {
                        return SizedBox(
                          height: MediaQuery.of(context).size.height - 200,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('No saved sources yet'),
                              const SizedBox(height: 15),
                              MyActionButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => SaveWebpageScreen(),
                                    ),
                                  );
                                },
                                text: 'Add a webpage',
                                icon: Icon(Icons.add),
                              ),
                            ],
                          ),
                        );
                      }

                      // TODO: You will filter the `items` list here based on `_tabController.index`
                      // final items = _viewModel.getItems()
                      final items = provider.items.values.toList();

                      return Column(
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // ! [ SORTING TYPE DROPDOWN ]
                              Expanded(
                                child: LabeledDropdown(
                                  selectedItem: _selectedSortingNotifier,
                                  items: _dropdownItems,
                                  label: 'Sort by',
                                  initialValue: _selectedSortingNotifier.value,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 25.0),
                                child: IconButton(
                                  onPressed: () {
                                    // TODO: switch the value of isDescending
                                    // _viewModel.switchIsDescending();
                                    print('switch button pressed');
                                  },
                                  // TODO: show a different arrow according to isDescending
                                  // icon: Icon(_viewModel.isDescending ? Icons.arrow_downward : Icons.arrow_upward)
                                  icon: Icon(Icons.arrow_downward),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 8),

                          ListView.builder(
                            physics: const NeverScrollableScrollPhysics(),
                            shrinkWrap: true,
                            itemCount: items.length,
                            // reverse so that new items will appear on the top
                            reverse: true,
                            itemBuilder: (context, index) {
                              final item = items[index];
                              // if (_items[index].type == ItemType.webpage)
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 5,
                                ),
                                child: SavedWebpageCard(
                                  key: ValueKey(item.id),
                                  viewModel: SavedItemViewModel(
                                    currentItem: item,
                                    provider: provider,
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => SaveWebpageScreen())),
        child: const Icon(Icons.add),
      ),
    );
  }
}
