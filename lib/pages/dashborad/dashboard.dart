import 'package:garden/api/dsm_api.dart';
import 'package:garden/extensions/map.dart';
import 'package:garden/pages/dashborad/dashboard_appbar_title.dart';
import 'package:garden/stores/settings_store.dart';
import 'package:garden/stores/connection_store.dart';
import 'dart:math';

import 'package:garden/pages/control_panel/task_scheduler/task_scheduler.dart';
import 'package:garden/pages/dashborad/applications.dart';
import 'package:garden/pages/dashborad/shortcut_list.dart';
import 'package:garden/pages/dashborad/widget_setting.dart';
import 'package:garden/pages/log_center/log_center.dart';
import 'package:garden/pages/resource_monitor/performance.dart';
import 'package:garden/pages/resource_monitor/resource_monitor.dart';
import 'package:garden/theme/app_theme.dart';
import 'package:garden/util/http_util.dart';
import 'package:garden/util/log.dart';
import 'package:garden/util/ui_util.dart';
import 'package:garden/widgets/animation_progress_bar.dart';
import 'package:garden/extensions/context.dart';
import 'package:garden/widgets/dashboard/dashboard_log_item.dart';
import 'package:garden/widgets/dashboard/dashboard_task_item.dart';
import 'package:garden/widgets/dashboard/dashboard_user_item.dart';
import 'package:garden/widgets/dashboard/volume_card.dart';
import 'package:extended_image/extended_image.dart';
import 'package:fl_chart/fl_chart.dart';
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
      computed(() => _scaffoldKey.currentState?.isDrawerOpen ?? false);
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

  int refreshDuration = 10;

  @override
  void initState() {
    effect(() async {
      await fetchDesktopInitdata();
      await getData();
    });
    super.initState();
  }

  closeDrawer() {
    if (isDrawerOpen.value && mounted) {
      Navigator.of(context).pop();
    }
  }

  fetchDesktopInitdata() async {
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

          desktopShortcutItems
              .set(res['UserSettings']['Desktop']['ShortcutItems']);
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

  getData() async {
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
                return a['num_id'].compareTo(b['num_id']);
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

  Widget _buildWidgetModuleItem(BuildContext context, String widget) {
    if (widget == "SYNO.SDS.SystemInfoApp.SystemHealthWidget") {
      return SystemHealthWidget(
        sessionHostname: sessionHostname,
        wallpaper: desktopWallpaper,
        systemData: systemData,
      );
    } else if (widget == "SYNO.SDS.SystemInfoApp.ConnectionLogWidget") {
      return ConnectionLogWidget(
        onKickSuccess: getData,
      );
    } else if (widget == "SYNO.SDS.SystemInfoApp.StorageUsageWidget") {
      return StorageUsageWidget(
          storageDisks: storageDisks,
          storageVolumes: storageVolumes,
          storageSsdCaches: storageSsdCaches);
    } else if (widget == "SYNO.SDS.SystemInfoApp.TaskSchedulerWidget") {
      return const TaskSchedulerWidget();
    } else if (widget == "SYNO.SDS.SystemInfoApp.RecentLogWidget") {
      return const RecentLogWidget();
    } else if (widget == "SYNO.SDS.ResourceMonitor.Widget") {
      return const ResourceMonitorWidget();
    } else if (widget == "SYNO.SDS.SystemInfoApp.FileChangeLogWidget") {
      return const FileChangeLogWidget();
    } else {
      return const SizedBox.shrink();
    }
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
                  onEjectSuccess: getData,
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
                      getData();
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
            ...sdsWidgetModuleList
                .map((widget) => _buildWidgetModuleItem(context, widget))
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
                            getData();
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

class DashboardCardItemCollapseIcon extends StatelessWidget {
  const DashboardCardItemCollapseIcon(this.itemName, {super.key});
  final String itemName;
  @override
  Widget build(BuildContext context) {
    return Watch((context) => IconButton(
        onPressed: () {
          settingsStore.setDashboardCardCollapseState(item: (
            itemName,
            !(settingsStore.dashboardCardCollapseState[itemName] ?? false)
          ));
        },
        icon: Icon(settingsStore.dashboardCardCollapseState
                    .watch(context)
                    .getBool(itemName) ==
                true
            ? Icons.unfold_less
            : Icons.unfold_more)));
  }
}

class SystemHealthWidget extends StatefulWidget {
  const SystemHealthWidget(
      {super.key,
      this.onPressed,
      this.sessionHostname,
      required this.wallpaper,
      required this.systemData});
  final VoidCallback? onPressed;
  final ReadonlySignal<Map> wallpaper;
  final ReadonlySignal<String>? sessionHostname;
  final ReadonlySignal<Map> systemData;

  @override
  State<SystemHealthWidget> createState() => _SystemHealthWidgetState();
}

class _SystemHealthWidgetState extends State<SystemHealthWidget>
    with SignalsMixin {
  late final heatDissipation = computed(() =>
      "${widget.systemData['sys_temp']}℃ ${widget.systemData['temperature_warning'] == null ? (widget.systemData['sys_temp'] > 80 ? "警告" : "正常") : (widget.systemData['temperature_warning'] ? "警告" : "正常")}");
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (connectionStore.notVisitorAccount.watch(context)) {
          widget.onPressed?.call();
        }
      },
      child: Card(
        shape: context.stadiumShapeBorder,
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.paddingSmall),
          child: Stack(
            children: [
              // 自定义壁纸
              if (settingsStore.showWallpaper.value &&
                  (widget.wallpaper['customizeWallpaper'] == true ||
                      widget.wallpaper['customizeBackground'] == true))
                ExtendedImage.network(
                  "${connectionStore.baseUri}/webapi/entry.cgi?api=SYNO.Core.PersonalSettings&method=wallpaper&version=1&path=%22%22&retina=true&_sid=${connectionStore.sid}",
                  height: 170,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  shape: BoxShape.rectangle,
                  borderRadius: BorderRadius.circular(20),
                ),
              // 黑暗主题蒙版
              if (Theme.brightnessOf(context) == Brightness.dark)
                Container(
                  height: 170,
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .scaffoldBackgroundColor
                        .withValues(alpha: .1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
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
                              if (widget.systemData['model'] != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 5),
                                  child: Row(
                                    children: [
                                      const Text("产品型号："),
                                      Text("${widget.systemData['model']}"),
                                    ],
                                  ),
                                ),
                              const SizedBox(
                                height: 5,
                              ),
                              Row(
                                children: [
                                  const Text("系统名称："),
                                  Text(widget.sessionHostname?.value ?? ''),
                                ],
                              ),
                              // 散热
                              if (widget.systemData['sys_temp'] != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 5),
                                  child: Row(
                                    children: [
                                      const Text("散热状态："),
                                      Text(
                                        heatDissipation.value,
                                        style: TextStyle(
                                            color: widget.systemData[
                                                        'temperature_warning'] ==
                                                    null
                                                ? (widget.systemData[
                                                            'sys_temp'] >
                                                        80
                                                    ? context.errorColor
                                                    : context.successColor)
                                                : (widget.systemData[
                                                        'temperature_warning']
                                                    ? context.errorColor
                                                    : context.successColor)),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              // 运行时间
                              if (widget.systemData['up_time'] != null &&
                                  widget.systemData['up_time'] != "")
                                Padding(
                                  padding: const EdgeInsets.only(top: 5),
                                  child: Row(
                                    children: [
                                      const Text("运行时间："),
                                      Text(parseOpTime(
                                          widget.systemData['up_time'])),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ],
                      )),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class ConnectionLogWidget extends StatefulWidget {
  const ConnectionLogWidget({super.key, this.onKickSuccess});
  final VoidCallback? onKickSuccess;
  @override
  State<ConnectionLogWidget> createState() => _ConnectionLogWidgetState();
}

class _ConnectionLogWidgetState extends State<ConnectionLogWidget>
    with SignalsMixin {
  late final connectedUsers = createListSignal([]);
  @override
  initState() {
    super.initState();
    effect(() async {
      try {
        final res = await dsmCoreCurrentConnectionList();
        connectedUsers.set(res['items']);
      } catch (e) {
        Log.error('dsmCoreCurrentConnectionList: $e');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return connectedUsers.isEmpty
        ? Container()
        : Card(
            shape: context.stadiumShapeBorder,
            margin: const EdgeInsets.all(AppConstants.paddingMedium),
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.paddingSmall),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppConstants.paddingLarge),
                    child: Row(
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
                        const DashboardCardItemCollapseIcon("ConnectionLog")
                      ],
                    ),
                  ),
                  if (settingsStore.dashboardCardCollapseState.value
                          .getBool('ConnectionLog') ==
                      true)
                    ...connectedUsers.map((user) => DashboardUserItem(
                          user: user,
                          onKickSuccess: widget.onKickSuccess,
                        )),
                  const SizedBox(
                    height: 20,
                  ),
                ],
              ),
            ),
          );
  }
}

class TaskSchedulerWidget extends StatefulWidget {
  const TaskSchedulerWidget({super.key});

  @override
  State<TaskSchedulerWidget> createState() => _TaskSchedulerWidgetState();
}

class _TaskSchedulerWidgetState extends State<TaskSchedulerWidget>
    with SignalsMixin {
  late final schedulerTasks = createListSignal([]);
  @override
  initState() {
    super.initState();
    effect(() async {
      try {
        final res = await dsmCoreTaskSchedulerList(
          sortBy: 'next_trigger_time',
          sortDirection: 'ASC',
        );
        schedulerTasks.set(res['tasks']);
      } catch (e) {
        Log.error('dsmCoreTaskList: $e');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(CupertinoPageRoute(builder: (context) {
          return const TaskScheduler();
        }));
      },
      child: Card(
        shape: context.stadiumShapeBorder,
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.paddingSmall),
          child: Column(
            children: [
              const SizedBox(
                height: 20,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.paddingLarge),
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
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    const Spacer(),
                    const DashboardCardItemCollapseIcon("TaskScheduler")
                  ],
                ),
              ),
              if (settingsStore.dashboardCardCollapseState
                      .watch(context)
                      .getBool('TaskScheduler') ==
                  true)
                ...schedulerTasks.value
                    .map((task) => DashboardTaskItem(task: task)),
              const SizedBox(
                height: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RecentLogWidget extends StatefulWidget {
  const RecentLogWidget({super.key});

  @override
  State<RecentLogWidget> createState() => _RecentLogWidgetState();
}

class _RecentLogWidgetState extends State<RecentLogWidget> with SignalsMixin {
  late final syslogs = createListSignal([]);
  @override
  initState() {
    super.initState();
    effect(() async {
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
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(CupertinoPageRoute(
            builder: (context) {
              return const LogCenter();
            },
            settings: const RouteSettings(name: "log_center")));
      },
      child: Card(
        // TODO: use animation, this will cause hard fade.
        shape: !(settingsStore.dashboardCardCollapseState
                    .watch(context)
                    .getBool('RecentLog') ==
                true)
            ? context.stadiumShapeBorder
            : const RoundedRectangleBorder(),
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.paddingSmall),
          child: Column(
            children: [
              const SizedBox(
                height: 20,
              ),
              Padding(
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
                    const Spacer(),
                    const DashboardCardItemCollapseIcon("RecentLog")
                  ],
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              if (settingsStore.dashboardCardCollapseState
                      .watch(context)
                      .getBool('RecentLog') ==
                  true)
                SizedBox(
                  height: 300,
                  child: syslogs.isNotEmpty
                      ? CupertinoScrollbar(
                          child: ListView.builder(
                            itemBuilder: (context, i) {
                              return DashboardLogItem(log: syslogs[i]);
                            },
                            itemCount: syslogs.length,
                          ),
                        )
                      : Center(
                          child: Text(
                            "暂无日志",
                            style: TextStyle(
                                color: AppTheme.of(context).placeholderColor),
                          ),
                        ),
                ),
              const SizedBox(
                height: 10,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ResourceMonitorWidget extends StatefulWidget {
  const ResourceMonitorWidget({super.key});

  @override
  State<ResourceMonitorWidget> createState() => _ResourceMonitorWidgetState();
}

class _ResourceMonitorWidgetState extends State<ResourceMonitorWidget>
    with SignalsMixin {
  late final utilization = createMapSignal({});

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
  initState() {
    super.initState();
    effect(() async {
      try {
        final res = await dsmCoreSystemUtilization(
            ["cpu", "memory", "network", "lun", "disk", "space"].join(','));
        utilization.set(res);
        if (networks.length > 20) {
          networks.removeAt(0);
        }
        networks.add(res['network'][0]);
      } catch (e) {
        Log.error("dsmCoreSystemUtilization error: $e");
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(CupertinoPageRoute(builder: (context) {
          return const ResourceMonitor();
        }));
      },
      child: Card(
        shape: context.stadiumShapeBorder,
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.paddingSmall),
          child: Column(
            children: [
              const SizedBox(
                height: 20,
              ),
              Padding(
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
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    const Spacer(),
                    const DashboardCardItemCollapseIcon("ResourceMonitor")
                  ],
                ),
              ),
              if (settingsStore.dashboardCardCollapseState
                      .watch(context)
                      .getBool('ResourceMonitor') ==
                  true) ...[
                const SizedBox(
                  height: 10,
                ),
                _performanceCpuWidget(context),
                const SizedBox(
                  height: 15,
                ),
                _performanceRamWidget(context),
                const SizedBox(
                  height: 15,
                ),
                _performanceNetworkWidget(context),
                const SizedBox(
                  height: 5,
                ),
                _performanceNetworkChartWidget(context),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _performanceNetworkChartWidget(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(CupertinoPageRoute(
            builder: (context) {
              return const Performance(
                tabIndex: 3,
              );
            },
            settings: const RouteSettings(name: "performance")));
      },
      child: AspectRatio(
        aspectRatio: 1.70,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Card(
            shape: RoundedRectangleBorder(
                side: const BorderSide(),
                borderRadius: BorderRadius.circular(18)),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: LineChart(
                LineChartData(
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      tooltipBorder:
                          BorderSide(color: Colors.white.withValues(alpha: .6)),
                      tooltipRoundedRadius: 20,
                      fitInsideHorizontally: true,
                      fitInsideVertically: true,
                      getTooltipItems: (List<LineBarSpot> items) {
                        return items.map((LineBarSpot touchedSpot) {
                          final textStyle = TextStyle(
                            color: touchedSpot.bar.color,
                            // color: touchedSpot.bar.colors[0],
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          );
                          return LineTooltipItem(
                              '${touchedSpot.bar.color == context.uploadColor ? "上传" : "下载"}:${(touchedSpot.y.floor()).formatSize()}',
                              textStyle);
                        }).toList();
                      },
                    ),
                  ),
                  gridData: const FlGridData(
                    show: false,
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: const AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: false,
                        reservedSize: 22,
                      ),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, _) {
                          return Text((value.toInt()).formatSize(fixed: 0),
                              style: TextStyle(
                                color: context.chartTextColor,
                                fontSize: 12,
                              ));
                        },
                        reservedSize: 35,
                        interval: maxNetworkSpeed.chartInterval(),
                      ),
                    ),
                  ),
                  // maxY: 20,
                  minY: 0,
                  borderData: FlBorderData(
                      show: true,
                      border: Border.all(color: Colors.black12, width: 1)),
                  lineBarsData: [
                    LineChartBarData(
                      spots: networks.map((network) {
                        return FlSpot(networks.indexOf(network).toDouble(),
                            (network['tx'] ?? 0).toDouble());
                      }).toList(),
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 2,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(
                        show: false,
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: context.uploadColor.withValues(alpha: .2),
                      ),
                    ),
                    LineChartBarData(
                      spots: networks.map((network) {
                        return FlSpot(networks.indexOf(network).toDouble(),
                            (network['rx'] ?? 0).toDouble());
                      }).toList(),
                      isCurved: true,
                      color: Colors.green,
                      barWidth: 2,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(
                        show: false,
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: context.downloadColor.withValues(alpha: .2),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _performanceNetworkWidget(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(CupertinoPageRoute(
            builder: (context) {
              return const Performance(
                tabIndex: 3,
              );
            },
            settings: const RouteSettings(name: "performance")));
      },
      child: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: AppConstants.paddingLarge),
        child: Row(
          children: [
            const SizedBox(width: 60, child: Text("网络：")),
            Icon(
              Icons.upload_sharp,
              color: context.uploadColor,
            ),
            Text(
              "${(utilization['network']?[0]?['tx'] ?? 0).formatSize()}/S",
              style: TextStyle(color: context.uploadColor),
            ),
            const SizedBox(
              width: 30,
            ),
            Icon(
              Icons.download_sharp,
              color: context.downloadColor,
            ),
            Text(
              "${(utilization['network'][0]['rx'] ?? 0).formatSize()}/S",
              style: TextStyle(color: context.downloadColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _performanceRamWidget(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(CupertinoPageRoute(
            builder: (context) {
              return const Performance(
                tabIndex: 2,
              );
            },
            settings: const RouteSettings(name: "performance")));
      },
      child: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: AppConstants.paddingLarge),
        child: Row(
          children: [
            const SizedBox(width: 60, child: Text("RAM：")),
            Expanded(
              child: FAProgressBar(
                backgroundColor: Colors.transparent,
                changeColorValue: 90,
                changeProgressColor: context.errorColor,
                progressColor: context.infoColor,
                displayTextStyle: TextStyle(
                    color: AppTheme.of(context).progressColor, fontSize: 12),
                currentValue: (utilization['memory']?['real_usage'] ?? 0),
                displayText: '%',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _performanceCpuWidget(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(CupertinoPageRoute(
            builder: (context) {
              return const Performance(
                tabIndex: 1,
              );
            },
            settings: const RouteSettings(name: "performance")));
      },
      child: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: AppConstants.paddingLarge),
        child: Row(
          children: [
            const SizedBox(
              width: 60,
              child: Text("CPU："),
            ),
            Expanded(
              child: FAProgressBar(
                backgroundColor: Colors.transparent,
                changeColorValue: 90,
                changeProgressColor: context.errorColor,
                progressColor: context.infoColor,
                displayTextStyle: TextStyle(
                    color: AppTheme.of(context).progressColor, fontSize: 12),
                currentValue: (utilization['cpu']?['user_load'] ?? 0) +
                    (utilization['cpu']?['system_load'] ?? 0),
                displayText: '%',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StorageUsageWidget extends StatelessWidget {
  const StorageUsageWidget(
      {super.key,
      required this.storageSsdCaches,
      required this.storageVolumes,
      required this.storageDisks,
      this.onTap});
  final ReadonlySignal<List> storageSsdCaches;
  final ReadonlySignal<List> storageVolumes;
  final ReadonlySignal<List> storageDisks;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Card(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.paddingSmall),
              child: Column(
                children: [
                  const SizedBox(
                    height: 20,
                  ),
                  Padding(
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
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w600),
                        ),
                        const Spacer(),
                        const DashboardCardItemCollapseIcon("StorageUsage")
                      ],
                    ),
                  ),
                  if (settingsStore.dashboardCardCollapseState
                          .watch(context)
                          .getBool('StorageUsage') ==
                      true)
                    ...storageVolumes
                        .map((volume) => VolumeCard(volume: volume)),
                  const SizedBox(
                    height: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
        Watch((_) {
          if (storageSsdCaches.isNotEmpty) {
            return Card(
              shape: RoundedRectangleBorder(
                  side: const BorderSide(),
                  borderRadius: BorderRadius.circular(18)),
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.paddingSmall),
                child: Column(
                  children: [
                    const SizedBox(
                      height: 20,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppConstants.paddingLarge),
                      child: Row(
                        children: [
                          Image.asset(
                            "assets/icons/cache.png",
                            width: 26,
                            height: 26,
                          ),
                          const SizedBox(
                            width: 10,
                          ),
                          const Text(
                            "缓存",
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w600),
                          ),
                          const Spacer(),
                          const DashboardCardItemCollapseIcon("StorageUsage")
                        ],
                      ),
                    ),
                    if (settingsStore.dashboardCardCollapseState.value
                            .getBool('StorageUsage') ==
                        true)
                      ...storageSsdCaches.map(
                          (volume) => VolumeCard(volume: volume, isSSD: true)),
                    const SizedBox(
                      height: 20,
                    ),
                  ],
                ),
              ),
            );
          } else {
            return Container();
          }
        })
      ],
    );
  }
}

class FileChangeLogWidget extends StatefulWidget {
  const FileChangeLogWidget({super.key});

  @override
  State<FileChangeLogWidget> createState() => _FileChangeLogWidgetState();
}

class _FileChangeLogWidgetState extends State<FileChangeLogWidget> with SignalsMixin {
  late final syslogs = createListSignal([]);
  @override
  Widget build(BuildContext context) {
    return Card(
      shape: context.stadiumShapeBorder,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingSmall),
        child: Column(
          children: [
            const SizedBox(
              height: 20,
            ),
            Padding(
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
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  const DashboardCardItemCollapseIcon("FileChangeLog")
                ],
              ),
            ),
            const SizedBox(
              height: 10,
            ),
            if (settingsStore.dashboardCardCollapseState
                    .watch(context)
                    .getBool('FileChangeLog') ==
                true)
              SizedBox(
                height: 300,
                child: syslogs.isNotEmpty
                    ? CupertinoScrollbar(
                        child: ListView.builder(
                          itemBuilder: (context, i) {
                            return DashboardFileLogItem(log: syslogs[i]);
                          },
                          itemCount: syslogs.length,
                        ),
                      )
                    : Center(
                        child: Text(
                          "暂无日志",
                          style: TextStyle(
                              color: AppTheme.of(context).placeholderColor),
                        ),
                      ),
              ),
            const SizedBox(
              height: 10,
            ),
          ],
        ),
      ),
    );
  }
}
