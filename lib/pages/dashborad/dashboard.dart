import 'package:garden/api/dsm_api.dart';
import 'package:garden/extensions/map.dart';
import 'package:garden/pages/dashborad/dashboard_appbar_title.dart';
import 'package:garden/pages/dashborad/dashboard_monitor_resource_widget.dart';
import 'package:garden/stores/settings_store.dart';
import 'package:garden/stores/connection_store.dart';
import 'dart:math';

import 'package:garden/pages/dashborad/applications.dart';
import 'package:garden/pages/dashborad/shortcut_list.dart';
import 'package:garden/pages/dashborad/widget_setting.dart';
import 'package:garden/theme/app_theme.dart';
import 'package:garden/util/http_util.dart';
import 'package:garden/util/log.dart';
import 'package:garden/util/ui_util.dart';
import 'package:garden/extensions/context.dart';
import 'package:garden/widgets/dashboard/dashboard_log_item.dart';
import 'package:garden/widgets/dashboard/dashboard_task_item.dart';
import 'package:garden/widgets/dashboard/dashboard_user_item.dart';
import 'package:garden/widgets/dashboard/volume_card.dart';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:garden/constants/app_constants.dart';
import 'package:signals_flutter/signals_flutter.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});
  @override
  DashboardState createState() => DashboardState();
}

class DashboardState extends State<Dashboard> with SignalsMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late final isDrawerOpen =
      createComputed(() => _scaffoldKey.currentState?.isDrawerOpen ?? false);
  // sds data
  late final storageVolumes = createListSignal([]);
  late final storageDisks = createListSignal([]);
  late final storageSsdCaches = createListSignal([]);

  /// desktop init data
  late final sdsWidgetModuleList = createListSignal([]);
  late final sdsWidgetRestoreSizePos = createMapSignal({});

  late final desktopAppViewOrder = createListSignal([]);
  late final desktopShortcutItems = createListSignal<Map>([]);
  late final desktopValidAppViewOrder = createListSignal([]);
  late final desktopWallpaper = createMapSignal({});
  late final sessionHostname = createSignal("获取中");

  late final appNotify = createMapSignal({});
  late final systemData = createMapSignal({});

  late final heatDissipation = createComputed(() =>
      "${systemData['sys_temp']}℃ ${systemData['temperature_warning'] == null ? (systemData['sys_temp'] > 80 ? "警告" : "正常") : (systemData['temperature_warning'] ? "警告" : "正常")}");

  late final connectedUsers = createListSignal([]);
  late final schedulerTasks = createListSignal([]);
  late final syslogs = createListSignal([]);
  // resourceMonitor
  late final monitoredResources = createMapSignal<String, dynamic>({});

  int refreshDuration = 10;
  final networks = List.generate(20, (i) => {"tx": 0, "rx": 0});
  int get maxNetworkSpeed {
    int maxSpeed = 0;
    for (int i = 0; i < networks.length; i++) {
      int maxVal = max(networks[i]['rx'] ?? 0, networks[i]['tx'] ?? 0);
      if (maxSpeed < maxVal) {
        maxSpeed = maxVal;
      }
    }
    return maxSpeed;
  }

  @override
  void initState() {
    super.initState();
    _fetchDesktopInitdata();
    _fetchWidgetModuleList();
    _fetcCurrentConnectionList();
    _fetchWidgetModuleList();
    _fetcCurrentConnectionList();
    _fetchSchedulerTasks();
    _fetchMonitoredResources();
    _fetchSyslogs();
  }

  _fetchDesktopInitdata() async {
    try {
      final res = await dsmCoreDesktopInitdata();
      if (res['UserSettings'] != null) {
        if (res['UserSettings']['SYNO.SDS._Widget.Instance'] != null) {
          sdsWidgetModuleList.set(res['UserSettings']
                  ['SYNO.SDS._Widget.Instance']['modulelist'] ??
              []);
          sdsWidgetRestoreSizePos.set(res['UserSettings']
                  ['SYNO.SDS._Widget.Instance']['restoreSizePos'] ??
              {});
        }
        if (res['UserSettings']['Desktop'] != null) {
          desktopAppViewOrder.set(res['UserSettings']['Desktop']
                  ['valid_appview_order'] ??
              res['UserSettings']['Desktop']['appview_order'] ??
              []);

          desktopShortcutItems.set(
              (res['UserSettings']['Desktop']['ShortcutItems'] as List?)
                      ?.cast<Map>() ??
                  []);
          desktopValidAppViewOrder
              .set(res['UserSettings']['Desktop']['valid_appview_order']);
          desktopWallpaper.set(res['UserSettings']['Desktop']['wallpaper']);
        }
      }
      if (res['Session'] != null) {
        sessionHostname.set(res['Session']['hostname']);
        connectionStore.setHostname(sessionHostname.value);
      }
      if (res['Strings'] != null) {
        connectionStore.setStrings(res['Strings'] ?? {});
      }
    } catch (e) {
      Log.error('fetchDesktopInitdata error: $e');
      UiUtil.toast('fetchDesktopInitdata error: $e');
    }
  }

  _fetchWidgetModuleList() async {
    try {
      final res = await dsmSDSWidgetModuleListDetail(sdsWidgetModuleList.value);
      List result = res['result'];
      for (final item in result) {
        if (item['success'] == true) {
          switch (item['api']) {
            case "SYNO.Core.System":
              systemData.set(item['data']);
              settingsStore.setFirmwareVersion(systemData['firmware_ver']);
              break;
            case "SYNO.Storage.CGI.Storage":
              storageSsdCaches.set(item['data']['ssdCaches']);
              final d = item['data']['volumes'];
              d.sort((a, b) {
                final aid = a['num_id'] as int;
                final bid = b['num_id'] as int;
                return aid.compareTo(bid);
              });
              storageVolumes.set(d);
              storageDisks.set(item['data']['disks']);
              break;
            case "SYNO.Core.AppNotify":
              appNotify.set(item['data']);
              break;
          }
        }
      }
    } catch (e) {
      Log.error('dsmSDSWidgetModuleListDetail error: $e');
    }
  }

  _fetcCurrentConnectionList() async {
    try {
      final res = await dsmCoreCurrentConnectionList();
      connectedUsers.set(res['items']);
    } catch (e) {
      Log.error('dsmCoreCurrentConnectionList: $e');
    }
  }

  _fetchSchedulerTasks() async {
    try {
      final res = await dsmCoreTaskSchedulerList(
        sortBy: 'next_trigger_time',
        sortDirection: 'ASC',
      );
      schedulerTasks.set(res['tasks']);
    } catch (e) {
      Log.error('dsmCoreTaskList: $e');
    }
  }

  _fetchSyslogs() async {
    try {
      final res = await dsmCoreSyslogClientLogList(
          logtype: 'ftp,filestation,webdav,cifs,tftp,afp',
          target: 'LOCAL',
          sortDirection: 'desc',
          limit: 50,
          offset: 0);
      syslogs.set(res['items']);
    } catch (e) {
      Log.error('dsmCoreSyslogList: $e');
    }
  }

  _fetchMonitoredResources() async {
    try {
      final res = await dsmCoreSystemUtilization(
          ["cpu", "memory", "network", "lun", "disk", "space"].join(','));
      monitoredResources.set(res as Map<String, dynamic>);
      if (networks.length > 20) {
        networks.removeAt(0);
      }
      networks.add(res['network'][0]);
    } catch (e) {
      Log.error("dsmCoreSystemUtilization error: $e");
    }
  }

  closeDrawer() {
    if (isDrawerOpen.value && mounted) {
      Navigator.of(context).pop();
    }
  }

  ExpansionPanel _buildSystemHealthPanel() {
    return ExpansionPanel(
        headerBuilder: (BuildContext context, bool isExpanded) {
          return Card(
            shape: context.stadiumShapeBorder,
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.paddingSmall),
              child: Row(
                children: [
                  Image.asset(
                    "assets/icons/task.png",
                    width: 26,
                    height: 26,
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  const Text(
                    "系统健康",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          );
        },
        body: Container(
          padding: const EdgeInsets.all(AppConstants.paddingSmall),
          child: Stack(
            children: [
              // 自定义壁纸
              Watch<Widget>((context) {
                final customize = desktopWallpaper.select((v) =>
                    v['customizeWallpaper'] == true ||
                    v['customizeBackground'] == true);

                if (settingsStore.showWallpaper.value && customize.value) {
                  return ExtendedImage.network(
                    "${connectionStore.baseUri}/webapi/entry.cgi?api=SYNO.Core.PersonalSettings&method=wallpaper&version=1&path=%22%22&retina=true&_sid=${connectionStore.sid}",
                    height: 170,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    shape: BoxShape.rectangle,
                    borderRadius: BorderRadius.circular(20),
                  );
                }
                return const SizedBox.shrink();
              }),
              // 黑暗主题蒙版
              // if (Theme.brightnessOf(context) == Brightness.dark)
              //   Container(
              //     height: 170,
              //     decoration: BoxDecoration(
              //       color: Theme.of(context)
              //           .scaffoldBackgroundColor
              //           .withValues(alpha: .1),
              //       borderRadius: BorderRadius.circular(20),
              //     ),
              //   ),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppConstants.paddingSmall),
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.paddingSmall),
                  child: DefaultTextStyle(
                      style: TextStyle(
                          color: Theme.of(context).textTheme.bodyLarge?.color),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Image.asset(
                                "assets/icons/info.png",
                                width: 26,
                                height: 26,
                              ),
                              const SizedBox(
                                width: 10,
                              ),
                              const Text(
                                "系统状态",
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(
                                height: 5,
                              ),
                              // product model
                              Watch<Widget>((context) {
                                final model =
                                    systemData.select((v) => v['model']);
                                if (model.value != null) {
                                  Padding(
                                    padding: const EdgeInsets.only(top: 5),
                                    child: Row(
                                      children: [
                                        const Text("产品型号："),
                                        Text("${model.value}"),
                                      ],
                                    ),
                                  );
                                }
                                return const SizedBox.shrink();
                              }),
                              const SizedBox(
                                height: 5,
                              ),
                              Watch<Widget>(
                                (context) => Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8.0),
                                  child: Row(
                                    children: [
                                      const Text("系统名称："),
                                      Text(sessionHostname.value),
                                    ],
                                  ),
                                ),
                              ),
                              // 散热
                              Watch<Widget>((context) {
                                final sysTemp =
                                    systemData.select((v) => v['sys_temp']);
                                final temperatureWarning = systemData
                                    .select((v) => v['temperature_warning']);
                                if (sysTemp.value != null) {
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 5),
                                    child: Row(
                                      children: [
                                        const Text("散热状态："),
                                        Text(
                                          heatDissipation.value,
                                          style: TextStyle(
                                              color: sysTemp.value == null
                                                  ? (sysTemp.value > 80
                                                      ? context.errorColor
                                                      : context.successColor)
                                                  : (temperatureWarning.value
                                                      ? context.errorColor
                                                      : context.successColor)),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  );
                                } else {
                                  return const SizedBox.shrink();
                                }
                              }),
                              // 运行时间
                              Watch<Widget>((context) {
                                final upTime =
                                    systemData.select((v) => v['up_time']);
                                if (upTime.value != null &&
                                    upTime.value.isNotEmpty) {
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 5),
                                    child: Row(
                                      children: [
                                        const Text("运行时间："),
                                        Text(parseOpTime(upTime.value)),
                                      ],
                                    ),
                                  );
                                } else {
                                  return const SizedBox.shrink();
                                }
                              })
                            ],
                          ),
                        ],
                      )),
                ),
              )
            ],
          ),
        ),
        isExpanded: settingsStore.dashboardCardCollapseState
                .watch(context)
                .getBool("SystemHealth") ==
            true);
  }

  ExpansionPanel _buildConnectionLogPanel() {
    return ExpansionPanel(
        headerBuilder: (BuildContext context, bool isExpanded) {
          return Card(
            shape: context.stadiumShapeBorder,
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.paddingLarge),
              child: connectedUsers.isEmpty
                  ? TextButton(
                      onPressed: _fetcCurrentConnectionList,
                      child: const Text('没有获取到链接日志(点击重试)'))
                  : Row(
                      children: [
                        Image.asset(
                          "assets/icons/user.png",
                          width: 26,
                          height: 26,
                        ),
                        const SizedBox(
                          width: 10,
                        ),
                        const Text(
                          "登录用户",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w600),
                        ),
                        const Spacer(),
                      ],
                    ),
            ),
          );
        },
        body: ListView(
          children: connectedUsers
              .map((user) => DashboardUserItem(
                    user: user,
                    onKickSuccess: () {
                      // FIXME:
                    },
                  ))
              .toList(),
        ),
        isExpanded: connectedUsers.isNotEmpty &&
            settingsStore.dashboardCardCollapseState
                    .watch(context)
                    .getBool("ConnectionLog") ==
                true);
  }

  ExpansionPanel _buildStorageVolumePanel() {
    return ExpansionPanel(
        headerBuilder: (BuildContext context, bool isExpanded) {
          return Card(
              shape: context.stadiumShapeBorder,
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.paddingLarge),
                child: Row(
                  children: [
                    Image.asset(
                      "assets/icons/pie.png",
                      width: 26,
                      height: 26,
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                    const Text(
                      "存储",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ));
        },
        body: storageVolumes.isNotEmpty
            ? ListView(
                children:
                    storageVolumes.map((v) => VolumeCard(volume: v)).toList(),
              )
            : const Center(child: Text("没有获取到磁盘信息")),
        isExpanded: settingsStore.dashboardCardCollapseState
                .watch(context)
                .getBool("StorageVolume") ==
            true);
  }

  ExpansionPanel _buildStorageSsdCachePanel() {
    return ExpansionPanel(
        headerBuilder: (BuildContext context, bool isExpanded) {
          return Card(
              shape: context.stadiumShapeBorder,
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.paddingLarge),
                child: Row(
                  children: [
                    Image.asset(
                      "assets/icons/pie.png",
                      width: 26,
                      height: 26,
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                    const Text(
                      "存储",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ));
        },
        body: storageSsdCaches.isNotEmpty
            ? ListView(
                children:
                    storageSsdCaches.map((v) => VolumeCard(volume: v)).toList(),
              )
            : const Center(child: Text("没有获取到SSD缓存信息")),
        isExpanded: settingsStore.dashboardCardCollapseState
                .watch(context)
                .getBool("StorageSsdCache") ==
            true);
  }

  ExpansionPanel _buildStorageDiskPanel() {
    return ExpansionPanel(
        headerBuilder: (BuildContext context, bool isExpanded) {
          return Card(
              shape: context.stadiumShapeBorder,
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.paddingLarge),
                child: Row(
                  children: [
                    Image.asset(
                      "assets/icons/pie.png",
                      width: 26,
                      height: 26,
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                    const Text(
                      "存储",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ));
        },
        body: storageDisks.isNotEmpty
            ? ListView(
                children:
                    storageDisks.map((v) => VolumeCard(volume: v)).toList(),
              )
            : const Center(child: Text("没有获取到硬盘信息")),
        isExpanded: settingsStore.dashboardCardCollapseState
                .watch(context)
                .getBool("StorageDisk") ==
            true);
  }

  ExpansionPanel _buildTaskSchedulerPanel() {
    return ExpansionPanel(
        headerBuilder: (BuildContext context, bool isExpanded) {
          return Card(
            shape: context.stadiumShapeBorder,
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.paddingSmall),
              child: Row(
                children: [
                  Image.asset(
                    "assets/icons/task.png",
                    width: 26,
                    height: 26,
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  const Text(
                    "计划任务",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          );
        },
        body: ListView(
          children: schedulerTasks
              .watch(context)
              .map((task) => DashboardTaskItem(task: task))
              .toList(),
        ),
        isExpanded: schedulerTasks.isNotEmpty &&
            settingsStore.dashboardCardCollapseState
                    .watch(context)
                    .getBool("TaskScheduler") ==
                true);
  }

  ExpansionPanel _buildRecentLogPanel() {
    return ExpansionPanel(
        headerBuilder: (BuildContext context, bool isExpanded) {
          return Card(
              shape: context.stadiumShapeBorder,
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.paddingLarge),
                child: Row(
                  children: [
                    Image.asset(
                      "assets/icons/log.png",
                      width: 26,
                      height: 26,
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                    const Text(
                      "最新日志",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ));
        },
        body: SizedBox(
          height: 300,
          child: syslogs.watch(context).isNotEmpty
              ? CupertinoScrollbar(
                  child: ListView.builder(
                    itemBuilder: (context, i) {
                      return DashboardLogItem(log: syslogs.watch(context)[i]);
                    },
                    itemCount: syslogs.watch(context).length,
                  ),
                )
              : Center(
                  child: Text(
                    "暂无日志",
                    style:
                        TextStyle(color: AppTheme.of(context).placeholderColor),
                  ),
                ),
        ),
        isExpanded: settingsStore.dashboardCardCollapseState
                .watch(context)
                .getBool("RecentLog") ==
            true);
  }

  ExpansionPanel _buildResourceMonitorPanel() {
    return ExpansionPanel(
        headerBuilder: (BuildContext context, bool isExpanded) {
          return Card(
            shape: context.stadiumShapeBorder,
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.paddingLarge),
              child: Row(
                children: [
                  Image.asset(
                    "assets/icons/resources.png",
                    width: 26,
                    height: 26,
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  const Text(
                    "资源监控",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          );
        },
        body: Expanded(
            child: Column(
          children: [
            const SizedBox(
              height: 10,
            ),
            PerformanceNetworkChartWidget(
              networks: networks,
              maxNetworkSpeed: maxNetworkSpeed,
            ),
            const SizedBox(
              height: 15,
            ),
            PerformanceRamWidget(
              monitoredResources: monitoredResources,
            ),
            const SizedBox(
              height: 15,
            ),
            PerformanceNetowrkWidget(
              monitoredResources: monitoredResources,
            ),
            const SizedBox(
              height: 5,
            ),
            PerformanceCpuWidget(
              monitoredResources: monitoredResources,
            ),
          ],
        )),
        isExpanded: settingsStore.dashboardCardCollapseState
                .watch(context)
                .getBool("ResourceMonitor") ==
            true);
  }

  ExpansionPanel _buildFileChangeLogPanel() {
    return ExpansionPanel(
        headerBuilder: (BuildContext context, bool isExpanded) {
          return Card(
              shape: context.stadiumShapeBorder,
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.paddingLarge),
                child: Row(
                  children: [
                    Image.asset(
                      "assets/icons/file_change.png",
                      width: 26,
                      height: 26,
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                    const Text(
                      "文件更改日志",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ));
        },
        body: syslogs.isNotEmpty
            ? ListView(
                children: syslogs.map((e) => DashboardLogItem(log: e)).toList(),
              )
            : const Center(
                child: Text("暂无系统日志"),
              ),
        isExpanded: settingsStore.dashboardCardCollapseState
                .watch(context)
                .getBool("FileChangeLog") ==
            true);
  }

  Widget _buildWidgetModule() {
    return ExpansionPanelList(
      expansionCallback: (panelIndex, isExpaned) {
        String key = '';
        switch (panelIndex) {
          case 0:
            key = "SystemHealth";
            break;
          case 1:
            key = "ConnectionLog";
            break;
          case 2:
            key = "TaskScheduler";
            break;
          case 3:
            key = "RecentLog";
            break;
          case 4:
            key = "ResourceMonitor";
            break;
          case 5:
            key = "FileChangeLog";
            break;
          case 6:
            key = "StorageUsage";
            break;
        }
        if (key.isNotEmpty) {
          settingsStore.setDashboardCardCollapseState(item: (key, isExpaned));
        }
      },
      children: [
        if (sdsWidgetModuleList
            .contains('SYNO.SDS.SystemInfoApp.SystemHealthWidget'))
          _buildSystemHealthPanel(),
        if (sdsWidgetModuleList
            .contains('SYNO.SDS.SystemInfoApp.ConnectionLogWidget'))
          _buildConnectionLogPanel(),
        if (sdsWidgetModuleList
            .contains('SYNO.SDS.SystemInfoApp.TaskSchedulerWidget'))
          _buildTaskSchedulerPanel(),
        if (sdsWidgetModuleList
            .contains('SYNO.SDS.SystemInfoApp.RecentLogWidget'))
          _buildRecentLogPanel(),
        if (sdsWidgetModuleList
            .contains('SYNO.SDS.SystemInfoApp.ResourceMonitorWidget'))
          _buildResourceMonitorPanel(),
        if (sdsWidgetModuleList
            .contains('SYNO.SDS.SystemInfoApp.FileChangeLogWidget'))
          _buildFileChangeLogPanel(),
        if (sdsWidgetModuleList
            .contains('SYNO.SDS.SystemInfoApp.StorageUsageWidget')) ...[
          _buildStorageDiskPanel(),
          _buildStorageVolumePanel(),
          _buildStorageSsdCachePanel()
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Stack(
          alignment: Alignment.center,
          children: [
            Row(
              children: [
                DashboardAppbarTitleDrawer(
                  onOpenDrawer: _scaffoldKey.currentState?.openDrawer,
                ),
                DashboardAppbarTitleExternalDevice(
                  onEjectSuccess: _fetchWidgetModuleList,
                ),
                const DashboardAppbarTitleMediaConverter(),
                const Spacer(),
                DashboardAppbarTitleEdit(onEditClick: () {
                  Navigator.of(context)
                      .push(CupertinoPageRoute(builder: (context) {
                    return WidgetSetting(
                        sdsWidgetModuleList, sdsWidgetRestoreSizePos);
                  })).then((res) {
                    if (res != null) {
                      sdsWidgetModuleList.set(res);
                      _fetchWidgetModuleList();
                    }
                  });
                }),
                const DashboardAppbarTitleNotifier(),
              ],
            )
          ],
        ),
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 20),
        children: [
          if (desktopShortcutItems
                  .where((element) =>
                      supportedShortcuts.contains(element['className']))
                  .isNotEmpty &&
              connectionStore.notVisitorAccount.value &&
              settingsStore.showShortcut.value)
            ShortcutList(
              desktopShortcutItems,
              systemData,
              storageVolumes,
              storageDisks,
              appNotify,
              validAppViewOrder: desktopValidAppViewOrder,
            ),
          if (sdsWidgetModuleList.isNotEmpty)
            _buildWidgetModule()
          else
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "未添加小组件",
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  SizedBox(
                    width: 200,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(context)
                            .push(CupertinoPageRoute(builder: (context) {
                          return WidgetSetting(
                              sdsWidgetModuleList, sdsWidgetRestoreSizePos);
                        })).then((res) {
                          if (res != null) {
                            sdsWidgetModuleList.set(res);
                            _fetchWidgetModuleList();
                          }
                        });
                      },
                      child: const Text(
                        ' 添加 ',
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                  ),
                ],
              ),
            )
        ],
      ),
      drawer: desktopAppViewOrder.isNotEmpty
          ? ApplicationList(desktopAppViewOrder, systemData, storageVolumes,
              storageDisks, appNotify)
          : null,
    );
  }
}
