import 'dart:async';

import 'package:articly/presentation/authentication/widgets/auth_button.dart';
import 'package:flutter/material.dart';

/// A wrapper widget that handles the cooldown logic for your custom AuthButton.
class CooldownAuthButton extends StatefulWidget {
  final VoidCallback onResend;
  final int cooldownSeconds;
  final String text;
  final bool startCounting;

  const CooldownAuthButton({
    super.key,
    required this.onResend,
    this.cooldownSeconds = 60, // Default cooldown of 60 seconds
    required this.text,
    this.startCounting = false,
  });

  @override
  State<CooldownAuthButton> createState() => _CooldownAuthButtonState();
}

class _CooldownAuthButtonState extends State<CooldownAuthButton> {
  int _remainingSeconds = 0;
  Timer? _timer;

  // Helper getter to check if the button is currently in cooldown
  bool get _isCooldown => _remainingSeconds > 0;

  void _startCooldown() {
    setState(() {
      _remainingSeconds = widget.cooldownSeconds;
    });

    // Cancel any existing timer just in case
    _timer?.cancel();

    // Start a timer that ticks every 1 second
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        // Stop the timer when it hits 0
        timer.cancel();
      }
    });
  }

  void _handlePress() {
    if (_isCooldown) return; // Prevent clicking during cooldown

    // Trigger the actual email resend logic
    widget.onResend();

    // Start the cooldown timer
    _startCooldown();
  }

  @override
  void initState() {
    if (widget.startCounting) _startCooldown();
    super.initState();
  }

  @override
  void dispose() {
    // Always cancel the timer to prevent memory leaks when the widget is destroyed
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AuthButton(
          color: Theme.of(context).colorScheme.primary,
          onPressed: _isCooldown ? null : _handlePress,
          child: Text(widget.text, style: TextStyle(fontSize: 16)),
        ),

        if (_isCooldown) ...[
          const SizedBox(height: 8),
          Text(
            'Try again in $_remainingSeconds seconds',
            // style: const TextStyle(fontSize: 12, color: Colors.black87),
          ),
        ],
      ],
    );
  }
}
