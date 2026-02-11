import 'package:garden/api/dsm_api.dart';
import 'package:garden/util/http_util.dart';
import 'package:garden/util/log.dart';
import 'package:garden/widgets/bubble_tab_indicator.dart';
import 'package:garden/widgets/dashboard/volume_card.dart';
import 'package:garden/widgets/label.dart';
import 'package:garden/widgets/neu_back_button.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:garden/constants/app_constants.dart';
import 'package:signals_flutter/signals_flutter.dart';

class SystemInfo extends StatefulWidget {
  const SystemInfo(
      this.index, this.systemData, this.storageVolumes, this.storageDisks,
      {super.key});
  final int index;
  final ReadonlySignal<Map> systemData;
  final ReadonlySignal<List> storageVolumes;
  final ReadonlySignal<List> storageDisks;
  @override
  SystemInfoState createState() => SystemInfoState();
}

class SystemInfoState extends State<SystemInfo>
    with SingleTickerProviderStateMixin, SignalsMixin {
  late final TabController _tabController =
      TabController(initialIndex: widget.index, length: 6, vsync: this);
  late final usbDev = computed(() => widget.systemData['usb_dev'] ?? 0);
  final nifs = listSignal([]);
  late final volumes = futureSignal<List>(() async {
    if (widget.storageVolumes.isNotEmpty) {
      return Future.value(widget.storageVolumes.value);
    }
    final res = await dsmStorageCGIStorageLoadInfo();
    final d = res['volumes'];
    d.sort((a, b) {
      return a['num_id'].compareTo(b['num_id']);
    });
    return Future.value(d);
  });
  late final disks = futureSignal<List>(() async {
    if (widget.storageDisks.isNotEmpty) {
      return Future.value(widget.storageDisks.value);
    }
    final res = await dsmStorageCGIStorageLoadInfo();
    return Future.value(res['disks']);
  });
  late final network = createMapSignal({});
  late final loadingDisks = createSignal(false);
  @override
  void initState() {
    effect(() {
      getData();
    });
    super.initState();
  }

  getData() async {
    try {
      final res = await dsmCoreNetworkGet();
      network.set(res);
      nifs.set(network['nif']);
    } catch (e) {
      Log.error('dsmCoreNetworkGet: $e');
    }
  }

  Widget _buildNifItem(nif) {
    return Card(
      shape: RoundedRectangleBorder(
          side: const BorderSide(), borderRadius: BorderRadius.circular(18)),
      margin: const EdgeInsets.only(top: 20, left: 20, right: 20),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingSmall),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 20, left: 20),
              child: Text(
                "局域网 ${nifs.indexOf(nif) + 1}",
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ),
            Card(
              shape: RoundedRectangleBorder(
                  side: const BorderSide(),
                  borderRadius: BorderRadius.circular(18)),
              margin: const EdgeInsets.only(top: 20, left: 20, right: 20),
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.paddingSmall),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        "MAC 地址",
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        "${nif['mac']}",
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
              margin: const EdgeInsets.only(top: 20, left: 20, right: 20),
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.paddingSmall),
                child: Row(
                  children: [
                    const Expanded(
                      flex: 1,
                      child: Text(
                        "IP 地址",
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        "${nif['addr']}",
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
              margin: const EdgeInsets.only(top: 20, left: 20, right: 20),
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.paddingSmall),
                child: Row(
                  children: [
                    const Expanded(
                      flex: 1,
                      child: Text(
                        "子网掩码",
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        "${nif['mask']}",
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
    );
  }

  Widget _buildDevItem(dev) {
    return Card(
      shape: RoundedRectangleBorder(
          side: const BorderSide(), borderRadius: BorderRadius.circular(18)),
      margin: const EdgeInsets.only(top: 20, left: 20, right: 20),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingSmall),
        child: Row(
          children: [
            Expanded(
              child: Text(
                dev['cls'] == "hub" ? "USB集线器" : dev['cls'],
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                "${dev['product']}${dev['producer']}",
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiskItem(disk) {
    return Card(
      shape: RoundedRectangleBorder(
          side: const BorderSide(), borderRadius: BorderRadius.circular(18)),
      margin: const EdgeInsets.only(top: 20, left: 20, right: 20),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingSmall),
        child: Row(
          children: [
            Card(
              shape: RoundedRectangleBorder(
                  side: const BorderSide(),
                  borderRadius: BorderRadius.circular(18)),
              margin: const EdgeInsets.all(10),
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.paddingSmall),
                child: Image.asset(
                  disk['isSsd']
                      ? "assets/icons/ssd.png"
                      : "assets/icons/hdd.png",
                  width: 40,
                ),
              ),
            ),
            const SizedBox(
              width: 10,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        "${disk['longName']}",
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(
                        width: 5,
                      ),
                      Label(
                        disk['overview_status'] == "normal"
                            ? "正常"
                            : disk['overview_status'],
                        disk['overview_status'] == "normal"
                            ? Colors.green
                            : Colors.red,
                        fill: true,
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 5,
                  ),
                  Text("${disk['vendor'].trim()} ${disk['model'].trim()}"),
                  const SizedBox(
                    height: 5,
                  ),
                  Row(
                    children: [
                      Text(int.parse(disk['size_total']).formatSize()),
                      Text("  ${disk['temp']}℃"),
                    ],
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildVolume() {
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
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
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

  Widget _buildDisk() {
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
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ),
                ...value.map(_buildDiskItem),
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

  @override
  Widget build(BuildContext context) {
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
              controller: _tabController,
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
              controller: _tabController,
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
                                        "${widget.systemData['serial']}",
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
                                        "${widget.systemData['model']}",
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
                                        "${widget.systemData['cpu_vendor']} ${widget.systemData['cpu_family']} ${widget.systemData['cpu_series']}",
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
                                        "${widget.systemData['cpu_cores']}核 @ ${(widget.systemData['cpu_clock_speed'] / 1000).toStringAsFixed(2)}GHz",
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
                                        "${widget.systemData['ram_size']}MB",
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
                                        "${widget.systemData['firmware_ver']}",
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
                                        "${widget.systemData['time']}",
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
                                        parseOpTime(
                                            widget.systemData['up_time']),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (widget.systemData['sys_temp'] != null)
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
                                          "${widget.systemData['sys_temp']}℃ ${widget.systemData['temperature_warning'] == null ? (widget.systemData['sys_temp'] > 80 ? "警告" : "正常") : (widget.systemData['temperature_warning'] ? "警告" : "正常")}",
                                          style: TextStyle(
                                              color: widget.systemData[
                                                          'temperature_warning'] ==
                                                      null
                                                  ? (widget.systemData[
                                                              'sys_temp'] >
                                                          80
                                                      ? Colors.red
                                                      : Colors.green)
                                                  : (widget.systemData[
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
                                        "${widget.systemData['ntp_server']} ${widget.systemData['enabled_ntp'] ? "" : "(暂未启用)"}",
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
                                        "${widget.systemData['time_zone_desc']}",
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
                              ...usbDev.value.map(_buildDevItem),
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
                    ...nifs.map(_buildNifItem),
                  ],
                ),
                Expanded(child: _buildVolume()),
                Expanded(child: _buildDisk()),
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
