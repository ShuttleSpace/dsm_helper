import 'package:flutter/material.dart';
import 'package:garden/constants/app_constants.dart';
import 'package:garden/widgets/label.dart';

/// S.M.A.R.T. 测试日志列表项。
class SmartLogItem extends StatelessWidget {
  final Map log;

  const SmartLogItem(this.log, {super.key});

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
            Text("${log['time']}"),
            const SizedBox(height: 10),
            Row(
              children: [
                Label(
                  log['result'] == "smart_complete" ? "正常" : log['result'],
                  log['result'] == "smart_complete" ? Colors.green : Colors.red,
                  fill: true,
                ),
                const SizedBox(width: 10),
                Text(
                  "${log['test_type'] == "quick" ? "S.M.A.R.T. 快速测试" : log['test_type']}",
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
