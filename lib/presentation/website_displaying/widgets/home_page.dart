import 'package:articly/data/models/saved_item.dart';
import 'package:articly/presentation/authentication/widgets/profile_page.dart';
import 'package:articly/presentation/website_displaying/view_models/home_page_view_model.dart';
import 'package:articly/presentation/website_displaying/view_models/saved_item_view_model.dart';
import 'package:articly/presentation/website_displaying/widgets/saved_item_card.dart';
import 'package:articly/presentation/website_saving/widgets/labeled_dropdown.dart';
import 'package:articly/presentation/website_saving/widgets/save_webpage_screen.dart';
import 'package:articly/utils/my_action_button.dart';
import 'package:articly/utils/providers_shortcuts.dart';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  HomePage(BuildContext? context, {super.key, HomePageViewModel? viewModel})
    : viewModel =
          viewModel ??
          HomePageViewModel(
            provider: MyProviders(context!).savedItemsProvider(),
            prefsService: MyProviders(context).sharedPreferencesService(),
          );

  final HomePageViewModel viewModel;

  @override
  State<HomePage> createState() => _HomePageState();
}

// Added SingleTickerProviderStateMixin for the TabController
class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  late final HomePageViewModel _viewModel;

  final sortingOptions = {
    OrderType.creationDate: 'Creation date',
    OrderType.name: 'Name (A-Z)',
  };

  // final _dropdownItems = const ['Creation date', 'Name (A-Z)'];
  late final TabController _tabController;

  @override
  void initState() {
    _viewModel = widget.viewModel;

    // start processing the items
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _viewModel.processItems(),
    );

    // Initialize TabController with 4 items
    _tabController = TabController(length: 4, vsync: this);

    // Listen to tab changes to rebuild the tab selection and re-process the items based on the new filter
    _tabController.addListener(() {
      _viewModel.switchTab(_tabController.index);
      _viewModel.processItems();
    });

    super.initState();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    await _viewModel.processItems(reload: true);
    if (mounted &&
        _viewModel.processItemsCommand.hasError &&
        _viewModel.items.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_viewModel.processItemsCommand.error!)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tabs = const [
      Tab(text: 'All'),
      Tab(text: 'Unread'),
      Tab(text: 'Reading'),
      Tab(text: 'Read'),
    ];

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: _buildAppBar(tabs: tabs),
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
                  child: ListenableBuilder(
                    listenable: _viewModel,
                    builder: (context, child) {
                      if (_viewModel.processItemsCommand.running) {
                        return _buildRunningView();
                      }
                      if (_viewModel.processItemsCommand.hasError &&
                          !_viewModel.processItemsCommand.completed) {
                        return _buildErrorView();
                      }

                      if (_viewModel.items.isEmpty) {
                        return _buildNoItemsView();
                      }

                      return _buildTabView();
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => SaveWebpageScreen()));
          _viewModel.processItems(); // reload after coming back to the page
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildTabView() {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text('Sorting', style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(width: 8),
            _buildSortingTypeDropdown(),
            _buildDescendingSwitch(),
          ],
        ),
        const SizedBox(height: 8),
        _buildListView(),
      ],
    );
  }

  Widget _buildListView() {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: _viewModel.items.length,
      itemBuilder: (context, index) {
        final item = _viewModel.items[index];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: _buildItemCard(item),
        );
      },
    );
  }

  Widget _buildItemCard(SavedItem item) {
    return SavedWebpageCard(
      key: ValueKey(item.id),
      viewModel: SavedItemViewModel(
        currentItem: item,
        provider: _viewModel.provider,
      ),
    );
  }

  Widget _buildDescendingSwitch() {
    return IconButton(
      onPressed: () {
        _viewModel.switchIsDescending();
        _viewModel.processItems();
        // TODO: later, maybe just reverse the ListView instead of re-sorting the list
      },
      icon: Tooltip(
        message: 'Flip',
        child: Icon(
          _viewModel.isDescending ? Icons.arrow_upward : Icons.arrow_downward,
        ),
      ),
    );
  }

  Widget _buildSortingTypeDropdown() {
    final selectedSortingNotifier = ValueNotifier(
      sortingOptions[_viewModel.orderBy] ?? 'Creation date',
    );

    return Expanded(
      child: LabeledDropdown(
        selectedItem: selectedSortingNotifier,
        items: sortingOptions.values.toList(),
        initialValue: selectedSortingNotifier.value,
        onChanged: (newValue) {
          if (newValue == null) return;

          OrderType orderBy = OrderType.creationDate;
          if (newValue == 'Name (A-Z)') {
            orderBy = OrderType.name;
          }
          debugPrint('Selected orderBy: $orderBy');

          // don't wait for these operations (should be fast)
          _viewModel.setOrderBy(orderBy);
          _viewModel.processItems();
        },
      ),
    );
  }

  AppBar _buildAppBar({required List<Tab> tabs}) {
    // Define the different underline colors for each tab
    final List<Color> tabIndicatorColors = [
      Colors.blueGrey, // All
      Colors.red, // Unread
      Colors.orange, // Reading
      Colors.green, // Read
    ];

    final textColor = Theme.of(context).colorScheme.onSurface;
    return AppBar(
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
        indicatorColor: tabIndicatorColors[_tabController.index],
        labelColor: textColor,
        unselectedLabelColor: textColor.withValues(alpha: 0.6),
        tabs: tabs,
      ),
    );
  }

  Widget _buildRunningView() {
    return SizedBox(
      height: MediaQuery.of(context).size.height - 200,
      child: Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildErrorView() {
    return SizedBox(
      height: MediaQuery.of(context).size.height - 200,
      child: Center(child: Text(_viewModel.processItemsCommand.error!)),
    );
  }

  Widget _buildNoItemsView() {
    return SizedBox(
      height: MediaQuery.of(context).size.height - 200,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('No saved sources yet'),
          const SizedBox(height: 20),
          MyActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => SaveWebpageScreen()),
              );
            },
            text: 'Add a webpage',
            icon: Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}
