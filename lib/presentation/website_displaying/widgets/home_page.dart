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

class _HomePageState extends State<HomePage> {
  final _dropdownItems = const ['Creation date', 'Name (A-Z)'];
  String _initialValue = 'Creation date';

  late final ValueNotifier<String> _selectedSortingNotifier;

  @override
  void initState() {
    // TODO: set _initialValue to the one returned from SharedPrerences
    // _initialValue = widget.viewModel.orderBy;
    _selectedSortingNotifier = ValueNotifier(_initialValue);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<SavedItemsProvider>(context, listen: false);

      provider.load();
    });

    super.initState();
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
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SelectionArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverAppBar(
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
              ),
              SliverPadding(
                padding: const EdgeInsets.all(15.0),
                sliver: SliverToBoxAdapter(
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
                          final items = provider.items.values.toList();
                          return Column(
                            children: [
                              Row(
                                children: [
                                  // ! [ SORTING TYPE DROPDOWN ]
                                  LabeledDropdown(
                                    selectedItem: _selectedSortingNotifier,
                                    items: _dropdownItems,
                                    label: 'Sort by',
                                  ),
                                  IconButton(
                                    onPressed: () {
                                      // TODO: switch the value of isDescending
                                      // _viewModel.switchIsDescending();
                                    },
                                    // TODO: show a different arrow according to isDescending
                                    // icon: Icon(_viewModel.isDescending ? Icons.arrow_downward : Icons.arrow_upward)
                                    icon: Icon(Icons.arrow_downward),
                                  ),
                                ],
                              ),
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
            ],
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
