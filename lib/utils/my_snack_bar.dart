import 'dart:math';

import 'package:flutter/material.dart';

class MySnackBar {
  MySnackBar(this.context, {required this.message, this.maxWidth = 500});

  final BuildContext context;
  final String message;
  final double maxWidth;

  SnackBar buildSnackBar() {
    return SnackBar(
      width: min(MediaQuery.of(context).size.width, maxWidth),
      content: Text(message),
      behavior: SnackBarBehavior.floating,
    );
  }

  void show() {
    ScaffoldMessenger.of(context).showSnackBar(buildSnackBar());
  }
}
