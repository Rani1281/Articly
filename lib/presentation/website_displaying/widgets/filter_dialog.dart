import 'package:articly/data/models/tag.dart';
import 'package:articly/domain/providers/user_provider.dart';
import 'package:articly/presentation/website_displaying/view_models/home_page_view_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class FilterDialogResult {
  final ReadingStatusFilterType status;
  final List<String> tagIds;

  const FilterDialogResult({required this.status, required this.tagIds});
}

Future<FilterDialogResult?> showFilterDialog({
  required BuildContext context,
  required ReadingStatusFilterType currentStatus,
  required List<String> currentTagIds,
}) {
  return showDialog<FilterDialogResult>(
    context: context,
    builder: (context) => FilterDialog(
      currentStatus: currentStatus,
      currentTagIds: currentTagIds,
    ),
  );
}

class FilterDialog extends StatefulWidget {
  const FilterDialog({
    super.key,
    required this.currentStatus,
    required this.currentTagIds,
  });

  final ReadingStatusFilterType currentStatus;
  final List<String> currentTagIds;

  @override
  State<FilterDialog> createState() => _FilterDialogState();
}

class _FilterDialogState extends State<FilterDialog> {
  late ReadingStatusFilterType _selectedStatus;
  late List<String> _selectedTagIds;
  late final TextEditingController _searchController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.currentStatus;
    _selectedTagIds = List.from(widget.currentTagIds);
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleTag(String tagId) {
    setState(() {
      if (_selectedTagIds.contains(tagId)) {
        _selectedTagIds.remove(tagId);
      } else {
        _selectedTagIds.add(tagId);
      }
    });
  }

  void _resetFilters() {
    setState(() {
      _selectedStatus = ReadingStatusFilterType.none;
      _selectedTagIds.clear();
      _searchController.clear();
      _searchQuery = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final provider = context.watch<UserProvider>();

    // Sorted tags from provider
    final allTags = provider.tags.values.toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    // Filtered by search
    final trimmedQuery = _searchQuery.trim();
    final normalizedQuery = Tag.normalize(trimmedQuery);
    final lowerQuery = trimmedQuery.toLowerCase();

    final filteredTags = trimmedQuery.isEmpty
        ? allTags
        : allTags.where((tag) {
            return tag.normalizeName().contains(normalizedQuery) ||
                tag.name.toLowerCase().contains(lowerQuery);
          }).toList();

    final hasChangesOrFilters =
        _selectedStatus != ReadingStatusFilterType.none ||
        _selectedTagIds.isNotEmpty;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440, maxHeight: 620),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- Header ---
              Row(
                children: [
                  Icon(
                    Icons.filter_list_rounded,
                    color: colorScheme.primary,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Filter Items',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    tooltip: 'Close',
                    onPressed: () => Navigator.pop(context),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),

              const SizedBox(height: 14),

              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // --- Reading Status Section ---
                      Text(
                        'Reading Status',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ChoiceChip(
                            key: const ValueKey('filterChip_all'),
                            label: const Text('All'),
                            selected:
                                _selectedStatus == ReadingStatusFilterType.none,
                            onSelected: (selected) {
                              if (selected) {
                                setState(
                                  () => _selectedStatus =
                                      ReadingStatusFilterType.none,
                                );
                              }
                            },
                          ),
                          ChoiceChip(
                            key: const ValueKey('filterChip_unread'),
                            label: const Text('Unread'),
                            selected:
                                _selectedStatus ==
                                ReadingStatusFilterType.unread,
                            onSelected: (selected) {
                              setState(() {
                                _selectedStatus = selected
                                    ? ReadingStatusFilterType.unread
                                    : ReadingStatusFilterType.none;
                              });
                            },
                          ),
                          ChoiceChip(
                            key: const ValueKey('filterChip_reading'),
                            label: const Text('Reading'),
                            selected:
                                _selectedStatus ==
                                ReadingStatusFilterType.reading,
                            onSelected: (selected) {
                              setState(() {
                                _selectedStatus = selected
                                    ? ReadingStatusFilterType.reading
                                    : ReadingStatusFilterType.none;
                              });
                            },
                          ),
                          ChoiceChip(
                            key: const ValueKey('filterChip_read'),
                            label: const Text('Read'),
                            selected:
                                _selectedStatus == ReadingStatusFilterType.read,
                            onSelected: (selected) {
                              setState(() {
                                _selectedStatus = selected
                                    ? ReadingStatusFilterType.read
                                    : ReadingStatusFilterType.none;
                              });
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),
                      const Divider(height: 1),
                      const SizedBox(height: 14),

                      // --- Tags Section Header ---
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Tags',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          if (_selectedTagIds.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${_selectedTagIds.length} selected',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: colorScheme.onPrimaryContainer,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      if (allTags.isNotEmpty) ...[
                        // Search bar
                        TextField(
                          key: const ValueKey('filterTagSearchField'),
                          controller: _searchController,
                          onChanged: (val) {
                            setState(() => _searchQuery = val);
                          },
                          decoration: InputDecoration(
                            hintText: 'Search tags...',
                            prefixIcon: const Icon(Icons.search, size: 20),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 18),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() => _searchQuery = '');
                                    },
                                  )
                                : null,
                            filled: true,
                            fillColor: colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.45),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: colorScheme.primary,
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Tags list container
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 190),
                          child: filteredTags.isEmpty
                              ? Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 24.0,
                                  ),
                                  child: Center(
                                    child: Text(
                                      'No tags matching "$_searchQuery"',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                    ),
                                  ),
                                )
                              : ListView.builder(
                                  shrinkWrap: true,
                                  itemCount: filteredTags.length,
                                  itemBuilder: (context, index) {
                                    final tag = filteredTags[index];
                                    final isSelected = _selectedTagIds.contains(
                                      tag.id,
                                    );

                                    return InkWell(
                                      key: ValueKey(
                                        'filter_tag_item_${tag.id}',
                                      ),
                                      onTap: () => _toggleTag(tag.id),
                                      borderRadius: BorderRadius.circular(10),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 6,
                                        ),
                                        margin: const EdgeInsets.symmetric(
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? colorScheme.primaryContainer
                                                    .withValues(alpha: 0.35)
                                              : Colors.transparent,
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.tag,
                                              size: 18,
                                              color: isSelected
                                                  ? colorScheme.primary
                                                  : colorScheme
                                                        .onSurfaceVariant,
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Text(
                                                tag.name,
                                                style: theme
                                                    .textTheme
                                                    .bodyMedium
                                                    ?.copyWith(
                                                      fontWeight: isSelected
                                                          ? FontWeight.w600
                                                          : FontWeight.normal,
                                                      color: isSelected
                                                          ? colorScheme.primary
                                                          : colorScheme
                                                                .onSurface,
                                                    ),
                                              ),
                                            ),
                                            Checkbox(
                                              key: ValueKey(
                                                'filter_tag_checkbox_${tag.id}',
                                              ),
                                              value: isSelected,
                                              onChanged: (_) =>
                                                  _toggleTag(tag.id),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              visualDensity:
                                                  VisualDensity.compact,
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ] else ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.label_outline,
                                  size: 32,
                                  color: colorScheme.outline.withValues(
                                    alpha: 0.6,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'No tags created yet',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // --- Footer Actions ---
              Row(
                children: [
                  if (hasChangesOrFilters)
                    TextButton(
                      key: const ValueKey('resetFilterButton'),
                      onPressed: _resetFilters,
                      child: const Text('Reset'),
                    ),
                  const Spacer(),
                  TextButton(
                    key: const ValueKey('cancelFilterButton'),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    key: const ValueKey('applyFilterButton'),
                    onPressed: () {
                      Navigator.pop(
                        context,
                        FilterDialogResult(
                          status: _selectedStatus,
                          tagIds: _selectedTagIds,
                        ),
                      );
                    },
                    child: const Text('Apply'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
