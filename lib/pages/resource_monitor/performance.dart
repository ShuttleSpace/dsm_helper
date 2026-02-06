import 'dart:async';

import 'package:garden/stores/settings_store.dart';
import 'package:garden/theme/app_theme.dart';
import 'package:garden/util/http_util.dart';
import 'package:garden/util/log.dart';
import 'package:garden/widgets/bubble_tab_indicator.dart';
import 'package:garden/widgets/neu_back_button.dart';
import 'package:garden/widgets/resource_monitor/cpu_tab.dart';
import 'package:garden/widgets/resource_monitor/memory_tab.dart';
import 'package:garden/widgets/resource_monitor/network_tab.dart';
import 'package:garden/widgets/resource_monitor/disk_tab.dart';
import 'package:garden/widgets/resource_monitor/storage_tab.dart';
import 'package:flutter/material.dart';
import 'package:garden/constants/app_constants.dart';
import 'package:signals_flutter/signals_flutter.dart';

/// 资源监控页面（优化版）
class Performance extends StatefulWidget {
  const Performance({super.key, this.tabIndex = 0});
  final int tabIndex;

  @override
  PerformanceState createState() => PerformanceState();
}

class PerformanceState extends State<Performance>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool loading = true;
  List cpus = [];
  List memories = [];
  List networks = [];
  List disks = [];
  List spaces = [];
  List luns = [];
  late Timer timer;
  int maxNetworkSpeed = 0;
  int maxDiskReadSpeed = 0;
  int maxDiskWriteSpeed = 0;
  int maxVolumeReadSpeed = 0;
  int maxVolumeWriteSpeed = 0;
  int networkCount = 0;

  // 图表颜色列表 - 使用主题语义颜色
  List<Color> get _chartColors {
    final theme = Theme.of(context);
    final appTheme = theme.extension<AppTheme>();
    return [
      appTheme?.errorColor ?? Colors.red,
      Colors.purpleAccent,
      Colors.redAccent,
      appTheme?.successColor ?? Colors.green,
      appTheme?.warningColor ?? Colors.amber,
      Colors.orange,
      Colors.teal,
      Colors.indigoAccent,
      Colors.cyanAccent,
      Colors.yellow,
      theme.colorScheme.onSurface,
      Colors.lightGreenAccent,
      Colors.pinkAccent
    ];
  }

  @override
  void initState() {
    _tabController =
        TabController(initialIndex: widget.tabIndex, length: 6, vsync: this);
    getData();
    timer = Timer.periodic(
        Duration(seconds: settingsStore.refreshDuration.watch(context)),
        (timer) {
      getData();
    });
    super.initState();
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }

  getData() async {
    var res = await DsmApi.utilization();
    Log.info("performance data: $res");
    if (res['success']) {
      if (mounted) {
        setState(() {
          loading = false;
          if (cpus.length > 30) {
            cpus.removeAt(0);
            disks.removeAt(0);
            luns.removeAt(0);
            memories.removeAt(0);
            networks.removeAt(0);
            spaces.removeAt(0);
          }
          List result = res['data']['result'];
          for (var item in result) {
            if (item['success'] == true) {
              switch (item['api']) {
                case "SYNO.Core.System.Utilization":
                  if (item['data']['cpu'] != null) {
                    cpus.add(item['data']);
                  }
                  if (item['data']['memory'] != null) {
                    memories.add(item['data']);
                  }
                  if (item['data']['network'] != null) {
                    networks.add(item['data']['network']);
                    num totalDownload = 0;
                    num totalUpload = 0;
                    item['data']['network'].forEach((net) {
                      totalDownload += net['download'];
                      totalUpload += net['upload'];
                    });
                    if (totalDownload > maxNetworkSpeed) {
                      maxNetworkSpeed = totalDownload.toInt();
                    }
                    if (totalUpload > maxNetworkSpeed) {
                      maxNetworkSpeed = totalUpload.toInt();
                    }
                  }
                  break;
                case "SYNO.Storage.CPUSHareStorage.Storage":
                  spaces.add(item['data']);
                  break;
                case "SYNO.Storage.CPUSHareStorage.LUN":
                  luns.add(item['data']);
                  break;
              }
            }
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: AppBackButton(context),
        title: const Text("资源监控"),
      ),
      body: Column(
        children: [
          Card(
            shape: RoundedRectangleBorder(
                side: const BorderSide(),
                borderRadius:
                    BorderRadius.circular(AppConstants.cardBorderRadius)),
            margin: const EdgeInsets.symmetric(
                vertical: AppConstants.paddingSmall,
                horizontal: AppConstants.paddingLarge),
            child: TabBar(
              dividerHeight: 0,
              isScrollable: false,
              controller: _tabController,
              indicatorSize: TabBarIndicatorSize.label,
              labelColor: Theme.brightnessOf(context) == Brightness.dark
                  ? Colors.white
                  : Colors.black,
              unselectedLabelColor: Colors.grey,
              indicator: const BubbleTabIndicator(),
              tabs: const [
                Padding(
                  padding: EdgeInsets.symmetric(
                      vertical: AppConstants.paddingSmall,
                      horizontal: AppConstants.paddingSmall),
                  child: Text("CPU"),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(
                      vertical: AppConstants.paddingSmall,
                      horizontal: AppConstants.paddingSmall),
                  child: Text("内存"),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(
                      vertical: AppConstants.paddingSmall,
                      horizontal: AppConstants.paddingSmall),
                  child: Text("网络"),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(
                      vertical: AppConstants.paddingSmall,
                      horizontal: AppConstants.paddingSmall),
                  child: Text("磁盘"),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(
                      vertical: AppConstants.paddingSmall,
                      horizontal: AppConstants.paddingSmall),
                  child: Text("存储空间"),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(
                      vertical: AppConstants.paddingSmall,
                      horizontal: AppConstants.paddingSmall),
                  child: Text("LUN"),
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                CpuTab(
                  loading: loading,
                  cpus: cpus,
                  colors: _chartColors,
                ),
                MemoryTab(
                  loading: loading,
                  memories: memories,
                  colors: _chartColors,
                ),
                NetworkTab(
                  loading: loading,
                  networks: networks,
                  maxSpeed: maxNetworkSpeed,
                  colors: _chartColors,
                ),
                DiskTab(
                  loading: loading,
                  disks: disks,
                  maxReadSpeed: maxDiskReadSpeed,
                  maxWriteSpeed: maxDiskWriteSpeed,
                  colors: _chartColors,
                ),
                StorageTab(
                  loading: loading,
                  data: spaces,
                  title: "存储空间",
                ),
                StorageTab(
                  loading: loading,
                  data: luns,
                  title: "LUN",
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
