import 'package:flutter/material.dart';
import 'package:garden/constants/app_constants.dart';

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
              padding: const EdgeInsets.all(AppConstants.paddingSmall),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    content,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.of(context).pop(confirmResult);
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
                      const SizedBox(width: 20),
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
