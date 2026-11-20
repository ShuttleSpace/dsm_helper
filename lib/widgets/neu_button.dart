import 'package:flutter/material.dart';

/// 新拟态风格通用按钮组件
/// 
/// 用法示例：
/// ```dart
/// NeuButton(
///   text: "确定",
///   onPressed: () => print("点击"),
///   textColor: Colors.blue,
/// )
/// ```
class NeuButton extends StatelessWidget {
  /// 按钮文本
  final String text;
  
  /// 点击回调
  final VoidCallback? onPressed;
  
  /// 文本颜色
  final Color? textColor;
  
  /// 字体大小
  final double? fontSize;
  
  /// 字体粗细
  final FontWeight? fontWeight;
  
  /// 是否为填充按钮
  final bool filled;
  
  /// 填充颜色
  final Color? fillColor;
  
  /// 是否展开
  final bool expanded;
  
  /// 按钮内边距
  final EdgeInsetsGeometry? padding;

  const NeuButton({
    super.key,
    required this.text,
    this.onPressed,
    this.textColor,
    this.fontSize = 18,
    this.fontWeight = FontWeight.normal,
    this.filled = false,
    this.fillColor,
    this.expanded = false,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    final button = filled
        ? ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: fillColor ?? theme.colorScheme.primary,
              foregroundColor: Colors.white,
              padding: padding,
            ),
            child: Text(
              text,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: fontWeight,
              ),
            ),
          )
        : OutlinedButton(
            onPressed: onPressed,
            style: OutlinedButton.styleFrom(
              foregroundColor: textColor ?? theme.colorScheme.onSurface,
              padding: padding,
            ),
            child: Text(
              text,
              style: TextStyle(
                fontSize: fontSize,
                color: textColor ?? theme.colorScheme.onSurface,
                fontWeight: fontWeight,
              ),
            ),
          );

    if (expanded) {
      return Expanded(child: button);
    }

    return button;
  }
}