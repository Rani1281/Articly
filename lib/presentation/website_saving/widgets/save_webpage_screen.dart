import 'package:articly/data/models/saved_item.dart';
import 'package:articly/domain/providers/saved_items_provider.dart';
import 'package:articly/presentation/website_saving/view_models/save_webpage_view_model.dart';
import 'package:articly/presentation/website_saving/widgets/labeled_dropdown.dart';
import 'package:articly/presentation/website_saving/widgets/labeled_text_field.dart';
import 'package:articly/theme/theme_model.dart';
import 'package:articly/utils/my_snack_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
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

  final log = Logger('SaveWebpageScreen');

  late SavedItemsProvider provider;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      provider = context.read<SavedItemsProvider>();
      provider.addListener(_onProviderChanged);
    });
  }

  void _onProviderChanged() {
    if (provider.saveCommand.hasError) {
      MySnackBar(context, message: provider.saveCommand.error!).show();
    }
  }

  @override
  void dispose() {
    provider.removeListener(_onProviderChanged);
    super.dispose();
  }

  void _save(BuildContext context) async {
    // selected values are "Unread, Reading, Read", so lowercase them
    final readingStatus = ReadingStatus.values.firstWhere(
      (status) => status.name == _selectedStatusNotifier.value?.toLowerCase(),
      orElse: () => ReadingStatus.unread,
    );
    final url = _urlController.text.trim();
    final title = _titleController.text;
    final notes = _notesController.text;

    final isValid = widget.viewModel.validateFields(url, title, notes);
    if (!isValid) {
      log.warning('Some info is invalid, so not saving the webpage');
      return;
    }

    final item = SavedItem(
      type: ItemType.webpage,
      readingStatus: readingStatus,
      uri: Uri.tryParse(url),
      title: title,
      notes: notes,
      remindReading: widget.viewModel.remindMe,
    );

    final provider = Provider.of<SavedItemsProvider>(context, listen: false);
    await provider.save(item);
    if (provider.saveCommand.completed && mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeModel>(
      context,
      listen: false,
    ).isDark(context);

    return Consumer<SavedItemsProvider>(
      builder: (context, provider, child) {
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
                      behavior: HitTestBehavior.opaque,
                      key: ValueKey('saveButton'),
                      onTap: (provider.saveCommand.running)
                          ? null
                          : () => _save(context),
                      child: provider.saveCommand.running
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(),
                            )
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
                padding: EdgeInsets.all(20),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 450),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ! [-- TITLE FIELD --]
                        TextField(
                          key: const ValueKey('titleTextField'),
                          controller: _titleController,
                          keyboardType: TextInputType.multiline,
                          minLines: 1,
                          maxLines: null,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w600),
                          maxLength: SaveWebpageViewModel.titleMaxChars,
                          decoration: InputDecoration(
                            hintText: 'Add title',
                            errorText: widget.viewModel.titleError,
                            counterText: '',
                            hintStyle: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context).colorScheme.onSurface
                                      .withValues(alpha: 0.65),
                                ),
                          ),
                        ),
                        const SizedBox(height: 20),

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
                              child: Tooltip(
                                message: 'Paste',
                                child: Icon(
                                  Icons.paste_outlined,
                                  color: Colors.blue[900],
                                  size: 18,
                                ),
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

                        // ! [-- NOTES FIELD --]
                        LabeledTextField(
                          key: ValueKey('notesTextField'),
                          controller: _notesController,
                          label: 'Notes (optional)',
                          hintText: 'Enter notes...',
                          isDark: isDark,
                          errorText: widget.viewModel.notesError,
                          maxLength: SaveWebpageViewModel.notesMaxChars,
                          maxLines: 6,
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
            );
          },
        );
      },
    );
  }
}
