import 'package:articly/data/models/reading_status_count.dart';
import 'package:articly/data/models/saved_item.dart';
import 'package:articly/presentation/authentication/widgets/profile_page.dart';
import 'package:articly/presentation/website_displaying/widgets/donut_chart.dart';
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

  late final TabController _tabController;

  bool _isRefreshing = false;

  final unreadColor = Colors.blue.shade100;
  final readingColor = Colors.blue.shade300;
  final readColor = Colors.blue.shade600;

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
        return LayoutBuilder(
          builder: (context, outerConstraints) {
            // Determine if we have a wide screen (e.g. web/desktop)
            final bool isWideScreen = outerConstraints.maxWidth > 800;

            return Scaffold(
              // Hide default AppBar on wide screens, handle it in the layout instead
              appBar: isWideScreen ? null : _buildAppBar(),
              body: SelectionArea(
                child: RefreshIndicator(
                  onRefresh: _refresh,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      const double minAppWidth = 200.0;
                      final double currentWidth =
                          constraints.maxWidth > minAppWidth
                          ? constraints.maxWidth
                          : minAppWidth;

                      return SizedBox(
                        width: currentWidth,
                        height: constraints.maxHeight,
                        child: isWideScreen
                            ? _buildWideLayout()
                            : _buildMobileLayout(),
                      );
                    },
                  ),
                ),
              ),
              floatingActionButton: FloatingActionButton(
                onPressed: () async {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const SaveWebpageScreen(),
                    ),
                  );
                },
                child: const Icon(Icons.add),
              ),
            );
          },
        );
      },
    );
  }

  // =========================================================================
  // RESPONSIVE LAYOUTS
  // =========================================================================

  Widget _buildWideLayout() {
    final colorScheme = Theme.of(context).colorScheme;
    final counts = _viewModel.readingStatusCount;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left Pane Window
        Container(
          color: colorScheme.surfaceContainerLow,
          width: 340, // Fixed width for left pane, adjust as needed
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Safe area spacing + Profile Icon Button in top right corner
              Padding(
                padding: const EdgeInsets.only(
                  top: 8.0,
                  right: 8.0,
                  bottom: 8.0,
                ),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    icon: const Icon(Icons.account_circle, size: 28),
                    onPressed: () {
                      Navigator.of(
                        context,
                      ).push(MaterialPageRoute(builder: (_) => ProfilePage()));
                    },
                  ),
                ),
              ),
              // Progress Card
              Expanded(
                child: SingleChildScrollView(
                  child: _buildProgressDonutContainer(colorScheme, counts),
                ),
              ),
            ],
          ),
        ),

        // Divider separating panes
        VerticalDivider(
          width: 1,
          thickness: 1,
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),

        // Right Pane Window
        Expanded(
          child: Builder(
            builder: (context) {
              if (_viewModel.processItemsCommand.running && !_isRefreshing) {
                return _buildRunningView();
              }
              if (_viewModel.processItemsCommand.hasError &&
                  !_viewModel.processItemsCommand.completed) {
                return _buildErrorView();
              }
              if (_viewModel.items.isEmpty) {
                return _buildNoItemsView();
              }

              return CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  _buildSavedSourcesTitle(),
                  _buildToolbarSliver(),
                  _viewModel.isGridView
                      ? _buildSliverGridView()
                      : _buildSliverListView(),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    if (_viewModel.processItemsCommand.running && !_isRefreshing) {
      return _buildRunningView();
    }
    if (_viewModel.processItemsCommand.hasError &&
        !_viewModel.processItemsCommand.completed) {
      return _buildErrorView();
    }
    if (_viewModel.items.isEmpty) {
      return _buildNoItemsView();
    }

    final colorScheme = Theme.of(context).colorScheme;
    final counts = _viewModel.readingStatusCount;

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        // Progress donut chart
        SliverToBoxAdapter(
          child: _buildProgressDonutContainer(colorScheme, counts),
        ),
        _buildSavedSourcesTitle(),
        _buildToolbarSliver(),
        // Main Content Area
        _viewModel.isGridView ? _buildSliverGridView() : _buildSliverListView(),
      ],
    );
  }

  // =========================================================================
  // SHARED WIDGETS
  // =========================================================================

  Widget _buildSavedSourcesTitle() {
    return SliverToBoxAdapter(
      child: Padding(
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
    );
  }

  Widget _buildToolbarSliver() {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _SliverToolbarDelegate(child: _buildListToolBar()),
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
          padding: EdgeInsets.all(30),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  DonutChartWidget(
                    sections: [
                      DonutChartSection(
                        value: counts.unread.toDouble(),
                        color: unreadColor,
                        label: ReadingStatus.unread.name,
                      ),
                      DonutChartSection(
                        value: counts.reading.toDouble(),
                        color: readingColor,
                        label: ReadingStatus.reading.name,
                      ),
                      DonutChartSection(
                        value: counts.read.toDouble(),
                        color: readColor,
                        label: ReadingStatus.read.name,
                      ),
                    ],
                    // Center number = to finish reading
                    centerNumber: counts.unread + counts.reading,
                    centerText: 'TO FINISH',
                  ),

                  // Title counts
                  // if (kIsWeb) ...[_buildTitleCounts(horizontal: true)],
                ],
              ),

              // Title counts
              _buildTitleCounts(horizontal: true),
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
        lineColor: unreadColor,
        horizontal: horizontal,
      ),
      _buildTitle(
        text: 'READING',
        count: counts.reading,
        lineColor: readingColor,
        horizontal: horizontal,
      ),
      _buildTitle(
        text: 'READ',
        count: counts.read,
        lineColor: readColor,
        horizontal: horizontal,
      ),
    ];

    return horizontal
        ? Padding(
            padding: EdgeInsets.only(top: 30),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
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
    );

    return horizontal
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Container(
                width: 50,
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

        // filter text (visible is a filter is applied)
        if (_viewModel.filter != FilterType.none)
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              _viewModel.setFilter(FilterType.none);
              log.info('Clearing filter');
            },
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              spacing: 3,
              children: [
                Icon(Icons.clear, size: 18, color: Colors.blueGrey),
                SelectionContainer.disabled(
                  child: Text(
                    _viewModel.filter.name,
                    style: TextStyle(color: Colors.blueGrey),
                  ),
                ),
              ],
            ),
          ),

        // filter icon button
        IconButton(
          tooltip: _viewModel.filter != FilterType.none
              ? 'Clear filter'
              : 'Filter',
          onPressed: () async {
            await showFilterBottomSheet(
              context: context,
              currentValue: _viewModel.filter,
              onChanged: (FilterType filter) {
                _viewModel.setFilter(filter);
              },
            );
            log.info('Selected filter: ${_viewModel.filter}');
          },
          icon: Icon(
            Icons.filter_list,
            color: colorScheme.onSurface.withValues(alpha: 0.9),
          ),
        ),

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
                _viewModel.setSorting(order, !isBottomUp);
              },
            );
            log.info(
              'Order by ${_viewModel.orderBy}, Is descending: ${_viewModel.isDescending}',
            );
          },
          icon: Icon(
            Icons.swap_vert,
            color: colorScheme.onSurface.withValues(alpha: 0.9),
          ),
        ),
      ],
    );
  }

  // =========================================================================
  // SLIVER GRID VIEW IMPLEMENTATION
  // =========================================================================
  Widget _buildSliverGridView() {
    return SliverPadding(
      padding: const EdgeInsets.only(bottom: 80, left: 8.0, right: 8.0),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 280,
          childAspectRatio: 1.15,
          crossAxisSpacing: 3,
          mainAxisSpacing: 3,
        ),
        delegate: SliverChildBuilderDelegate((context, index) {
          final item = _viewModel.items[index];
          return SavedItemCard(
            isGridView: _viewModel.isGridView,
            item: item,
            onDeleted: _refresh,
          );
        }, childCount: _viewModel.items.length),
      ),
    );
  }

  // =========================================================================
  // SLIVER LIST VIEW IMPLEMENTATION
  // =========================================================================
  Widget _buildSliverListView() {
    return SliverPadding(
      padding: const EdgeInsets.only(top: 8.0, bottom: 70),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final item = _viewModel.items[index];
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: SavedItemCard(
                  isGridView: _viewModel.isGridView,
                  item: item,
                  onDeleted: _refresh,
                ),
              ),
              if (index < _viewModel.items.length - 1)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Divider(height: 1),
                ),
            ],
          );
        }, childCount: _viewModel.items.length),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      scrolledUnderElevation: 0,
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
    return const CustomScrollView(
      physics: AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverFillRemaining(child: Center(child: CircularProgressIndicator())),
      ],
    );
  }

  Widget _buildErrorView() {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverFillRemaining(
          child: Center(child: Text(_viewModel.processItemsCommand.error!)),
        ),
      ],
    );
  }

  Widget _buildNoItemsView() {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverFillRemaining(
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
                    MaterialPageRoute(
                      builder: (_) => const SaveWebpageScreen(),
                    ),
                  );
                },
                text: 'Add a webpage',
                icon: Icon(Icons.add),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SliverToolbarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double height = 58.0;

  _SliverToolbarDelegate({required this.child});

  @override
  double get minExtent => height;
  @override
  double get maxExtent => height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final theme = Theme.of(context);
    final isPinned = shrinkOffset > 0;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: isPinned
                ? theme.dividerColor.withValues(alpha: 0.2)
                : Colors.transparent,
            width: 1,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 16.0),
      child: SizedBox.expand(child: child),
    );
  }

  @override
  bool shouldRebuild(_SliverToolbarDelegate oldDelegate) {
    return child != oldDelegate.child || height != oldDelegate.height;
  }
}
