import 'package:flutter/material.dart';

/// 底部确认浮层：标题 + 说明 + 「确认/取消」按钮。
///
/// 用于替代各页面中重复内联的 `showCupertinoModalPopup + Card + Row` 结构。
/// 确认按钮在左侧（与原先内联布局一致），点击后先关闭浮层再执行 [onConfirm]。
class BottomConfirmSheet extends StatelessWidget {
  final String title;
  final String content;
  final String confirmText;
  final String cancelText;
  final Color confirmColor;
  final VoidCallback onConfirm;
  final bool showTrailingSpace;
  final Object? confirmResult;
  final Object? cancelResult;
  final double padding;
  final double buttonSpacing;
  final double borderRadius;
  final Color? textColor;
  final bool popBeforeConfirm;

  const BottomConfirmSheet({
    super.key,
    required this.title,
    required this.content,
    required this.onConfirm,
    this.confirmText = "确定",
    this.cancelText = "取消",
    this.confirmColor = Colors.redAccent,
    this.showTrailingSpace = false,
    this.confirmResult,
    this.cancelResult,
    this.padding = 8,
    this.buttonSpacing = 20,
    this.borderRadius = 18,
    this.textColor,
    this.popBeforeConfirm = true,
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
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.all(padding),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    content,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w400,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            if (popBeforeConfirm) {
                              Navigator.of(context).pop(confirmResult);
                            }
                            onConfirm();
                          },
                          child: Text(
                            confirmText,
                            style: TextStyle(
                              fontSize: 18,
                              color: confirmColor,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: buttonSpacing),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(cancelResult),
                          child: Text(
                            cancelText,
                            style: const TextStyle(fontSize: 18),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (showTrailingSpace) const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
