import 'package:garden/stores/settings_store.dart';
import 'package:garden/util/log.dart';
import 'package:garden/util/ui_util.dart';
import 'package:garden/util/storage_util.dart';
import 'package:garden/api/dsm_api.dart';
import 'package:garden/widgets/neu_back_button.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:garden/constants/app_constants.dart';
import 'package:garden/theme/app_colors.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:signals_hooks/signals_hooks.dart';

class WidgetSetting extends HookWidget {
  const WidgetSetting(this.widgets, this.restoreSizePos, {super.key});
  final ReadonlySignal<List> widgets;
  final ReadonlySignal<Map> restoreSizePos;

  static const List<String> allWidgets = [
    // "SYNO.SDS.SystemInfoApp.FileChangeLogWidget",
    "SYNO.SDS.SystemInfoApp.SystemHealthWidget",
    "SYNO.SDS.ResourceMonitor.Widget",
    "SYNO.SDS.SystemInfoApp.StorageUsageWidget",
    "SYNO.SDS.SystemInfoApp.ConnectionLogWidget",
    "SYNO.SDS.TaskScheduler.TaskSchedulerWidget",
    "SYNO.SDS.SystemInfoApp.FileChangeLogWidget",
    "SYNO.SDS.SystemInfoApp.RecentLogWidget",
  ];
  static const Map<String, dynamic> name = {
    "SYNO.SDS.SystemInfoApp.FileChangeLogWidget": "文件更改日志",
    "SYNO.SDS.SystemInfoApp.RecentLogWidget": "最新日志",
    "SYNO.SDS.TaskScheduler.TaskSchedulerWidget": "计划任务",
    "SYNO.SDS.SystemInfoApp.SystemHealthWidget": "系统状况",
    "SYNO.SDS.SystemInfoApp.ConnectionLogWidget": "目前连接用户",
    "SYNO.SDS.SystemInfoApp.StorageUsageWidget": "存储",
    "SYNO.SDS.ResourceMonitor.Widget": "资源监控",
  };

  @override
  Widget build(BuildContext context) {
    final showShortcut = useSignal(true);
    final showWallpaper = useSignal(true);
    final showWidgets = useListSignal([]);
    final selectedWidgets = useListSignal([]);

    useEffect(() {
      (() async {
        showWidgets.value =
            <dynamic>{...widgets.value, ...allWidgets}.toList();
        selectedWidgets.value = widgets.value;
        showShortcut.value = await StorageUtil.getBool("show_shortcut") ?? true;
        showWallpaper.value = await StorageUtil.getBool("show_wallpaper") ?? true;
      })();
      return null;
    }, const []);

    final showWidgetsValue = showWidgets.watch(context);
    final selectedWidgetsValue = selectedWidgets.watch(context);
    final showShortcutValue = showShortcut.watch(context);
    final showWallpaperValue = showWallpaper.watch(context);
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
                for (var widget in showWidgetsValue) {
                  if (selectedWidgetsValue.contains(widget)) {
                    saveWidgets.add(widget);
                  }
                }
                Map data = {
                  "SYNO.SDS._Widget.Instance": {"modulelist": saveWidgets},
                  // "restoreSizePos": widget.restoreSizePos
                };
                try {
                  await dsmCoreUserSettingsApplyForPage(data);
                  UiUtil.toast("保存小组件成功");
                  if (context.mounted) {
                    // ignore: use_build_context_synchronously
                    Navigator.of(context).pop();
                  }
                } catch (e) {
                  final code = e is DSMException ? e.code : -1;
                  UiUtil.toast("保存小组件失败，代码$code");
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
                showShortcut.value = !showShortcut.value;
                settingsStore.setShowShortcut(showShortcut.value);
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
                          if (showShortcutValue)
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
                showWallpaper.value = !showWallpaper.value;
                settingsStore.setShowWallpaper(showWallpaper.value);
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
                          if (showWallpaperValue)
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
              children: showWidgetsValue.map((widget) {
                return GestureDetector(
                  key: ValueKey(widget),
                  onTap: () {
                    if (selectedWidgetsValue.contains(widget)) {
                      selectedWidgets.remove(widget);
                    } else {
                      selectedWidgets.add(widget);
                    }
                    Log.info(showWidgetsValue);
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
                              child: selectedWidgetsValue.contains(widget)
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
              onReorderItem: (int oldIndex, int newIndex) {
                var child = showWidgets.removeAt(oldIndex);
                showWidgets.insert(newIndex, child);
              },
            ),
          ),
        ],
      ),
    );
  }
}
