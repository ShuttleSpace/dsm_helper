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
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:garden/constants/app_constants.dart';
import 'package:signals_hooks/signals_hooks.dart';

/// 资源监控页面（优化版）
class Performance extends HookWidget {
  const Performance({super.key, this.tabIndex = 0});
  final int tabIndex;

  @override
  Widget build(BuildContext context) {
    final tickerProvider = useSingleTickerProvider();
    final tabController = useMemoized(
      () => TabController(initialIndex: tabIndex, length: 6, vsync: tickerProvider),
      const [],
    );
    final loading = useSignal(true);
    final cpus = useSignal<List>([]);
    final memories = useSignal<List>([]);
    final networks = useSignal<List>([]);
    final disks = useSignal<List>([]);
    final spaces = useSignal<List>([]);
    final luns = useSignal<List>([]);
    final maxNetworkSpeed = useSignal(0);
    final maxDiskReadSpeed = useSignal(0);
    final maxDiskWriteSpeed = useSignal(0);

    // 图表颜色列表 - 使用主题语义颜色
    List<Color> chartColors() {
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

    getData() async {
      var res = await DsmApi.utilization();
      Log.info("performance data: $res");
      if (res['success']) {
        if (context.mounted) {
          loading.value = false;
          if (cpus.value.length > 30) {
            cpus.value = List.of(cpus.value)..removeAt(0);
            disks.value = List.of(disks.value)..removeAt(0);
            luns.value = List.of(luns.value)..removeAt(0);
            memories.value = List.of(memories.value)..removeAt(0);
            networks.value = List.of(networks.value)..removeAt(0);
            spaces.value = List.of(spaces.value)..removeAt(0);
          }
          List result = res['data']['result'];
          for (var item in result) {
            if (item['success'] == true) {
              switch (item['api']) {
                case "SYNO.Core.System.Utilization":
                  if (item['data']['cpu'] != null) {
                    cpus.value = [...cpus.value, item['data']];
                  }
                  if (item['data']['memory'] != null) {
                    memories.value = [...memories.value, item['data']];
                  }
                  if (item['data']['network'] != null) {
                    networks.value = [
                      ...networks.value,
                      item['data']['network']
                    ];
                    num totalDownload = 0;
                    num totalUpload = 0;
                    item['data']['network'].forEach((net) {
                      totalDownload += net['download'];
                      totalUpload += net['upload'];
                    });
                    if (totalDownload > maxNetworkSpeed.value) {
                      maxNetworkSpeed.value = totalDownload.toInt();
                    }
                    if (totalUpload > maxNetworkSpeed.value) {
                      maxNetworkSpeed.value = totalUpload.toInt();
                    }
                  }
                  break;
                case "SYNO.Storage.CPUSHareStorage.Storage":
                  spaces.value = [...spaces.value, item['data']];
                  break;
                case "SYNO.Storage.CPUSHareStorage.LUN":
                  luns.value = [...luns.value, item['data']];
                  break;
              }
            }
          }
        }
      }
    }

    useEffect(() {
      getData();
      final timer = Timer.periodic(
          Duration(seconds: settingsStore.refreshDuration.value), (timer) {
        // getData();
      });
      return () {
        timer.cancel();
        tabController.dispose();
      };
    }, const []);

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
              controller: tabController,
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
              controller: tabController,
              children: [
                CpuTab(
                  loading: loading.value,
                  cpus: cpus.value,
                  colors: chartColors(),
                ),
                MemoryTab(
                  loading: loading.value,
                  memories: memories.value,
                  colors: chartColors(),
                ),
                NetworkTab(
                  loading: loading.value,
                  networks: networks.value,
                  maxSpeed: maxNetworkSpeed.value,
                  colors: chartColors(),
                ),
                DiskTab(
                  loading: loading.value,
                  disks: disks.value,
                  maxReadSpeed: maxDiskReadSpeed.value,
                  maxWriteSpeed: maxDiskWriteSpeed.value,
                  colors: chartColors(),
                ),
                StorageTab(
                  loading: loading.value,
                  data: spaces.value,
                  title: "存储空间",
                ),
                StorageTab(
                  loading: loading.value,
                  data: luns.value,
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
