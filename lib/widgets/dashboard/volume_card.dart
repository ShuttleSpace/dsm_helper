import 'package:flutter/material.dart';
import 'package:garden/util/format_util.dart';
import 'package:garden/constants/app_constants.dart';
import 'package:garden/widgets/label.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

/// 存储空间卡片（可复用）
class VolumeCard extends StatelessWidget {
  final Map volume;
  final bool isSSD;

  const VolumeCard({
    super.key,
    required this.volume,
    this.isSSD = false,
  });

  @override
  Widget build(BuildContext context) {
    double used = isSSD
        ? int.parse(volume['size']['used'] ?? volume['size']['reusable']) /
            int.parse(volume['size']['total'])
        : int.parse(volume['size']['used']) /
            int.parse(volume['size']['total']);

    String displayName = isSSD
        ? volume['id'].toString().replaceFirst("ssd_", "SSD 缓存 ")
        : (volume['deploy_path'] != null
            ? volume['deploy_path'].toString().replaceFirst("volume_", "存储空间 ")
            : volume['id'].toString().replaceFirst("volume_", "存储空间 "));

    String usedSize = isSSD
        ? FormatUtil.formatSize(
            int.parse(volume['size']['used'] ?? volume['size']['reusable']))
        : FormatUtil.formatSize(int.parse(volume['size']['used']));

    return Card(
      shape: RoundedRectangleBorder(
          side: const BorderSide(),
          borderRadius: isSSD ? BorderRadius.circular(18) : BorderRadius.circular(5)),
      margin: const EdgeInsets.only(top: 20, left: 20, right: 20),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingSmall),
        child: Row(
          children: [
            CircularPercentIndicator(
              radius: 40,
              animation: true,
              linearGradient: LinearGradient(
                colors: used <= 0.9
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
              percent: used,
              center: Text(
                "${(used * 100).toStringAsFixed(0)}%",
                style: TextStyle(
                    color: used <= 0.9 ? Colors.blue : Colors.red,
                    fontSize: 22),
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
                        displayName,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(
                        width: 5,
                      ),
                      _buildStatusLabel(volume['status']),
                    ],
                  ),
                  const SizedBox(
                    height: 5,
                  ),
                  Text("已用：$usedSize"),
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
        return Label(status ?? "未知", Colors.red, fill: true);
    }
  }
}