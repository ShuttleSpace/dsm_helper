import 'package:flutter/material.dart';
import 'package:garden/util/format_util.dart';
import 'package:garden/widgets/label.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'info_card.dart';

/// 存储空间项组件
/// 用于显示单个存储空间的使用情况
class VolumeItem extends StatelessWidget {
  /// 存储空间数据
  final Map<String, dynamic> volume;

  /// 存储空间索引（用于显示标题）
  final int index;

  const VolumeItem({
    super.key,
    required this.volume,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final used = int.tryParse(volume['size']['used'] ?? '0') ?? 0;
    final total = int.tryParse(volume['size']['total'] ?? '0') ?? 0;
    final percent = total > 0 ? used / total : 0.0;

    return InfoCard(
      margin: const EdgeInsets.only(top: 20, left: 20, right: 20),
      child: Row(
        children: [
          CircularPercentIndicator(
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
            percent: percent.clamp(0.0, 1.0),
            center: Text(
              "${(percent * 100).toStringAsFixed(0)}%",
              style: TextStyle(
                color: percent <= 0.9 ? Colors.blue : Colors.red,
                fontSize: 22,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      "存储空间 ${volume['num_id'] ?? ''}",
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 5),
                    _buildStatusLabel(volume['status']),
                  ],
                ),
                const SizedBox(height: 5),
                Text(volume['desc'] ?? (volume['vol_desc'] ?? "-")),
                const SizedBox(height: 5),
                Text(
                  "${FormatUtil.formatSize(used)} / ${FormatUtil.formatSize(total)}",
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildStatusLabel(String? status) {
    switch (status) {
      case "normal":
        return const Label("正常", Colors.green, fill: true);
      case "background":
        return const Label("正在检查硬盘", Colors.lightBlueAccent, fill: true);
      case "attention":
        return const Label("注意", Colors.orangeAccent, fill: true);
      default:
        return Label(status ?? "", Colors.red, fill: true);
    }
  }
}