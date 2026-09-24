import 'package:flutter/material.dart';
import 'package:garden/constants/app_constants.dart';

class GuestPowerActionDialog extends StatelessWidget {
  final VoidCallback onShutdown;
  final VoidCallback onForceShutdown;
  final VoidCallback onReboot;

  const GuestPowerActionDialog({
    super.key,
    required this.onShutdown,
    required this.onForceShutdown,
    required this.onReboot,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Card(
        shape: RoundedRectangleBorder(
            side: const BorderSide(), borderRadius: BorderRadius.circular(18)),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.paddingSmall),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Text(
                  "选择操作",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                ),
                const SizedBox(
                  height: 12,
                ),
                OutlinedButton(
                  onPressed: onShutdown,
                  child: const Text(
                    "关机",
                    style: TextStyle(fontSize: 18, color: Colors.redAccent),
                  ),
                ),
                const SizedBox(
                  height: 22,
                ),
                OutlinedButton(
                  onPressed: onForceShutdown,
                  child: const Text(
                    "强制关机",
                    style: TextStyle(fontSize: 18, color: Colors.redAccent),
                  ),
                ),
                const SizedBox(
                  height: 22,
                ),
                OutlinedButton(
                  onPressed: onReboot,
                  child: const Text(
                    "重新启动",
                    style: TextStyle(fontSize: 18, color: Colors.redAccent),
                  ),
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
