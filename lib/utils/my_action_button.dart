import 'package:flutter/material.dart';

class MyActionButton extends StatelessWidget {
  const MyActionButton({
    super.key,
    required this.onPressed,
    required this.text,
    this.icon,
  });

  final void Function()? onPressed;
  final String text;
  final Widget? icon;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      label: Text(text),
      icon: icon,
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.all(20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
      ),
    );
  }
}
