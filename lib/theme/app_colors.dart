import 'package:flutter/material.dart';

/// 应用颜色常量
/// 
/// 统一管理应用中使用的所有颜色，确保主题一致性
class AppColors {
  AppColors._();

  // ==================== 主色 ====================
  
  /// 深色主题主色
  static const Color primaryDark = Color(0xff121212);
  
  /// 浅色主题主色
  static const Color primaryLight = Color(0xff333333);
  
  /// 深色主题背景色
  static const Color backgroundDark = Color(0xff121212);
  
  /// 浅色主题背景色
  static const Color backgroundLight = Color(0xFFF4F4F4);
  
  /// 深色主题表面色
  static const Color surfaceDark = Color(0xff121212);
  
  /// 浅色主题表面色
  static const Color surfaceLight = Color(0xFFF4F4F4);
  
  // ==================== 文字颜色 ====================
  
  /// 深色主题文字颜色
  static const Color textDark = Color(0xffa6a6a6);
  
  /// 浅色主题文字颜色
  static const Color textLight = Color(0xff121212);
  
  /// 深色主题占位符文字颜色
  static const Color textPlaceholderDark = Color(0xffa6a6a6);
  
  /// 浅色主题占位符文字颜色
  static const Color textPlaceholderLight = Color(0xffa9a9a9);
  
  /// 深色主题提示文字颜色
  static const Color textHintDark = Color(0xff808080);
  
  /// 浅色主题提示文字颜色
  static const Color textHintLight = Colors.grey;
  
  /// 深色主题副色
  static const Color secondaryDark = Color(0xff888888);
  
  // ==================== 状态颜色 ====================
  
  /// 深色主题成功颜色
  static const Color successDark = Color(0xff66BB6A);
  
  /// 浅色主题成功颜色
  static const Color successLight = Color(0xff4CAF50);
  
  /// 深色主题警告颜色
  static const Color warningDark = Color(0xffFFB74D);
  
  /// 浅色主题警告颜色
  static const Color warningLight = Color(0xffFF9800);
  
  /// 深色主题错误颜色
  static const Color errorDark = Color(0xffEF5350);
  
  /// 浅色主题错误颜色
  static const Color errorLight = Color(0xffF44336);
  
  /// 深色主题信息颜色
  static const Color infoDark = Color(0xff42A5F5);
  
  /// 浅色主题信息颜色
  static const Color infoLight = Color(0xff2196F3);
  
  /// 深色主题进度颜色
  static const Color progressDark = Color(0xffd3d3d3);
  
  /// 浅色主题进度颜色
  static const Color progressLight = Color(0xfff4f4f4);
  
  // ==================== 强调色 ====================
  
  /// 主操作颜色（橙色）
  static const Color primaryAction = Color(0xffff9813);
  
  // ==================== 占位符背景色 ====================
  
  /// 深色主题占位符背景色
  static const Color placeholderBackgroundDark = Color(0xff2C2C2C);
  
  /// 浅色主题占位符背景色
  static const Color placeholderBackgroundLight = Color(0xffE9E9E9);
  
  // ==================== 通用颜色 ====================
  
  /// 白色
  static const Color white = Color(0xFFFFFFFF);
  
  /// 黑色
  static const Color black = Color(0xFF000000);
  
  /// 透明
  static const Color transparent = Color(0x00000000);
  
  /// 灰色
  static const Color grey = Color(0xFF808080);
  
  /// 浅灰色
  static const Color greyLight = Color(0xFFE0E0E0);
  
  /// 深灰色
  static const Color greyDark = Color(0xFF424242);

  // ==================== 图表颜色 ====================
  
  /// 图表网格颜色
  static const Color chartGrid = Color(0xff67727d);
  
  /// 图表文本颜色
  static const Color chartText = Color(0xff67727d);
  
  /// 图表颜色 1（绿色）
  static const Color chart1 = Color(0xffBAE050);
  
  /// 图表颜色 2（蓝色）
  static const Color chart2 = Color(0xff73B0EE);
  
  /// 图表颜色 3（深蓝色）
  static const Color chart3 = Color(0xff5584C8);

  // ==================== 更新对话框颜色 ====================
  
  /// 更新对话框标题颜色
  static const Color updateTitle = Color(0xffFFDFD8);
  
  // ==================== 辅助方法 ====================
  
  /// 获取当前主题的主色
  static Color getPrimary(bool isDark) => isDark ? primaryDark : primaryLight;
  
  /// 获取当前主题的背景色
  static Color getBackground(bool isDark) => isDark ? backgroundDark : backgroundLight;
  
  /// 获取当前主题的表面色
  static Color getSurface(bool isDark) => isDark ? surfaceDark : surfaceLight;
  
  /// 获取当前主题的文字颜色
  static Color getText(bool isDark) => isDark ? textDark : textLight;
  
  /// 获取当前主题的占位符文字颜色
  static Color getTextPlaceholder(bool isDark) => isDark ? textPlaceholderDark : textPlaceholderLight;
  
  /// 获取当前主题的提示文字颜色
  static Color getTextHint(bool isDark) => isDark ? textHintDark : textHintLight;
  
  /// 获取当前主题的成功颜色
  static Color getSuccess(bool isDark) => isDark ? successDark : successLight;
  
  /// 获取当前主题的警告颜色
  static Color getWarning(bool isDark) => isDark ? warningDark : warningLight;
  
  /// 获取当前主题的错误颜色
  static Color getError(bool isDark) => isDark ? errorDark : errorLight;
  
  /// 获取当前主题的信息颜色
  static Color getInfo(bool isDark) => isDark ? infoDark : infoLight;
  
  /// 获取当前主题的进度颜色
  static Color getProgress(bool isDark) => isDark ? progressDark : progressLight;
  
  /// 获取当前主题的占位符背景色
  static Color getPlaceholderBackground(bool isDark) => isDark ? placeholderBackgroundDark : placeholderBackgroundLight;

  // ==================== 基于 BuildContext 的辅助方法 ====================
  
  /// 根据 BuildContext 获取当前主题的主色
  static Color primaryOf(BuildContext context) => 
      getPrimary(Theme.brightnessOf(context) == Brightness.dark);
  
  /// 根据 BuildContext 获取当前主题的背景色
  static Color backgroundOf(BuildContext context) => 
      getBackground(Theme.brightnessOf(context) == Brightness.dark);
  
  /// 根据 BuildContext 获取当前主题的表面色
  static Color surfaceOf(BuildContext context) => 
      getSurface(Theme.brightnessOf(context) == Brightness.dark);
  
  /// 根据 BuildContext 获取当前主题的文字颜色
  static Color textOf(BuildContext context) => 
      getText(Theme.brightnessOf(context) == Brightness.dark);
  
  /// 根据 BuildContext 获取当前主题的占位符文字颜色
  static Color textPlaceholderOf(BuildContext context) => 
      getTextPlaceholder(Theme.brightnessOf(context) == Brightness.dark);
  
  /// 根据 BuildContext 获取当前主题的提示文字颜色
  static Color textHintOf(BuildContext context) => 
      getTextHint(Theme.brightnessOf(context) == Brightness.dark);
  
  /// 根据 BuildContext 获取当前主题的成功颜色
  static Color successOf(BuildContext context) => 
      getSuccess(Theme.brightnessOf(context) == Brightness.dark);
  
  /// 根据 BuildContext 获取当前主题的警告颜色
  static Color warningOf(BuildContext context) => 
      getWarning(Theme.brightnessOf(context) == Brightness.dark);
  
  /// 根据 BuildContext 获取当前主题的错误颜色
  static Color errorOf(BuildContext context) => 
      getError(Theme.brightnessOf(context) == Brightness.dark);
  
  /// 根据 BuildContext 获取当前主题的信息颜色
  static Color infoOf(BuildContext context) => 
      getInfo(Theme.brightnessOf(context) == Brightness.dark);
  
  /// 根据 BuildContext 获取当前主题的进度颜色
  static Color progressOf(BuildContext context) => 
      getProgress(Theme.brightnessOf(context) == Brightness.dark);
  
  /// 根据 BuildContext 获取当前主题的占位符背景色
  static Color placeholderBackgroundOf(BuildContext context) => 
      getPlaceholderBackground(Theme.brightnessOf(context) == Brightness.dark);
}