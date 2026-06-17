import 'package:flutter/material.dart';

class AuthTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? hintText;
  // final Color? fillColor;
  final bool? isDark;
  final Widget? suffixIcon;
  final bool obscureText;
  final double maxWidth;
  final TextInputType keyboardType;
  final void Function(String)? onChanged;

  const AuthTextField({
    super.key,
    this.controller,
    this.hintText,
    // this.fillColor,
    this.isDark,
    this.suffixIcon,
    this.obscureText = false,
    this.maxWidth = 450.0,
    this.keyboardType = TextInputType.text,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: SizedBox(
          width: double.infinity,
          child: TextField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            onChanged: onChanged,
            // style: const TextStyle(fontSize: 16.0, color: Colors.black87),
            decoration: InputDecoration(
              filled: true,
              // fillColor: (isDark ?? false) ? Colors.black : Colors.white,

              // 1. DISABLES THE GREY HOVER EFFECT ON WEB/DESKTOP
              hoverColor: Colors.transparent,

              // 2. DISPLAYS THE HINT TEXT WHEN EMPTY
              hintText: hintText,

              // hintStyle: TextStyle(
              //   color: (isDark ?? false) ? Colors.white54 : Colors.black54,
              // ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 18.0,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16.0),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16.0),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16.0),
                borderSide: BorderSide.none,
              ),

              suffixIcon: Padding(
                padding: EdgeInsetsGeometry.fromLTRB(0, 0, 15, 0),
                child: suffixIcon,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
