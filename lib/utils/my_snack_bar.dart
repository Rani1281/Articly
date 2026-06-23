import 'dart:math';

import 'package:flutter/material.dart';

void showSnackBar(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      width: min(MediaQuery.of(context).size.width, 500),
      content: Text('Copied to clipboard'),
      behavior: SnackBarBehavior.floating,
    ),
  );
}
