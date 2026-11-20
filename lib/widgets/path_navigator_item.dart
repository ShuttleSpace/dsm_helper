import 'package:flutter/material.dart';
import 'package:garden/constants/app_constants.dart';
import 'package:garden/theme/app_colors.dart';

/// 路径导航项组件
///
/// 用于显示文件路径面包屑导航
class PathNavigatorItem extends StatelessWidget {
  final String path;
  final int index;
  final int total;
  final VoidCallback onTap;
  final bool isLast;

  const PathNavigatorItem({
    super.key,
    required this.path,
    required this.index,
    required this.total,
    required this.onTap,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    Color pathColor = isLast
        ? AppColors.getText(
            Theme.of(context).brightness == Brightness.dark,
          )
        : AppColors.getTextPlaceholder(
            Theme.of(context).brightness == Brightness.dark,
          );

    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: AppConstants.paddingSmall + 2,
      ),
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: pathColor,
          backgroundColor: Colors.transparent,
          side: BorderSide(color: pathColor.withValues(alpha: .3)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.paddingSmall,
            vertical: AppConstants.paddingSmall / 2,
          ),
        ),
        child: Text(
          path,
          style: TextStyle(
            fontSize: AppConstants.fontSizeMedium,
            color: pathColor,
          ),
        ),
      ),
    );
  }
}
