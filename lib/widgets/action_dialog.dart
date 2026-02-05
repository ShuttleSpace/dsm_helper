import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:garden/widgets/neu_button.dart';

/// 通用操作对话框组件
///
/// 用于显示确认对话框、警告对话框等，提供统一的样式和行为
///
/// 用法示例：
/// ```dart
/// // 简单用法
/// ActionDialog.show(
///   context: context,
///   title: "确认删除",
///   message: "确定要删除这个文件吗？",
///   confirmText: "删除",
///   isDanger: true,
/// ).then((confirmed) {
///   if (confirmed == true) {
///     // 执行删除操作
///   }
/// });
///
/// // 自定义按钮回调
/// showCupertinoModalPopup(
///   context: context,
///   builder: (context) => ActionDialog(
///     title: "提示",
///     message: "操作成功",
///     confirmText: "确定",
///     showCancel: false,
///     onConfirm: () {
///       Navigator.of(context).pop();
///     },
///   ),
/// );
/// ```
class ActionDialog extends StatelessWidget {
  /// 对话框标题
  final String title;

  /// 对话框消息
  final String message;

  /// 确认按钮文本
  final String confirmText;

  /// 取消按钮文本
  final String cancelText;

  /// 确认按钮回调
  final VoidCallback? onConfirm;

  /// 取消按钮回调
  final VoidCallback? onCancel;

  /// 是否为危险操作（红色按钮）
  final bool isDanger;

  /// 是否显示取消按钮
  final bool showCancel;

  /// 确认按钮文本颜色
  final Color? confirmTextColor;

  const ActionDialog({
    super.key,
    required this.title,
    required this.message,
    required this.confirmText,
    this.cancelText = "取消",
    this.onConfirm,
    this.onCancel,
    this.isDanger = false,
    this.showCancel = true,
    this.confirmTextColor,
  });

  /// 显示对话框并返回确认结果
  ///
  /// 返回 `true` 表示用户点击了确认按钮
  /// 返回 `false` 表示用户点击了取消按钮
  /// 返回 `null` 表示对话框被关闭
  static Future<bool?> show({
    required BuildContext context,
    required String title,
    required String message,
    String confirmText = "确定",
    String cancelText = "取消",
    bool isDanger = false,
    Color? confirmTextColor,
  }) {
    return showCupertinoModalPopup<bool>(
      context: context,
      builder: (context) => ActionDialog(
        title: title,
        message: message,
        confirmText: confirmText,
        cancelText: cancelText,
        isDanger: isDanger,
        confirmTextColor: confirmTextColor,
        onConfirm: () => Navigator.of(context).pop(true),
        onCancel: () => Navigator.of(context).pop(false),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: Card(
        shape: RoundedRectangleBorder(
          side: BorderSide(
            color: theme.colorScheme.onSurface.withValues(alpha: .1),
          ),
          borderRadius: BorderRadius.circular(18),
        ),
        color: theme.colorScheme.surface,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                // 标题
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
                // 消息
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w400,
                    color: theme.colorScheme.onSurface.withValues(alpha: .8),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 22),
                // 按钮组
                Row(
                  children: [
                    if (showCancel) ...[
                      Expanded(
                        child: NeuButton(
                          text: cancelText,
                          onPressed: () {
                            onCancel?.call();
                            Navigator.of(context).pop();
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                    ],
                    Expanded(
                      child: NeuButton(
                        text: confirmText,
                        onPressed: () {
                          onConfirm?.call();
                        },
                        textColor: confirmTextColor ??
                            (isDanger
                                ? theme.colorScheme.error
                                : theme.colorScheme.primary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
