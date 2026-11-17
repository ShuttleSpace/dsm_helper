import 'package:flutter/material.dart';

/// 通用确认对话框组件
///
/// 用法示例：
/// ```dart
/// showCupertinoModalPopup(
///   context: context,
///   builder: (context) => ConfirmDialog(
///     title: "确认操作",
///     content: "确定要继续吗？",
///     confirmText: "确定",
///     cancelText: "取消",
///     onConfirm: () => print("确认"),
///     onCancel: () => print("取消"),
///   ),
/// );
/// ```
class ConfirmDialog extends StatelessWidget {
  /// 对话框标题
  final String title;

  /// 对话框内容
  final String content;

  /// 确认按钮文本
  final String confirmText;

  /// 取消按钮文本
  final String cancelText;

  /// 确认按钮回调
  final VoidCallback? onConfirm;

  /// 取消按钮回调
  final VoidCallback? onCancel;

  /// 确认按钮文本颜色
  final Color? confirmTextColor;

  /// 取消按钮文本颜色
  final Color? cancelTextColor;

  /// 是否显示取消按钮
  final bool showCancel;

  const ConfirmDialog({
    super.key,
    required this.title,
    required this.content,
    this.confirmText = "确定",
    this.cancelText = "取消",
    this.onConfirm,
    this.onCancel,
    this.confirmTextColor,
    this.cancelTextColor,
    this.showCancel = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: SizedBox(
        width: double.infinity,
        child: SafeArea(
          top: false,
          child: Card(
            shape: RoundedRectangleBorder(
              side: const BorderSide(),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    content,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w400,
                      color: theme.colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      if (showCancel) ...[
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              onCancel?.call();
                              Navigator.of(context).pop();
                            },
                            child: Text(
                              cancelText,
                              style: TextStyle(
                                fontSize: 18,
                                color: cancelTextColor ??
                                    theme.colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                      ],
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            onConfirm?.call();
                            Navigator.of(context).pop();
                          },
                          child: Text(
                            confirmText,
                            style: TextStyle(
                              fontSize: 18,
                              color: confirmTextColor ?? theme.colorScheme.primary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
