import 'package:garden/api/dsm_api.dart';
import 'package:garden/util/http_util.dart';
import 'package:garden/util/log.dart';
import 'package:garden/widgets/bubble_tab_indicator.dart';
import 'package:garden/widgets/dashboard/volume_card.dart';
import 'package:garden/widgets/neu_back_button.dart';
import 'package:garden/widgets/system_info/dev_item.dart';
import 'package:garden/widgets/system_info/disk_item.dart';
import 'package:garden/widgets/system_info/nif_item.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:garden/constants/app_constants.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:signals_hooks/signals_hooks.dart';

class SystemInfo extends HookWidget {
  const SystemInfo(
      this.index, this.systemData, this.storageVolumes, this.storageDisks,
      {super.key});
  final int index;
  final ReadonlySignal<Map> systemData;
  final ReadonlySignal<List> storageVolumes;
  final ReadonlySignal<List> storageDisks;

  @override
  Widget build(BuildContext context) {
    final tickerProvider = useSingleTickerProvider();
    final tabController = useMemoized(
      () =>
          TabController(initialIndex: index, length: 6, vsync: tickerProvider),
      const [],
    );
    final usbDev = useComputed(() => systemData['usb_dev'] ?? 0);
    final nifs = useListSignal([]);
    final volumes = useFutureSignal<List>(() async {
      if (storageVolumes.isNotEmpty) {
        return Future.value(storageVolumes.value);
      }
      final res = await dsmStorageCGIStorageLoadInfo();
      final d = res['volumes'];
      d.sort((a, b) {
        return a['num_id'].compareTo(b['num_id']);
      });
      return Future.value(d);
    });
    final disks = useFutureSignal<List>(() async {
      if (storageDisks.isNotEmpty) {
        return Future.value(storageDisks.value);
      }
      final res = await dsmStorageCGIStorageLoadInfo();
      return Future.value(res['disks']);
    });
    final network = useMapSignal({});

    getData() async {
      try {
        final res = await dsmCoreNetworkGet();
        network.value = res;
        nifs.value = network['nif'] ?? [];
      } catch (e) {
        Log.error('dsmCoreNetworkGet: $e');
      }
    }

    Widget buildVolume() {
      return switch (volumes.value) {
        AsyncData(:final value) => Card(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.paddingSmall),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(left: 20, top: 20),
                    child: Text(
                      "存储空间",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                  ),
                  ...value.map((volume) => VolumeCard(volume: volume)),
                  const SizedBox(
                    height: 20,
                  ),
                ],
              ),
            ),
          ),
        AsyncError(:final error) => Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Oops! $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => volumes.reload(),
                child: const Text('Retry'),
              ),
            ],
          ),
        _ => const Center(
            child: CupertinoActivityIndicator(
              radius: 14,
            ),
          )
      };
    }

    Widget buildDisk() {
      return switch (disks.value) {
        AsyncData(:final value) => Card(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.paddingSmall),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(left: 20, top: 20),
                    child: Text(
                      "硬盘",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                  ),
                  ...value.map((disk) => SystemDiskItem(disk)),
                  const SizedBox(
                    height: 20,
                  ),
                ],
              ),
            ),
          ),
        AsyncError(:final error) => Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Oops! $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => disks.reload(),
                child: const Text('Retry'),
              ),
            ],
          ),
        _ => const Center(
            child: CupertinoActivityIndicator(
              radius: 14,
            ),
          )
      };
    }

    useEffect(() {
      getData();
      return () {
        tabController.dispose();
      };
    }, const []);

    return Scaffold(
      appBar: AppBar(
        leading: AppBackButton(context),
        title: const Text(
          "信息中心",
        ),
      ),
      body: Column(
        children: [
          Card(
            shape: RoundedRectangleBorder(
                side: const BorderSide(),
                borderRadius: BorderRadius.circular(18)),
            margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
            child: TabBar(
              dividerHeight: 0,
              isScrollable: true,
              controller: tabController,
              indicatorSize: TabBarIndicatorSize.label,
              labelColor: Theme.brightnessOf(context) == Brightness.dark
                  ? Colors.white
                  : Colors.black,
              unselectedLabelColor: Colors.grey,
              indicator: const BubbleTabIndicator(),
              tabs: const [
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 10, horizontal: 5),
                  child: Text("常规"),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 10, horizontal: 5),
                  child: Text("网络"),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 10, horizontal: 5),
                  child: Text("存储"),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 10, horizontal: 5),
                  child: Text("服务"),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 10, horizontal: 5),
                  child: Text("设备分析"),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 10, horizontal: 5),
                  child: Text("Synology账户"),
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: tabController,
              children: [
                ListView(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  children: [
                    Card(
                      shape: RoundedRectangleBorder(
                          side: const BorderSide(),
                          borderRadius: BorderRadius.circular(18)),
                      margin: const EdgeInsets.only(left: 20, right: 20),
                      child: Padding(
                        padding:
                            const EdgeInsets.all(AppConstants.paddingSmall),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(top: 20, left: 20),
                              child: Text(
                                "基本信息",
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.w600),
                              ),
                            ),
                            Card(
                              shape: RoundedRectangleBorder(
                                  side: const BorderSide(),
                                  borderRadius: BorderRadius.circular(18)),
                              margin: const EdgeInsets.only(
                                  top: 20, left: 20, right: 20),
                              child: Padding(
                                padding: const EdgeInsets.all(
                                    AppConstants.paddingSmall),
                                child: Row(
                                  children: [
                                    const Expanded(
                                      child: Text(
                                        "产品序列号",
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        "${systemData['serial']}",
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Card(
                              shape: RoundedRectangleBorder(
                                  side: const BorderSide(),
                                  borderRadius: BorderRadius.circular(18)),
                              margin: const EdgeInsets.only(
                                  top: 20, left: 20, right: 20),
                              child: Padding(
                                padding: const EdgeInsets.all(
                                    AppConstants.paddingSmall),
                                child: Row(
                                  children: [
                                    const Expanded(
                                      child: Text(
                                        "产品型号",
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        "${systemData['model']}",
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Card(
                              shape: RoundedRectangleBorder(
                                  side: const BorderSide(),
                                  borderRadius: BorderRadius.circular(18)),
                              margin: const EdgeInsets.only(
                                  top: 20, left: 20, right: 20),
                              child: Padding(
                                padding: const EdgeInsets.all(
                                    AppConstants.paddingSmall),
                                child: Row(
                                  children: [
                                    const Expanded(
                                      child: Text(
                                        "CPU",
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        "${systemData['cpu_vendor']} ${systemData['cpu_family']} ${systemData['cpu_series']}",
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Card(
                              shape: RoundedRectangleBorder(
                                  side: const BorderSide(),
                                  borderRadius: BorderRadius.circular(18)),
                              margin: const EdgeInsets.only(
                                  top: 20, left: 20, right: 20),
                              child: Padding(
                                padding: const EdgeInsets.all(
                                    AppConstants.paddingSmall),
                                child: Row(
                                  children: [
                                    const Expanded(
                                      child: Text(
                                        "CPU核心",
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        "${systemData['cpu_cores']}核 @ ${(systemData['cpu_clock_speed'] / 1000).toStringAsFixed(2)}GHz",
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Card(
                              shape: RoundedRectangleBorder(
                                  side: const BorderSide(),
                                  borderRadius: BorderRadius.circular(18)),
                              margin: const EdgeInsets.only(
                                  top: 20, left: 20, right: 20),
                              child: Padding(
                                padding: const EdgeInsets.all(
                                    AppConstants.paddingSmall),
                                child: Row(
                                  children: [
                                    const Expanded(
                                      child: Text(
                                        "物理内存",
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        "${systemData['ram_size']}MB",
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Card(
                              shape: RoundedRectangleBorder(
                                  side: const BorderSide(),
                                  borderRadius: BorderRadius.circular(18)),
                              margin: const EdgeInsets.only(
                                  top: 20, left: 20, right: 20),
                              child: Padding(
                                padding: const EdgeInsets.all(
                                    AppConstants.paddingSmall),
                                child: Row(
                                  children: [
                                    const Expanded(
                                      child: Text(
                                        "DSM版本",
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        "${systemData['firmware_ver']}",
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Card(
                              shape: RoundedRectangleBorder(
                                  side: const BorderSide(),
                                  borderRadius: BorderRadius.circular(18)),
                              margin: const EdgeInsets.only(
                                  top: 20, left: 20, right: 20),
                              child: Padding(
                                padding: const EdgeInsets.all(
                                    AppConstants.paddingSmall),
                                child: Row(
                                  children: [
                                    const Expanded(
                                      child: Text(
                                        "系统时间",
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        "${systemData['time']}",
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Card(
                              shape: RoundedRectangleBorder(
                                  side: const BorderSide(),
                                  borderRadius: BorderRadius.circular(18)),
                              margin: const EdgeInsets.only(
                                  top: 20, left: 20, right: 20),
                              child: Padding(
                                padding: const EdgeInsets.all(
                                    AppConstants.paddingSmall),
                                child: Row(
                                  children: [
                                    const Expanded(
                                      child: Text(
                                        "运行时间",
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        parseOpTime(systemData['up_time']),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (systemData['sys_temp'] != null)
                              Card(
                                shape: RoundedRectangleBorder(
                                    side: const BorderSide(),
                                    borderRadius: BorderRadius.circular(18)),
                                margin: const EdgeInsets.only(
                                    top: 20, left: 20, right: 20),
                                child: Padding(
                                  padding: const EdgeInsets.all(
                                      AppConstants.paddingSmall),
                                  child: Row(
                                    children: [
                                      const Expanded(
                                        child: Text(
                                          "散热状态",
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          "${systemData['sys_temp']}℃ ${systemData['temperature_warning'] == null ? (systemData['sys_temp'] > 80 ? "警告" : "正常") : (systemData['temperature_warning'] ? "警告" : "正常")}",
                                          style: TextStyle(
                                              color: systemData[
                                                          'temperature_warning'] ==
                                                      null
                                                  ? (systemData['sys_temp'] > 80
                                                      ? Colors.red
                                                      : Colors.green)
                                                  : (systemData[
                                                          'temperature_warning']
                                                      ? Colors.red
                                                      : Colors.green)),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            const SizedBox(
                              height: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                    Card(
                      shape: RoundedRectangleBorder(
                          side: const BorderSide(),
                          borderRadius: BorderRadius.circular(18)),
                      margin:
                          const EdgeInsets.only(top: 20, left: 20, right: 20),
                      child: Padding(
                        padding:
                            const EdgeInsets.all(AppConstants.paddingSmall),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(top: 20, left: 20),
                              child: Text(
                                "时间信息",
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.w600),
                              ),
                            ),
                            Card(
                              shape: RoundedRectangleBorder(
                                  side: const BorderSide(),
                                  borderRadius: BorderRadius.circular(18)),
                              margin: const EdgeInsets.only(
                                  top: 20, left: 20, right: 20),
                              child: Padding(
                                padding: const EdgeInsets.all(
                                    AppConstants.paddingSmall),
                                child: Row(
                                  children: [
                                    const Expanded(
                                      child: Text(
                                        "服务器地址",
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        "${systemData['ntp_server']} ${systemData['enabled_ntp'] == true ? "" : "(暂未启用)"}",
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Card(
                              shape: RoundedRectangleBorder(
                                  side: const BorderSide(),
                                  borderRadius: BorderRadius.circular(18)),
                              margin: const EdgeInsets.only(
                                  top: 20, left: 20, right: 20),
                              child: Padding(
                                padding: const EdgeInsets.all(
                                    AppConstants.paddingSmall),
                                child: Row(
                                  children: [
                                    const Expanded(
                                      flex: 1,
                                      child: Text(
                                        "时区",
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        "${systemData['time_zone_desc']}",
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(
                              height: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (usbDev.value.isNotEmpty)
                      Card(
                        margin:
                            const EdgeInsets.only(top: 20, left: 20, right: 20),
                        child: Padding(
                          padding:
                              const EdgeInsets.all(AppConstants.paddingSmall),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(top: 20, left: 20),
                                child: Text(
                                  "外接设备",
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600),
                                ),
                              ),
                              ...usbDev.value.map((dev) => UsbDeviceItem(dev)),
                              const SizedBox(
                                height: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
                ListView(
                  children: [
                    Card(
                      margin:
                          const EdgeInsets.only(top: 20, left: 20, right: 20),
                      child: Padding(
                        padding:
                            const EdgeInsets.all(AppConstants.paddingSmall),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(top: 20, left: 20),
                              child: Text(
                                "基本信息",
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.w600),
                              ),
                            ),
                            Card(
                              margin: const EdgeInsets.only(
                                  top: 20, left: 20, right: 20),
                              child: Padding(
                                padding: const EdgeInsets.all(
                                    AppConstants.paddingSmall),
                                child: Row(
                                  children: [
                                    const Expanded(
                                      child: Text(
                                        "系统名称",
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        "${network['hostname']}",
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Card(
                              margin: const EdgeInsets.only(
                                  top: 20, left: 20, right: 20),
                              child: Padding(
                                padding: const EdgeInsets.all(
                                    AppConstants.paddingSmall),
                                child: Row(
                                  children: [
                                    const Expanded(
                                      flex: 1,
                                      child: Text(
                                        "DNS",
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        "${network['dns']}",
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Card(
                              margin: const EdgeInsets.only(
                                  top: 20, left: 20, right: 20),
                              child: Padding(
                                padding: const EdgeInsets.all(
                                    AppConstants.paddingSmall),
                                child: Row(
                                  children: [
                                    const Expanded(
                                      flex: 1,
                                      child: Text(
                                        "默认网关",
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        "${network['gateway']}",
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Card(
                              margin: const EdgeInsets.only(
                                  top: 20, left: 20, right: 20),
                              child: Padding(
                                padding: const EdgeInsets.all(
                                    AppConstants.paddingSmall),
                                child: Row(
                                  children: [
                                    const Expanded(
                                      flex: 1,
                                      child: Text(
                                        "工作群组",
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        "${network['workgroup']}",
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(
                              height: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                    ...nifs.map(
                        (nif) => NetworkInterfaceItem(nif, nifs.indexOf(nif))),
                  ],
                ),
                Expanded(child: buildVolume()),
                Expanded(child: buildDisk()),
                const Center(
                  child: Text("待开发"),
                ),
                const Center(
                  child: Text("待开发"),
                ),
                const Center(
                  child: Text("待开发"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
