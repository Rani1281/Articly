import 'package:articly/data/models/saved_item.dart';
import 'package:articly/presentation/website_displaying/view_models/saved_item_view_model.dart';
import 'package:articly/presentation/website_saving/widgets/save_webpage_screen.dart';
import 'package:articly/utils/my_snack_bar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/link.dart'; // Added for web link preview

class SavedWebpageCard extends StatefulWidget {
  const SavedWebpageCard({
    super.key,
    required this.viewModel,
    this.isDark = false,
  });

  final SavedItemViewModel viewModel;
  final bool isDark;

  @override
  State<SavedWebpageCard> createState() => _SavedWebpageCardState();
}

class _SavedWebpageCardState extends State<SavedWebpageCard> {
  late final SavedItemViewModel _viewModel;
  late SavedItem _currentItem;

  @override
  void initState() {
    super.initState();
    _viewModel = widget.viewModel;
    _currentItem = _viewModel.currentItem;

    _viewModel.addListener(_checkDeletion);
  }

  void _checkDeletion() {
    final cmd = _viewModel.deleteItemCommand;
    if (!cmd.completed && cmd.hasError) {
      MySnackBar(context, message: _viewModel.deleteItemCommand.error!).show();
    } else if (cmd.completed) {
      MySnackBar(context, message: 'Deleted the item successfully!').show();
    }
  }

  _openUrl() async {
    if (_currentItem.uri == null) {
      return null;
    }
    await _viewModel.openUrl();
    if (!_viewModel.openUrlCommand.completed &&
        _viewModel.openUrlCommand.hasError &&
        mounted) {
      MySnackBar(context, message: _viewModel.openUrlCommand.error!).show();
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

  @override
  void dispose() {
    _viewModel.removeListener(_checkDeletion);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _currentItem = _viewModel.currentItem;
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        return !_viewModel.isVisible
            ? const SizedBox()
            : Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Header Section
                    // Wrap the header in a Link widget to generate the native HTML <a> tag on Web
                    _currentItem.uri == null
                        ? buildHeader()
                        : Link(
                            uri: _currentItem.uri,
                            target: LinkTarget.blank,
                            builder: (context, followLink) => buildHeader(),
                          ),

                    // Divider
                    Divider(
                      height: 1,
                      thickness: 1,
                      color: Theme.of(context).colorScheme.surfaceContainerHigh,
                    ),

                    // Bottom Accordion Section
                    // Action Bar (Always visible)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8.0,
                        vertical: 4.0,
                      ),
                      child: Row(
                        children: [
                          _buildActionIcon(
                            Icons.edit_outlined,
                            "Edit",
                            onPressed: () async {
                              SavedItem? newItem =
                                  await Navigator.push<SavedItem>(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => SaveWebpageScreen(
                                        currentItem: _viewModel.currentItem,
                                        isEdit: true,
                                      ),
                                    ),
                                  );
                              if (newItem != null) {
                                setState(() {
                                  _viewModel.currentItem = newItem;
                                });
                              }
                            },
                          ),
                          _buildActionIcon(
                            Icons.delete_outline,
                            "Delete",
                            onPressed: () async {
                              final confirmed = await _showDeleteDialog();
                              if (confirmed == true) {
                                // ! Don't await this to show immediate results in the app. Deletion will happen in the background.
                                _viewModel.deleteItem(_currentItem.id);
                              }
                            },
                          ),
                          _buildActionIcon(
                            Icons.content_copy_outlined,
                            "Copy",
                            onPressed: () async {
                              await widget.viewModel.copyContents();
                              if (mounted) {
                                MySnackBar(
                                  context,
                                  message: 'Copied to clipboard',
                                ).show();
                              }
                            },
                          ),
                          const Spacer(),
                          // Expand/Collapse Toggle Button
                          _currentItem.notes == null
                              ? const SizedBox()
                              : IconButton(
                                  icon: Icon(
                                    widget.viewModel.isExpanded
                                        ? Icons.keyboard_arrow_up
                                        : Icons.keyboard_arrow_down,
                                    color: Colors.grey.shade700,
                                  ),
                                  onPressed: widget.viewModel.toggleExpand,
                                  tooltip: widget.viewModel.isExpanded
                                      ? "Show less"
                                      : "Show notes",
                                ),
                        ],
                      ),
                    ),

                    // Expandable Notes Area
                    if (_currentItem.notes != null) ...[
                      AnimatedSize(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        child: widget.viewModel.isExpanded
                            ? Padding(
                                padding: const EdgeInsets.only(
                                  left: 16.0,
                                  right: 16.0,
                                  bottom: 16.0,
                                ),
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.surface
                                        .withValues(alpha: 0.9),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.surfaceContainerHigh,
                                    ),
                                  ),
                                  child: SelectableText(
                                    _currentItem.notes!,
                                    style: TextStyle(
                                      fontSize: 15,
                                      height: 1.5,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withValues(alpha: 0.8),
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                              )
                            : const SizedBox.shrink(), // Takes zero space when collapsed
                      ),
                    ],
                  ],
                ),
              );
      },
    );
  }

  Widget buildHeader() {
    return MouseRegion(
      cursor: _currentItem.uri != null
          ? SystemMouseCursors
                .click // Changes cursor to pointing finger
          : SystemMouseCursors.basic,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _openUrl,
        child: Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerLowest,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title and External Link Icon
              if (_currentItem.title != null &&
                  _currentItem.title!.isNotEmpty) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(0, 0, 8, 0),
                        child: SelectableText(
                          _currentItem.title!,
                          onTap: _openUrl,
                          // softWrap: true,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          maxLines: null,
                        ),
                      ),
                    ),
                    const SizedBox(width: 5),
                    Icon(
                      Icons.north_east,
                      size: 20,
                      color: Colors.grey.shade500,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],

              // URL and Reading Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_currentItem.uri != null &&
                      _currentItem.uri.toString().isNotEmpty)
                    SelectableText(
                      _currentItem.uri!.host,
                      onTap: _openUrl,
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.blueAccent,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _currentItem.readingStatus.name,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method to create the small action icons uniformly
  Widget _buildActionIcon(
    IconData icon,
    String tooltip, {
    void Function()? onPressed,
  }) {
    return IconButton(
      icon: Icon(icon, size: 20, color: Colors.grey.shade600),
      onPressed: onPressed,
      tooltip: tooltip,
      splashRadius: 20,
    );
  }
}
