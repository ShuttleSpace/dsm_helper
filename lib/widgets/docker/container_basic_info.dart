import 'package:flutter/material.dart';
import 'package:garden/util/http_util.dart';

class ContainerBasicInfo extends StatelessWidget {
  final int upTime;
  final Map shortcut;
  final int cpuPriority;
  final int memory;
  final String cmd;

  const ContainerBasicInfo({
    super.key,
    required this.upTime,
    required this.shortcut,
    required this.cpuPriority,
    required this.memory,
    required this.cmd,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
          side: const BorderSide(), borderRadius: BorderRadius.circular(18)),
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "基本信息",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 5),
            Row(
              children: [
                const Text("启动时间："),
                Expanded(
                  child: Text(
                    DateTime.fromMillisecondsSinceEpoch(upTime * 1000).timeAgo,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Row(
              children: [
                const Text("快捷方式："),
                Expanded(
                  child: Text(
                    shortcut['enable_shortcut']
                        ? (shortcut['enable_status_page']
                            ? "状态页面"
                            : shortcut['enable_web_page']
                                ? shortcut['web_page_url']
                                : "")
                        : "无",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Row(
              children: [
                const Text("CPU优先顺序："),
                Expanded(
                  child: Text(
                    cpuPriority > 50
                        ? "高"
                        : cpuPriority == 50
                            ? "中"
                            : cpuPriority < 50
                                ? "低"
                                : "",
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Row(
              children: [
                const Text("内存限制："),
                Expanded(
                  child: Text(
                    memory > 0 ? memory.formatSize() : "自动",
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Row(
              children: [
                const Text("执行命令："),
                Expanded(
                  child: Text(
                    cmd,
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
