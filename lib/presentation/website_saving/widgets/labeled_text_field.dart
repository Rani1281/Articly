import 'package:flutter/material.dart';

class LabeledTextField extends StatelessWidget {
  const LabeledTextField({
    super.key,
    this.controller,
    this.label,
    this.hintText,
    this.isDark,
    this.suffixIcon,
    this.onSuffixIconTap,
    this.maxLines = 1,
    this.errorText,
    this.maxLength,
  });

  final TextEditingController? controller;
  final String? label;
  final String? hintText;
  final bool? isDark;
  final Widget? suffixIcon;
  final VoidCallback? onSuffixIconTap;
  final int maxLines;
  final String? errorText;
  final int? maxLength;

  @override
  Widget build(BuildContext context) {
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
        TextField(
          maxLength: maxLength,
          maxLines: maxLines,
          controller: controller,
          decoration: InputDecoration(
            errorText: errorText,
            hintText: hintText,
            hintStyle: TextStyle(
              // color: Color(0xFF98A2B3),
              color: hintColor,
              fontWeight: FontWeight.normal,
            ),
            filled: true,
            fillColor: (isDark ?? false)
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
            suffixIcon: suffixIcon != null && onSuffixIconTap != null
                ? GestureDetector(
                    onTap: onSuffixIconTap,
                    child: suffixIcon,
                  )
                : suffixIcon,
          ),
        ),
      ],
    );
  }
}
