import 'package:garden/themes/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

ThemeData lightTheme = ThemeData.light().copyWith(
    extensions: <ThemeExtension>[
      AppTheme(
        primaryColor: Color(0xff333333),
        placeholderColor: Color(0xffa9a9a9),
        titleColor: Color(0xff121212),
        progressColor: Color(0xfff4f4f4),
        successColor: Color(0xff4CAF50),
        warningColor: Color(0xffFF9800),
        errorColor: Color(0xffF44336),
        infoColor: Color(0xff2196F3),
        primaryActionColor: Color(0xffff9813),
        placeholderBackgroundColor: Color(0xffE9E9E9),
      ),
    ],
    textTheme: TextTheme(
      bodySmall: TextStyle(fontSize: 12.0, color: Color(0xff121212)),
      bodyMedium: TextStyle(fontSize: 15.0, color: Color(0xff121212)),
      bodyLarge: TextStyle(fontSize: 18.0, color: Color(0xff121212)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      hintStyle: TextStyle(fontSize: 16.0, color: Colors.grey),
      labelStyle: TextStyle(fontSize: 16.0, color: Colors.grey),
    ),
    appBarTheme: AppBarTheme(
      centerTitle: true,
      elevation: 0,
      color: Color(0xFFF4F4F4),
      iconTheme: IconThemeData(color: Color(0xff121212)),
      actionsIconTheme: IconThemeData(color: Color(0xff121212)),
      titleTextStyle: TextStyle(fontSize: 20.0, color: Color(0xff121212)),
      systemOverlayStyle: SystemUiOverlayStyle.dark,
    ),
    scaffoldBackgroundColor: Color(0xFFF4F4F4),
    colorScheme: ColorScheme.light(
      surface: Color(0xFFF4F4F4),
    ),
  );
