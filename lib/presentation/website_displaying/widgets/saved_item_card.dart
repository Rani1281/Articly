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
  });

  final bool isGridView;
  final SavedItem item;
  final bool isDark;
  final VoidCallback? onDeleted;

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

    _viewModel.addListener(_checkDeletion);
  }

  @override
  void didUpdateWidget(covariant SavedItemCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    _isGridView = widget.isGridView;

    if (oldWidget.item != widget.item) {
      _viewModel.currentItem = widget.item;
    }
  }

  void _checkDeletion() {
    final cmd = _viewModel.deleteItemCommand;
    if (!cmd.completed && cmd.hasError) {
      MySnackBar(context, message: _viewModel.deleteItemCommand.error!).show();
    } else if (!showedSuccessMessage && cmd.completed) {
      MySnackBar(context, message: 'Deleted the item successfully!').show();
      showedSuccessMessage = true;
      widget.onDeleted?.call();
    }
  }

  _openUrl() async {
    final currentItem = _viewModel.currentItem;
    if (currentItem.uri == null) {
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
      _viewModel.deleteItem();
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
                item.title ?? 'Untitled',
                style: TextStyle(
                  color: colorScheme.onSurface.withValues(alpha: 0.85),
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
                // style: Theme.of(context).textTheme.titleMedium?.copyWith(
                //   fontWeight: FontWeight.w600,
                //   color: colorScheme.onSurface.withValues(alpha: 0.85),
                // ),
                // softWrap: true,
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

                    if (item.uri != null && item.uri!.toString().isNotEmpty)
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
                                  // WidgetsBinding.instance.addPostFrameCallback(
                                  //   (_) => _openUrl(),
                                  // );
                                  _openUrl();
                                },
                                icon: Icon(Icons.open_in_new, size: 20),
                              ),
                            ],
                          ),
                        ),
                      ),

                    const SizedBox(height: 20),

                    if (item.notes != null && item.notes!.isNotEmpty)
                      Container(
                        decoration: BoxDecoration(
                          color: colorScheme.onSurface.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.all(8),
                        child: SelectableText(
                          item.notes!,
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
    _viewModel.removeListener(_checkDeletion);
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        return MouseRegion(
          cursor: _viewModel.currentItem.uri != null
              ? SystemMouseCursors
                    .click // Changes cursor to pointing finger
              : SystemMouseCursors.basic,
          child: GestureDetector(
            // behavior: HitTestBehavior.opaque,
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
                  item.title ?? 'Untitled',
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
                    if (item.uri != null && item.uri!.host.isNotEmpty)
                      Expanded(
                        child: Text(
                          item.uri!.host,
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
                          item.title ?? 'Untitled',
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
                    if (item.uri != null && item.uri!.host.isNotEmpty)
                      Expanded(
                        child: Text(
                          item.uri!.host,
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

  // // Helper method to create the small action icons uniformly
  // Widget _buildActionIcon(
  //   IconData icon,
  //   String tooltip, {
  //   void Function()? onPressed,
  // }) {
  //   return IconButton(
  //     icon: Icon(icon, size: 20, color: Colors.grey.shade600),
  //     onPressed: onPressed,
  //     tooltip: tooltip,
  //     splashRadius: 20,
  //   );
  // }
}

//     : Container(
// decoration: BoxDecoration(
// color: Theme.of(context).colorScheme.surfaceContainerLowest,
// borderRadius: BorderRadius.circular(12),
// border: Border.all(
// color: Theme.of(
// context,
// ).colorScheme.surfaceContainerHighest,
// ),
// boxShadow: [
// BoxShadow(
// color: Colors.black.withValues(alpha: 0.04),
// blurRadius: 10,
// offset: const Offset(0, 4),
// ),
// ],
// ),
// child: Column(
// mainAxisSize: MainAxisSize.min,
// crossAxisAlignment: CrossAxisAlignment.start,
// children: [
// // Top Header Section
// // Wrap the header in a Link widget to generate the native HTML <a> tag on Web
// currentItem.uri == null
// ? buildHeader()
//     : Link(
// uri: currentItem.uri,
// target: LinkTarget.blank,
// builder: (context, followLink) => buildHeader(),
// ),
//
// // Divider
// Divider(
// height: 1,
// thickness: 1,
// color: Theme.of(context).colorScheme.surfaceContainerHigh,
// ),
//
// // Bottom Accordion Section
// // Action Bar (Always visible)
// Padding(
// padding: const EdgeInsets.symmetric(
// horizontal: 8.0,
// vertical: 4.0,
// ),
// child: GestureDetector(
// behavior: HitTestBehavior.opaque,
// onTap: widget.viewModel.toggleExpand,
// child: Row(
// children: [
// _buildActionIcon(
// Icons.edit_outlined,
// "Edit",
// onPressed: () async {
// SavedItem? newItem =
// await Navigator.push<SavedItem>(
// context,
// MaterialPageRoute(
// builder: (_) => SaveWebpageScreen(
// currentItem: _viewModel.currentItem,
// isEdit: true,
// viewModel: SaveWebpageViewModel(
// MyProviders(
// context,
// ).savedItemsProvider(),
// ),
// ),
// ),
// );
// if (newItem != null) {
// setState(() {
// _viewModel.currentItem = newItem;
// _currentItem = newItem;
// });
// }
// },
// ),
// _buildActionIcon(
// Icons.delete_outline,
// "Delete",
// onPressed: () async {
// final confirmed = await _showDeleteDialog();
// if (confirmed == true) {
// // ! Don't await this to show immediate results in the app. Deletion will happen in the background.
// _viewModel.deleteItem();
// }
// },
// ),
// _buildActionIcon(
// Icons.content_copy_outlined,
// "Copy",
// onPressed: () async {
// await widget.viewModel.copyContents();
// if (mounted) {
// MySnackBar(
// context,
// message: 'Copied to clipboard',
// ).show();
// }
// },
// ),
// const Spacer(),
// // Expand/Collapse Toggle Button
// _currentItem.notes == null ||
// _currentItem.notes!.isEmpty
// ? const SizedBox()
//     : IconButton(
// icon: Icon(
// widget.viewModel.isExpanded
// ? Icons.keyboard_arrow_up
//     : Icons.keyboard_arrow_down,
// color: Colors.grey.shade700,
// ),
// onPressed: widget.viewModel.toggleExpand,
// tooltip: widget.viewModel.isExpanded
// ? "Show less"
//     : "Show notes",
// ),
// ],
// ),
// ),
// ),
//
// // Expandable Notes Area
// if (_currentItem.notes != null &&
// _currentItem.notes!.isNotEmpty) ...[
// AnimatedSize(
// duration: const Duration(milliseconds: 300),
// curve: Curves.easeInOut,
// child: widget.viewModel.isExpanded
// ? Padding(
// padding: const EdgeInsets.only(
// left: 16.0,
// right: 16.0,
// bottom: 16.0,
// ),
// child: Container(
// width: double.infinity,
// padding: const EdgeInsets.all(12),
// decoration: BoxDecoration(
// color: Theme.of(context).colorScheme.surface
//     .withValues(alpha: 0.9),
// borderRadius: BorderRadius.circular(8),
// border: Border.all(
// color: Theme.of(
// context,
// ).colorScheme.surfaceContainerHigh,
// ),
// ),
// child: SelectableText(
// _currentItem.notes!,
// style: TextStyle(
// fontSize: 15,
// height: 1.5,
// color: Theme.of(context)
//     .colorScheme
//     .onSurface
//     .withValues(alpha: 0.8),
// fontStyle: FontStyle.italic,
// ),
// ),
// ),
// )
//     : const SizedBox.shrink(), // Takes zero space when collapsed
// ),
// ],
// ],
// ),
// );
