import 'package:flutter/cupertino.dart';
import 'package:garden/widgets/bottom_confirm_sheet.dart';
import 'package:flutter/material.dart';
import 'package:garden/constants/app_constants.dart';

/// 套件操作按钮组件
class PackageButton extends StatelessWidget {
  final Map package;
  final bool beta;
  final VoidCallback onUpdate;
  final VoidCallback onInstall;
  final Future<void> Function() onStart;
  final Future<void> Function() onStop;

  const PackageButton({
    super.key,
    required this.package,
    this.beta = false,
    required this.onUpdate,
    required this.onInstall,
    required this.onStart,
    required this.onStop,
  });

  @override
  Widget build(BuildContext context) {
    Widget button;

    if (package['can_update'] == null || package['installed'] == null) {
      button = Card(
        shape: RoundedRectangleBorder(
            side: const BorderSide(), borderRadius: BorderRadius.circular(18)),
        child: const Text("获取中"),
      );
    } else if (package['can_update']) {
      button = OutlinedButton(
        onPressed: onUpdate,
        child: const Text("更新"),
      );
    } else if (package['installed']) {
      String text = "";
      if (package['launched'] &&
          package['additional'] != null &&
          package['additional']['startable']) {
        text = "停用";
      } else if (package['additional'] != null &&
          package['additional']['startable']) {
        text = "启动";
      } else {
        text = "已安装";
      }

      button = OutlinedButton(
        onPressed: () async {
          if (text == "启动") {
            await onStart();
          } else if (text == "停用") {
            _showStopDialog(context);
          }
        },
        child: Text(
          text,
          style: text == "启动"
              ? null
              : text == "停用"
                  ? const TextStyle(color: Colors.red)
                  : const TextStyle(color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      );
    } else {
      button = OutlinedButton(
        onPressed: onInstall,
        child: const Text("安装套件"),
      );
    }

    return button;
  }

  void _showStopDialog(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => BottomConfirmSheet(
        title: "停用套件",
        content: "确认要停用此套件？",
        confirmText: "停用",
        showTrailingSpace: true,
        onConfirm: onStop,
      ),
    );
  }
}
