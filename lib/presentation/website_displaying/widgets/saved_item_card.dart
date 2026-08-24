import 'package:articly/config/config.dart';
import 'package:articly/data/models/saved_item.dart';
import 'package:articly/presentation/website_displaying/view_models/saved_item_view_model.dart';
import 'package:articly/presentation/website_saving/widgets/save_webpage_screen.dart';
import 'package:articly/utils/my_snack_bar.dart';
import 'package:articly/utils/providers_shortcuts.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';

class SavedItemCard extends StatefulWidget {
  const SavedItemCard({
    super.key,
    required this.isGridView,
    required this.item,
    this.isDark = false,
    this.onDeleted,
    // this.onEdit,
  });

  final bool isGridView;
  final SavedItem item;
  final bool isDark;
  final VoidCallback? onDeleted;
  // final VoidCallback? onEdit;

  @override
  State<SavedItemCard> createState() => _SavedItemCardState();
}

class _SavedItemCardState extends State<SavedItemCard> {
  late SavedItemViewModel _viewModel;
  late bool _isGridView;

  bool showedSuccessMessage = false;

  final log = Logger('SavedItemCard');

  @override
  void initState() {
    super.initState();
    _viewModel = SavedItemViewModel(
      currentItem: widget.item,
      provider: MyProviders(context).userProvider(),
    );
    _isGridView = widget.isGridView;

    // _viewModel.addListener(_checkDeletion);
  }

  @override
  void didUpdateWidget(covariant SavedItemCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    _isGridView = widget.isGridView;

    if (oldWidget.item != widget.item) {
      _viewModel.currentItem = widget.item;
      // add setState({}) ?
    }
  }

  _openUrl() async {
    final currentItem = _viewModel.currentItem;
    if (currentItem.uri.toString().isEmpty) {
      return null;
    }
    await _viewModel.openUrl();
    if (!_viewModel.openUrlCommand.completed &&
        _viewModel.openUrlCommand.hasError &&
        mounted) {
      MySnackBar(context, message: _viewModel.openUrlCommand.error!).show();
    }
  }

  _deleteItem() async {
    final confirm = await _showDeleteDialog();
    if (confirm == true) {
      await _viewModel.deleteItem();
    }
    if (!mounted) return;
    if (_viewModel.deleteItemCommand.completed &&
        !_viewModel.deleteItemCommand.hasError & mounted) {
      MySnackBar(context, message: 'Item deleted successfully!').show();
      showedSuccessMessage = true;
      widget.onDeleted?.call();
    } else {
      MySnackBar(context, message: _viewModel.deleteItemCommand.error!).show();
    }
  }

  _editItem() async {
    final SavedItem? newItem = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SaveWebpageScreen(
          isEdit: true,
          currentItem: _viewModel.currentItem,
        ),
      ),
    );
    if (newItem != null) {
      _viewModel.currentItem = newItem;
      log.info('New item: $newItem');
    }
  }

  _updateStatus(ReadingStatus newStatus) async {
    await _viewModel.updateStatus(newStatus);
    if (!mounted) return;
    if (_viewModel.updateStatusCommand.completed &&
        !_viewModel.updateStatusCommand.hasError) {
      // MySnackBar(context, message: 'Status updated successfully!').show();
      log.info('Status updated successfully!');
    } else {
      MySnackBar(
        context,
        message: _viewModel.updateStatusCommand.error!,
      ).show();
    }
  }

  Future<bool?> _showDeleteDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete item'),
        content: const Text('Are you sure you want delete this item?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _showDetailsDialog() {
    final colorScheme = Theme.of(context).colorScheme;
    final item = _viewModel.currentItem;

    return showDialog(
      context: context,
      // 1. Return AlertDialog directly (removed Center & outer SingleChildScrollView)
      builder: (context) => AlertDialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        contentPadding: const EdgeInsets.all(20),
        content: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 400, maxWidth: 600),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title (Pinned at the top)
              SelectableText(
                (item.title.isEmpty) ? defaultTitleName : item.title,
                style: TextStyle(
                  color: colorScheme.onSurface.withValues(alpha: 0.85),
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
              ),

              const Divider(height: 30),

              // 2. Wrap the inner scroll view with Flexible so it shrinks to
              // the available screen height and allows scrolling without overflowing.
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Reading status
                      Row(
                        children: [
                          const Text(
                            "• ",
                            style: TextStyle(color: Colors.blue, fontSize: 16),
                          ),
                          Text(
                            item.readingStatus.name,
                            style: const TextStyle(
                              color: Colors.blue,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // Url
                      if (item.uri.toString().isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.surfaceContainerLowest,
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Theme(
                            data: Theme.of(context).copyWith(
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                              splashColor: Colors.transparent,
                              highlightColor: Colors.transparent,
                              hoverColor: Colors.transparent,
                            ),
                            child: Row(
                              children: [
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 5),
                                  child: Icon(
                                    Icons.link_rounded,
                                    size: 20,
                                    color: Colors.blueGrey,
                                  ),
                                ),

                                const SizedBox(width: 5),

                                // Scrollable URL
                                Expanded(
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: MouseRegion(
                                      cursor: SystemMouseCursors.click,
                                      child: SelectableText(
                                        item.uri.toString(),
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(width: 5),

                                // copy icon button
                                _buildCopyIconButton(item),

                                const SizedBox(width: 5),

                                // open link icon
                                IconButton(
                                  padding: const EdgeInsets.all(5),
                                  constraints: const BoxConstraints(),
                                  tooltip: 'Open link',
                                  onPressed: () {
                                    _openUrl();
                                  },
                                  icon: const Icon(Icons.open_in_new, size: 20),
                                ),
                              ],
                            ),
                          ),
                        ),

                      const SizedBox(height: 20),

                      if (item.notes.isNotEmpty)
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: colorScheme.onSurface.withValues(
                              alpha: 0.08,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.all(8),
                          child: SelectableText(
                            item.notes,
                            style: TextStyle(
                              fontSize: 14,
                              color: colorScheme.onSurface.withValues(
                                alpha: 0.7,
                              ),
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCopyIconButton(SavedItem item) {
    bool copied = false;

    return StatefulBuilder(
      builder: (context, setDialogState) {
        return IconButton(
          padding: EdgeInsets.all(5),
          constraints: const BoxConstraints(),
          tooltip: copied ? 'Copied!' : 'Copy',
          icon: Icon(
            copied ? Icons.check_rounded : Icons.content_copy_outlined,
            size: 20,
          ),
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: item.uri.toString()));

            setDialogState(() {
              copied = true;
            });

            Future.delayed(const Duration(seconds: 2), () {
              if (context.mounted) {
                setDialogState(() {
                  copied = false;
                });
              }
            });
          },
        );
      },
    );
  }

  @override
  void dispose() {
    // _viewModel.removeListener(_checkDeletion);
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        return MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _showDetailsDialog,
            child: _isGridView ? _buildGridItemCard() : _buildListItemCard(),
          ),
        );
      },
    );
  }

  Widget _buildListItemCard() {
    final isDarkMode = MyProviders(context).themeModel().isDark(context);
    final colorScheme = Theme.of(context).colorScheme;
    final item = _viewModel.currentItem;
    return Card(
      key: ValueKey(item.id),
      elevation: 0,
      color: !isDarkMode
          ? colorScheme.surfaceContainerLowest
          : colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: colorScheme.onSurface.withValues(alpha: 0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Circular Link Icon
            Container(
              width: 35,
              height: 35,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: _buildFaviconSection(item),
            ),
            const SizedBox(width: 16),

            // Title Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    (item.title.isEmpty) ? defaultTitleName : item.title,
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
                      if (item.uri.host.isNotEmpty)
                        Expanded(
                          child: Text(
                            item.uri.host,
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
                      const Text(
                        "• ",
                        style: TextStyle(color: Colors.blue, fontSize: 16),
                      ),
                      Text(
                        item.readingStatus.name,
                        style: TextStyle(
                          color: Colors.blue,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // const SizedBox(width: 16),
            const SizedBox(width: 12),

            // Options Icon
            Padding(
              padding: EdgeInsets.only(right: 10.0),
              child: _buildOptionsIcon(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFaviconSection(SavedItem item) {
    const defaultIcon = Icon(
      Icons.link_rounded,
      size: 18,
      color: Colors.blueGrey,
    );

    if (item.faviconUrl == null || item.faviconUrl!.isEmpty) return defaultIcon;

    return ClipOval(
      child: Image.network(
        item.faviconUrl!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => defaultIcon,
      ),
    );
  }

  Widget _buildGridItemCard() {
    final isDarkMode = MyProviders(context).themeModel().isDark(context);
    final colorScheme = Theme.of(context).colorScheme;
    final item = _viewModel.currentItem;
    return Card(
      elevation: 0,
      color: !isDarkMode
          ? colorScheme.surfaceContainerLowest
          : colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.onSurface.withValues(alpha: 0.1)),
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
                    Padding(
                      padding: EdgeInsets.only(top: 2.0, right: 8.0),
                      child: SizedBox.square(
                        dimension: 20,
                        child: _buildFaviconSection(item),
                      ),
                    ),

                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 3.5),
                        child: Text(
                          (item.title.isEmpty) ? defaultTitleName : item.title,
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
                    Padding(
                      padding: EdgeInsets.only(left: 4.0),
                      child: _buildOptionsIcon(size: 20),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // Status & Domain Row
                Row(
                  children: [
                    // Domain (Truncates if too long)
                    if (item.uri.host.isNotEmpty)
                      Expanded(
                        child: Text(
                          item.uri.host,
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
                      item.readingStatus.name,
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
              margin: const EdgeInsets.only(left: 12, right: 12, bottom: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey.shade200,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                    ? Image.network(
                        item.imageUrl!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        errorBuilder: (context, error, stackTrace) {
                          return Image.asset(
                            'assets/image_placeholder.png',
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                          );
                        },
                      )
                    : Image.asset(
                        'assets/image_placeholder.png',
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionsIcon({double? size}) {
    return Theme(
      data: Theme.of(context).copyWith(
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
      ),
      child: MenuAnchor(
        builder:
            (BuildContext context, MenuController controller, Widget? child) {
              return IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                tooltip: '',
                icon: Icon(Icons.more_vert, size: size),
                onPressed: () {
                  if (controller.isOpen) {
                    controller.close();
                  } else {
                    controller.open();
                  }
                },
              );
            },
        menuChildren: [
          MenuItemButton(
            leadingIcon: const Icon(Icons.open_in_new, size: 20),
            onPressed: _openUrl,
            child: const Text('Open link'),
          ),
          MenuItemButton(
            leadingIcon: const Icon(Icons.visibility_outlined, size: 20),
            onPressed: _showDetailsDialog,
            child: const Text('See details'),
          ),
          SubmenuButton(
            leadingIcon: const Icon(Icons.drive_file_move_outline, size: 20),
            menuChildren: [
              if (_viewModel.currentItem.readingStatus != ReadingStatus.unread)
                MenuItemButton(
                  onPressed: () => _updateStatus(ReadingStatus.unread),
                  child: const Text('Unread'),
                ),
              if (_viewModel.currentItem.readingStatus != ReadingStatus.reading)
                MenuItemButton(
                  onPressed: () => _updateStatus(ReadingStatus.reading),
                  child: const Text('Reading'),
                ),
              if (_viewModel.currentItem.readingStatus != ReadingStatus.read)
                MenuItemButton(
                  onPressed: () => _updateStatus(ReadingStatus.read),
                  child: const Text('Read'),
                ),
            ],
            child: const Text('Move to'),
          ),
          MenuItemButton(
            leadingIcon: const Icon(Icons.edit, size: 20),
            onPressed: _editItem,
            child: const Text('Edit'),
          ),
          MenuItemButton(
            leadingIcon: const Icon(Icons.delete, size: 20),
            onPressed: _deleteItem,
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
