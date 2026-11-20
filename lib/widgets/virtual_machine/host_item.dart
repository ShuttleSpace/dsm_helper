import 'package:flutter/material.dart';
import 'package:garden/constants/app_constants.dart';
import 'package:garden/widgets/animation_progress_bar.dart';
import 'package:garden/widgets/label.dart';
import 'network_item.dart';

class HostItem extends StatelessWidget {
  final Map<String, dynamic> host;

  const HostItem({
    super.key,
    required this.host,
  });

  @override
  Widget build(BuildContext context) {
    List networks = host['nics'];

    return Card(
      shape: RoundedRectangleBorder(
          side: const BorderSide(), borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  host['name'],
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                host['type'] == "healthy"
                    ? const Label("正常", Colors.green)
                    : host['type'] == "warning"
                        ? const Label("警告", Colors.orange)
                        : const Label("错误", Colors.red),
              ],
            ),
            const SizedBox(
              height: 20,
            ),
            Row(
              children: [
                const SizedBox(
                  width: 50,
                  child: Text("CPU："),
                ),
                Expanded(
                  child: Card(
                    shape: RoundedRectangleBorder(
                        side: const BorderSide(),
                        borderRadius: BorderRadius.circular(18)),
                    child: Padding(
                      padding: const EdgeInsets.all(AppConstants.paddingSmall),
                      child: FAProgressBar(
                        backgroundColor: Colors.transparent,
                        changeColorValue: 90,
                        changeProgressColor: Colors.red,
                        progressColor: Colors.blue,
                        currentValue: host['cpu_usage'],
                        displayText: '%',
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(
              height: 20,
            ),
            Row(
              children: [
                const SizedBox(
                  width: 50,
                  child: Text("RAM："),
                ),
                Expanded(
                  child: Card(
                    shape: RoundedRectangleBorder(
                        side: const BorderSide(),
                        borderRadius: BorderRadius.circular(18)),
                    child: Padding(
                      padding: const EdgeInsets.all(AppConstants.paddingSmall),
                      child: FAProgressBar(
                        backgroundColor: Colors.transparent,
                        changeColorValue: 90,
                        changeProgressColor: Colors.red,
                        progressColor: Colors.blue,
                        currentValue: host['ram_usage'],
                        displayText: '%',
                      ),
                    ),
                  ),
                ),
              ],
            ),
            ...networks.map((network) {
              return NetworkItem(
                network: network,
                index: networks.indexOf(network),
              );
            }),
          ],
        ),
      ),
    );
  }
}
