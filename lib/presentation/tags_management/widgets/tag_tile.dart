import 'package:articly/presentation/tags_management/view_models/tag_tile_view_model.dart';
import 'package:articly/presentation/tags_management/widgets/confirm_delete_dialog.dart';
import 'package:articly/utils/my_snack_bar.dart';
import 'package:flutter/material.dart';

class TagTile extends StatefulWidget {
  const TagTile({
    super.key,
    required this.viewModel,
    this.onTagSaved,
    this.onTagDeleted,
    this.onCancelNewTag,
    this.autoFocus = false,
  });

  final TagTileViewModel viewModel;
  final VoidCallback? onTagSaved;
  final VoidCallback? onTagDeleted;
  final VoidCallback? onCancelNewTag;
  final bool autoFocus;

  @override
  State<TagTile> createState() => _TagTileState();
}

class _TagTileState extends State<TagTile> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.viewModel.tag?.name ?? '');
    _focusNode = FocusNode();
    if (widget.autoFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _focusNode.requestFocus();
        }
      });
    }
  }

  @override
  void didUpdateWidget(covariant TagTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.viewModel.isEditMode &&
        _controller.text != (widget.viewModel.tag?.name ?? '')) {
      _controller.text = widget.viewModel.tag?.name ?? '';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _onSavePressed(BuildContext context) async {
    final text = _controller.text;
    if (widget.viewModel.tag == null) {
      final error = await widget.viewModel.createTag(text);
      if (context.mounted) {
        if (error == null) {
          MySnackBar(context, message: 'Tag created successfully').show();
          widget.onTagSaved?.call();
        } else {
          MySnackBar(context, message: error).show();
        }
      }
    } else {
      final error = await widget.viewModel.editTag(text);
      if (context.mounted) {
        if (error == null) {
          MySnackBar(context, message: 'Tag updated successfully').show();
          widget.onTagSaved?.call();
        } else {
          MySnackBar(context, message: error).show();
        }
      }
    }
  }

  Future<void> _onDeletePressed(BuildContext context) async {
    if (widget.viewModel.tag == null) {
      // Temporary new tag being created, just discard/cancel it
      widget.onCancelNewTag?.call();
      return;
    }

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final mediaQuerySize = MediaQuery.of(context).size;
    final tagName = widget.viewModel.tag!.name;
    showDialog<bool>(
      context: context,
      builder: (dialogContext) => ConfirmDeleteDialog(
        title: const Text('Delete tag'),
        content: Text('Are you sure you want to delete "$tagName"?'),
        action: () async {
          final error = await widget.viewModel.deleteTag();
          scaffoldMessenger.hideCurrentSnackBar();
          if (error == null) {
            scaffoldMessenger.showSnackBar(
              SnackBar(
                width: (mediaQuerySize.width - 20).clamp(0, 500),
                content: const Text('Tag deleted successfully'),
                behavior: SnackBarBehavior.floating,
              ),
            );
            widget.onTagDeleted?.call();
          } else {
            scaffoldMessenger.showSnackBar(
              SnackBar(
                width: (mediaQuerySize.width - 20).clamp(0, 500),
                content: Text(error),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        final isEdit = widget.viewModel.isEditMode;
        final isRunning =
            widget.viewModel.createTagCommand.running ||
            widget.viewModel.editTagCommand.running ||
            widget.viewModel.deleteTagCommand.running;

        return ListTile(
          leading: isEdit
              ? IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Delete tag',
                  onPressed: isRunning ? null : () => _onDeletePressed(context),
                )
              : const Icon(Icons.label_outline),
          title: isEdit
              ? TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  maxLines: 1,
                  textInputAction: TextInputAction.done,
                  onSubmitted: isRunning
                      ? null
                      : (_) => _onSavePressed(context),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Enter tag name',
                  ),
                )
              : Text(
                  widget.viewModel.tag?.name ?? '',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
          trailing: isEdit
              ? (isRunning
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : IconButton(
                        icon: const Icon(Icons.check),
                        tooltip: 'Save tag',
                        onPressed: () => _onSavePressed(context),
                      ))
              : IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: 'Edit tag',
                  onPressed: () {
                    _controller.text = widget.viewModel.tag?.name ?? '';
                    widget.viewModel.setEditMode(true);
                    _focusNode.requestFocus();
                  },
                ),
        );
      },
    );
  }
}
