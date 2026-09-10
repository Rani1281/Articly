import 'package:flutter/material.dart';

class CreateTagButton extends StatelessWidget {
  const CreateTagButton({
    super.key,
    required this.onPressed,
    this.enabled = true,
  });

  final VoidCallback? onPressed;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: enabled ? onPressed : null,
        icon: const Icon(Icons.add),
        label: const Text('Create a tag'),
      ),
    );
  }
}
