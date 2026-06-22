import 'package:articly/data/models/saved_item.dart';
import 'package:articly/presentation/authentication/widgets/profile_page.dart';
import 'package:articly/presentation/website_displaying/view_models/home_page_view_model.dart';
import 'package:articly/presentation/website_displaying/widgets/saved_item_card.dart';
import 'package:articly/presentation/website_saving/widgets/save_webpage_screen.dart';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  HomePage({super.key, HomePageViewModel? viewModel})
    : viewModel = viewModel ?? HomePageViewModel();

  final HomePageViewModel viewModel;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    widget.viewModel.load.execute();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
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
            padding: const EdgeInsets.all(24.0),
            sliver: SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 450),
                  child: ListenableBuilder(
                    listenable: widget.viewModel,
                    builder: (context, _) {
                      if (widget.viewModel.load.running) {
                        return const CircularProgressIndicator();
                      }
                      if (widget.viewModel.load.hasError) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(widget.viewModel.load.error!),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                      final items = widget.viewModel.items.values.toList();
                      return ListView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final item = items[index];
                          // if (_items[index].type == ItemType.webpage)
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 5),
                            child: SavedWebpageCard(
                              title: item.title,
                              uri: item.uri,
                              status: item.readingStatus.name,
                              notes: item.notes,
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => SaveWebsiteScreen())),
        child: const Icon(Icons.add),
      ),
    );
  }
}
