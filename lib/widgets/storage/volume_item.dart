import 'package:garden/constants/app_constants.dart';
import 'package:garden/extensions/int.dart';
import 'package:garden/widgets/label.dart';
import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

class VolumeItem extends StatelessWidget {
  final Map<String, dynamic> volume;

  const VolumeItem({
    super.key,
    required this.volume,
  });

  @override
  Widget build(BuildContext context) {
    double usedPercent =
        int.parse(volume['size']['used']) / int.parse(volume['size']['total']);

    return Card(
      shape: RoundedRectangleBorder(
          side: const BorderSide(), borderRadius: BorderRadius.circular(18)),
      margin: const EdgeInsets.only(top: 20, left: 20, right: 20),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingSmall),
        child: Row(
          children: [
            Card(
              shape: RoundedRectangleBorder(
                  side: const BorderSide(),
                  borderRadius: BorderRadius.circular(18)),
              margin: const EdgeInsets.all(10),
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.paddingSmall),
                child: CircularPercentIndicator(
                  radius: 40,
                  animation: true,
                  linearGradient: LinearGradient(
                    colors: usedPercent <= 0.9
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
                  percent: usedPercent,
                  center: Text(
                    "${(usedPercent * 100).toStringAsFixed(0)}%",
                    style: TextStyle(
                        color: usedPercent <= 0.9 ? Colors.blue : Colors.red,
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
                  Text(
                    "存储空间 ${volume['num_id']}",
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(
                    height: 5,
                  ),
                  Row(
                    children: [
                      Label(
                        "${volume['fs_type']}",
                        Colors.lightBlueAccent,
                        height: 23,
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
                  Text("已用：${int.parse(volume['size']['used']).formatSize()}"),
                  const SizedBox(
                    height: 5,
                  ),
                  Text(
                      "可用：${(int.parse(volume['size']['total']) - int.parse(volume['size']['used'])).formatSize()}"),
                  const SizedBox(
                    height: 5,
                  ),
                  Text("全部：${int.parse(volume['size']['total']).formatSize()}"),
                ],
              ),
            )
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
}
