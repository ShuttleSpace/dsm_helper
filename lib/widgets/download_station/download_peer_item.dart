import 'package:flutter/material.dart';
import 'package:garden/constants/app_constants.dart';
import 'package:garden/extensions/int.dart';

/// BT 任务 Peer 列表项。
class DownloadPeerItem extends StatelessWidget {
  final Map peer;

  const DownloadPeerItem(this.peer, {super.key});

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
            Row(
              children: [
                Text("${peer['ip']}"),
                const Spacer(),
                Text("${peer['client']}"),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Text("进度：${(peer['progress'] * 100).toStringAsFixed(0)}%"),
                const Spacer(),
                const Icon(Icons.download_sharp, color: Colors.green, size: 16),
                Text(
                  (peer['speed_download'] as num).formatSize(),
                  style: const TextStyle(color: Colors.green),
                ),
                const SizedBox(width: 10),
                const Icon(Icons.upload_sharp, color: Colors.blue, size: 16),
                Text(
                  (peer['speed_upload'] as num).formatSize(),
                  style: const TextStyle(color: Colors.blue),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
