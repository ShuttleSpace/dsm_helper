import 'package:garden/widgets/label.dart';
import 'package:garden/util/format_util.dart';
import 'package:flutter/material.dart';

class PoolItem extends StatelessWidget {
  final Map<String, dynamic> pool;

  const PoolItem({
    super.key,
    required this.pool,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
          side: const BorderSide(), borderRadius: BorderRadius.circular(18)),
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text("存储池 ${pool['num_id']}"),
                const SizedBox(width: 10),
                _buildStatusLabel(pool['status']),
                const Spacer(),
                Text(FormatUtil.formatSize(int.parse(pool['size']['total']))),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Text(
                  _getDeviceTypeText(),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                if (pool['device_type'] == "basic" ||
                    pool['device_type'] == "shr_without_disk_protect")
                  const Text(
                    "（无数据保护）",
                    style: TextStyle(fontSize: 12, color: Colors.red),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusLabel(String status) {
    switch (status) {
      case "normal":
        return const Label(
          "正常",
          Colors.green,
          fill: true,
        );
      case "background":
        return const Label(
          "正在检查硬盘",
          Colors.lightBlueAccent,
          fill: true,
        );
      case "attention":
        return const Label(
          "注意",
          Colors.orangeAccent,
          fill: true,
        );
      default:
        return Label(
          status,
          Colors.red,
          fill: true,
        );
    }
  }

  String _getDeviceTypeText() {
    switch (pool['device_type']) {
      case "basic":
        return "Basic";
      case "shr_without_disk_protect":
      case "shr":
        return "Synology Hybrid RAID (SHR) ";
      default:
        return pool['device_type'];
    }
  }
}