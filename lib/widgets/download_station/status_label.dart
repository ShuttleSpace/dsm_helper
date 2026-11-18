import 'package:flutter/material.dart';
import 'package:garden/extensions/int.dart';

/// 下载任务状态标签，集中处理 DSM 状态码到文案/颜色的映射。
class DownloadStatusLabel extends StatelessWidget {
  final int status;
  final num speedDownload;

  const DownloadStatusLabel({
    super.key,
    required this.status,
    this.speedDownload = 0,
  });

  @override
  Widget build(BuildContext context) {
    return switch (status) {
      1 => const Text("等待中", style: TextStyle(color: Colors.grey)),
      2 => Text(
          "${speedDownload.formatSize()}/s",
          style: const TextStyle(color: Colors.lightBlueAccent),
        ),
      3 => const Text("已暂停", style: TextStyle(color: Colors.grey)),
      5 => const Text("已完成", style: TextStyle(color: Colors.green)),
      6 => const Text("检查中", style: TextStyle(color: Colors.grey)),
      101 => const Text("错误", style: TextStyle(color: Colors.red)),
      105 => const Text("空间不足", style: TextStyle(color: Colors.red)),
      113 => const Text("重复的任务", style: TextStyle(color: Colors.red)),
      _ => Text("代码：$status", style: const TextStyle(color: Colors.red)),
    };
  }
}
