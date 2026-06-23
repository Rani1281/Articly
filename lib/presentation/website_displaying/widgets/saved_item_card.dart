import 'package:articly/presentation/website_displaying/view_models/saved_item_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
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
              GestureDetector(
                onTap: widget.uri == null
                    ? null
                    : () async {
                        final openUrl = widget.viewModel.openUrl;
                        await openUrl.execute();

                        if (!openUrl.completed && openUrl.hasError && mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(openUrl.error!),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },

                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title and External Link Icon
                      if (widget.title != null) ...[
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: SelectableText(
                                widget.title!,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  // color: Color(0xFF2D3748),
                                  color: Theme.of(context).colorScheme.onSurface
                                      .withValues(alpha: 0.9),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
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
                              ? SizedBox()
                              : SelectableText(
                                  widget.uri!.host,
                                  style: TextStyle(
                                    fontSize: 14,
                                    // color: Colors.grey.shade600,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
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
                                  // color: Color(0xFF4A5568),
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
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
                      onPressed: widget.viewModel.copyContents,
                    ),
                    _buildActionIcon(Icons.delete_outline, "Delete"),
                    // _buildActionIcon(Icons.share_outlined, "Share"),
                    // _buildActionIcon(Icons.local_offer_outlined, "Tag"),
                    _buildActionIcon(Icons.content_copy_outlined, "Copy"),
                    const Spacer(),
                    // Expand/Collapse Toggle Button
                    widget.notes == null
                        ? SizedBox()
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
                              // color: const Color(0xFFF7FAFC),
                              color: Theme.of(
                                context,
                              ).colorScheme.surface.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                // color: Colors.grey.shade200
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
                                // color: Color(0xFF4A5568),
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
