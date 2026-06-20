import 'package:articly/data/models/saved_item.dart';
import 'package:articly/presentation/website_saving/view_models/save_webpage_view_model.dart';
import 'package:articly/presentation/website_saving/widgets/labeled_dropdown.dart';
import 'package:articly/presentation/website_saving/widgets/labeled_text_field.dart';
import 'package:articly/theme/theme_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class SaveWebsiteScreen extends StatefulWidget {
  SaveWebsiteScreen({super.key, SaveWebpageViewModel? viewModel})
    : viewModel = viewModel ?? SaveWebpageViewModel();

  final SaveWebpageViewModel viewModel;

  @override
  State<SaveWebsiteScreen> createState() => _SaveWebsiteScreenState();
}

class _SaveWebsiteScreenState extends State<SaveWebsiteScreen> {
  final String _initialValue = 'Unread';
  // final List<String> _statuses = ['Unread', 'Reading', 'Read'];
  final Map<String, ReadingStatus> _statuses = {
    'Unread': ReadingStatus.unread,
    'Reading': ReadingStatus.reading,
    'Read': ReadingStatus.read,
  };

  final ValueNotifier<String?> _selectedStatusNotifier = ValueNotifier<String?>(
    'Unread',
  );

  final _urlController = TextEditingController();
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // add a listener to to error
    widget.viewModel.addListener(_checkError);
  }

  void _checkError() {
    final error = widget.viewModel.savingError;
    if (error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), behavior: SnackBarBehavior.floating),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeModel>(
      context,
      listen: false,
    ).isDark(context);
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: true,
            actions: [
              // ! [-- SAVE BUTTON --]
              Padding(
                padding: const EdgeInsets.only(right: 20),
                child: GestureDetector(
                  key: ValueKey('saveButton'),
                  onTap: widget.viewModel.isSaving
                      ? null
                      : () async {
                          final readingStatus = ReadingStatus.values.firstWhere(
                            (status) =>
                                status.name == _selectedStatusNotifier.value,
                            orElse: () => ReadingStatus.unread,
                          );
                          await widget.viewModel.saveWebpage(
                            url: _urlController.text,
                            readingStatus: readingStatus,
                            title: _titleController.text,
                            notes: _notesController.text,
                          );
                          if (widget.viewModel.isSavingSuccessful) {
                            Navigator.pop(context);
                          }
                        },
                  child: widget.viewModel.isSaving
                      ? CircularProgressIndicator()
                      : Row(
                          children: [
                            Icon(Icons.check),
                            SizedBox(width: 5),
                            Text('Save'),
                          ],
                        ),
                ),
              ),
            ],
            title: Text('Save website'),
          ),
          body: SingleChildScrollView(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 450),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // const SizedBox(height: 8),
                      // ! [-- URL FIELD --]
                      LabeledTextField(
                        key: ValueKey('urlTextField'),
                        controller: _urlController,
                        label: 'Url',
                        hintText: 'https://example.com/page',
                        isDark: isDark,
                        errorText: widget.viewModel.urlError,
                        maxLength: SaveWebpageViewModel.urlMaxChars,
                        suffixIcon: Padding(
                          padding: const EdgeInsets.fromLTRB(6.0, 6.0, 9, 6),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.blue[100]?.withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(
                              Icons.paste_outlined,
                              color: Colors.blue[900],
                              size: 18,
                            ),
                          ),
                        ),
                        onSuffixIconTap: () async {
                          final data = await Clipboard.getData(
                            Clipboard.kTextPlain,
                          );
                          if (data?.text != null) {
                            _urlController.text = data!.text!;
                          }
                        },
                      ),
                      const SizedBox(height: 20),

                      // const SizedBox(height: 8),
                      // ! [-- STATUS DROPDOWN --]
                      LabeledDropdown(
                        key: ValueKey('statusDropdown'),
                        selectedItem: _selectedStatusNotifier,
                        label: 'Status',
                        items: _statuses.keys.toList(),
                        initialValue: _initialValue,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 20),

                      // ! [-- TITLE FIELD --]
                      LabeledTextField(
                        key: ValueKey('titleTextField'),
                        controller: _titleController,
                        label: 'Title (optional)',
                        hintText: 'Enter title...',
                        isDark: isDark,
                        errorText: widget.viewModel.titleError,
                        maxLength: SaveWebpageViewModel.titleMaxChars,
                        maxLines: 2,
                      ),
                      const SizedBox(height: 20),

                      // ! [-- NOTES FIELD --]
                      LabeledTextField(
                        key: ValueKey('notesTextField'),
                        controller: _notesController,
                        label: 'Notes (optional)',
                        hintText: 'Enter notes...',
                        isDark: isDark,
                        errorText: widget.viewModel.notesError,
                        maxLength: SaveWebpageViewModel.notesMaxChars,
                        maxLines: 4,
                      ),
                      const SizedBox(height: 24),

                      // ! [-- REMIND ME SWITCH --]
                      Row(
                        key: ValueKey('remindMeSwitch'),
                        children: [
                          SizedBox(
                            height: 24, // Adjusting switch size slightly
                            child: Switch(
                              value: widget.viewModel.remindMe,
                              onChanged: (bool value) {
                                widget.viewModel.remindMe = value;
                              },
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(12, 0, 6, 0),
                            child: Text('Remind me'),
                          ),
                          Icon(
                            Icons.help_outline,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.5),
                            size: 16,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
