import 'package:articly/presentation/authentication/widgets/profile_page.dart';
import 'package:articly/presentation/website_displaying/widgets/saved_item_card.dart';
import 'package:articly/presentation/website_saving/widgets/labeled_dropdown.dart';
import 'package:articly/presentation/website_saving/widgets/save_webpage_screen.dart';
import 'package:articly/utils/my_action_button.dart';
import 'package:articly/utils/providers_shortcuts.dart';
import 'package:flutter/material.dart';

import '../view_models/home_page_view_model.dart';

class HomePage extends StatefulWidget {
  HomePage(BuildContext context, {super.key, HomePageViewModel? viewModel})
    : viewModel =
          viewModel ??
          HomePageViewModel(
            provider: MyProviders(context).savedItemsProvider(),
            prefsService: MyProviders(context).sharedPreferencesService(),
          );

  final HomePageViewModel viewModel;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  late final HomePageViewModel _viewModel;

  bool _isGridView = false;

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
      if (!_tabController.indexIsChanging) {
        _viewModel.switchTab(_tabController.index);
        _viewModel.processItems();
      }
    });

    super.initState();
  }

  @override
  void didUpdateWidget(covariant HomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.viewModel != widget.viewModel) {
      _viewModel = widget.viewModel;
    }
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

    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, child) {
        return Scaffold(
          appBar: _buildAppBar(tabs: tabs),
          body: SelectionArea(
            child: RefreshIndicator(
              onRefresh: _refresh,
              // LayoutBuilder and SingleChildScrollView combination enforces a minimum
              // width for the screen, preventing the zero-width squishing bug on web.
              child: LayoutBuilder(
                builder: (context, constraints) {
                  const double minAppWidth = 200.0;
                  final double currentWidth = constraints.maxWidth > minAppWidth
                      ? constraints.maxWidth
                      : minAppWidth;

                  return SizedBox(
                    width: currentWidth,
                    height: constraints
                        .maxHeight, // Fixes height for the Expanded view below
                    child: Builder(
                      builder: (context) {
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

                        return _buildView();
                      },
                    ),
                  );
                },
              ),
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () async {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => SaveWebpageScreen(context)),
              );
            },
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }

  Column _buildView() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // View Switcher (Grid / List)
              Tooltip(
                message: 'View',
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: SegmentedButton<bool>(
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(
                        value: false,
                        icon: Icon(Icons.view_list_rounded),
                        // label: Text("List View"),
                      ),
                      ButtonSegment(
                        value: true,
                        icon: Icon(Icons.grid_view_rounded),
                        // label: Text("Grid View"),
                      ),
                    ],
                    selected: {_isGridView},
                    onSelectionChanged: (Set<bool> newSelection) {
                      setState(() {
                        _isGridView = newSelection.first;
                      });
                    },
                  ),
                ),
              ),
              // const SizedBox(width: 8),
              Spacer(),
              _buildSortingTypeDropdown(),
              const SizedBox(width: 5),
              _buildDescendingSwitch(),
            ],
          ),
        ),
        // const SizedBox(height: 10),

        // Main Content Area
        Expanded(child: _isGridView ? _buildGridView() : _buildListView()),
      ],
    );
  }

  // =========================================================================
  // GRID VIEW IMPLEMENTATION
  // =========================================================================
  Widget _buildGridView() {
    // final isDarkMode = MyProviders(context).themeModel().isDark(context);
    // final colorScheme = Theme.of(context).colorScheme;
    return GridView.builder(
      padding: const EdgeInsets.only(bottom: 80, left: 8.0, right: 8.0),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 280,
        childAspectRatio: 1.15,
        crossAxisSpacing: 3,
        mainAxisSpacing: 3,
      ),
      itemCount: _viewModel.items.length,
      itemBuilder: (context, index) {
        final item = _viewModel.items[index];
        return SavedItemCard(isGridView: _isGridView, item: item);
      },
    );
  }

  // =========================================================================
  // LIST VIEW IMPLEMENTATION
  // =========================================================================
  Widget _buildListView() {
    return ListView.separated(
      padding: const EdgeInsets.only(top: 8.0, bottom: 70),
      itemCount: _viewModel.items.length,
      separatorBuilder: (context, index) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Divider(height: 1),
      ),
      itemBuilder: (context, index) {
        final item = _viewModel.items[index];
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: SavedItemCard(isGridView: _isGridView, item: item),
        );
      },
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

  Widget _buildDescendingSwitch() {
    return IconButton(
      onPressed: () {
        _viewModel.switchIsDescending();
        _viewModel.processItems();
        // TODO: later, maybe just reverse the ListView instead of re-sorting the list
      },
      icon: Tooltip(
        message: 'Flip direction',
        child: Icon(
          _viewModel.isDescending ? Icons.arrow_upward : Icons.arrow_downward,
        ),
      ),
    );
  }

  Widget _buildSortingTypeDropdown() {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: 170),
      child: Tooltip(
        message: 'Sorting',
        child: LabeledDropdown(
          items: sortingOptions.values.toList(),
          value: sortingOptions[_viewModel.orderBy],
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
          Text(
            _tabController.index == 0
                ? 'No saved sources yet'
                : 'No saved sources for the current status',
          ),
          const SizedBox(height: 20),
          MyActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => SaveWebpageScreen(context)),
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
