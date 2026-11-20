import 'package:background_downloader/background_downloader.dart';
import 'package:garden/util/ui_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';
import 'package:garden/constants/app_constants.dart';
import 'package:garden/widgets/action_dialog.dart';

/// 下载任务操作菜单
class DownloadActionMenuWidget extends StatelessWidget {
  final DownloadTask task;
  final TaskStatus status;
  final VoidCallback onRetry;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onDelete;

  const DownloadActionMenuWidget({
    super.key,
    required this.task,
    required this.status,
    required this.onRetry,
    required this.onPause,
    required this.onResume,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: SizedBox(
        width: double.infinity,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SafeArea(
              top: false,
              child: Card(
                shape: RoundedRectangleBorder(
                    side: const BorderSide(),
                    borderRadius: BorderRadius.circular(18)),
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.paddingSmall),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      const Text(
                        "选择操作",
                        style:
                            TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(
                        height: 22,
                      ),
                      if (status == TaskStatus.failed)
                        _buildButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            onRetry();
                          },
                          text: "重试",
                        ),
                      if (status == TaskStatus.running)
                        _buildButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            onPause();
                          },
                          text: "暂停",
                        ),
                      if (status == TaskStatus.paused)
                        _buildButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            onResume();
                          },
                          text: "继续下载",
                        ),
                      if ([TaskStatus.paused, TaskStatus.running,
                          TaskStatus.failed].contains(status))
                        const SizedBox(
                          height: 16,
                        ),
                      _buildButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _showDeleteConfirmDialog(context);
                        },
                        text: "删除",
                        textColor: Colors.redAccent,
                      ),
                      const SizedBox(
                        height: 16,
                      ),
                      _buildButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        text: "取消",
                      ),
                      const SizedBox(
                        height: 8,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  OutlinedButton _buildButton({
    required VoidCallback onPressed,
    required String text,
    Color? textColor,
  }) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: textColor,
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 18, color: textColor),
      ),
    );
  }

  void _showDeleteConfirmDialog(BuildContext context) {
    UiUtil.vibrate(FeedbackType.warning);
    ActionDialog.show(
      context: context,
      title: "确认删除",
      message: "确认要删除文件？",
      confirmText: "确认删除",
      isDanger: true,
    ).then((confirmed) {
      if (confirmed == true) {
        onDelete();
      }
    });
  }
}