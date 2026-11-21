import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:garden/constants/app_constants.dart';
import 'package:garden/theme/app_colors.dart';

/// 设置页通用的「勾选行」。
///
/// 文件服务、FTP 等页面里大量重复
/// `GestureDetector + Card + Row(Expanded(Text), Icon(checkmark))`，
/// 统一到这里后业务侧只需提供标签、当前值和点击行为。
class SettingsToggleTile extends StatelessWidget {
  final String label;
  final bool value;
  final VoidCallback onTap;
  final Color checkColor;
  final ShapeBorder? shape;

  const SettingsToggleTile({
    super.key,
    required this.label,
    required this.value,
    required this.onTap,
    this.checkColor = AppColors.primaryAction,
    this.shape,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        shape: shape ??
            RoundedRectangleBorder(
              side: const BorderSide(),
              borderRadius: BorderRadius.circular(5),
            ),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.paddingSmall),
          child: Row(
            children: [
              Expanded(child: Text(label)),
              if (value)
                Icon(
                  CupertinoIcons.checkmark_alt,
                  color: checkColor,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
