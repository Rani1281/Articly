import 'package:articly/domain/providers/user_provider.dart';
import 'package:articly/presentation/tags_management/widgets/manage_tags_page.dart';
import 'package:articly/presentation/website_saving/view_models/add_tags_view_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AddTagsDialog extends StatefulWidget {
  const AddTagsDialog({
    super.key,
    this.initialSelectedTagIds = const [],
    this.viewModel,
  });

  final List<String> initialSelectedTagIds;
  final AddTagsViewModel? viewModel;

  @override
  State<AddTagsDialog> createState() => _AddTagsDialogState();
}

class _AddTagsDialogState extends State<AddTagsDialog> {
  late final AddTagsViewModel _viewModel;
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _viewModel =
        widget.viewModel ??
        AddTagsViewModel(
          provider: context.read<UserProvider>(),
          initialSelectedTagIds: widget.initialSelectedTagIds,
        );
  }

  @override
  void dispose() {
    _searchController.dispose();
    if (widget.viewModel == null) {
      _viewModel.dispose();
    }
    super.dispose();
  }

  void _navigateToCreateTag() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ManageTagsPage(autoCreate: true),
      ),
    );
  }

  void _navigateToManageTags() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ManageTagsPage(autoCreate: false),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        final filteredTags = _viewModel.filteredTags;
        final totalTagsCount = _viewModel.sortedTags.length;

        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 24,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440, maxHeight: 560),
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
                        Icons.label_outline,
                        color: colorScheme.primary,
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Attach Tags',
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

                  const SizedBox(height: 12),

                  // --- Search Input ---
                  TextField(
                    key: const ValueKey('tagSearchField'),
                    controller: _searchController,
                    onChanged: _viewModel.setSearchQuery,
                    decoration: InputDecoration(
                      hintText: 'Search tags...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                _viewModel.clearSearchQuery();
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: colorScheme.surfaceContainerHighest.withValues(
                        alpha: 0.45,
                      ),
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

                  // --- Create Tag & Manage Tags Links ---
                  Row(
                    children: [
                      TextButton.icon(
                        key: const ValueKey('createTagButtonInDialog'),
                        onPressed: _navigateToCreateTag,
                        icon: const Icon(Icons.add, size: 17),
                        label: const Text('Create tag'),
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        key: const ValueKey('manageTagsButtonInDialog'),
                        onPressed: _navigateToManageTags,
                        icon: const Icon(Icons.tune_rounded, size: 16),
                        label: const Text('Manage tags'),
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                      ),
                    ],
                  ),

                  const Divider(height: 16),

                  // --- Tags List or Empty State ---
                  Flexible(
                    child: totalTagsCount == 0
                        ? _buildNoTagsState(theme, colorScheme)
                        : filteredTags.isEmpty
                        ? _buildNoSearchResultsState(theme, colorScheme)
                        : ListView.builder(
                            shrinkWrap: true,
                            itemCount: filteredTags.length,
                            itemBuilder: (context, index) {
                              final tag = filteredTags[index];
                              final isSelected = _viewModel.isTagSelected(
                                tag.id,
                              );

                              return InkWell(
                                key: ValueKey('tag_item_${tag.id}'),
                                onTap: () => _viewModel.toggleTag(tag.id),
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
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.tag,
                                        size: 18,
                                        color: isSelected
                                            ? colorScheme.primary
                                            : colorScheme.onSurfaceVariant,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          tag.name,
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(
                                                fontWeight: isSelected
                                                    ? FontWeight.w600
                                                    : FontWeight.normal,
                                                color: isSelected
                                                    ? colorScheme.primary
                                                    : colorScheme.onSurface,
                                              ),
                                        ),
                                      ),
                                      Checkbox(
                                        key: ValueKey('tag_checkbox_${tag.id}'),
                                        value: isSelected,
                                        onChanged: (_) =>
                                            _viewModel.toggleTag(tag.id),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        visualDensity: VisualDensity.compact,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),

                  const SizedBox(height: 16),

                  // --- Action Buttons ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        key: const ValueKey('cancelAddTagsButton'),
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        key: const ValueKey('doneAddTagsButton'),
                        onPressed: () =>
                            Navigator.pop(context, _viewModel.selectedTagIds),
                        child: Text(
                          _viewModel.selectedTagIds.isEmpty
                              ? 'Done'
                              : 'Done (${_viewModel.selectedTagIds.length})',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNoTagsState(ThemeData theme, ColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.label_outline,
              size: 44,
              color: colorScheme.outline.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 12),
            Text(
              'No tags yet',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Create tags to organize your saved articles.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.tonalIcon(
              onPressed: _navigateToCreateTag,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Create tag'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoSearchResultsState(ThemeData theme, ColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off_outlined,
              size: 40,
              color: colorScheme.outline.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 8),
            Text(
              'No tags matching "${_viewModel.searchQuery}"',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
