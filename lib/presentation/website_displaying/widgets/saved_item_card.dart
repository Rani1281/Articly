import 'package:flutter/material.dart';

class SavedWebpageCard extends StatefulWidget {
  final String? title;
  final String? urlHost;
  final String status;
  final String? notes;

  const SavedWebpageCard({
    super.key,
    required this.title,
    required this.urlHost,
    required this.status,
    required this.notes,
  });

  @override
  State<SavedWebpageCard> createState() => _SavedWebpageCardState();
}

class _SavedWebpageCardState extends State<SavedWebpageCard> {
  bool _isExpanded = false;

  void _toggleExpand() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 500),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
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
            onTap: widget.urlHost == null
                ? null
                : () {
                    // TODO: OPEN THE LINK IN THE BROWSER
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
                          child: Text(
                            widget.title!,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2D3748),
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
                      widget.urlHost == null
                          ? SizedBox()
                          : Text(
                              widget.urlHost!,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
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
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF4A5568),
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
          Divider(height: 1, thickness: 1, color: Colors.grey.shade200),

          // Bottom Accordion Section
          // Action Bar (Always visible)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: Row(
              children: [
                _buildActionIcon(Icons.edit_outlined, "Edit"),
                _buildActionIcon(Icons.delete_outline, "Delete"),
                _buildActionIcon(Icons.share_outlined, "Share"),
                _buildActionIcon(Icons.local_offer_outlined, "Tag"),
                _buildActionIcon(Icons.content_copy_outlined, "Copy"),
                const Spacer(),
                // Expand/Collapse Toggle Button
                widget.notes == null
                    ? SizedBox()
                    : IconButton(
                        icon: Icon(
                          _isExpanded
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down,
                          color: Colors.grey.shade700,
                        ),
                        onPressed: _toggleExpand,
                        tooltip: _isExpanded ? "Show less" : "Show notes",
                      ),
              ],
            ),
          ),

          // Expandable Notes Area
          if (widget.notes != null) ...[
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: _isExpanded
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
                          color: const Color(0xFFF7FAFC),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Text(
                          widget.notes!,
                          style: const TextStyle(
                            fontSize: 15,
                            height: 1.5,
                            color: Color(0xFF4A5568),
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
