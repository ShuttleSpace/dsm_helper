import 'package:flutter/material.dart';

/// 文件页标题栏的图标按钮。
///
/// 统一处理左右边距与点击行为，避免每个按钮重复写 Padding + OutlinedButton。
class FileToolButton extends StatelessWidget {
  final VoidCallback onTap;
  final Widget child;
  final bool alignLeft;

  const FileToolButton({
    super.key,
    required this.onTap,
    required this.child,
    this.alignLeft = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: alignLeft ? 10 : 0,
        right: alignLeft ? 0 : 10,
        top: 8,
        bottom: 8,
      ),
      child: OutlinedButton(onPressed: onTap, child: child),
    );
  }
}
