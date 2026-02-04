import 'package:garden/themes/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

ThemeData darkTheme = ThemeData.dark().copyWith(
  extensions: <ThemeExtension>[
    AppTheme(
      primaryColor: Color(0xff121212),
      placeholderColor: Color(0xffa6a6a6),
      titleColor: Color(0xffa6a6a6),
      progressColor: Color(0xffd3d3d3),
      successColor: Color(0xff66BB6A),
      warningColor: Color(0xffFFB74D),
      errorColor: Color(0xffEF5350),
      infoColor: Color(0xff42A5F5),
      primaryActionColor: Color(0xffff9813),
      placeholderBackgroundColor: Color(0xff2C2C2C),
    ),
  ],
  scaffoldBackgroundColor: Color(0xff121212),
  textTheme: TextTheme(
    bodySmall: TextStyle(fontSize: 12.0, color: Color(0xffa6a6a6)),
    bodyMedium: TextStyle(fontSize: 15.0, color: Color(0xffa6a6a6)),
    bodyLarge: TextStyle(fontSize: 18.0, color: Color(0xffa6a6a6)),
  ),
  inputDecorationTheme: InputDecorationTheme(
    hintStyle: TextStyle(fontSize: 16.0, color: Color(0xff808080)),
    helperStyle: TextStyle(fontSize: 16.0, color: Color(0xff808080)),
    labelStyle: TextStyle(fontSize: 16.0, color: Color(0xff808080)),
  ),
  iconTheme: IconThemeData(color: Color(0xffa6a6a6)),
  appBarTheme: AppBarTheme(
    centerTitle: true,
    elevation: 0,
    color: Color(0xff121212),
    iconTheme: IconThemeData(color: Color(0xffa6a6a6)),
    actionsIconTheme: IconThemeData(color: Color(0xffa6a6a6)),
    titleTextStyle: TextStyle(fontSize: 20.0, color: Color(0xffa6a6a6)),
    systemOverlayStyle: SystemUiOverlayStyle.light,
  ),
  colorScheme: ColorScheme.dark(
    secondary: Color(0xff888888),
    surface: Color(0xff121212),
  ),
);
