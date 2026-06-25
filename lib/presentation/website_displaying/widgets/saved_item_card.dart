import 'package:articly/presentation/website_displaying/view_models/saved_item_view_model.dart';
import 'package:articly/utils/my_snack_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/link.dart'; // Added for web link preview

class SavedWebpageCard extends StatefulWidget {
  final String? title;
  final Uri? uri;
  final String status;
  final String? notes;

  final SavedItemViewModel viewModel;

  final bool isDark;

  SavedWebpageCard({
    super.key,
    SavedItemViewModel? viewModel,
    required this.title,
    required this.uri,
    required this.status,
    required this.notes,
    this.isDark = false,
  }) : viewModel =
           viewModel ??
           SavedItemViewModel(title: title, uri: uri, notes: notes);

  @override
  State<SavedWebpageCard> createState() => _SavedWebpageCardState();
}

class _SavedWebpageCardState extends State<SavedWebpageCard> {
  late final SavedItemViewModel _viewModel;

  @override
  void initState() {
    _viewModel = widget.viewModel;
    super.initState();
  }

  _openUrl() async {
    if (widget.uri == null) {
      return null;
    }

    await _viewModel.openUrl();

    if (!_viewModel.openUrlCommand.completed &&
        _viewModel.openUrlCommand.hasError &&
        mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_viewModel.openUrlCommand.error!),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // final isDark = Provider.of<ThemeModel>(
    //   context,
    //   listen: false,
    // ).isDark(context);

    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        // Extracted the header into a helper method so we can easily wrap it in a Link
        Widget buildHeader() {
          return MouseRegion(
            cursor: widget.uri != null
                ? SystemMouseCursors
                      .click // Changes cursor to pointing finger
                : SystemMouseCursors.basic,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _openUrl,
              child: Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerLow.withValues(alpha: 0.4),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title and External Link Icon
                    if (widget.title != null) ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(0, 0, 8, 0),
                            child: SelectableText(
                              widget.title!,
                              onTap: _openUrl,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.9),
                              ),
                            ),
                          ),
                          const Spacer(),
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
                        widget.uri == null
                            ? const SizedBox()
                            : SelectableText(
                                widget.uri!.host,
                                onTap: _openUrl,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Theme.of(context).colorScheme.onSurface
                                      .withValues(alpha: 0.7),
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
                              widget.status,
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

        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
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
              widget.uri == null
                  ? buildHeader()
                  : Link(
                      uri: widget.uri,
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
                    _buildActionIcon(Icons.edit_outlined, "Edit"),
                    _buildActionIcon(Icons.delete_outline, "Delete"),
                    _buildActionIcon(
                      Icons.content_copy_outlined,
                      "Copy",
                      onPressed: () async {
                        await widget.viewModel.copyContents();
                        if (mounted) {
                          MySnackBar(context, message: 'Copied to clipboard');
                        }
                      },
                    ),
                    const Spacer(),
                    // Expand/Collapse Toggle Button
                    widget.notes == null
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
              if (widget.notes != null) ...[
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
                              color: Theme.of(
                                context,
                              ).colorScheme.surface.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Theme.of(
                                  context,
                                ).colorScheme.surfaceContainerHigh,
                              ),
                            ),
                            child: SelectableText(
                              widget.notes!,
                              style: TextStyle(
                                fontSize: 15,
                                height: 1.5,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.8),
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
