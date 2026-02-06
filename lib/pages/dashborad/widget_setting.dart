import 'package:garden/stores/settings_store.dart';
import 'package:garden/util/log.dart';
import 'package:garden/util/ui_util.dart';
import 'package:garden/util/storage_util.dart';
import 'package:garden/util/http_util.dart';
import 'package:garden/widgets/neu_back_button.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:garden/constants/app_constants.dart';
import 'package:garden/theme/app_colors.dart';

class WidgetSetting extends StatefulWidget {
  final List widgets;
  final Map restoreSizePos;
  const WidgetSetting(this.widgets, this.restoreSizePos, {super.key});
  @override
  WidgetSettingState createState() => WidgetSettingState();
}

class WidgetSettingState extends State<WidgetSetting> {
  bool showShortcut = true;
  bool showWallpaper = true;
  List<String> allWidgets = [
    // "SYNO.SDS.SystemInfoApp.FileChangeLogWidget",
    "SYNO.SDS.SystemInfoApp.SystemHealthWidget",
    "SYNO.SDS.ResourceMonitor.Widget",
    "SYNO.SDS.SystemInfoApp.StorageUsageWidget",
    "SYNO.SDS.SystemInfoApp.ConnectionLogWidget",
    "SYNO.SDS.TaskScheduler.TaskSchedulerWidget",
    "SYNO.SDS.SystemInfoApp.FileChangeLogWidget",
    "SYNO.SDS.SystemInfoApp.RecentLogWidget",
  ];
  Map name = {
    "SYNO.SDS.SystemInfoApp.FileChangeLogWidget": "文件更改日志",
    "SYNO.SDS.SystemInfoApp.RecentLogWidget": "最新日志",
    "SYNO.SDS.TaskScheduler.TaskSchedulerWidget": "计划任务",
    "SYNO.SDS.SystemInfoApp.SystemHealthWidget": "系统状况",
    "SYNO.SDS.SystemInfoApp.ConnectionLogWidget": "目前连接用户",
    "SYNO.SDS.SystemInfoApp.StorageUsageWidget": "存储",
    "SYNO.SDS.ResourceMonitor.Widget": "资源监控",
  };
  List showWidgets = [];
  List selectedWidgets = [];
  @override
  void initState() {
    StorageUtil.getBool("show_shortcut").then((showShortcutStr) {
      setState(() {
        if (showShortcutStr != null) {
          showShortcut = showShortcutStr;
        } else {
          showShortcut = true;
        }
      });
    });
    StorageUtil.getBool("show_wallpaper").then((showWallpaperStr) {
      setState(() {
        if (showWallpaperStr != null) {
          showWallpaper = showWallpaperStr == "1";
        } else {
          showWallpaper = true;
        }
      });
    });
    setState(() {
      selectedWidgets.addAll(widget.widgets);
      showWidgets.addAll(widget.widgets);
    });
    for (var widget in allWidgets) {
      if (!showWidgets.contains(widget)) {
        setState(() {
          showWidgets.add(widget);
        });
      }
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: AppBackButton(context),
        title: const Text("小组件设置"),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10, top: 8, bottom: 8),
            child: OutlinedButton(
              onPressed: () async {
                List saveWidgets = [];
                for (var widget in showWidgets) {
                  if (selectedWidgets.contains(widget)) {
                    saveWidgets.add(widget);
                  }
                }
                Map data = {
                  "SYNO.SDS._Widget.Instance": {"modulelist": saveWidgets},
                  // "restoreSizePos": widget.restoreSizePos
                };
                var res = await DsmApi.userSetting(data);
                if (res['success']) {
                  UiUtil.toast("保存小组件成功");
                  if (context.mounted) {
                    // ignore: use_build_context_synchronously
                    Navigator.of(context).pop();
                  }
                } else {
                  UiUtil.toast("保存小组件失败，代码${res['error']['code']}");
                }
              },
              child: Image.asset(
                "assets/icons/save.png",
                width: 20,
                height: 20,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppConstants.paddingLarge),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  setState(() {
                    showShortcut = !showShortcut;
                    settingsStore.setShowShortcut(showShortcut);
                  });
                });
              },
              child: Card(
                shape: RoundedRectangleBorder(
                    side: const BorderSide(),
                    borderRadius: BorderRadius.circular(18)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Image.asset(
                            "assets/icons/shortcut.png",
                            width: 30,
                          ),
                          const SizedBox(
                            width: 8,
                          ),
                          const Text(
                            "控制台快捷方式",
                            style: TextStyle(fontSize: 16),
                          ),
                          const Spacer(),
                          if (showShortcut)
                            const Icon(
                              CupertinoIcons.checkmark_alt,
                              color: AppColors.primaryAction,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  setState(() {
                    showWallpaper = !showWallpaper;
                    settingsStore.setShowWallpaper(showWallpaper);
                  });
                });
              },
              child: Card(
                shape: RoundedRectangleBorder(
                    side: const BorderSide(),
                    borderRadius: BorderRadius.circular(18)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Image.asset(
                            "assets/icons/wallpaper.png",
                            width: 30,
                          ),
                          const SizedBox(
                            width: 8,
                          ),
                          const Text(
                            "系统状态显示壁纸",
                            style: TextStyle(fontSize: 16),
                          ),
                          const Spacer(),
                          if (showWallpaper)
                            const Icon(
                              CupertinoIcons.checkmark_alt,
                              color: AppColors.primaryAction,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(
            height: 20,
          ),
          Expanded(
            child: ReorderableListView(
              children: showWidgets.map((widget) {
                return GestureDetector(
                  key: ValueKey(widget),
                  onTap: () {
                    setState(() {
                      if (selectedWidgets.contains(widget)) {
                        selectedWidgets.remove(widget);
                      } else {
                        selectedWidgets.add(widget);
                      }
                      Log.info(showWidgets);
                    });
                  },
                  child: Card(
                    shape: RoundedRectangleBorder(
                        side: const BorderSide(),
                        borderRadius: BorderRadius.circular(18)),
                    margin: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 20),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              name[widget],
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                          Card(
                            shape: RoundedRectangleBorder(
                                side: const BorderSide(),
                                borderRadius: BorderRadius.circular(18)),
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: selectedWidgets.contains(widget)
                                  ? const Icon(
                                      CupertinoIcons.checkmark_alt,
                                      color: AppColors.primaryAction,
                                    )
                                  : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
              onReorder: (int oldIndex, int newIndex) {
                if (oldIndex < newIndex) {
                  newIndex -= 1;
                }
                var child = showWidgets.removeAt(oldIndex);
                showWidgets.insert(newIndex, child);

                setState(() {});
              },
            ),
          ),
        ],
      ),
    );
  }
}
