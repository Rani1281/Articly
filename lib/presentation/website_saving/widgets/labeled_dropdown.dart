import 'package:articly/theme/theme_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LabeledDropdown extends StatelessWidget {
  const LabeledDropdown({
    super.key,
    this.label,
    required this.items,
    this.selectedItem,
    this.initialValue,
    this.hintText,
    this.isDark,
  });

  final String? label;
  final List<String> items;
  final ValueNotifier<String?>? selectedItem;
  final String? initialValue;
  final String? hintText;
  final bool? isDark;

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeModel>(
      context,
      listen: false,
    ).isDark(context);
    final Color borderColor = Theme.of(
      context,
    ).colorScheme.surfaceContainerHighest;
    final Color hintColor = Theme.of(
      context,
    ).colorScheme.onSurface.withValues(alpha: 0.5);
    return Column(
      children: [
        if (label != null) ...[
          Align(
            alignment: Alignment.centerLeft,
            child: Text(label!, style: Theme.of(context).textTheme.labelLarge),
          ),
          SizedBox(height: 5),
        ],
        ButtonTheme(
          alignedDropdown:
              true, // Aligns the dropdown menu width perfectly to the button's boundaries
          child: DropdownButtonFormField<String>(
            isExpanded:
                true, // Expands the content inner space and avoids RenderFlex overflow with long texts
            borderRadius: BorderRadius.circular(12),
            dropdownColor: Theme.of(context)
                .colorScheme
                .surfaceContainer, // Added dropdownColor for better visual
            initialValue: initialValue,
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: TextStyle(
                color: hintColor,
                fontWeight: FontWeight.normal,
              ),
              filled: true,
              fillColor: isDark
                  ? Theme.of(context).colorScheme.surfaceContainer
                  : Colors.white,
              contentPadding: const EdgeInsets.all(14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: borderColor, width: 1.5),
              ),
            ),
            icon: Icon(Icons.keyboard_arrow_down, color: hintColor),
            items: items.map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(value: value, child: Text(value));
            }).toList(),
            onChanged: (String? newValue) {
              // setState(() {
              selectedItem?.value = newValue;
              debugPrint('New value: ${selectedItem?.value}');
              // });
            },
          ),
        ),
      ],
    );
  }
}
