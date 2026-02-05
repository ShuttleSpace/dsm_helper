import 'dart:io';
import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';

/// 下载页面 AppBar 组件
class DownloadAppBarWidget extends StatelessWidget
    implements PreferredSizeWidget {
  final Signal<bool> multiSelect;
  final Signal<String> downloadPath;
  final VoidCallback onExitMultiSelect;
  final VoidCallback onSelectAll;
  final VoidCallback onOpenSettings;

  const DownloadAppBarWidget({
    super.key,
    required this.multiSelect,
    required this.downloadPath,
    required this.onExitMultiSelect,
    required this.onSelectAll,
    required this.onOpenSettings,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: Watch((context) => multiSelect.value
          ? GestureDetector(
              onTap: onExitMultiSelect,
              child: const Icon(Icons.close),
            )
          : Container()),
      title: Column(
        children: [
          const Text("下载"),
          if (Platform.isAndroid)
            Watch((context) => Text(
                  downloadPath.value,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                )),
        ],
      ),
      actions: [
        Watch((context) => multiSelect.value
            ? Padding(
                padding: const EdgeInsets.only(right: 10, top: 8, bottom: 8),
                child: OutlinedButton(
                  onPressed: onSelectAll,
                  child: Image.asset(
                    "assets/icons/select_all.png",
                    width: 20,
                    height: 20,
                  ),
                ),
              )
            : Container()),
        if (Platform.isAndroid)
          Padding(
            padding: const EdgeInsets.only(right: 10, top: 8, bottom: 8),
            child: OutlinedButton(
              onPressed: onOpenSettings,
              child: Image.asset(
                "assets/icons/setting.png",
                width: 20,
                height: 20,
              ),
            ),
          ),
      ],
    );
  }

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (Platform.isAndroid ? 20 : 0));
}
