import 'package:articly/config/config.dart';
import 'package:articly/data/models/saved_item.dart';
import 'package:articly/domain/providers/user_provider.dart';
import 'package:articly/presentation/website_saving/view_models/save_webpage_view_model.dart';
import 'package:articly/presentation/website_saving/widgets/labeled_dropdown.dart';
import 'package:articly/presentation/website_saving/widgets/labeled_text_field.dart';
import 'package:articly/theme/theme_model.dart';
import 'package:articly/utils/my_snack_bar.dart';
import 'package:articly/utils/providers_shortcuts.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';

class SaveWebpageScreen extends StatefulWidget {
  const SaveWebpageScreen({
    super.key,
    this.viewModel,
    this.currentItem,
    this.isEdit = false,
  });

  final SaveWebpageViewModel? viewModel;

  final SavedItem? currentItem;
  final bool isEdit;

  @override
  State<SaveWebpageScreen> createState() => _SaveWebpageScreenState();
}

class _SaveWebpageScreenState extends State<SaveWebpageScreen> {
  late final SaveWebpageViewModel _viewModel;

  String _initialValue = 'Unread';
  // final List<String> _statuses = ['Unread', 'Reading', 'Read'];
  final Map<String, ReadingStatus> _statuses = {
    'Unread': ReadingStatus.unread,
    'Reading': ReadingStatus.reading,
    'Read': ReadingStatus.read,
  };

  late final ValueNotifier<String> _selectedStatusNotifier;

  final _urlController = TextEditingController();
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();

  final log = Logger('SaveWebpageScreen');

  late UserProvider provider;

  bool _remindMe = false;

  bool _autoTitle = true;

  @override
  void initState() {
    super.initState();

    _viewModel =
        widget.viewModel ??
        SaveWebpageViewModel(MyProviders(context).savedItemsProvider());

    final values = {
      ReadingStatus.unread: 'Unread',
      ReadingStatus.reading: 'Reading',
      ReadingStatus.read: 'Read',
    };

    // prepopulate fields
    final item = widget.currentItem;
    if (widget.isEdit && item != null) {
      _urlController.text = item.uri.toString();
      _titleController.text = item.title;
      _notesController.text = item.notes;

      _initialValue = values[item.readingStatus] ?? 'Unread';
      _remindMe = item.remindReading;
      // Since the title is required, it cannot be empty or null, so initialize autoTitle with false
      _autoTitle = false;
    }

    _selectedStatusNotifier = ValueNotifier(_initialValue);
  }

  String? nullIfEmpty(String? value) {
    if (value != null && value.isEmpty) return null;
    return value;
  }

  _save() async {
    // selected values are "Unread, Reading, Read", so lowercase them
    final readingStatus = ReadingStatus.values.firstWhere(
      (status) => status.name == _selectedStatusNotifier.value.toLowerCase(),
      orElse: () => ReadingStatus.unread,
    );
    final String url = _urlController.text.trim();
    final Uri? uri = Uri.tryParse(url);
    String title = _titleController.text;
    final String notes = _notesController.text;
    String? imageUrl;
    String? faviconUrl;

    // Validate fields
    // Returns if uri is null
    final isValid = _viewModel.validateFields(uri, title, notes);
    if (!isValid) {
      log.info('Some info is invalid, so not saving the webpage');
      return;
    }

    setState(() {
      _viewModel.saveCommand.start();
    });

    // fetch the metadata
    final prevUrl = widget.currentItem?.uri.toString();
    if (url != prevUrl) {
      final metadata = await _viewModel.fetchWebpageMetadata(uri!);
      if (_autoTitle && title.isEmpty) {
        title = metadata.title ?? '';
      }
      imageUrl = metadata.imageUrl;
      faviconUrl = metadata.faviconUrl;
    }

    final item = SavedItem(
      id: widget.currentItem?.id, // will be set if is edit
      type: ItemType.webpage,
      readingStatus: readingStatus,
      uri: uri!,
      title: title.isEmpty ? defaultTitleName : title,
      notes: notes,
      remindReading: _remindMe,
      imageUrl: imageUrl ?? widget.currentItem?.imageUrl,
      faviconUrl: faviconUrl ?? widget.currentItem?.faviconUrl,
      createdAt: widget.currentItem?.createdAt ?? DateTime.now(),
    );

    final errorMsg = await _viewModel.saveWebpage(
      savedItem: item,
      isEdit: widget.isEdit,
    );

    setState(() {
      _viewModel.saveCommand.finish(errorMsg);
    });

    if (!mounted) return;

    final cmd = _viewModel.saveCommand;
    if (cmd.hasError && !cmd.completed) {
      MySnackBar(context, message: cmd.error!).show();
    } else {
      MySnackBar(context, message: 'Saved webpage successfully!').show();
      Navigator.pop(context, item);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeModel>(
      context,
      listen: false,
    ).isDark(context);

    return Consumer<UserProvider>(
      builder: (context, provider, child) {
        return ListenableBuilder(
          listenable: _viewModel,
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
                      onTap: (_viewModel.saveCommand.running) ? null : _save,
                      child: _viewModel.saveCommand.running
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
                title: Text('Save webpage'),
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
                        StatefulBuilder(
                          builder: (context, setSwitchState) {
                            return Column(
                              children: [
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
                                    fillColor: Theme.of(
                                      context,
                                    ).colorScheme.surfaceContainerHighest,
                                    hintText: 'Add title',
                                    errorText: _viewModel.titleError,
                                    counterText: '',
                                    hintStyle: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withValues(alpha: 0.65),
                                        ),
                                  ),
                                  onChanged: (value) {
                                    setSwitchState(() {
                                      if (_autoTitle && value.isNotEmpty) {
                                        // if the switch is on, but the field is not empty anymore
                                        _autoTitle = false;
                                      } else if (!_autoTitle && value.isEmpty) {
                                        // if the switch is off, but the value is now empty
                                        _autoTitle = true;
                                      }
                                    });
                                  },
                                ),

                                const SizedBox(height: 8),

                                // auto title switch
                                // will be disabled if the title field is not empty
                                Row(
                                  children: [
                                    Transform.scale(
                                      scale: 0.8,
                                      child: Switch(
                                        value: _autoTitle,
                                        onChanged:
                                            _titleController.text.isNotEmpty
                                            ? null
                                            : (bool value) {
                                                setSwitchState(() {
                                                  _autoTitle = value;
                                                });
                                              },
                                      ),
                                    ),

                                    const SizedBox(width: 5),

                                    const Text('Auto title'),

                                    const SizedBox(width: 5),

                                    Tooltip(
                                      message:
                                          'If enabled, will automatically set the title from the webpage by the url',
                                      child: Icon(
                                        Icons.help_outline,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withValues(alpha: 0.5),
                                        size: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            );
                          },
                        ),

                        const SizedBox(height: 20),

                        // const SizedBox(height: 8),
                        // ! [-- URL FIELD --]
                        LabeledTextField(
                          key: ValueKey('urlTextField'),
                          controller: _urlController,
                          autoFocus: true,
                          label: 'Url',
                          hintText: 'https://example.com/page',
                          isDark: isDark,
                          errorText: _viewModel.urlError,
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
                          value: _initialValue,
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
                          errorText: _viewModel.notesError,
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
                                value: _remindMe,
                                onChanged: (bool value) {
                                  setState(() {
                                    _remindMe = value;
                                  });
                                },
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(12, 0, 6, 0),
                              child: Text('Remind me'),
                            ),
                            Tooltip(
                              message:
                                  'If enabled, will give you reading reminders for this source',
                              child: Icon(
                                Icons.help_outline,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.5),
                                size: 16,
                              ),
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
