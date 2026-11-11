import 'dart:async';
import 'package:garden/api/dsm_api.dart';
import 'package:garden/stores/connection_store.dart';

import 'package:garden/util/http_util.dart';
import 'package:garden/util/log.dart';
import 'package:garden/util/strings.dart';
import 'package:garden/widgets/bubble_tab_indicator.dart';
import 'package:garden/widgets/label.dart';
import 'package:garden/widgets/neu_back_button.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:garden/constants/app_constants.dart';
import 'package:signals_hooks/signals_hooks.dart';

class TaskManager extends HookWidget {
  const TaskManager({super.key});

  @override
  Widget build(BuildContext context) {
    final tickerProvider = useSingleTickerProvider();
    final tabController = useMemoized(
      () => TabController(length: 2, vsync: tickerProvider),
      const [],
    );
    final dsmVersion = useSignalValue(connectionStore.dsmVersion);
    final stringsMap = useSignalValue(connectionStore.strings);
    final processes = useSignal<List>([]);
    final services = useSignal<List>([]);
    final slices = useSignal<List>([]);
    final loading = useSignal(true);

    getData() async {
      var process = await dsmCoreSystemProcess();
      var group = await dsmCoreSystemProcessGroup();
      if (process['success']) {
        loading.value = false;
        try {
          processes.value = process['data']['process'];
          if (dsmVersion == 7) {
            slices.value = group['data']['slices'];
          } else {
            services.value = group['data']['services'];
          }
        } catch (e) {
          Log.error(e);
        }
      }
    }

    Widget buildServiceItem(service) {
      String title = "";
      List<String> titles = service['display_name'].split(":");
      //判断是否在string内
      if (titles.length > 1) {
        if (webManagerStrings[titles[0]] != null &&
            webManagerStrings[titles[0]][titles[1]] != null) {
          if (webManagerStrings[titles[0]][titles[1]] != null) {
            title = webManagerStrings[titles[0]][titles[1]];
          }
        } else if (stringsMap[service['display_name']][titles[0]] != null &&
            stringsMap[service['display_name']][titles[0]][titles[1]] !=
                null) {
          title = stringsMap[service['display_name']][titles[0]][titles[1]];
        } else if (stringsMap[service['display_name']] != null &&
            stringsMap[service['display_name']]['common'] != null &&
            stringsMap[service['display_name']]['common']['displayname'] !=
                null) {
          title =
              stringsMap[service['display_name']]['common']['displayname'];
        }
      } else {
        title = service['display_name'];
      }

      return Card(
        shape: RoundedRectangleBorder(
            side: const BorderSide(), borderRadius: BorderRadius.circular(18)),
        margin: const EdgeInsets.all(10),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.paddingSmall),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 16),
              ),
              // SizedBox(
              //   height: 10,
              // ),
            ],
          ),
        ),
      );
    }

    Widget buildSliceItem(slice) {
      Map<String, int> cpuTime = {};
      if (slice['cpu_time'] is num) {
        cpuTime = (int.parse(slice['cpu_time'])).formatTime();
      }
      return Card(
        shape: RoundedRectangleBorder(
            side: const BorderSide(), borderRadius: BorderRadius.circular(18)),
        margin: const EdgeInsets.all(10),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.paddingSmall),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      "${slice['name'] != '' ? slice['name'] : slice['name_i18n'] != '' ? slice['name_i18n'] : slice['unit_name']}",
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  Text(
                      "内存：${slice['memory'] is num ? (int.parse(slice['memory'])).formatSize(fixed: 1) : slice['memory']}")
                ],
              ),
              const SizedBox(
                height: 10,
              ),
              Row(
                children: [
                  Expanded(
                      child: Text(
                          "CPU(%)：${slice['cpu_utilization'] is num ? slice['cpu_utilization'].toStringAsFixed(2) : slice['cpu_utilization']}")),
                  Expanded(
                      child: Text(
                          "CPU Time：${slice['cpu_time'] is String ? slice['cpu_time'] : '${cpuTime['hours']}:${cpuTime['minutes']}:${cpuTime['seconds']}'}")),
                ],
              ),
              Row(
                children: [
                  Expanded(
                      child: Text(
                          "读取(秒)：${slice['byte_read_per_sec'] is num ? (int.parse(slice['byte_read_per_sec'])).formatSize(fixed: 1, showByte: true) : slice['byte_read_per_sec']}")),
                  Expanded(
                      child: Text(
                          "写入(秒)：${slice['byte_write_per_sec'] is num ? (int.parse(slice['byte_write_per_sec'])).formatSize(fixed: 1, showByte: true) : slice['byte_write_per_sec']}")),
                ],
              ),
            ],
          ),
        ),
      );
    }

    Widget buildProcessItem(process) {
      return Card(
        shape: RoundedRectangleBorder(
            side: const BorderSide(), borderRadius: BorderRadius.circular(18)),
        margin: const EdgeInsets.all(10),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.paddingSmall),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "${process['command']}",
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(
                height: 10,
              ),
              Row(
                children: [
                  process['status'] == "R"
                      ? const Label("运行中", Colors.green)
                      : process['status'] == "S"
                          ? const Label("睡眠中", Colors.grey)
                          : Label(process['status'], Colors.red),
                  const SizedBox(
                    width: 10,
                  ),
                  Text("CPU:${(process['cpu'] / 10).toStringAsFixed(1)}%"),
                  const SizedBox(
                    width: 10,
                  ),
                  Text("PID:${process['pid']}"),
                ],
              ),
              const SizedBox(
                height: 10,
              ),
              Row(
                children: [
                  Expanded(
                      child: Text(
                          "私有内存：${(int.parse(process['mem'] * 97)).formatSize(fixed: 1)}")),
                  Expanded(
                      child: Text(
                          "共享内存：${(int.parse(process['mem_shared'] * 1024)).formatSize(fixed: 2)}")),
                ],
              ),
            ],
          ),
        ),
      );
    }

    useEffect(() {
      getData();
      final timer = Timer.periodic(const Duration(seconds: 5), (timer) {
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
        title: const Text("任务管理器"),
      ),
      body: loading.value
          ? const Center(
              child: CupertinoActivityIndicator(
                radius: 14,
              ),
            )
          : Column(
              children: [
                Container(
                  color: Theme.of(context).colorScheme.surface,
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
                        child: Text("服务"),
                      ),
                      Padding(
                        padding:
                            EdgeInsets.symmetric(vertical: 10, horizontal: 5),
                        child: Text("进程"),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    controller: tabController,
                    children: [
                      if (dsmVersion == 7)
                        ListView.builder(
                          padding: const EdgeInsets.all(20),
                          itemBuilder: (context, i) {
                            return buildSliceItem(slices.value[i]);
                          },
                          itemCount: slices.value.length,
                        )
                      else
                        ListView.builder(
                          padding: const EdgeInsets.all(20),
                          itemBuilder: (context, i) {
                            return buildServiceItem(services.value[i]);
                          },
                          itemCount: services.value.length,
                        ),
                      ListView.builder(
                        padding: const EdgeInsets.all(20),
                        itemBuilder: (context, i) {
                          return buildProcessItem(processes.value[i]);
                        },
                        itemCount: processes.value.length,
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
