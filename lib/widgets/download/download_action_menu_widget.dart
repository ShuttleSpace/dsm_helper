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
      child: Card(
        shape: RoundedRectangleBorder(
            side: const BorderSide(), borderRadius: BorderRadius.circular(18)),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.paddingSmall),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Text(
                  "选择操作",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                ),
                const SizedBox(
                  height: 22,
                ),
                if (status == TaskStatus.failed)
                  OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      onRetry();
                    },
                    child: const Text(
                      "重试",
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                if (status == TaskStatus.running)
                  OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      onPause();
                    },
                    child: const Text(
                      "暂停",
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                if (status == TaskStatus.paused)
                  OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      onResume();
                    },
                    child: const Text(
                      "继续下载",
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                if ([TaskStatus.paused, TaskStatus.running, TaskStatus.failed]
                    .contains(status))
                  const SizedBox(
                    height: 16,
                  ),
                OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _showDeleteConfirmDialog(context);
                  },
                  child: const Text(
                    "删除",
                    style: TextStyle(fontSize: 18, color: Colors.redAccent),
                  ),
                ),
                const SizedBox(
                  height: 16,
                ),
                OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text(
                    "取消",
                    style: TextStyle(fontSize: 18),
                  ),
                ),
                const SizedBox(
                  height: 8,
                ),
              ],
            ),
          ),
        ),
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