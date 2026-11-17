import 'package:flutter/material.dart';

/// 只用于展示选中状态的紧凑复选框。
///
/// 点击事件交给外层的卡片/按钮处理，因此这里忽略自身的手势。
class StatusCheckbox extends StatelessWidget {
  final bool value;
  final double scale;

  const StatusCheckbox({
    super.key,
    required this.value,
    this.scale = 0.8,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: scale,
      child: IgnorePointer(
        child: Checkbox(
          value: value,
          onChanged: (_) {},
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
        ),
      ),
    );
  }
}
