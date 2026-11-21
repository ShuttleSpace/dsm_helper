import 'package:flutter/material.dart';
import 'package:garden/theme/app_theme.dart';
import 'package:garden/widgets/animation_progress_bar.dart';

/// 后台文件操作（复制/移动/删除/解压/压缩）进度列表。
class FileProcessList extends StatelessWidget {
  final Map processes;

  const FileProcessList(this.processes, {super.key});

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    const types = {
      "copy": "复制：",
      "move": "移动：",
      "delete": "删除：",
      "extract": "解压：",
      "compress": "压缩：",
    };
    processes.forEach((key, task) {
      final value = task['data'];
      children.add(
        Card(
          shape: RoundedRectangleBorder(
            side: const BorderSide(),
            borderRadius: BorderRadius.circular(18),
          ),
          margin: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: types["${task['type'] ?? ''}"]),
                      TextSpan(
                        text: task['path']
                            .map((e) => e.split("/").last)
                            .join(","),
                        style: TextStyle(
                          color: AppTheme.of(context).placeholderColor,
                        ),
                      ),
                      if (['copy', 'move', 'achieve', 'compress']
                              .contains(task['type']) &&
                          value != null) ...[
                        const TextSpan(text: " 至 "),
                        TextSpan(
                          text: value['dest_folder_path'] ?? '',
                          style: TextStyle(
                            color: AppTheme.of(context).placeholderColor,
                          ),
                        ),
                      ],
                    ],
                  ),
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 10),
                if (value != null)
                  FAProgressBar(
                    backgroundColor: Colors.transparent,
                    changeColorValue: 100,
                    changeProgressColor: Colors.green,
                    progressColor: Colors.blue,
                    size: 20,
                    currentValue:
                        (num.parse("${value['progress']}") * 100).toInt(),
                    displayText: '%',
                  ),
              ],
            ),
          ),
        ),
      );
    });
    return Column(mainAxisSize: MainAxisSize.min, children: children);
  }
}
