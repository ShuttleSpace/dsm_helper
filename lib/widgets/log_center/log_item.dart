import 'package:flutter/material.dart';
import 'package:garden/widgets/label.dart';

/// 日志项组件（通用）
class LogItem extends StatelessWidget {
  final Map log;
  final String logType; // 'recent', 'history', or 'log'

  const LogItem({
    super.key,
    required this.log,
    required this.logType,
  });

  @override
  Widget build(BuildContext context) {
    switch (logType) {
      case 'recent':
        return _buildRecentLogItem();
      case 'history':
        return _buildHistoryItem();
      case 'log':
        return _buildLogItem();
      default:
        return _buildLogItem();
    }
  }

  Widget _buildRecentLogItem() {
    return Card(
      shape: RoundedRectangleBorder(
          side: const BorderSide(), borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Label(log['prio'] == "info" ? "信息" : log['prio'] ?? "未知",
                    log['prio'] == "info" ? Colors.green : Colors.red),
                const SizedBox(
                  width: 5,
                ),
                Text(
                  log['fac'] ?? "",
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(
                  width: 10,
                ),
                Expanded(
                  child: Text(
                    "${log['ldate']}${log['ltime']}",
                    textAlign: TextAlign.right,
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
              ],
            ),
            const SizedBox(
              height: 10,
            ),
            Text("${log['msg']?.trim() ?? ''}"),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryItem() {
    return Card(
      shape: RoundedRectangleBorder(
          side: const BorderSide(), borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Label(log['level'] == 0 ? "信息" : "${log['level'] ?? '未知'}",
                    log['level'] == 0 ? Colors.green : Colors.red),
                const SizedBox(
                  width: 5,
                ),
                Text(
                  log['user'] ?? "",
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(
                  width: 10,
                ),
                Expanded(
                  child: Text(
                    "${log['time'] ?? ''}",
                    textAlign: TextAlign.right,
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
              ],
            ),
            const SizedBox(
              height: 10,
            ),
            Text("${log['event']?.trim() ?? ''}"),
          ],
        ),
      ),
    );
  }

  Widget _buildLogItem() {
    String levelLabel = log['level'] == "info"
        ? "信息"
        : log['level'] == "warn"
            ? "警告"
            : log['level'] == "error"
                ? "错误"
                : log['level'] ?? "未知";

    Color levelColor = log['level'] == "info"
        ? Colors.green
        : log['level'] == "warn"
            ? Colors.orange
            : log['level'] == "error"
                ? Colors.red
                : Colors.red;

    return Card(
      shape: RoundedRectangleBorder(
          side: const BorderSide(), borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Label(levelLabel, levelColor),
                const SizedBox(
                  width: 5,
                ),
                Label(log['logtype'] ?? "未知", Colors.lightBlueAccent),
                const SizedBox(
                  width: 5,
                ),
                Text(
                  log['who'] ?? "",
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(
                  width: 10,
                ),
                Expanded(
                  child: Text(
                    "${log['time'] ?? ''}",
                    textAlign: TextAlign.right,
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
              ],
            ),
            const SizedBox(
              height: 10,
            ),
            Text("${log['descr']?.trim() ?? ''}"),
          ],
        ),
      ),
    );
  }
}
