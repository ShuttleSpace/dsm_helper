import 'package:flutter/material.dart';

/// 新拟态风格通用卡片组件
///
/// 用法示例：
/// ```dart
/// NeuCard(
///   child: Text("卡片内容"),
///   margin: EdgeInsets.only(bottom: 20),
///   padding: EdgeInsets.all(20),
/// )
/// ```
class NeuCard extends StatelessWidget {
  /// 卡片内容
  final Widget child;

  /// 外边距
  final EdgeInsetsGeometry? margin;

  /// 内边距
  final EdgeInsetsGeometry? padding;

  /// 边框宽度
  final double? borderSideWidth;

  /// 边框颜色
  final Color? borderSideColor;

  /// 圆角半径
  final double? borderRadius;

  /// 点击回调
  final VoidCallback? onTap;

  /// 长按回调
  final VoidCallback? onLongPress;

  /// 卡片颜色
  final Color? color;

  const NeuCard({
    super.key,
    required this.child,
    this.margin = const EdgeInsets.only(bottom: 20),
    this.padding = const EdgeInsets.all(20),
    this.borderSideWidth,
    this.borderSideColor,
    this.borderRadius = 18,
    this.onTap,
    this.onLongPress,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget card = Card(
      color: color ?? theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        side: BorderSide(
          width: borderSideWidth ?? 1,
          color: borderSideColor ??
              theme.colorScheme.onSurface.withValues(alpha: .1),
        ),
        borderRadius: BorderRadius.circular(borderRadius!),
      ),
      margin: margin,
      child: Padding(
        padding: padding!,
        child: child,
      ),
    );

    if (onTap != null || onLongPress != null) {
      card = InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(borderRadius!),
        child: card,
      );
    }

    return card;
  }
}
