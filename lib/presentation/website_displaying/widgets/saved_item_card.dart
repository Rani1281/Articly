import 'package:articly/config/config.dart';
import 'package:articly/data/models/saved_item.dart';
import 'package:articly/presentation/website_displaying/view_models/saved_item_view_model.dart';
import 'package:articly/presentation/website_saving/widgets/save_webpage_screen.dart';
import 'package:articly/utils/my_snack_bar.dart';
import 'package:articly/utils/providers_shortcuts.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';

enum MenuAction { seeDetails, edit, copy, delete }

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
      provider: MyProviders(context).savedItemsProvider(),
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

  // void _checkDeletion() {
  //   final cmd = _viewModel.deleteItemCommand;
  //   if (!cmd.completed && cmd.hasError) {
  //     MySnackBar(context, message: _viewModel.deleteItemCommand.error!).show();
  //   } else if (!showedSuccessMessage && cmd.completed) {
  //     MySnackBar(context, message: 'Deleted the item successfully!').show();
  //     showedSuccessMessage = true;
  //     widget.onDeleted?.call();
  //   }
  // }

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
      // change the item and rebuild the page
      _viewModel.currentItem = newItem;
      // widget.onEdit?.call(); // refresh after edit.

      log.info('New item: $newItem');
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
      builder: (context) => AlertDialog(
        // contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        contentPadding: const EdgeInsets.all(20),
        content: ConstrainedBox(
          // min wid: 500
          constraints: const BoxConstraints(minWidth: 400, maxWidth: 600),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              SelectableText(
                (item.title.isEmpty) ? defaultTitleName : item.title,
                style: TextStyle(
                  color: colorScheme.onSurface.withValues(alpha: 0.85),
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
              ),

              // const SizedBox(height: 20),
              const Divider(height: 30),

              SingleChildScrollView(
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

                    if (item.uri.toString().isEmpty)
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
                                    child: SelectableText(item.uri.toString()),
                                  ),
                                ),
                              ),

                              const SizedBox(width: 5),

                              // copy icon button
                              _buildCopyIconButton(item),

                              const SizedBox(width: 5),

                              // open link icon
                              IconButton(
                                padding: EdgeInsets.all(5),
                                constraints: const BoxConstraints(),
                                tooltip: 'Open link',
                                onPressed: () {
                                  _openUrl();
                                },
                                icon: Icon(Icons.open_in_new, size: 20),
                              ),
                            ],
                          ),
                        ),
                      ),

                    const SizedBox(height: 20),

                    if (item.notes.isNotEmpty)
                      Container(
                        decoration: BoxDecoration(
                          color: colorScheme.onSurface.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.all(8),
                        child: SelectableText(
                          item.notes,
                          style: TextStyle(
                            fontSize: 14,
                            color: colorScheme.onSurface.withValues(alpha: 0.7),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                  ],
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
    final url = _viewModel.currentItem.uri.toString();
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        return MouseRegion(
          cursor: url.isNotEmpty
              ? SystemMouseCursors
                    .click // Changes cursor to pointing finger
              : SystemMouseCursors.basic,
          child: GestureDetector(
            onTap: _openUrl,
            child: _isGridView ? _buildGridItemCard() : _buildListItemCard(),
          ),
        );
      },
    );
  }

  Padding _buildListItemCard() {
    final item = _viewModel.currentItem;
    return Padding(
      key: ValueKey(item.id),
      padding: const EdgeInsets.symmetric(vertical: 16.0),
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
    );
  }

  Widget _buildFaviconSection(SavedItem item) {
    const defaultIcon = Icon(
      Icons.link_rounded,
      size: 18,
      color: Colors.blueGrey,
    );

    if (item.faviconUrl == null) return defaultIcon;

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
      elevation: 1,
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
                image: DecorationImage(
                  image: item.imageUrl != null
                      ? NetworkImage(item.imageUrl!)
                      : AssetImage('assets/image_placeholder.png'),
                  fit: BoxFit.cover,
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
      child: PopupMenuButton<MenuAction>(
        padding: EdgeInsets.zero,
        tooltip: '',
        child: Icon(Icons.more_vert, size: size),
        onSelected: (action) {
          switch (action) {
            case MenuAction.seeDetails:
              _showDetailsDialog();
              break;
            case MenuAction.edit:
              _editItem();
              break;
            case MenuAction.copy:
              _viewModel.copyContents();
              break;
            case MenuAction.delete:
              _deleteItem();
              break;
          }
        },
        itemBuilder: (context) => [
          _buildMenuItem(
            value: MenuAction.seeDetails,
            text: 'See details',
            icon: Icons.visibility_outlined,
          ),
          _buildMenuItem(
            value: MenuAction.copy,
            text: 'Copy source',
            icon: Icons.copy,
          ),
          _buildMenuItem(
            value: MenuAction.edit,
            text: 'Edit',
            icon: Icons.edit,
          ),
          _buildMenuItem(
            value: MenuAction.delete,
            text: 'Delete',
            icon: Icons.delete,
          ),
        ],
      ),
    );
  }

  PopupMenuItem<MenuAction> _buildMenuItem({
    required MenuAction value,
    IconData? icon,
    required String text,
  }) {
    return PopupMenuItem(
      value: value,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (icon != null)
            Icon(
              icon,
              color: Theme.of(context).colorScheme.onSurface,
              size: 20,
            ),
          const SizedBox(width: 10),
          Text(text),
        ],
      ),
    );
  }
}
