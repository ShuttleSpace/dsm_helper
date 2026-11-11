import 'package:dio/dio.dart';
import 'package:garden/api/dsm_api.dart';
import 'package:garden/theme/app_theme.dart';
import 'package:garden/util/log.dart';
import 'package:garden/util/ui_util.dart';
import 'package:garden/widgets/bubble_tab_indicator.dart';
import 'package:garden/widgets/label.dart';
import 'package:garden/widgets/neu_back_button.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:garden/constants/app_constants.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:signals_hooks/signals_hooks.dart';

class ExternalDevice extends HookWidget {
  const ExternalDevice({super.key});

  @override
  Widget build(BuildContext context) {
    final tickerProvider = useSingleTickerProvider();
    final tabController = useMemoized(
      () => TabController(length: 2, vsync: tickerProvider),
      const [],
    );
    final esatas = useListSignal([]);
    final usbs = useListSignal([]);
    final loading = useSignal(true);

    getData() async {
    try {
      final res = await dsmCoreExternalDeviceList();
      loading.value = false;
      List result = res['data']['result'];
      for (var item in result) {
        if (item['success'] == true) {
          switch (item['api']) {
            case "SYNO.Core.ExternalDevice.Storage.eSATA":
              esatas.clear();
              esatas.addAll(item['data']['devices']);
              break;
            case "SYNO.Core.ExternalDevice.Storage.USB":
              usbs.clear();
              usbs.addAll(item['data']['devices']);
              break;
          }
        }
      }
    } on DioException catch (e) {
      UiUtil.toast('获取外接设备失败, $e');
      Log.error('获取外接设备失败, $e');
    } on DSMException catch (e) {
      UiUtil.toast("获取外接设备失败, $e}");
      Log.error('获取外接设备失败, $e');
    }
  }

  Widget buildPartitionItem(partition) {
    return Card(
      shape: RoundedRectangleBorder(
          side: const BorderSide(), borderRadius: BorderRadius.circular(18)),
      margin: const EdgeInsets.only(top: 20),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingSmall),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text("${partition['partition_title']}"),
                const SizedBox(
                  width: 10,
                ),
                partition['status'] == "normal"
                    ? const Label(
                        "正常",
                        Colors.green,
                        fill: true,
                      )
                    : partition['status'] == "background"
                        ? const Label(
                            "正在检查硬盘",
                            Colors.lightBlueAccent,
                            fill: true,
                          )
                        : Label(
                            partition['status'],
                            Colors.red,
                            fill: true,
                          ),
              ],
            ),
            const SizedBox(
              height: 10,
            ),
            Row(
              children: [
                Card(
                  shape: RoundedRectangleBorder(
                      side: const BorderSide(),
                      borderRadius: BorderRadius.circular(18)),
                  margin: const EdgeInsets.all(10),
                  child: Padding(
                    padding: const EdgeInsets.all(AppConstants.paddingSmall),
                    child: CircularPercentIndicator(
                      radius: 40,
                      // progressColor: Colors.lightBlueAccent,
                      animation: true,
                      linearGradient: LinearGradient(
                        colors: partition['used_size_mb'] /
                                    partition['total_size_mb'] <=
                                0.9
                            ? [
                                Colors.blue,
                                Colors.blueAccent,
                              ]
                            : [
                                Colors.red,
                                Colors.orangeAccent,
                              ],
                      ),
                      animateFromLastPercent: true,
                      circularStrokeCap: CircularStrokeCap.round,
                      lineWidth: 12,
                      backgroundColor: Colors.black12,
                      percent: partition['used_size_mb'] /
                          partition['total_size_mb'],
                      center: Text(
                        "${(partition['used_size_mb'] / partition['total_size_mb'] * 100).toStringAsFixed(0)}%",
                        style: TextStyle(
                            color: partition['used_size_mb'] /
                                        partition['total_size_mb'] <=
                                    0.9
                                ? Colors.blue
                                : Colors.red,
                            fontSize: 22),
                      ),
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
                            "${partition['share_name']}",
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(
                            width: 10,
                          ),
                          Label(
                            partition['filesystem'] ?? partition['dev_fstype'],
                            Colors.blue,
                            fill: true,
                          )
                        ],
                      ),
                      const SizedBox(
                        height: 5,
                      ),
                      Text(
                          "已用：${(partition['used_size_mb'] * 1024 * 1024).formatSize()}"),
                      const SizedBox(
                        height: 5,
                      ),
                      Text(
                          "可用：${(partition['total_size_mb'] * 1024 * 1024 - partition['used_size_mb'] * 1024 * 1024).formatSize()}"),
                      const SizedBox(
                        height: 5,
                      ),
                      Text(
                          "容量：${(partition['total_size_mb'] * 1024 * 1024).formatSize()}"),
                    ],
                  ),
                )
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget buildESataItem(esata) {
    List partitions = esata['partitions'];
    return Card(
      shape: RoundedRectangleBorder(
          side: const BorderSide(), borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  "${esata['dev_title']}",
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(
                  width: 10,
                ),
                esata['status'] == "normal"
                    ? const Label(
                        "正常",
                        Colors.green,
                        fill: true,
                      )
                    : Label(
                        esata['status'],
                        Colors.red,
                        fill: true,
                      ),
                const SizedBox(
                  width: 10,
                ),
                const Spacer(),
                OutlinedButton(
                  onPressed: () async {
                    var res = await dsmCoreExternalDeviceEject(
                        esata['dev_id'], esata['dev_type']);
                    if (res['success']) {
                      UiUtil.toast("设备已退出");
                      getData();
                    } else {
                      UiUtil.toast("设备退出失败，代码${res['error']['code']}");
                    }
                  },
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: Icon(
                      CupertinoIcons.eject,
                      color: Theme.of(context).colorScheme.primary,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
            ...partitions.map(buildPartitionItem),
          ],
        ),
      ),
    );
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
        title: const Text("外接设备"),
      ),
      body: Column(
        children: [
          Card(
            shape: RoundedRectangleBorder(
                side: const BorderSide(),
                borderRadius: BorderRadius.circular(18)),
            margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.paddingSmall),
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
                    padding: EdgeInsets.symmetric(vertical: 10, horizontal: 5),
                    child: Text("外接设备"),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 10, horizontal: 5),
                    child: Text("打印机"),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: tabController,
              children: [
                loading.value
                    ? const Center(
                        child: CupertinoActivityIndicator(
                          radius: 14,
                        ),
                      )
                    : (esatas + usbs).isNotEmpty
                        ? ListView.separated(
                            padding: const EdgeInsets.all(20),
                            itemBuilder: (context, i) {
                              return buildESataItem((esatas + usbs)[i]);
                            },
                            separatorBuilder: (context, i) {
                              return const SizedBox(
                                height: 20,
                              );
                            },
                            itemCount: (esatas + usbs).length)
                        : Center(
                            child: Text(
                              "暂无外接设备",
                              style: TextStyle(
                                  color: AppTheme.of(context).placeholderColor),
                            ),
                          ),
                const Center(
                  child: Text("未开发"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
