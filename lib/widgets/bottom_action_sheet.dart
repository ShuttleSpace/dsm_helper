import 'package:flutter/material.dart';

/// 底部动作面板中的单个操作项。
class BottomActionItem {
  final String label;
  final String iconAsset;
  final VoidCallback onPressed;
  final Color? labelColor;
  final double widthDivisor;

  const BottomActionItem({
    required this.label,
    required this.iconAsset,
    required this.onPressed,
    this.labelColor,
    this.widthDivisor = 3,
  });
}

/// 通用的「选择操作」底部面板。
///
/// 文件页、收藏页等原先各自内联了一整棵 `Stack + Wrap + OutlinedButton`
/// 组件树，这里收敛为数据驱动的列表：[actions] 决定显示哪些操作。
class BottomActionSheet extends StatelessWidget {
  final String title;
  final List<BottomActionItem> actions;
  final Widget? leading;
  final String cancelText;
  final double titleSpacing;
  final double cancelSpacing;

  const BottomActionSheet({
    super.key,
    required this.title,
    required this.actions,
    this.leading,
    this.cancelText = "取消",
    this.titleSpacing = 20,
    this.cancelSpacing = 16,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: Colors.transparent,
        child: Card(
          shape: RoundedRectangleBorder(
            side: const BorderSide(),
            borderRadius: BorderRadius.circular(18),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Stack(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      if (leading != null) leading!,
                    ],
                  ),
                  SizedBox(height: titleSpacing),
                  SizedBox(
                    width: double.infinity,
                    child: Wrap(
                      runSpacing: 20,
                      spacing: 20,
                      children: [
                        for (final action in actions)
                          Container(
                            constraints: const BoxConstraints(maxWidth: 112),
                            width: (MediaQuery.sizeOf(context).width - 100) /
                                action.widthDivisor,
                            child: OutlinedButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                                action.onPressed();
                              },
                              child: Column(
                                children: [
                                  Image.asset(
                                    action.iconAsset,
                                    width: 30,
                                  ),
                                  Text(
                                    action.label,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: action.labelColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  SizedBox(height: cancelSpacing),
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      cancelText,
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
