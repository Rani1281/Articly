import 'dart:async';
import 'package:flutter/material.dart';

class ConfirmDeleteDialog extends StatelessWidget {
  const ConfirmDeleteDialog({
    super.key,
    this.title = const Text('Delete'),
    required this.content,
    required this.action,
    this.confirmButtonText = 'Delete',
    this.cancelButtonText = 'Cancel',
  });

  final Widget? title;
  final Widget content;
  final FutureOr<void> Function() action;
  final String confirmButtonText;
  final String cancelButtonText;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: title,
      content: content,
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(cancelButtonText),
        ),
        TextButton(
          onPressed: () async {
            Navigator.of(context).pop(true);
            await action();
          },
          child: Text(confirmButtonText),
        ),
      ],
    );
  }
}
