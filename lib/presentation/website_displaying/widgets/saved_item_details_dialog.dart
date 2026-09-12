import 'package:articly/config/config.dart';
import 'package:articly/data/models/saved_item.dart';
import 'package:articly/data/models/tag.dart';
import 'package:articly/domain/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> showSavedItemDetailsDialog({
  required BuildContext context,
  required SavedItem item,
  VoidCallback? onOpenUrl,
}) {
  return showDialog(
    context: context,
    builder: (context) =>
        SavedItemDetailsDialog(item: item, onOpenUrl: onOpenUrl),
  );
}

class SavedItemDetailsDialog extends StatelessWidget {
  const SavedItemDetailsDialog({super.key, required this.item, this.onOpenUrl});

  final SavedItem item;
  final VoidCallback? onOpenUrl;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final provider = context.watch<UserProvider>();

    // Resolve tag IDs to Tag objects, preserving user's selection order
    final List<Tag> tags = item.tags
        .map((tagId) => provider.tags[tagId])
        .whereType<Tag>()
        .toList();

    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      contentPadding: const EdgeInsets.all(20),
      content: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 400, maxWidth: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Tags Chips at the Top ---
            if (tags.isNotEmpty) ...[
              Wrap(
                key: const ValueKey('detailsDialogTagsWrap'),
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final tag in tags)
                    Container(
                      key: ValueKey('details_tag_chip_${tag.id}'),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.secondaryContainer.withValues(
                          alpha: 0.6,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: colorScheme.outlineVariant.withValues(
                            alpha: 0.5,
                          ),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.tag,
                            size: 13,
                            color: colorScheme.onSecondaryContainer,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            tag.name,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: colorScheme.onSecondaryContainer,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
            ],

            // --- Title (Pinned at the top) ---
            SelectableText(
              (item.title.isEmpty) ? defaultTitleName : item.title,
              style: TextStyle(
                color: colorScheme.onSurface.withValues(alpha: 0.85),
                fontWeight: FontWeight.w600,
                fontSize: 18,
              ),
            ),

            const Divider(height: 30),

            // --- Scrollable Details ---
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
                          color: colorScheme.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Theme(
                          data: theme.copyWith(
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

                              // Copy icon button
                              _buildCopyIconButton(item),

                              const SizedBox(width: 5),

                              // Open link icon
                              IconButton(
                                padding: const EdgeInsets.all(5),
                                constraints: const BoxConstraints(),
                                tooltip: 'Open link',
                                onPressed: () {
                                  if (onOpenUrl != null) {
                                    onOpenUrl!();
                                  } else {
                                    launchUrl(item.uri);
                                  }
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCopyIconButton(SavedItem item) {
    bool copied = false;

    return StatefulBuilder(
      builder: (context, setDialogState) {
        return IconButton(
          padding: const EdgeInsets.all(5),
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
}
