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
import 'package:garden/constants/app_constants.dart';
import 'package:signals_flutter/signals_flutter.dart';

class TaskManager extends StatefulWidget {
  const TaskManager({super.key});

  @override
  TaskManagerState createState() => TaskManagerState();
}

class TaskManagerState extends State<TaskManager>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List processes = [];
  List services = [];
  List slices = [];
  late Timer timer;
  bool loading = true;
  @override
  void initState() {
    _tabController = TabController(length: 2, vsync: this);
    getData();
    timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      // getData();
    });
    super.initState();
  }

  getData() async {
    var process = await dsmCoreSystemProcess();
    var group = await dsmCoreSystemProcessGroup();
    if (process['success']) {
      setState(() {
        loading = false;
        try {
          processes = process['data']['process'];
          if (connectionStore.dsmVersion.watch(context) == 7) {
            slices = group['data']['slices'];
          } else {
            services = group['data']['services'];
          }
        } catch (e) {
          Log.error(e);
        }
      });
    }
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }

  Widget _buildServiceItem(service) {
    String title = "";
    List<String> titles = service['display_name'].split(":");
    //判断是否在string内
    if (titles.length > 1) {
      if (webManagerStrings[titles[0]] != null &&
          webManagerStrings[titles[0]][titles[1]] != null) {
        if (webManagerStrings[titles[0]][titles[1]] != null) {
          title = webManagerStrings[titles[0]][titles[1]];
        }
      } else if (connectionStore.strings.watch(context)[service['display_name']]
                  [titles[0]] !=
              null &&
          connectionStore.strings[service['display_name']][titles[0]]
                  [titles[1]] !=
              null) {
        title = connectionStore.strings[service['display_name']][titles[0]]
            [titles[1]];
      } else if (connectionStore.strings[service['display_name']] != null &&
          connectionStore.strings[service['display_name']]['common'] != null &&
          connectionStore.strings[service['display_name']]['common']
                  ['displayname'] !=
              null) {
        title = connectionStore.strings[service['display_name']]['common']
            ['displayname'];
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

  Widget _buildSliceItem(slice) {
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

  Widget _buildProcessItem(process) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: AppBackButton(context),
        title: const Text("任务管理器"),
      ),
      body: loading
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
                    controller: _tabController,
                    children: [
                      if (connectionStore.dsmVersion.watch(context) == 7)
                        ListView.builder(
                          padding: const EdgeInsets.all(20),
                          itemBuilder: (context, i) {
                            return _buildSliceItem(slices[i]);
                          },
                          itemCount: slices.length,
                        )
                      else
                        ListView.builder(
                          padding: const EdgeInsets.all(20),
                          itemBuilder: (context, i) {
                            return _buildServiceItem(services[i]);
                          },
                          itemCount: services.length,
                        ),
                      ListView.builder(
                        padding: const EdgeInsets.all(20),
                        itemBuilder: (context, i) {
                          return _buildProcessItem(processes[i]);
                        },
                        itemCount: processes.length,
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
