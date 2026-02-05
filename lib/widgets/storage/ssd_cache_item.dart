import 'package:garden/constants/app_constants.dart';
import 'package:garden/util/format_util.dart';
import 'package:garden/widgets/label.dart';
import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

class SsdCacheItem extends StatelessWidget {
  final Map<String, dynamic> volume;

  const SsdCacheItem({
    super.key,
    required this.volume,
  });

  @override
  Widget build(BuildContext context) {
    double percent =
        int.parse(volume['size']['used'] ?? volume['size']['reusable']) /
            int.parse(volume['size']['total']);

    return Card(
      shape: RoundedRectangleBorder(
          side: const BorderSide(), borderRadius: BorderRadius.circular(18)),
      margin: const EdgeInsets.only(top: 20, left: 20, right: 20),
      child: Row(
        children: [
          Card(
            shape: RoundedRectangleBorder(
                side: const BorderSide(), borderRadius: BorderRadius.circular(18)),
            margin: const EdgeInsets.all(10),
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.paddingSmall),
              child: CircularPercentIndicator(
                radius: 40,
                animation: true,
                linearGradient: LinearGradient(
                  colors: percent <= 0.9
                      ? [
                          Colors.blue,
                          Colors.blueAccent,
                        ]
                      : [
                          Colors.red,
                          Colors.orangeAccent,
                        ],
                ),
                animateFromLastPercent: true,
                circularStrokeCap: CircularStrokeCap.round,
                lineWidth: 12,
                backgroundColor: Colors.black12,
                percent: percent,
                center: Text(
                  "${(percent * 100).toStringAsFixed(0)}%",
                  style: TextStyle(
                      color: percent <= 0.9 ? Colors.blue : Colors.red,
                      fontSize: 22),
                ),
              ),
            ),
          ),
          const SizedBox(
            width: 10,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      volume['id'].toString().replaceFirst("ssd_", "SSD 缓存 "),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(
                      width: 5,
                    ),
                    Label(
                      volume['status'] == "normal" ? "正常" : volume['status'],
                      volume['status'] == "normal" ? Colors.green : Colors.red,
                      fill: true,
                    ),
                  ],
                ),
                const SizedBox(
                  height: 5,
                ),
                Text(
                    "已用：${FormatUtil.formatSize(int.parse(volume['size']['used'] ?? volume['size']['reusable']))}"),
                const SizedBox(
                  height: 5,
                ),
                Text(
                    "可用：${FormatUtil.formatSize(int.parse(volume['size']['total']) - int.parse(volume['size']['used'] ?? volume['size']['reusable']))}"),
                const SizedBox(
                  height: 5,
                ),
                Text(
                    "容量：${FormatUtil.formatSize(int.parse(volume['size']['total']))}"),
              ],
            ),
          )
        ],
      ),
    );
  }
}