import 'package:articly/domain/providers/user_provider.dart';
import 'package:articly/presentation/tags_management/view_models/manage_tags_view_model.dart';
import 'package:articly/presentation/tags_management/view_models/tag_tile_view_model.dart';
import 'package:articly/presentation/tags_management/widgets/create_tag_button.dart';
import 'package:articly/presentation/tags_management/widgets/tags_list.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ManageTagsPage extends StatefulWidget {
  const ManageTagsPage({super.key, this.viewModel, this.autoCreate = false});

  final ManageTagsViewModel? viewModel;
  final bool autoCreate;

  @override
  State<ManageTagsPage> createState() => _ManageTagsPageState();
}

class _ManageTagsPageState extends State<ManageTagsPage> {
  late final ManageTagsViewModel _viewModel;
  TagTileViewModel? _newTagViewModel;

  @override
  void initState() {
    super.initState();
    _viewModel =
        widget.viewModel ??
        ManageTagsViewModel(provider: context.read<UserProvider>());

    _viewModel.getTags();

    if (widget.autoCreate) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _startCreatingTag();
      });
    }
  }

  void _startCreatingTag() {
    if (_newTagViewModel != null) return;
    setState(() {
      _newTagViewModel = TagTileViewModel(
        tag: null,
        isEditMode: true,
        provider: _viewModel.provider,
      );
    });
  }

  void _onNewTagSaved() {
    setState(() {
      _newTagViewModel = null;
    });
  }

  void _onCancelNewTag() {
    setState(() {
      _newTagViewModel = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Tags')),
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) {
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      CreateTagButton(
                        onPressed: _newTagViewModel == null
                            ? _startCreatingTag
                            : null,
                        enabled: _newTagViewModel == null,
                      ),
                      const SizedBox(height: 8),
                      if (_viewModel.getTagsCommand.running &&
                          _viewModel.tags.isEmpty &&
                          _newTagViewModel == null)
                        const Padding(
                          padding: EdgeInsets.all(48.0),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else
                        TagsList(
                          tags: _viewModel.tags,
                          provider: _viewModel.provider,
                          newTagViewModel: _newTagViewModel,
                          onNewTagSaved: _onNewTagSaved,
                          onCancelNewTag: _onCancelNewTag,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
