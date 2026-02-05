import 'package:garden/theme/app_colors.dart';
import 'package:garden/theme/app_theme.dart';
import 'package:garden/constants/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 深色主题
ThemeData darkTheme = ThemeData.dark().copyWith(
  extensions: <ThemeExtension>[
    AppTheme(
      primaryColor: AppColors.primaryDark,
      placeholderColor: AppColors.textPlaceholderDark,
      titleColor: AppColors.textDark,
      progressColor: AppColors.progressDark,
      successColor: AppColors.successDark,
      warningColor: AppColors.warningDark,
      errorColor: AppColors.errorDark,
      infoColor: AppColors.infoDark,
      primaryActionColor: AppColors.primaryAction,
      placeholderBackgroundColor: AppColors.placeholderBackgroundDark,
    ),
  ],
  scaffoldBackgroundColor: AppColors.backgroundDark,
  textTheme: const TextTheme(
    bodySmall: TextStyle(
        fontSize: AppConstants.fontSizeSmall, color: AppColors.textDark),
    bodyMedium: TextStyle(fontSize: 15.0, color: AppColors.textDark),
    bodyLarge: TextStyle(
        fontSize: AppConstants.fontSizeLarge, color: AppColors.textDark),
  ),
  inputDecorationTheme: const InputDecorationTheme(
    hintStyle: TextStyle(
        fontSize: AppConstants.fontSizeLarge, color: AppColors.textHintDark),
    helperStyle: TextStyle(
        fontSize: AppConstants.fontSizeLarge, color: AppColors.textHintDark),
    labelStyle: TextStyle(
        fontSize: AppConstants.fontSizeLarge, color: AppColors.textHintDark),
  ),
  iconTheme: const IconThemeData(color: AppColors.textDark),
  appBarTheme: const AppBarTheme(
    centerTitle: true,
    elevation: 0,
    backgroundColor: AppColors.backgroundDark,
    iconTheme: IconThemeData(color: AppColors.textDark),
    actionsIconTheme: IconThemeData(color: AppColors.textDark),
    titleTextStyle: TextStyle(
        fontSize: AppConstants.fontSizeXXLarge, color: AppColors.textDark),
    systemOverlayStyle: SystemUiOverlayStyle.light,
  ),
  colorScheme: const ColorScheme.dark(
    secondary: AppColors.secondaryDark,
    surface: AppColors.backgroundDark,
  ),
);
