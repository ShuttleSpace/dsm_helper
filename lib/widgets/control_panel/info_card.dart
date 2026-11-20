import 'package:flutter/material.dart';
import 'package:garden/constants/app_constants.dart';

/// 信息卡片容器组件
/// 提供统一样式的卡片容器
class InfoCard extends StatelessWidget {
  /// 卡片内容
  final Widget child;

  /// 卡片外边距
  final EdgeInsetsGeometry? margin;

  /// 是否显示边框
  final bool showBorder;

  /// 圆角半径
  final double borderRadius;

  const InfoCard({
    super.key,
    required this.child,
    this.margin,
    this.showBorder = true,
    this.borderRadius = 18,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        side: showBorder ? const BorderSide() : BorderSide.none,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      margin: margin,
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingSmall),
        child: child,
      ),
    );
  }
}