import 'package:articly/data/models/saved_item.dart';
import 'package:articly/domain/providers/saved_items_provider.dart';
import 'package:articly/presentation/authentication/widgets/profile_page.dart';
import 'package:articly/presentation/website_displaying/widgets/saved_item_card.dart';
import 'package:articly/presentation/website_saving/widgets/save_webpage_screen.dart';
import 'package:articly/utils/my_action_button.dart';
import 'package:articly/utils/my_snack_bar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<SavedItemsProvider>(context, listen: false);

      provider.load();
    });

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
            padding: const EdgeInsets.all(15.0),
            sliver: SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 450),
                  // ! [ SAVED ITEMS CONSUMER ]
                  child: Consumer<SavedItemsProvider>(
                    builder: (context, provider, child) {
                      if (provider.loadCommand.running) {
                        return const CircularProgressIndicator();
                      }
                      if (provider.loadCommand.hasError) {
                        return Text(provider.loadCommand.error!);
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
                                      builder: (_) => SaveWebsiteScreen(),
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
                      return ListView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: items.length,
                        // reverse so that new items will appear on the top
                        reverse: true,
                        itemBuilder: (context, index) {
                          final item = items[index];
                          // if (_items[index].type == ItemType.webpage)
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 5),
                            child: SavedWebpageCard(
                              key: ValueKey('card$index'),
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
