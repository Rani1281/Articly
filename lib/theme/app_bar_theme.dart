import 'package:articly/theme/app_colors.dart';
import 'package:flutter/material.dart';

final AppBarTheme appBarTheme = AppBarTheme(
  // backgroundColor: Colors.white,
  backgroundColor: AppColors.scaffoldBackgroundColor,
  titleTextStyle: const TextStyle(
    color: Colors.black,
    fontSize: 18,
    fontWeight: FontWeight.bold,
  ),
  actionsPadding: EdgeInsets.all(8),
  centerTitle: true,
  elevation: 0,
);
