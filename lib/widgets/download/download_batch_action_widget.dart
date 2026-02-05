import 'package:flutter/material.dart';
import 'package:garden/constants/app_constants.dart';

/// 批量删除确认对话框
class DownloadBatchDeleteDialog extends StatelessWidget {
  final int count;
  final VoidCallback onConfirm;

  const DownloadBatchDeleteDialog({
    super.key,
    required this.count,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Card(
        shape: RoundedRectangleBorder(
            side: const BorderSide(), borderRadius: BorderRadius.circular(5)),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.paddingSmall),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Text(
                  "确认删除",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                ),
                const SizedBox(
                  height: 12,
                ),
                Text(
                  "确认要删除$count个下载任务？",
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w400),
                ),
                const SizedBox(
                  height: 22,
                ),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          onConfirm();
                        },
                        child: const Text(
                          "确认删除",
                          style:
                              TextStyle(fontSize: 18, color: Colors.redAccent),
                        ),
                      ),
                    ),
                    const SizedBox(
                      width: 20,
                    ),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: const Text(
                          "取消",
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                    ),
                  ],
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
}
