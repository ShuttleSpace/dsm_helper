import 'package:garden/constants/app_constants.dart';
import 'package:garden/util/http_util.dart';
import 'package:garden/widgets/animation_progress_bar.dart';
import 'package:garden/widgets/label.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ContainerItem extends StatelessWidget {
  final Map<String, dynamic> container;
  final bool isLoading;
  final VoidCallback onTap;
  final Function(String action, {bool preserveProfile}) onAction;

  const ContainerItem({
    super.key,
    required this.container,
    required this.isLoading,
    required this.onTap,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        shape: RoundedRectangleBorder(
            side: const BorderSide(), borderRadius: BorderRadius.circular(18)),
        margin: const EdgeInsets.only(bottom: 20),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Text(
                              container['name'],
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.w600),
                            ),
                            const Spacer(),
                            _buildStatusLabel(),
                          ],
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                container['image'],
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.grey),
                              ),
                            ),
                            const SizedBox(
                              width: 10,
                            ),
                            if (container['status'] == "running")
                              Text(
                                DateTime.fromMillisecondsSinceEpoch(
                                        container['up_time'] * 1000)
                                    .timeAgo,
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.grey),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(
                    width: 20,
                  ),
                  _buildActionButton(context),
                ],
              ),
              if (container['status'] == "running") ...[
                const SizedBox(
                  height: 10,
                ),
                _buildResourceInfo(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusLabel() {
    if (container['status'] == "running") {
      return const Label("运行中", Colors.green);
    } else if (container['status'] == "stopped") {
      return const Label("已停止", Colors.red);
    } else {
      return Label(container['status'], Colors.orange);
    }
  }

  Widget _buildActionButton(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : () => _showActionMenu(context),
      child: Card(
        shape: RoundedRectangleBorder(
            side: const BorderSide(), borderRadius: BorderRadius.circular(18)),
        child: isLoading
            ? const CupertinoActivityIndicator()
            : Image.asset(
                "assets/icons/shutdown.png",
                width: 20,
              ),
      ),
    );
  }

  void _showActionMenu(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) {
        return Material(
          color: Colors.transparent,
          child: Card(
            shape: RoundedRectangleBorder(
                side: const BorderSide(),
                borderRadius: BorderRadius.circular(18)),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.paddingSmall),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const Text(
                      "选择操作",
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(
                      height: 12,
                    ),
                    if (container['status'] == "stopped") ...[
                      OutlinedButton(
                        onPressed: () async {
                          Navigator.of(context).pop();
                          onAction("start");
                        },
                        child: const Text(
                          "启动",
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                      const SizedBox(
                        height: 22,
                      ),
                      OutlinedButton(
                        onPressed: () async {
                          Navigator.of(context).pop();
                          onAction("delete", preserveProfile: true);
                        },
                        child: const Text(
                          "清除",
                          style:
                              TextStyle(fontSize: 18, color: Colors.redAccent),
                        ),
                      ),
                      const SizedBox(
                        height: 22,
                      ),
                      OutlinedButton(
                        onPressed: () async {
                          Navigator.of(context).pop();
                          onAction("delete", preserveProfile: false);
                        },
                        child: const Text(
                          "删除",
                          style:
                              TextStyle(fontSize: 18, color: Colors.redAccent),
                        ),
                      ),
                    ] else ...[
                      OutlinedButton(
                        onPressed: () async {
                          Navigator.of(context).pop();
                          onAction("stop");
                        },
                        child: const Text(
                          "停止",
                          style:
                              TextStyle(fontSize: 18, color: Colors.redAccent),
                        ),
                      ),
                      const SizedBox(
                        height: 22,
                      ),
                      OutlinedButton(
                        onPressed: () async {
                          Navigator.of(context).pop();
                          onAction("signal");
                        },
                        child: const Text(
                          "强制停止",
                          style:
                              TextStyle(fontSize: 18, color: Colors.redAccent),
                        ),
                      ),
                      const SizedBox(
                        height: 22,
                      ),
                      OutlinedButton(
                        onPressed: () async {
                          Navigator.of(context).pop();
                          onAction("restart");
                        },
                        child: const Text(
                          "重新启动",
                          style:
                              TextStyle(fontSize: 18, color: Colors.redAccent),
                        ),
                      ),
                    ],
                    const SizedBox(
                      height: 8,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildResourceInfo() {
    return Row(
      children: [
        Expanded(
          child: Column(
            children: [
              Row(
                children: [
                  const Text("CPU"),
                  const Spacer(),
                  Text(
                    "${container['cpu'].toStringAsFixed(2)}%",
                    style: const TextStyle(
                        color: Colors.blue, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(
                height: 10,
              ),
              FAProgressBar(
                backgroundColor: Colors.transparent,
                changeColorValue: 90,
                changeProgressColor: Colors.red,
                progressColor: Colors.blue,
                size: 20,
                displayText: "%",
                currentValue: (container['cpu']).ceil(),
              ),
            ],
          ),
        ),
        const SizedBox(
          width: 20,
        ),
        Expanded(
          child: Column(
            children: [
              Row(
                children: [
                  const Text("内存"),
                  const Spacer(),
                  Text(
                    (int.parse(container['memory'])).formatSize(fixed: 0),
                    style: const TextStyle(
                        color: Colors.green, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(
                height: 10,
              ),
              FAProgressBar(
                backgroundColor: Colors.transparent,
                changeColorValue: 90,
                changeProgressColor: Colors.red,
                progressColor: Colors.green,
                size: 20,
                displayText: "%",
                currentValue: container['memoryPercent'].ceil(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
