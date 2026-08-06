import 'package:articly/presentation/authentication/widgets/profile_page.dart';
import 'package:articly/presentation/website_displaying/widgets/saved_item_card.dart';
import 'package:articly/presentation/website_displaying/widgets/show_bottom_sheets.dart';
import 'package:articly/presentation/website_saving/widgets/save_webpage_screen.dart';
import 'package:articly/utils/my_action_button.dart';
import 'package:articly/utils/providers_shortcuts.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

import '../view_models/home_page_view_model.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, this.viewModel});

  final HomePageViewModel? viewModel;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  late HomePageViewModel _viewModel;

  // final sortingOptions = {
  //   OrderType.creationDate: 'Creation date',
  //   OrderType.name: 'Name (A-Z)',
  // };

  // final _dropdownItems = const ['Creation date', 'Name (A-Z)'];
  late final TabController _tabController;

  bool _isRefreshing = false;

  final Logger log = Logger('HomePage');

  @override
  void initState() {
    _viewModel =
        widget.viewModel ??
        HomePageViewModel(
          provider: MyProviders(context).savedItemsProvider(),
          prefsService: MyProviders(context).sharedPreferencesService(),
        );

    // start processing the items
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _viewModel.processItems(),
    );

    // Initialize TabController with 4 items
    _tabController = TabController(length: 4, vsync: this);

    super.initState();
  }

  @override
  void didUpdateWidget(covariant HomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.viewModel != widget.viewModel && widget.viewModel != null) {
      _viewModel = widget.viewModel!;
      // _viewModel.switchTab(_tabController.index);
      _viewModel.processItems();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    _isRefreshing = true;
    await _viewModel.processItems(reload: true);
    // reload should be false (as default) to avoid mismatches with SharedPreferences
    // since operation aren't awaited so it could happen that data hasn't been
    // set there yet.
    if (mounted &&
        _viewModel.processItemsCommand.hasError &&
        _viewModel.items.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_viewModel.processItemsCommand.error!)),
      );
    }
    _isRefreshing = false;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, child) {
        return Scaffold(
          appBar: _buildAppBar(),
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
                        if (_viewModel.processItemsCommand.running &&
                            !_isRefreshing) {
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
                MaterialPageRoute(builder: (_) => const SaveWebpageScreen()),
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
          padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 16.0),
          child: _buildListToolBar(),
        ),
        // const SizedBox(height: 10),

        // Main Content Area
        Expanded(
          child: _viewModel.isGridView ? _buildGridView() : _buildListView(),
        ),
      ],
    );
  }

  Widget _buildListToolBar() {
    final isGridView = _viewModel.isGridView;
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        // view switcher (list view / grid view)
        _viewModel.isGridView
            // list view icon button
            ? IconButton(
                tooltip: 'List view',
                onPressed: () {
                  _viewModel.setIsGridView(false);
                  log.info('Is grid view: ${_viewModel.isGridView}');
                },
                icon: Icon(
                  Icons.list,
                  color: !isGridView
                      ? colorScheme.onSurface
                      : colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              )
            // grid view icon button
            : IconButton(
                tooltip: 'Grid view',
                onPressed: () {
                  _viewModel.setIsGridView(true);
                  log.info('Is grid view: ${_viewModel.isGridView}');
                },
                icon: Icon(
                  Icons.grid_view_outlined,
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),

        const Spacer(),

        // filter icon button
        IconButton(
          tooltip: _viewModel.filter != FilterType.none
              ? 'Clear filter'
              : 'Filter',
          onPressed: () async {
            if (_viewModel.filter != FilterType.none) {
              // clear the filter on each second press
              _viewModel.setFilter(FilterType.none);
              log.info('Clearing filter');
            } else {
              await showFilterBottomSheet(
                context: context,
                currentValue: _viewModel.filter,
                onChanged: (FilterType filter) {
                  _viewModel.setFilter(filter);
                },
              );
              log.info('Selected filter: ${_viewModel.filter}');
            }
          },
          icon: Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(
                Icons.filter_list,
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              if (_viewModel.filter != FilterType.none)
                Positioned(
                  right: -3,
                  bottom: -3,
                  child: const Center(
                    child: Icon(
                      Icons.close_rounded,
                      size: 16,
                      color: Colors.red,
                    ),
                  ),
                ),
            ],
          ),
        ),

        // clear filter
        const SizedBox(width: 5),

        // sorting icon button
        IconButton(
          tooltip: 'Sort',
          onPressed: () async {
            await showSortBottomSheet(
              context: context,
              currentSort: _viewModel.orderBy,
              isBottomUp: !_viewModel.isDescending,
              onApply: (OrderType order, bool isBottomUp) {
                // bottom up = ascending
                _viewModel.setSorting(order, !isBottomUp);
              },
            );
            log.info(
              'Order by ${_viewModel.orderBy}, Is descending: ${_viewModel.isDescending}',
            );
          },
          icon: Icon(
            Icons.swap_vert,
            color: colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
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
        return SavedItemCard(
          isGridView: _viewModel.isGridView,
          item: item,
          onDeleted: _refresh,
        );
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
          child: SavedItemCard(
            isGridView: _viewModel.isGridView,
            item: item,
            onDeleted: _refresh,
          ),
        );
      },
    );
  }

  AppBar _buildAppBar() {
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
                MaterialPageRoute(builder: (_) => const SaveWebpageScreen()),
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
