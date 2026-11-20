import 'package:flutter/material.dart';
import 'package:garden/constants/app_constants.dart';
import 'package:garden/widgets/label.dart';

/// S.M.A.R.T. 信息列表项。
class SmartInfoItem extends StatelessWidget {
  final Map info;

  const SmartInfoItem(this.info, {super.key});

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
                Label(info['id'], Colors.lightBlueAccent),
                const SizedBox(width: 5),
                Label(
                  info['status'],
                  info['status'] == "OK" ? Colors.green : Colors.red,
                  fill: true,
                ),
                const SizedBox(width: 5),
                Text(info['name']),
              ],
            ),
            const SizedBox(height: 5),
            Row(
              children: [
                SizedBox(
                  width: 100,
                  child: Text.rich(
                    TextSpan(
                      children: [
                        const TextSpan(
                          text: "现值：",
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        TextSpan(text: "${info['current']}"),
                      ],
                    ),
                  ),
                ),
                Text.rich(
                  TextSpan(
                    children: [
                      const TextSpan(
                        text: "最差值：",
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      TextSpan(text: "${info['worst']}"),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Row(
              children: [
                SizedBox(
                  width: 100,
                  child: Text.rich(
                    TextSpan(
                      children: [
                        const TextSpan(
                          text: "临界值：",
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        TextSpan(text: "${info['threshold']}"),
                      ],
                    ),
                  ),
                ),
                Text.rich(
                  TextSpan(
                    children: [
                      const TextSpan(
                        text: "原始资料：",
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      TextSpan(text: "${info['raw']}"),
                    ],
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
