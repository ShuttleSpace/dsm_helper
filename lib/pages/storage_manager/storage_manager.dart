import 'package:garden/pages/storage_manager/smart.dart';
import 'package:garden/util/ui_util.dart';
import 'package:garden/util/http_util.dart';
import 'package:garden/widgets/bubble_tab_indicator.dart';
import 'package:garden/widgets/dashed_decoration.dart';
import 'package:garden/widgets/neu_back_button.dart';
import 'package:garden/widgets/storage/ssd_cache_item.dart';
import 'package:garden/widgets/storage/volume_item.dart';
import 'package:garden/widgets/storage/disk_item.dart';
import 'package:garden/widgets/storage/pool_item.dart';
import 'package:garden/widgets/storage/pool_detail.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:garden/constants/app_constants.dart';

class StorageManager extends StatefulWidget {
  const StorageManager({super.key});

  @override
  StorageManagerState createState() => StorageManagerState();
}

class StorageManagerState extends State<StorageManager>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool loading = true;
  List<Map<String, dynamic>> ssdCaches = [];
  List<Map<String, dynamic>> volumes = [];
  List<Map<String, dynamic>> disks = [];
  List<Map<String, dynamic>> storagePools = [];
  List<Map<String, dynamic>> hotSpares = [];
  Map<String, dynamic> env = {};

  @override
  void initState() {
    _tabController = TabController(length: 6, vsync: this);
    getData();
    super.initState();
  }

  getData() async {
    var res = await Api.storage();
    if (res['success']) {
      setState(() {
        loading = false;
        ssdCaches = res['data']['ssdCaches'];
        volumes = res['data']['volumes'];

        volumes.sort((a, b) {
          return a['num_id'].compareTo(b['num_id']);
        });
        // print(volumes);
        disks = res['data']['disks'];
        disks.sort((a, b) {
          return a['num_id'].compareTo(b['num_id']);
        });
        storagePools = res['data']['storagePools'];
        env = res['data']['env'];
        hotSpares = res['data']['hotSpares'];
      });
    } else {
      UiUtil.toast("获取存储空间信息失败，代码${res['error']['code']}");
      if (context.mounted) {
        // ignore: use_build_context_synchronously
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: AppBackButton(context),
        title: const Text("存储空间管理员"),
      ),
      body: loading
          ? const Center(
              child: CupertinoActivityIndicator(
                radius: 14,
              ),
            )
          : Column(
              children: [
                Card(
                  shape: RoundedRectangleBorder(
                      side: const BorderSide(),
                      borderRadius: BorderRadius.circular(18)),
                  margin:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
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
                        padding:
                            EdgeInsets.symmetric(vertical: 10, horizontal: 5),
                        child: Text("系统概况"),
                      ),
                      Padding(
                        padding:
                            EdgeInsets.symmetric(vertical: 10, horizontal: 5),
                        child: Text("存储空间"),
                      ),
                      Padding(
                        padding:
                            EdgeInsets.symmetric(vertical: 10, horizontal: 5),
                        child: Text("存储池"),
                      ),
                      Padding(
                        padding:
                            EdgeInsets.symmetric(vertical: 10, horizontal: 5),
                        child: Text("HDD/SSD"),
                      ),
                      Padding(
                        padding:
                            EdgeInsets.symmetric(vertical: 10, horizontal: 5),
                        child: Text("Hot Spare"),
                      ),
                      Padding(
                        padding:
                            EdgeInsets.symmetric(vertical: 10, horizontal: 5),
                        child: Text("SSD 缓存"),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      ListView(
                        children: [
                          Card(
                            shape: RoundedRectangleBorder(
                                side: const BorderSide(),
                                borderRadius: BorderRadius.circular(18)),
                            margin: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 15),
                            child: Padding(
                              padding: const EdgeInsets.all(
                                  AppConstants.paddingSmall),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(
                                    height: 20,
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: AppConstants.paddingLarge),
                                    child: Text(
                                      "存储空间状态",
                                      style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                  ...volumes.map(
                                      (volume) => VolumeItem(volume: volume)),
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
                            margin: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 15),
                            child: Padding(
                              padding: const EdgeInsets.all(
                                  AppConstants.paddingSmall),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(
                                    height: 20,
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: AppConstants.paddingLarge),
                                    child: Text(
                                      "存储池",
                                      style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                  ...storagePools.reversed
                                      .map((pool) => PoolItem(pool: pool)),
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
                            margin: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 15),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "硬盘信息",
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(
                                    height: 20,
                                  ),
                                  Wrap(
                                    runSpacing: 5,
                                    spacing: 5,
                                    children: [
                                      for (int i = 0;
                                          i < int.parse(env['bay_number']);
                                          i++)
                                        Container(
                                          height: 20,
                                          width: 40,
                                          decoration: DashedDecoration(
                                            color: disks
                                                    .where((disk) =>
                                                        disk['num_id'] == i + 1)
                                                    .isNotEmpty
                                                ? Colors.blue
                                                : Colors.transparent,
                                            dashedColor: disks
                                                    .where((disk) =>
                                                        disk['num_id'] == i + 1)
                                                    .isNotEmpty
                                                ? Colors.blue
                                                : Colors.grey,
                                            gap: disks
                                                    .where((disk) =>
                                                        disk['num_id'] == i + 1)
                                                    .isNotEmpty
                                                ? 0.1
                                                : 2,
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      volumes.isNotEmpty
                          ? ListView.separated(
                              itemBuilder: (context, i) {
                                return VolumeItem(
                                    volume: volumes.reversed.toList()[i]);
                              },
                              itemCount: volumes.length,
                              separatorBuilder: (context, i) {
                                return const SizedBox(
                                  height: 20,
                                );
                              },
                            )
                          : const Center(
                              child: Text("无存储空间"),
                            ),
                      storagePools.isNotEmpty
                          ? ListView.separated(
                              padding: const EdgeInsets.all(20),
                              itemBuilder: (context, i) {
                                return PoolDetail(
                                  pool: storagePools.reversed.toList()[i],
                                  disks: disks,
                                  volumes: volumes,
                                  ssdCaches: ssdCaches,
                                );
                              },
                              itemCount: storagePools.length,
                              separatorBuilder: (context, i) {
                                return const SizedBox(
                                  height: 20,
                                );
                              },
                            )
                          : const Center(
                              child: Text("无存储池"),
                            ),
                      disks.isNotEmpty
                          ? ListView.separated(
                              padding: const EdgeInsets.all(20),
                              itemBuilder: (context, i) {
                                return GestureDetector(
                                  onTap: () {
                                    Navigator.of(context).push(
                                        CupertinoPageRoute(
                                            builder: (context) {
                                              return Smart(disks[i]);
                                            },
                                            settings: const RouteSettings(
                                                name: "disk_smart")));
                                  },
                                  child: DiskItem(
                                    disk: disks[i],
                                    storagePools: storagePools,
                                    ssdCaches: ssdCaches,
                                    full: true,
                                  ),
                                );
                              },
                              itemCount: disks.length,
                              separatorBuilder: (context, i) {
                                return const SizedBox(
                                  height: 20,
                                );
                              },
                            )
                          : const Center(
                              child: Text("无HDD/SSD"),
                            ),
                      Center(
                        child: Text(hotSpares.isNotEmpty
                            ? "暂不支持显示，共${hotSpares.length}个"
                            : "无备援装置"),
                      ),
                      ssdCaches.isNotEmpty
                          ? ListView.separated(
                              itemBuilder: (context, i) {
                                return SsdCacheItem(volume: ssdCaches[i]);
                              },
                              separatorBuilder: (context, i) {
                                return const SizedBox(
                                  height: 20,
                                );
                              },
                              itemCount: ssdCaches.length)
                          : const Center(
                              child: Text("无SSD缓存"),
                            ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
