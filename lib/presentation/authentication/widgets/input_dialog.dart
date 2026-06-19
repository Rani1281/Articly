import 'package:flutter/material.dart';

class EditUsernameDialog extends StatefulWidget {
  final String initialUsername;

  const EditUsernameDialog({super.key, required this.initialUsername});

  @override
  State<EditUsernameDialog> createState() => _EditUsernameDialogState();
}

class _EditUsernameDialogState extends State<EditUsernameDialog> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    // Prepopulate the text field with the previous username
    _controller = TextEditingController(text: widget.initialUsername);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Validation logic
  bool get _isValid {
    final text = _controller.text.trim();
    return text.isNotEmpty && text.length <= 50;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      constraints: const BoxConstraints.tightFor(width: 300),
      title: const Text('Edit Username'),
      content: SingleChildScrollView(
        child: TextField(
          controller: _controller,
          maxLines: 1,
          maxLength: 40,
        decoration: const InputDecoration(
          hintText: "Enter your username",
          border: OutlineInputBorder(),
        ),
        onChanged: (value) {
          setState(() {});
        },
      ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            // Close dialog returning null (cancel)
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          // If valid, pass the new trimmed string back. If not, set to null (disables button)
          onPressed: _isValid
              ? () {
                  Navigator.of(context).pop(_controller.text.trim());
                }
              : null,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
