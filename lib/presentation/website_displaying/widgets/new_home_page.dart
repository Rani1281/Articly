import 'package:articly/utils/providers_shortcuts.dart';
import 'package:flutter/material.dart';

// Data Model to represent each saved item
class SavedItem {
  final String title;
  final String status;
  final String imageUrl;
  final String url; // Added full url

  SavedItem({
    required this.title,
    required this.status,
    required this.imageUrl,
    required this.url,
  });

  // Getter to extract just the host domain (e.g. "booking.com")
  String get shortDomain {
    try {
      final uri = Uri.parse(url);
      String host = uri.host;
      if (host.startsWith('www.')) {
        host = host.substring(4);
      }
      return host;
    } catch (e) {
      return url; // fallback just in case of parse error
    }
  }
}

class SavedContentScreen extends StatefulWidget {
  const SavedContentScreen({super.key});

  @override
  State<SavedContentScreen> createState() => _SavedContentScreenState();
}

class _SavedContentScreenState extends State<SavedContentScreen> {
  // Toggle state: 'false' so List View is the default
  bool _isGridView = false;

  Color getStatusColor(String status) {
    switch (status) {
      case "Read":
        return Colors.green;
      case "Unread":
        return Colors.red;
      case "Reading":
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  // Sample data simulating the content with full urls added
  final List<SavedItem> _savedItems = [
    SavedItem(
      title: "Cake recipe",
      status: "Read",
      url: "https://www.foodnetwork.com/recipes/basic-cake-recipe",
      imageUrl:
          "https://images.unsplash.com/photo-1578985545062-69928b1d9587?auto=format&fit=crop&q=80&w=400&h=200",
    ),
    SavedItem(
      title: "Vector databases: Explanation & Examples",
      status: "Unread",
      url: "https://towardsdatascience.com/vector-databases-explained",
      imageUrl:
          "https://images.unsplash.com/photo-1544383835-bda2bc66a55d?auto=format&fit=crop&q=80&w=400&h=200",
    ),
    SavedItem(
      title: "Best Travel Destinations in 2026",
      status: "Reading",
      url: "https://www.booking.com/articles/destinations-2026",
      imageUrl:
          "https://images.unsplash.com/photo-1488085061387-422e29b40080?auto=format&fit=crop&q=80&w=400&h=200",
    ),
    // The "Template" edge-case item with a very long text to demonstrate truncation for both title and url
    SavedItem(
      title:
          "Extremely long title placeholder to demonstrate how the layout handles truncation beyond two lines in grid and one line in list",
      status: "Status",
      url:
          "https://www.a-very-long-domain-name-that-will-definitely-overflow-the-container.com/article/123",
      imageUrl:
          "https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?auto=format&fit=crop&q=80&w=400&h=200",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // TODO: add app bar for switching reading modes
      // LayoutBuilder and SingleChildScrollView combination enforces a minimum
      // width for the screen, preventing the zero-width squishing bug on web.
      body: LayoutBuilder(
        builder: (context, constraints) {
          const double minAppWidth = 360.0;
          final double currentWidth = constraints.maxWidth > minAppWidth
              ? constraints.maxWidth
              : minAppWidth;

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const ClampingScrollPhysics(),
            child: SizedBox(
              width: currentWidth,
              height: constraints
                  .maxHeight, // Fixes height for the Expanded view below
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // View Switcher (Grid / List)
                    Align(
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

                    const SizedBox(height: 10),

                    // Main Content Area
                    Expanded(
                      child: _isGridView ? _buildGridView() : _buildListView(),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // =========================================================================
  // GRID VIEW IMPLEMENTATION
  // =========================================================================
  Widget _buildGridView() {
    final isDarkMode = MyProviders(context).themeModel().isDark(context);
    final colorScheme = Theme.of(context).colorScheme;
    return GridView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 280,
        childAspectRatio: 1.15,
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
      ),
      itemCount: _savedItems.length,
      itemBuilder: (context, index) {
        final item = _savedItems[index];
        return Card(
          elevation: 2,
          color: !isDarkMode
              ? colorScheme.surfaceContainerLowest
              : colorScheme.surfaceContainer,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: colorScheme.onSurface.withValues(alpha: 0.1),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top text section
              Padding(
                padding: const EdgeInsets.only(
                  top: 12,
                  left: 12,
                  right: 12,
                  bottom: 6,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 2.0, right: 8.0),
                          child: Icon(
                            Icons.link_rounded,
                            size: 20,
                            color: Colors.blueGrey,
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 3.5),
                            child: Text(
                              item.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                height: 1.2,
                              ),
                            ),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.only(left: 4.0),
                          child: Icon(
                            Icons.more_vert,
                            size: 20,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Status & Domain Row
                    Row(
                      children: [
                        // Domain (Truncates if too long)
                        Expanded(
                          child: Text(
                            item.shortDomain,
                            textAlign: TextAlign.left,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.blueGrey.shade300,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          "• ",
                          style: TextStyle(color: Colors.blue, fontSize: 16),
                        ),
                        // Status (Always full form)
                        Text(
                          item.status,
                          style: const TextStyle(
                            color: Colors.blue,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Bottom image section
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(
                    left: 12,
                    right: 12,
                    bottom: 12,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey.shade200,
                    image: DecorationImage(
                      image: NetworkImage(item.imageUrl),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // =========================================================================
  // LIST VIEW IMPLEMENTATION
  // =========================================================================
  Widget _buildListView() {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      itemCount: _savedItems.length,
      separatorBuilder: (context, index) => Divider(height: 1),
      itemBuilder: (context, index) {
        final item = _savedItems[index];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Circular Link Icon
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: const Icon(
                  Icons.link_rounded,
                  size: 20,
                  color: Colors.blueGrey,
                ),
              ),
              const SizedBox(width: 16),

              // Text Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    // Status & Domain Row
                    Row(
                      children: [
                        // Domain (Truncates if too long)
                        Expanded(
                          child: Text(
                            item.shortDomain,
                            textAlign: TextAlign.left,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.blueGrey.shade300,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Status (Always full form)
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),

              const Text(
                "• ",
                style: TextStyle(color: Colors.blue, fontSize: 16),
              ),
              Text(
                item.status,
                style: TextStyle(
                  color: Colors.blue,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(width: 12),

              // Options Icon
              const Icon(Icons.more_vert, color: Colors.grey),
            ],
          ),
        );
      },
    );
  }
}
