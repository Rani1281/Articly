import 'package:articly/data/models/reading_status_count.dart';
import 'package:articly/data/models/saved_item.dart';
import 'package:articly/presentation/authentication/widgets/profile_page.dart';
import 'package:articly/presentation/website_displaying/widgets/donut_chart.dart';
import 'package:articly/presentation/website_displaying/widgets/saved_item_card.dart';
import 'package:articly/presentation/website_displaying/widgets/show_bottom_sheets.dart';
import 'package:articly/presentation/website_saving/widgets/save_webpage_screen.dart';
import 'package:articly/utils/my_action_button.dart';
import 'package:articly/utils/providers_shortcuts.dart';
import 'package:flutter/foundation.dart';
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
    final colorScheme = Theme.of(context).colorScheme;
    final counts = _viewModel.readingStatusCount;
    return Column(
      children: [
        // Progress donut chart
        _buildProgressDonutContainer(colorScheme, counts),

        // Title counts
        if (!kIsWeb) ...[_buildTitleCounts(horizontal: false)],
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'SAVED SOURCES',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ),
        ),

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

  Padding _buildProgressDonutContainer(
    ColorScheme colorScheme,
    ReadingStatusCount counts,
  ) {
    return Padding(
      padding: EdgeInsetsGeometry.all(16.0),
      child: Center(
        child: Container(
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(30),
          ),
          padding: EdgeInsets.all(24),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              DonutChartWidget(
                sections: [
                  DonutChartSection(
                    value: counts.unread.toDouble(),
                    color: Colors.blue.shade100,
                    label: ReadingStatus.unread.name,
                  ),
                  DonutChartSection(
                    value: counts.reading.toDouble(),
                    color: Colors.blue.shade300,
                    label: ReadingStatus.reading.name,
                  ),
                  DonutChartSection(
                    value: counts.read.toDouble(),
                    color: Colors.blue.shade500,
                    label: ReadingStatus.read.name,
                  ),
                ],
                // Center number = to finish reading
                centerNumber: counts.unread + counts.reading,
                centerText: 'TO FINISH',
              ),

              // Title counts
              if (kIsWeb) ...[_buildTitleCounts(horizontal: false)],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTitleCounts({required bool horizontal}) {
    final counts = _viewModel.readingStatusCount;
    final allTitles = [
      _buildTitle(
        text: 'UNREAD',
        count: counts.unread,
        lineColor: Colors.blue.shade100,
        horizontal: horizontal,
      ),
      _buildTitle(
        text: 'READING',
        count: counts.reading,
        lineColor: Colors.blue.shade300,
        horizontal: horizontal,
      ),
      _buildTitle(
        text: 'READ',
        count: counts.read,
        lineColor: Colors.blue.shade500,
        horizontal: horizontal,
      ),
    ];

    return horizontal
        ? Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: allTitles,
            ),
          )
        : Padding(
            padding: EdgeInsets.only(left: 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 8,
              children: allTitles,
            ),
          );
  }

  Widget _buildTitle({
    required String text,
    required int count,
    required Color lineColor,
    required bool horizontal,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    final countTextStyle = TextStyle(
      fontSize: 18,
      color: colorScheme.onSurface,
      fontWeight: FontWeight.w600,
    );
    final titleTextStyle = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w900,
      color: colorScheme.onSurface.withValues(alpha: 0.7),
      // decoration: TextDecoration.underline,
      // decorationColor: underlineColor,
    );

    // if horizontal = true, the count needs to be above the title
    // TODO later maybe: make it so when clicking this, the list will automatically get filtered
    return horizontal
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              // Divider(color: lineColor, thickness: 2),
              Container(
                width: 20,
                height: 8,
                decoration: BoxDecoration(
                  color: lineColor,
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              const SizedBox(height: 8),
              Text(count.toString(), style: countTextStyle),
              const SizedBox(height: 8),
              Text(text, style: titleTextStyle),
            ],
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // VerticalDivider(color: lineColor, thickness: 2),
              Container(
                width: 8,
                height: 20,
                decoration: BoxDecoration(
                  color: lineColor,
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              const SizedBox(width: 12),
              Text(count.toString(), style: countTextStyle),
              const SizedBox(width: 12),
              Text(text, style: titleTextStyle),
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
                      : colorScheme.onSurface.withValues(alpha: 0.9),
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
                  color: colorScheme.onSurface.withValues(alpha: 0.9),
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
                color: colorScheme.onSurface.withValues(alpha: 0.9),
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
