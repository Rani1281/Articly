import 'package:articly/data/models/saved_item.dart';
import 'package:articly/presentation/authentication/widgets/profile_page.dart';
import 'package:articly/presentation/website_displaying/widgets/saved_item_card.dart';
import 'package:articly/presentation/website_saving/widgets/save_webpage_screen.dart';
import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  HomePage({super.key});

  final List<SavedItem> _items = [
    SavedItem(
      type: ItemType.webpage,
      readingStatus: ReadingStatus.unread,
      uri: Uri.parse('https://machine-learning.com/page'),
      title: 'How does a vector database work?',
      remindReading: true,
      notes:
          """- RAG is currently one of the most important techniques in practical AI applications.
          - Vector databases allow a semantic understanding of the user queries.""",
    ),
    SavedItem(
      type: ItemType.webpage,
      readingStatus: ReadingStatus.read,
      uri: Uri.parse('http://machine-learning.com/page'),
      title:
          'How does a vector database work? How does a vector database work?',
      remindReading: true,
      notes:
          """- RAG is currently one of the most important techniques in practical AI applications.
          - Vector databases allow a semantic understanding of the user queries.""",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // title: const Text('Home'),
        actions: [
          IconButton(
            icon: Icon(Icons.account_circle),
            onPressed: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => ProfilePage()));
            },
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 450),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: ListView.builder(
              itemBuilder: (context, index) {
                final item = _items[index];
                // if (_items[index].type == ItemType.webpage)
                return SavedWebpageCard(
                  title: item.title,
                  urlHost: item.uri?.host,
                  status: item.readingStatus.name,
                  notes: item.notes,
                );
              },
            ),
          ),
        ),
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
