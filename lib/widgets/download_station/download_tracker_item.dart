import 'package:flutter/material.dart';
import 'package:garden/constants/app_constants.dart';

/// BT 任务 Tracker 列表项。
class DownloadTrackerItem extends StatelessWidget {
  final Map tracker;

  const DownloadTrackerItem(this.tracker, {super.key});

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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("${tracker['url']}"),
            const SizedBox(height: 10),
            Row(
              children: [
                Text(
                  "种子数：${tracker['seeds'] >= 0 ? tracker['seeds'] : "-"}",
                  style: const TextStyle(color: Colors.green),
                ),
                const SizedBox(width: 10),
                Text(
                  "Peer数：${tracker['peers'] >= 0 ? tracker['peers'] : "-"}",
                  style: const TextStyle(color: Colors.blue),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "${tracker['status']}",
                    style: TextStyle(
                      color: tracker['status'] == "Success"
                          ? Colors.green
                          : Colors.red,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
