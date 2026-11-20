import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:garden/constants/app_constants.dart';
import 'package:garden/widgets/animation_progress_bar.dart';
import 'package:garden/widgets/label.dart';
import 'network_item.dart';
import 'guest_power_action_dialog.dart';

class GuestItem extends StatelessWidget {
  final Map<String, dynamic> guest;
  final Map<String, bool> powerLoading;
  final Function(String action) onPowerAction;
  final Function() onPowerOn;

  const GuestItem({
    super.key,
    required this.guest,
    required this.powerLoading,
    required this.onPowerAction,
    required this.onPowerOn,
  });

  @override
  Widget build(BuildContext context) {
    final isLoading = powerLoading[guest['id']] ?? false;
    List networks = guest['nics'];

    return Card(
      shape: RoundedRectangleBorder(
          side: const BorderSide(), borderRadius: BorderRadius.circular(18)),
      margin: const EdgeInsets.only(bottom: 20),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  guest['name'],
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                guest['type'] == "healthy"
                    ? (guest['status'] == "none"
                        ? const Label(
                            "运行中",
                            Colors.green,
                            fill: true,
                          )
                        : guest['status'] == "shutdown"
                            ? const Label("已关机", Colors.green)
                            : const Label("正常", Colors.green))
                    : guest['type'] == "warning"
                        ? const Label("警告", Colors.orange)
                        : const Label("错误", Colors.red),
                const SizedBox(
                  width: 10,
                ),
                GestureDetector(
                  onTap: () {
                    if (isLoading) {
                      return;
                    }
                    if (guest['type'] == "healthy") {
                      if (guest['status'] == "none") {
                        // 显示电源操作对话框
                        showCupertinoModalPopup(
                          context: context,
                          builder: (context) {
                            return GuestPowerActionDialog(
                              onShutdown: () {
                                Navigator.of(context).pop();
                                onPowerAction("shutdown");
                              },
                              onForceShutdown: () {
                                Navigator.of(context).pop();
                                onPowerAction("poweroff");
                              },
                              onReboot: () {
                                Navigator.of(context).pop();
                                onPowerAction("reboot");
                              },
                            );
                          },
                        );
                      } else {
                        // 开机
                        onPowerOn();
                      }
                    } else {
                      // 状态未知
                    }
                  },
                  child: isLoading
                      ? const CupertinoActivityIndicator()
                      : Image.asset(
                          "assets/icons/shutdown.png",
                          width: 20,
                        ),
                ),
              ],
            ),
            if (guest['status'] != "shutdown") ...[
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
                        padding:
                            const EdgeInsets.all(AppConstants.paddingSmall),
                        child: FAProgressBar(
                          backgroundColor: Colors.transparent,
                          changeColorValue: 90,
                          changeProgressColor: Colors.red,
                          progressColor: Colors.blue,
                          currentValue: guest['cpu_usage'] ~/ 10,
                          displayText: '.${guest['cpu_usage'] % 10}%',
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
                        padding:
                            const EdgeInsets.all(AppConstants.paddingSmall),
                        child: FAProgressBar(
                          backgroundColor: Colors.transparent,
                          changeColorValue: 90,
                          changeProgressColor: Colors.red,
                          progressColor: Colors.blue,
                          currentValue: guest['ram_usage'] ~/ 100,
                          displayText:
                              '.${(guest['ram_usage'] % 100).toString().padLeft(2, "0")}%',
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
          ],
        ),
      ),
    );
  }
}
