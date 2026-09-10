import 'package:articly/data/models/tag.dart';
import 'package:articly/domain/providers/user_provider.dart';
import 'package:articly/presentation/tags_management/view_models/tag_tile_view_model.dart';
import 'package:articly/presentation/tags_management/widgets/tag_tile.dart';
import 'package:flutter/material.dart';

class TagsList extends StatelessWidget {
  const TagsList({
    super.key,
    required this.tags,
    required this.provider,
    this.newTagViewModel,
    this.onNewTagSaved,
    this.onCancelNewTag,
    this.onTagDeleted,
  });

  final List<Tag> tags;
  final UserProvider provider;
  final TagTileViewModel? newTagViewModel;
  final VoidCallback? onNewTagSaved;
  final VoidCallback? onCancelNewTag;
  final VoidCallback? onTagDeleted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final hasNewTag = newTagViewModel != null;

    if (tags.isEmpty && !hasNewTag) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 48.0, horizontal: 24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.label_outline, size: 56, color: colorScheme.outline),
              const SizedBox(height: 16),
              Text(
                'No tags yet',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tags help you organize and filter your saved articles by topics, projects, or interests.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final totalItems = (hasNewTag ? 1 : 0) + tags.length;

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: totalItems,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        if (hasNewTag && index == 0) {
          return TagTile(
            key: const ValueKey('new_tag_tile'),
            viewModel: newTagViewModel!,
            autoFocus: true,
            onTagSaved: onNewTagSaved,
            onCancelNewTag: onCancelNewTag,
          );
        }

        final tagIndex = hasNewTag ? index - 1 : index;
        final tag = tags[tagIndex];

        return TagTile(
          key: ValueKey(tag.id),
          viewModel: TagTileViewModel(
            tag: tag,
            isEditMode: false,
            provider: provider,
          ),
          onTagDeleted: onTagDeleted,
        );
      },
    );
  }
}
