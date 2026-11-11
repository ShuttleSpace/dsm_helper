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
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:garden/constants/app_constants.dart';
import 'package:signals_hooks/signals_hooks.dart';

class StorageManager extends HookWidget {
  const StorageManager({super.key});

  @override
  Widget build(BuildContext context) {
    final tickerProvider = useSingleTickerProvider();
    final tabController = useMemoized(
      () => TabController(length: 6, vsync: tickerProvider),
      const [],
    );
    final loading = useSignal(true);
    final ssdCaches = useSignal<List<Map<String, dynamic>>>([]);
    final volumes = useSignal<List<Map<String, dynamic>>>([]);
    final disks = useSignal<List<Map<String, dynamic>>>([]);
    final storagePools = useSignal<List<Map<String, dynamic>>>([]);
    final hotSpares = useSignal<List<Map<String, dynamic>>>([]);
    final env = useSignal<Map<String, dynamic>>({});

    getData() async {
      var res = await DsmApi.storage();
      if (res['success']) {
        loading.value = false;
        ssdCaches.value = res['data']['ssdCaches'];
        volumes.value = res['data']['volumes'];

        volumes.value.sort((a, b) {
          return a['num_id'].compareTo(b['num_id']);
        });
        // print(volumes);
        disks.value = res['data']['disks'];
        disks.value.sort((a, b) {
          return a['num_id'].compareTo(b['num_id']);
        });
        storagePools.value = res['data']['storagePools'];
        env.value = res['data']['env'];
        hotSpares.value = res['data']['hotSpares'];
      } else {
        UiUtil.toast("获取存储空间信息失败，代码${res['error']['code']}");
        if (context.mounted) {
          // ignore: use_build_context_synchronously
          Navigator.of(context).pop();
        }
      }
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
        title: const Text("存储空间管理员"),
      ),
      body: loading.value
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
                    controller: tabController,
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
                    controller: tabController,
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
                                  ...volumes.value.map(
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
                                  ...storagePools.value.reversed
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
                                          i <
                                              int.parse(
                                                  env.value['bay_number']);
                                          i++)
                                        Container(
                                          height: 20,
                                          width: 40,
                                          decoration: DashedDecoration(
                                            color: disks.value
                                                    .where((disk) =>
                                                        disk['num_id'] == i + 1)
                                                    .isNotEmpty
                                                ? Colors.blue
                                                : Colors.transparent,
                                            dashedColor: disks.value
                                                    .where((disk) =>
                                                        disk['num_id'] == i + 1)
                                                    .isNotEmpty
                                                ? Colors.blue
                                                : Colors.grey,
                                            gap: disks.value
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
                      volumes.value.isNotEmpty
                          ? ListView.separated(
                              itemBuilder: (context, i) {
                                return VolumeItem(
                                    volume: volumes.value.reversed.toList()[i]);
                              },
                              itemCount: volumes.value.length,
                              separatorBuilder: (context, i) {
                                return const SizedBox(
                                  height: 20,
                                );
                              },
                            )
                          : const Center(
                              child: Text("无存储空间"),
                            ),
                      storagePools.value.isNotEmpty
                          ? ListView.separated(
                              padding: const EdgeInsets.all(20),
                              itemBuilder: (context, i) {
                                return PoolDetail(
                                  pool: storagePools.value.reversed.toList()[i],
                                  disks: disks.value,
                                  volumes: volumes.value,
                                  ssdCaches: ssdCaches.value,
                                );
                              },
                              itemCount: storagePools.value.length,
                              separatorBuilder: (context, i) {
                                return const SizedBox(
                                  height: 20,
                                );
                              },
                            )
                          : const Center(
                              child: Text("无存储池"),
                            ),
                      disks.value.isNotEmpty
                          ? ListView.separated(
                              padding: const EdgeInsets.all(20),
                              itemBuilder: (context, i) {
                                return GestureDetector(
                                  onTap: () {
                                    Navigator.of(context).push(
                                        CupertinoPageRoute(
                                            builder: (context) {
                                              return Smart(disks.value[i]);
                                            },
                                            settings: const RouteSettings(
                                                name: "disk_smart")));
                                  },
                                  child: DiskItem(
                                    disk: disks.value[i],
                                    storagePools: storagePools.value,
                                    ssdCaches: ssdCaches.value,
                                    full: true,
                                  ),
                                );
                              },
                              itemCount: disks.value.length,
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
                        child: Text(hotSpares.value.isNotEmpty
                            ? "暂不支持显示，共${hotSpares.value.length}个"
                            : "无备援装置"),
                      ),
                      ssdCaches.value.isNotEmpty
                          ? ListView.separated(
                              itemBuilder: (context, i) {
                                return SsdCacheItem(
                                    volume: ssdCaches.value[i]);
                              },
                              separatorBuilder: (context, i) {
                                return const SizedBox(
                                  height: 20,
                                );
                              },
                              itemCount: ssdCaches.value.length)
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
