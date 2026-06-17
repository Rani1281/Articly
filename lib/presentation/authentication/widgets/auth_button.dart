import 'package:flutter/material.dart';

class AuthButton extends StatelessWidget {
  final Color? color;
  final Color textColor;
  final VoidCallback? onPressed;
  final double maxWidth;
  final Widget child;

  const AuthButton({
    super.key,
    this.color,
    required this.onPressed,
    this.textColor = Colors.white, // Defaults to white text
    this.maxWidth = 450.0, // Matches the text field's max width
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: textColor,
              elevation:
                  0, // Set to 0 for a modern, flat look to match the text field
              // Matches the padding of the text field for identical height
              padding: const EdgeInsets.symmetric(vertical: 18.0),

              // Exactly the same rounding as the text field
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0),
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
