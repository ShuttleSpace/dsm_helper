import 'package:flutter/material.dart';
import 'package:garden/constants/app_constants.dart';
import 'package:garden/theme/app_colors.dart';

/// Dashboard 列表项组件
///
/// 统一的列表项样式，用于 Dashboard 页面
class DashboardItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final IconData? icon;
  final Color? iconColor;

  const DashboardItem({
    super.key,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
    this.icon,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingLarge,
        vertical: AppConstants.paddingSmall,
      ),
      child: ListTile(
        leading: icon != null
            ? Icon(
                icon,
                color: iconColor ?? AppColors.primaryAction,
              )
            : null,
        title: Text(
          title,
          style: const TextStyle(
            fontSize: AppConstants.fontSizeMedium,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: AppConstants.fontSizeSmall,
            color: AppColors.getTextPlaceholder(
              Theme.of(context).brightness == Brightness.dark,
            ),
          ),
        ),
        trailing: trailing,
        onTap: onTap,
      ),
    );
  }
}

/// Dashboard 状态指示器组件
class StatusIndicator extends StatelessWidget {
  final String label;
  final Color color;
  final bool fill;

  const StatusIndicator({
    super.key,
    required this.label,
    required this.color,
    this.fill = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingSmall,
        vertical: AppConstants.paddingSmall / 2,
      ),
      decoration: BoxDecoration(
        color: fill ? color : color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
        border: !fill ? Border.all(color: color) : null,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: AppConstants.fontSizeSmall,
          color: fill ? Colors.white : color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
