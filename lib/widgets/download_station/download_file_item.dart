import 'package:flutter/material.dart';
import 'package:garden/constants/app_constants.dart';
import 'package:garden/extensions/int.dart';
import 'package:garden/widgets/label.dart';

/// BT 任务文件列表项。
class DownloadFileItem extends StatelessWidget {
  final Map file;

  const DownloadFileItem(this.file, {super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        side: const BorderSide(),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingSmall),
        child: Column(
          children: [
            Text(
              "${file['name']}",
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Text("${(file['size_downloaded'] as num).formatSize()} / "),
                Text((file['size'] as num).formatSize()),
                const SizedBox(width: 10),
                Text(
                  "${(file['size_downloaded'] * 100 / file['size']).toStringAsFixed(2)} %",
                  style: const TextStyle(color: Colors.blue),
                ),
                const Spacer(),
                Label(
                  file['priority'] == "normal"
                      ? "一般"
                      : file['priority'] == "high"
                          ? "高"
                          : "低",
                  file['priority'] == "normal"
                      ? Colors.blue
                      : file['priority'] == "high"
                          ? Colors.orange
                          : Colors.grey,
                  fill: true,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
