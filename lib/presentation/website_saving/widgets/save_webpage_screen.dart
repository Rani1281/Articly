import 'package:articly/presentation/website_saving/widgets/labeled_dropdown.dart';
import 'package:articly/presentation/website_saving/widgets/labeled_text_field.dart';
import 'package:articly/theme/theme_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SaveWebsiteScreen extends StatefulWidget {
  const SaveWebsiteScreen({super.key});

  @override
  State<SaveWebsiteScreen> createState() => _SaveWebsiteScreenState();
}

class _SaveWebsiteScreenState extends State<SaveWebsiteScreen> {
  final String _initialValue = 'Unread';
  final List<String> _items = ['Unread', 'Reading', 'Read'];

  final ValueNotifier<String?> _selectedItemNotifier = ValueNotifier<String?>(
    'Unread',
  );

  final _urlController = TextEditingController();
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();

  bool _remindMe = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeModel>(
      context,
      listen: false,
    ).isDark(context);
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: GestureDetector(
              onTap: () {},
              child: Row(
                children: [Icon(Icons.check), SizedBox(width: 5), Text('Save')],
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
                  // 1. URL Field
                  const SizedBox(height: 8),
                  LabeledTextField(
                    label: 'Url',
                    hintText: 'https://example.com/page',
                    isDark: isDark,
                    suffixIcon: Padding(
                      padding: const EdgeInsets.fromLTRB(6.0, 6.0, 9, 6),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.blue[100]?.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        // Paste/clipboard icon
                        child: Icon(
                          Icons.paste_outlined,
                          color: Colors.blue[900],
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 2. Status Dropdown
                  const SizedBox(height: 8),
                  LabeledDropdown(
                    selectedItem: _selectedItemNotifier,
                    label: 'Status',
                    items: _items,
                    initialValue: _initialValue,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 20),

                  // 3. Title Field
                  LabeledTextField(
                    label: 'Title (optional)',
                    hintText: 'Enter title...',
                    isDark: isDark,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 20),

                  // 4. Notes Field
                  LabeledTextField(
                    label: 'Notes (optional)',
                    hintText: 'Enter notes...',
                    isDark: isDark,
                    maxLines: 4,
                  ),
                  const SizedBox(height: 24),

                  // 5. Remind Me Switch
                  Row(
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
  }
}
