import 'package:flutter/cupertino.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';
import 'package:oktoast/oktoast.dart';
import 'dart:io';

/// UI 工具类
///
/// 提供 UI 相关的静态方法
class UiUtil {
  UiUtil._();

  /// 显示 Toast 提示
  static void toast(String text, {Duration? duration}) {
    showToast(text,
        dismissOtherToast: true,
        textPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
        duration: duration);
  }

  /// 震动反馈
  static Future<void> vibrate(
    FeedbackType type, {
    bool? vibrateOn,
    bool? vibrateWarning,
    bool? vibrateNormal,
  }) async {
    if (!Platform.isAndroid && !Platform.isIOS) return;

    bool canVibrate = await Vibrate.canVibrate;
    if (!canVibrate) return;

    // 如果没有提供设置参数，默认开启
    final isEnabled = vibrateOn ?? true;
    if (!isEnabled) return;

    if (type == FeedbackType.warning) {
      final isEnabled = vibrateWarning ?? true;
      if (isEnabled) {
        Vibrate.feedback(type);
      }
    } else {
      final isEnabled = vibrateNormal ?? true;
      if (isEnabled) {
        Vibrate.feedback(type);
      }
    }
  }

  /// 显示加载对话框
  static void showLoading(BuildContext context) {
    showCupertinoDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return const CupertinoActivityIndicator(radius: 14);
      },
    );
  }

  /// 隐藏加载对话框
  static void hideLoading(BuildContext context) {
    Navigator.of(context).pop();
  }

  /// 显示确认对话框
  static Future<bool?> showConfirmDialog(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = '确定',
    String cancelText = '取消',
  }) {
    return showCupertinoDialog<bool>(
      context: context,
      builder: (context) {
        return CupertinoAlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            CupertinoDialogAction(
              child: Text(cancelText),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              child: Text(confirmText),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );
  }

  /// 显示选择对话框
  static Future<T?> showChoiceDialog<T>(
    BuildContext context, {
    required String title,
    required List<T> choices,
    required String Function(T) labelBuilder,
    T? selected,
  }) {
    return showCupertinoDialog<T>(
      context: context,
      builder: (context) {
        return CupertinoAlertDialog(
          title: Text(title),
          content: Column(
            children: choices.map((choice) {
              return CupertinoDialogAction(
                child: Row(
                  children: [
                    if (choice == selected)
                      const Icon(CupertinoIcons.checkmark, size: 16),
                    const SizedBox(width: 8),
                    Text(labelBuilder(choice)),
                  ],
                ),
                onPressed: () => Navigator.of(context).pop(choice),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}
