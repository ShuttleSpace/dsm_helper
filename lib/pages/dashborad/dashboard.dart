import 'dart:async';
import 'package:garden/stores/settings_store.dart';
import 'package:garden/stores/connection_store.dart';
import 'dart:math';

import 'package:garden/models/api_model.dart';
import 'package:garden/models/shortcut_item_model.dart';
import 'package:garden/models/wallpaper_model.dart';
import 'package:garden/pages/control_panel/external_device/external_device.dart';
import 'package:garden/pages/control_panel/info/info.dart';
import 'package:garden/pages/control_panel/task_scheduler/task_scheduler.dart';
import 'package:garden/pages/dashborad/applications.dart';
import 'package:garden/pages/dashborad/media_converter.dart';
import 'package:garden/pages/dashborad/shortcut_list.dart';
import 'package:garden/pages/dashborad/widget_setting.dart';
import 'package:garden/pages/log_center/log_center.dart';
import 'package:garden/pages/notify/notify.dart';
import 'package:garden/pages/resource_monitor/performance.dart';
import 'package:garden/pages/resource_monitor/resource_monitor.dart';
import 'package:garden/theme/app_theme.dart';
import 'package:garden/util/http_util.dart';
import 'package:garden/util/log.dart';
import 'package:garden/widgets/animation_progress_bar.dart';
import 'package:garden/widgets/dashboard/dashboard_log_item.dart';
import 'package:garden/widgets/dashboard/dashboard_task_item.dart';
import 'package:garden/widgets/dashboard/dashboard_user_item.dart';
import 'package:garden/widgets/dashboard/esata_device_card.dart';
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

class DashboardState extends State<Dashboard> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  Map utilization = {};
  List volumes = [];
  List disks = [];
  List connectedUsers = [];
  List interfaces = [];
  List networks = [];
  List ssdCaches = [];
  List tasks = [];
  List latestLog = [];
  List notifies = [];
  List widgets = [];
  List applications = [];
  List fileLogs = [];
  List<ShortcutItemModel> shortcutItems = [];
  List validAppViewOrder = [];
  WallpaperModel? wallpaperModel;
  List esatas = [];
  List usbs = [];
  Map appNotify = {};
  Map system = {};
  Map restoreSizePos = {};
  Map converter = {};
  bool loading = true;
  bool success = true;
  int refreshDuration = 10;
  String hostname = "获取中";
  int get maxNetworkSpeed {
    int maxSpeed = 0;
    for (int i = 0; i < networks.length; i++) {
      int maxVal = max(networks[i]['rx'], networks[i]['tx']);
      if (maxSpeed < maxVal) {
        maxSpeed = maxVal;
      }
    }
    return maxSpeed;
  }

  Map volWarnings = {};
  String msg = "";

  // 主题颜色 - 根据 AppTheme 获取
  Color get _errorColor =>
      Theme.of(context).extension<AppTheme>()?.errorColor ?? Colors.redAccent;
  Color get _successColor =>
      Theme.of(context).extension<AppTheme>()?.successColor ?? Colors.teal;
  Color get _infoColor =>
      Theme.of(context).extension<AppTheme>()?.infoColor ?? Colors.limeAccent;
  Color get _uploadColor => Colors.blueAccent;
  Color get _downloadColor => _successColor;
  Color get _chartTextColor =>
      Theme.of(context).colorScheme.onSurface.withAlpha(153);

  @override
  void initState() {
    // getGroups();
    networks = List.generate(20, (i) => {"tx": 0, "rx": 0});
    getNotifyStrings();
    SynoApiInfo.fetch().then((apis) {
      DsmApi.apiList = apis;
    });
    getInfo().then((_) {
      getData(init: true);
    });
    super.initState();
  }

  bool get isDrawerOpen {
    return _scaffoldKey.currentState?.isDrawerOpen ?? false;
  }

  closeDrawer() {
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      Navigator.of(context).pop();
    }
  }

  getNotifyStrings() async {
    var res = await DsmApi.notifyStrings();
    Log.debug("notifyStrings");
    if (res['success']) {
      setState(() {
        connectionStore.setNotifyStrings(res['data'] ?? {});
      });
    }
  }

  getExternalDevice() async {
    var res = await DsmApi.externalDevice();
    if (res['success']) {
      List result = res['data']['result'];
      for (var item in result) {
        if (item['success'] == true) {
          switch (item['api']) {
            case "SYNO.Core.ExternalDevice.Storage.eSATA":
              setState(() {
                esatas = item['data']['devices'];
              });
              break;
            case "SYNO.Core.ExternalDevice.Storage.USB":
              setState(() {
                usbs = item['data']['devices'];
              });
              break;
          }
        }
      }
    }
  }

  getMediaConverter() async {
    var res = await DsmApi.mediaConverter("status");
    if (res['success'] && mounted) {
      setState(() {
        converter = res['data'];
        if (((converter['photo_remain'] ?? 0) +
                (converter['thumb_remain'] ?? 0) +
                (converter['video_remain'] ?? 0) >
            0)) {
          Future.delayed(const Duration(seconds: 5))
              .then((value) => getMediaConverter());
        }
      });
    }
  }

  Future<void> getInfo() async {
    var init = await DsmApi.initData();
    if (init['success']) {
      setState(() {
        if (init['data']['UserSettings'] != null) {
          if (init['data']['UserSettings']['SYNO.SDS._Widget.Instance'] !=
              null) {
            widgets = init['data']['UserSettings']['SYNO.SDS._Widget.Instance']
                    ['modulelist'] ??
                [];
            restoreSizePos = init['data']['UserSettings']
                    ['SYNO.SDS._Widget.Instance']['restoreSizePos'] ??
                {};
          }
          if (init['data']['UserSettings']['Desktop'] != null) {
            applications = init['data']['UserSettings']['Desktop']
                    ['valid_appview_order'] ??
                init['data']['UserSettings']['Desktop']['appview_order'] ??
                [];

            shortcutItems = ShortcutItemModel.fromList(
                init['data']['UserSettings']['Desktop']['ShortcutItems']);
            validAppViewOrder =
                init['data']['UserSettings']['Desktop']['valid_appview_order'];
            wallpaperModel = WallpaperModel.fromJson(
                init['data']['UserSettings']['Desktop']['wallpaper']);
          }
        }
        if (init['data']['Session'] != null) {
          hostname = init['data']['Session']['hostname'];
          connectionStore.setHostname(hostname);
        }
        if (init['data']['Strings'] != null) {
          connectionStore.setStrings(init['data']['Strings'] ?? {});
        }
      });
    }
  }

  getData({bool init = false}) async {
    getExternalDevice();
    getMediaConverter();
    var res = await DsmApi.systemInfo(widgets);

    if (res['success']) {
      if (!mounted) {
        return;
      }

      setState(() {
        loading = false;
        success = true;
      });

      List result = res['data']['result'];
      for (var item in result) {
        if (item['success'] == true) {
          switch (item['api']) {
            case "SYNO.Core.System.Utilization":
              setState(() {
                utilization = item['data'];
                if (networks.length > 20) {
                  networks.removeAt(0);
                }
                networks.add(item['data']['network'][0]);
              });
              break;
            case "SYNO.Core.System":
              setState(() {
                system = item['data'];
                settingsStore.setFirmwareVersion(system['firmware_ver']);
              });
              break;
            case "SYNO.Core.CurrentConnection":
              setState(() {
                connectedUsers = item['data']['items'];
              });
              break;
            case "SYNO.Storage.CGI.Storage":
              setState(() {
                ssdCaches = item['data']['ssdCaches'];
                volumes = item['data']['volumes'];
                volumes.sort((a, b) {
                  return a['num_id'].compareTo(b['num_id']);
                });
                disks = item['data']['disks'];
              });
              break;
            case 'SYNO.Core.TaskScheduler':
              setState(() {
                tasks = item['data']['tasks'];
              });
              break;
            case 'SYNO.Core.SyslogClient.Status':
              setState(() {
                latestLog = item['data']['logs'];
              });
              break;
            case "SYNO.Core.DSMNotify":
              setState(() {
                notifies = item['data']['items'];
              });
              break;
            case "SYNO.Core.AppNotify":
              setState(() {
                appNotify = item['data'];
              });
              break;
            case "SYNO.Core.SyslogClient.Log":
              setState(() {
                fileLogs = item['data']['items'];
              });
              break;
          }
        }

        // else if(item['api'] == ""){
        //
        // }
      }
    } else {
      setState(() {
        if (loading) {
          success = res['success'];
          loading = false;
        }

        msg = res['msg'] ?? "加载失败，code:${res['error']['code']}";
      });
    }
    if (init && mounted) {
      Future.delayed(Duration(seconds: refreshDuration)).then((value) {
        getData(init: init);
      });
      return;
    }
  }

  bool _isCardItemCollapsed(String itemName) =>
      settingsStore.dashboardCardCollapseState[itemName] == true;

  Widget _cardItemCollapse(String itemName) {
    return IconButton(
        onPressed: () {
          setState(() {
            settingsStore.dashboardCardCollapseState.watch(context)[itemName] =
                !(_isCardItemCollapsed(itemName));
          });
        },
        icon: Icon(_isCardItemCollapsed(itemName)
            ? Icons.unfold_less
            : Icons.unfold_more));
  }

  Widget _buildWidgetItem(widget) {
    if (widget == "SYNO.SDS.SystemInfoApp.SystemHealthWidget") {
      return GestureDetector(
        onTap: () {
          if (connectionStore.notReviewAccount.watch(context)) {
            Navigator.of(context).push(CupertinoPageRoute(builder: (context) {
              return SystemInfo(0, system, volumes, disks);
            }));
          }
        },
        child: Card(
          shape: RoundedRectangleBorder(
              side: const BorderSide(),
              borderRadius: BorderRadius.circular(18)),
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.paddingSmall),
            child: Stack(
              children: [
                Watch(
                  (context) {
                    return Stack(
                      children: [
                        if (settingsStore.showWallpaper.watch(context) &&
                            wallpaperModel != null &&
                            (wallpaperModel!.customizeWallpaper == true ||
                                wallpaperModel!.customizeBackground == true))
                          ExtendedImage.network(
                            "${connectionStore.baseUrl}/webapi/entry.cgi?api=SYNO.Core.PersonalSettings&method=wallpaper&version=1&path=%22%22&retina=true&_sid=${connectionStore.sid}",
                            height: 170,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            shape: BoxShape.rectangle,
                            borderRadius: BorderRadius.circular(20),
                          ),
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
                            padding: const EdgeInsets.all(20),
                            child: DefaultTextStyle(
                              style: TextStyle(
                                color: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.color,
                              ),
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
                                            fontSize: 18,
                                            fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(
                                    height: 5,
                                  ),
                                  if (system['model'] != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 5),
                                      child: Row(
                                        children: [
                                          const Text("产品型号："),
                                          Text("${system['model']}"),
                                        ],
                                      ),
                                    ),
                                  const SizedBox(
                                    height: 5,
                                  ),
                                  Row(
                                    children: [
                                      const Text("系统名称："),
                                      Text(hostname),
                                    ],
                                  ),
                                  if (system['sys_temp'] != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 5),
                                      child: Row(
                                        children: [
                                          const Text("散热状态："),
                                          Text(
                                            "${system['sys_temp']}℃ ${system['temperature_warning'] == null ? (system['sys_temp'] > 80 ? "警告" : "正常") : (system['temperature_warning'] ? "警告" : "正常")}",
                                            style: TextStyle(
                                                color: system[
                                                            'temperature_warning'] ==
                                                        null
                                                    ? (system['sys_temp'] > 80
                                                        ? _errorColor
                                                        : _successColor)
                                                    : (system[
                                                            'temperature_warning']
                                                        ? _errorColor
                                                        : _successColor)),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  if (system['up_time'] != null &&
                                      system['up_time'] != "")
                                    Padding(
                                      padding: const EdgeInsets.only(top: 5),
                                      child: Row(
                                        children: [
                                          const Text("运行时间："),
                                          Text(parseOpTime(system['up_time'])),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      );
    } else if (widget == "SYNO.SDS.SystemInfoApp.ConnectionLogWidget" &&
        connectedUsers.isNotEmpty) {
      return Card(
        shape: RoundedRectangleBorder(
            side: const BorderSide(), borderRadius: BorderRadius.circular(18)),
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
                      "assets/icons/user.png",
                      width: 26,
                      height: 26,
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                    const Text(
                      "登录用户",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    const Spacer(),
                    _cardItemCollapse("ConnectionLog")
                  ],
                ),
              ),
              if (_isCardItemCollapsed('ConnectionLog'))
                ...connectedUsers.map((user) => DashboardUserItem(
                      user: user,
                      onKickSuccess: getData,
                    )),
              const SizedBox(
                height: 20,
              ),
            ],
          ),
        ),
      );
    } else if (widget == "SYNO.SDS.TaskScheduler.TaskSchedulerWidget") {
      return GestureDetector(
        onTap: () {
          Navigator.of(context).push(CupertinoPageRoute(builder: (context) {
            return const TaskScheduler();
          }));
        },
        child: Card(
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
                        "assets/icons/task.png",
                        width: 26,
                        height: 26,
                      ),
                      const SizedBox(
                        width: 10,
                      ),
                      const Text(
                        "计划任务",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                      const Spacer(),
                      _cardItemCollapse("TaskScheduler")
                    ],
                  ),
                ),
                if (_isCardItemCollapsed('TaskScheduler'))
                  ...tasks.map((task) => DashboardTaskItem(task: task)),
                const SizedBox(
                  height: 20,
                ),
              ],
            ),
          ),
        ),
      );
    } else if (widget == "SYNO.SDS.SystemInfoApp.RecentLogWidget") {
      return GestureDetector(
        onTap: () {
          Navigator.of(context).push(CupertinoPageRoute(
              builder: (context) {
                return const LogCenter();
              },
              settings: const RouteSettings(name: "log_center")));
        },
        child: Card(
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
                        "assets/icons/log.png",
                        width: 26,
                        height: 26,
                      ),
                      const SizedBox(
                        width: 10,
                      ),
                      const Text(
                        "最新日志",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                      const Spacer(),
                      _cardItemCollapse("RecentLog")
                    ],
                  ),
                ),
                const SizedBox(
                  height: 10,
                ),
                if (_isCardItemCollapsed('RecentLog'))
                  SizedBox(
                    height: 300,
                    child: latestLog.isNotEmpty
                        ? CupertinoScrollbar(
                            child: ListView.builder(
                              itemBuilder: (context, i) {
                                return DashboardLogItem(log: latestLog[i]);
                              },
                              itemCount: latestLog.length,
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
    } else if (widget == "SYNO.SDS.ResourceMonitor.Widget") {
      return GestureDetector(
        onTap: () {
          Navigator.of(context).push(CupertinoPageRoute(builder: (context) {
            return const ResourceMonitor();
          }));
        },
        child: Card(
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
                        "assets/icons/resources.png",
                        width: 26,
                        height: 26,
                      ),
                      const SizedBox(
                        width: 10,
                      ),
                      const Text(
                        "资源监控",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                      const Spacer(),
                      _cardItemCollapse("ResourceMonitor")
                    ],
                  ),
                ),
                if (_isCardItemCollapsed('ResourceMonitor')) ...[
                  const SizedBox(
                    height: 10,
                  ),
                  GestureDetector(
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppConstants.paddingLarge),
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
                              changeProgressColor: _errorColor,
                              progressColor: _infoColor,
                              displayTextStyle: TextStyle(
                                  color: AppTheme.of(context).progressColor,
                                  fontSize: 12),
                              currentValue:
                                  (utilization['cpu']?['user_load'] ?? 0) +
                                      (utilization['cpu']?['system_load'] ?? 0),
                              displayText: '%',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 15,
                  ),
                  GestureDetector(
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppConstants.paddingLarge),
                      child: Row(
                        children: [
                          const SizedBox(width: 60, child: Text("RAM：")),
                          Expanded(
                            child: FAProgressBar(
                              backgroundColor: Colors.transparent,
                              changeColorValue: 90,
                              changeProgressColor: _errorColor,
                              progressColor: _infoColor,
                              displayTextStyle: TextStyle(
                                  color: AppTheme.of(context).progressColor,
                                  fontSize: 12),
                              currentValue:
                                  (utilization['memory']?['real_usage'] ?? 0),
                              displayText: '%',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 15,
                  ),
                  GestureDetector(
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppConstants.paddingLarge),
                      child: Row(
                        children: [
                          const SizedBox(width: 60, child: Text("网络：")),
                          Icon(
                            Icons.upload_sharp,
                            color: _uploadColor,
                          ),
                          Text(
                            "${(utilization['network']?[0]?['tx'] ?? 0).formatSize()}/S",
                            style: TextStyle(color: _uploadColor),
                          ),
                          const SizedBox(
                            width: 30,
                          ),
                          Icon(
                            Icons.download_sharp,
                            color: _downloadColor,
                          ),
                          Text(
                            "${(utilization['network'][0]['rx'] ?? 0).formatSize()}/S",
                            style: TextStyle(color: _downloadColor),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 5,
                  ),
                  GestureDetector(
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
                                    tooltipBorder: BorderSide(
                                        color:
                                            Colors.white.withValues(alpha: .6)),
                                    tooltipRoundedRadius: 20,
                                    fitInsideHorizontally: true,
                                    fitInsideVertically: true,
                                    getTooltipItems: (List<LineBarSpot> items) {
                                      return items
                                          .map((LineBarSpot touchedSpot) {
                                        final textStyle = TextStyle(
                                          color: touchedSpot.bar.color,
                                          // color: touchedSpot.bar.colors[0],
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        );
                                        return LineTooltipItem(
                                            '${touchedSpot.bar.color == _uploadColor ? "上传" : "下载"}:${(touchedSpot.y.floor()).formatSize()}',
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
                                      // getTextStyles: (value, _) => const TextStyle(
                                      //   color: Color(0xff67727d),
                                      //   fontSize: 12,
                                      // ),
                                      // getTitles: chartTitle,
                                      getTitlesWidget: (value, _) {
                                        return Text(
                                            (value.toInt())
                                                .formatSize(fixed: 0),
                                            style: TextStyle(
                                              color: _chartTextColor,
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
                                    border: Border.all(
                                        color: Colors.black12, width: 1)),
                                lineBarsData: [
                                  LineChartBarData(
                                    spots: networks.map((network) {
                                      return FlSpot(
                                          networks.indexOf(network).toDouble(),
                                          network['tx'].toDouble());
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
                                      color: _uploadColor.withValues(alpha: .2),
                                    ),
                                  ),
                                  LineChartBarData(
                                    spots: networks.map((network) {
                                      return FlSpot(
                                          networks.indexOf(network).toDouble(),
                                          network['rx'].toDouble());
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
                                      color:
                                          _downloadColor.withValues(alpha: .2),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    } else if (widget == "SYNO.SDS.SystemInfoApp.StorageUsageWidget") {
      return Column(
        children: [
          GestureDetector(
            onTap: () {
              Navigator.of(context).push(CupertinoPageRoute(builder: (context) {
                return SystemInfo(2, system, volumes, disks);
              }));
            },
            child: Card(
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
                          _cardItemCollapse("StorageUsage")
                        ],
                      ),
                    ),
                    if (_isCardItemCollapsed('StorageUsage'))
                      ...volumes.map((volume) => VolumeCard(volume: volume)),
                    const SizedBox(
                      height: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (ssdCaches.isNotEmpty)
            Card(
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
                          _cardItemCollapse("StorageUsage")
                        ],
                      ),
                    ),
                    if (_isCardItemCollapsed('StorageUsage'))
                      ...ssdCaches.map(
                          (volume) => VolumeCard(volume: volume, isSSD: true)),
                    const SizedBox(
                      height: 20,
                    ),
                  ],
                ),
              ),
            )
        ],
      );
    } else if (widget == "SYNO.SDS.SystemInfoApp.FileChangeLogWidget") {
      return Card(
        shape: RoundedRectangleBorder(
            side: const BorderSide(), borderRadius: BorderRadius.circular(18)),
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
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    const Spacer(),
                    _cardItemCollapse("FileChangeLog")
                  ],
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              if (_isCardItemCollapsed('FileChangeLog'))
                SizedBox(
                  height: 300,
                  child: fileLogs.isNotEmpty
                      ? CupertinoScrollbar(
                          child: ListView.builder(
                            itemBuilder: (context, i) {
                              return DashboardFileLogItem(log: fileLogs[i]);
                            },
                            itemCount: fileLogs.length,
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
    } else {
      return Container();
    }
  }

  @override
  Widget build(BuildContext context) {
    refreshDuration = settingsStore.refreshDuration.watch(context);
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Stack(
          alignment: Alignment.center,
          children: [
            Row(
              children: [
                if (connectionStore.notReviewAccount.watch(context))
                  Padding(
                    padding: const EdgeInsets.only(left: 10, top: 8, bottom: 8),
                    child: OutlinedButton(
                      onPressed: () {
                        _scaffoldKey.currentState?.openDrawer();
                      },
                      child: Image.asset(
                        "assets/icons/application.png",
                        width: 20,
                      ),
                    ),
                  ),
                if ((esatas + usbs).isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(left: 10, top: 8, bottom: 8),
                    child: OutlinedButton(
                      onPressed: () {
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
                                    padding: const EdgeInsets.all(20),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: <Widget>[
                                        const Text(
                                          "外接设备",
                                          style: TextStyle(
                                              fontSize: 20,
                                              color: Colors.black,
                                              fontWeight: FontWeight.w500),
                                        ),
                                        const SizedBox(
                                          height: 12,
                                        ),
                                        ...(esatas + usbs)
                                            .map((esata) => ESataDeviceCard(
                                                  esata: esata,
                                                  onEjectSuccess: getData,
                                                )),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: OutlinedButton(
                                                onPressed: () async {
                                                  Navigator.of(context).push(
                                                      CupertinoPageRoute(
                                                          builder: (context) {
                                                            return const ExternalDevice();
                                                          },
                                                          settings:
                                                              const RouteSettings(
                                                                  name:
                                                                      "external_device")));
                                                },
                                                child: const Text(
                                                  "查看详情",
                                                  style:
                                                      TextStyle(fontSize: 18),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(
                                              width: 16,
                                            ),
                                            Expanded(
                                              child: OutlinedButton(
                                                onPressed: () async {
                                                  Navigator.of(context).pop();
                                                },
                                                child: const Text(
                                                  "取消",
                                                  style:
                                                      TextStyle(fontSize: 18),
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
                      },
                      child: Image.asset(
                        "assets/icons/external_devices.png",
                        width: 20,
                      ),
                    ),
                  ),
                if (((converter['photo_remain'] ?? 0) +
                        (converter['thumb_remain'] ?? 0) +
                        (converter['video_remain'] ?? 0) >
                    0))
                  Padding(
                    padding: const EdgeInsets.only(left: 10, top: 8, bottom: 8),
                    child: OutlinedButton(
                      onPressed: () {
                        showCupertinoModalPopup(
                            context: context,
                            builder: (context) {
                              return MediaConverter(converter);
                            });
                      },
                      child: Image.asset(
                        "assets/icons/converter.gif",
                        width: 20,
                      ),
                    ),
                  ),
                const Spacer(),
                if (connectionStore.notReviewAccount.watch(context))
                  Padding(
                    padding: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(context)
                            .push(CupertinoPageRoute(builder: (context) {
                          return WidgetSetting(widgets, restoreSizePos);
                        })).then((res) {
                          if (res != null) {
                            setState(() {
                              widgets = res;
                              getData();
                            });
                          }
                        });
                      },
                      child: Image.asset(
                        "assets/icons/edit.png",
                        width: 20,
                        height: 20,
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(context)
                          .push(CupertinoPageRoute(
                              builder: (context) {
                                return Notify(notifies);
                              },
                              settings: const RouteSettings(name: "notify")))
                          .then((res) {
                        if (res != null && res) {
                          setState(() {
                            notifies = [];
                          });
                        }
                      });
                    },
                    child: Stack(
                      alignment: Alignment.topRight,
                      children: [
                        Image.asset(
                          "assets/icons/message.png",
                          width: 20,
                          height: 20,
                        ),
                        if (notifies.isNotEmpty)
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            width: 5,
                            height: 5,
                          )
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const Text("控制台")
          ],
        ),
        automaticallyImplyLeading: false,
      ),
      body: loading
          ? const Center(
              child: CupertinoActivityIndicator(
                radius: 14,
              ),
            )
          : success
              ? ListView(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  children: [
                    if (shortcutItems
                            .where((element) =>
                                supportedShortcuts.contains(element.className))
                            .isNotEmpty &&
                        connectionStore.notReviewAccount.watch(context) &&
                        settingsStore.showShortcut.watch(context))
                      ShortcutList(
                        shortcutItems,
                        system,
                        volumes,
                        disks,
                        appNotify,
                        context,
                        validAppViewOrder: validAppViewOrder,
                      ),
                    if (widgets.isNotEmpty)
                      ...widgets.map((widget) {
                        return _buildWidgetItem(widget);
                        // return Text(widget);
                      })
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
                                  Navigator.of(context).push(
                                      CupertinoPageRoute(builder: (context) {
                                    return WidgetSetting(
                                        widgets, restoreSizePos);
                                  })).then((res) {
                                    if (res != null) {
                                      setState(() {
                                        widgets = res;
                                        getData();
                                      });
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
                )
              : Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(msg),
                      const SizedBox(
                        height: 20,
                      ),
                      SizedBox(
                        width: 200,
                        child: OutlinedButton(
                          onPressed: () {
                            getData();
                          },
                          child: const Text(
                            ' 刷新 ',
                            style: TextStyle(fontSize: 18),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
      drawer: applications.isNotEmpty
          ? ApplicationList(applications, system, volumes, disks, appNotify)
          : null,
    );
  }
}
