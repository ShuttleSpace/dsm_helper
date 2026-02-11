import 'package:flutter/material.dart';
import 'package:garden/constants/app_constants.dart';
import 'package:garden/extensions/context.dart';

class PowerConfirmDialog extends StatelessWidget {
  final String action;
  final VoidCallback onConfirm;

  const PowerConfirmDialog({
    super.key,
    required this.action,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Card(
        shape: context.stadiumShapeBorder,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.paddingSmall),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Text(
                  "确认操作",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                ),
                const SizedBox(
                  height: 12,
                ),
                Text(
                  action == "poweroff"
                      ? "如果您强制关闭虚拟机，可能出现数据丟失或文件系统错误。是否确定继续？"
                      : "如果您虚拟机上未安装Guest Agent，可能无法成功关闭，是否确定继续？",
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w400),
                ),
                const SizedBox(
                  height: 22,
                ),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          onConfirm();
                        },
                        child: const Text(
                          "确认",
                          style:
                              TextStyle(fontSize: 18, color: Colors.redAccent),
                        ),
                      ),
                    ),
                    const SizedBox(
                      width: 16,
                    ),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: const Text(
                          "取消",
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(
                  height: 8,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
