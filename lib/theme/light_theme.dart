import 'package:garden/theme/app_colors.dart';
import 'package:garden/theme/app_theme.dart';
import 'package:garden/constants/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 浅色主题
ThemeData lightTheme = ThemeData.light().copyWith(
  extensions: <ThemeExtension>[
    AppTheme(
      primaryColor: AppColors.primaryLight,
      placeholderColor: AppColors.textPlaceholderLight,
      titleColor: AppColors.textLight,
      progressColor: AppColors.progressLight,
      successColor: AppColors.successLight,
      warningColor: AppColors.warningLight,
      errorColor: AppColors.errorLight,
      infoColor: AppColors.infoLight,
      primaryActionColor: AppColors.primaryAction,
      placeholderBackgroundColor: AppColors.placeholderBackgroundLight,
    ),
  ],
  textTheme: const TextTheme(
    bodySmall: TextStyle(
        fontSize: AppConstants.fontSizeSmall, color: AppColors.textLight),
    bodyMedium: TextStyle(fontSize: 15.0, color: AppColors.textLight),
    bodyLarge: TextStyle(
        fontSize: AppConstants.fontSizeLarge, color: AppColors.textLight),
  ),
  inputDecorationTheme: const InputDecorationTheme(
    hintStyle:
        TextStyle(fontSize: AppConstants.fontSizeLarge, color: Colors.grey),
    labelStyle:
        TextStyle(fontSize: AppConstants.fontSizeLarge, color: Colors.grey),
  ),
  appBarTheme: const AppBarTheme(
    centerTitle: true,
    elevation: 0,
    backgroundColor: AppColors.backgroundLight,
    iconTheme: IconThemeData(color: AppColors.textLight),
    actionsIconTheme: IconThemeData(color: AppColors.textLight),
    titleTextStyle: TextStyle(
        fontSize: AppConstants.fontSizeXXLarge, color: AppColors.textLight),
    systemOverlayStyle: SystemUiOverlayStyle.dark,
  ),
  scaffoldBackgroundColor: AppColors.backgroundLight,
  colorScheme: const ColorScheme.light(
    surface: AppColors.backgroundLight,
  ),
);
