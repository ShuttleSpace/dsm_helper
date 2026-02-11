import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:garden/constants/app_constants.dart';
import 'package:garden/extensions/context.dart';

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
        shape: context.stadiumShapeBorder,
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
                      "停用套件",
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(
                      height: 12,
                    ),
                    const Text(
                      "确认要停用此套件？",
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.w400),
                    ),
                    const SizedBox(
                      height: 22,
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () async {
                              Navigator.of(context).pop();
                              await onStop();
                            },
                            child: const Text(
                              "停用",
                              style: TextStyle(
                                  fontSize: 18, color: Colors.redAccent),
                            ),
                          ),
                        ),
                        const SizedBox(
                          width: 20,
                        ),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () async {
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
      },
    );
  }
}
