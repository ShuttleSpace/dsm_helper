import 'package:flutter/material.dart';

/// 底部弹窗的通用容器外壳。
///
/// 统一 `SizedBox(full width) → Material(transparent) → Card(border, radius)
/// → SafeArea → Padding` 结构，供各类确认/操作/选项面板组合使用。
class BottomSheetCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final bool safeArea;

  const BottomSheetCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.borderRadius = 18,
    this.safeArea = true,
  });

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: padding,
      child: child,
    );
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: Colors.transparent,
        child: Card(
          shape: RoundedRectangleBorder(
            side: const BorderSide(),
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          child: safeArea
              ? SafeArea(top: false, child: content)
              : content,
        ),
      ),
    );
  }
}
