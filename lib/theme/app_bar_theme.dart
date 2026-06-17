import 'package:articly/theme/app_colors.dart';
import 'package:flutter/material.dart';

const AppBarTheme appBarThemeLight = AppBarTheme(
  // backgroundColor: Colors.white,
  backgroundColor: Colors.transparent,
  titleTextStyle: TextStyle(
    color: Colors.black,
    fontSize: 18,
    fontWeight: FontWeight.w600,
  ),
  actionsPadding: EdgeInsets.all(8),
  centerTitle: true,
  elevation: 0,
);

const AppBarTheme appBarThemeDark = AppBarTheme(
  // backgroundColor: Colors.white,
  backgroundColor: Colors.transparent,
  titleTextStyle: TextStyle(
    color: Colors.white,
    fontSize: 18,
    fontWeight: FontWeight.w600,
  ),
  actionsPadding: EdgeInsets.all(8),
  centerTitle: true,
  elevation: 0,
);
