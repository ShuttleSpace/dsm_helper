import 'package:garden/util/ui_util.dart';
import 'package:garden/util/http_util.dart';
import 'package:garden/widgets/bubble_tab_indicator.dart';
import 'package:garden/widgets/neu_back_button.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:garden/widgets/docker/container_basic_info.dart';
import 'package:garden/widgets/docker/container_ports.dart';
import 'package:garden/widgets/docker/container_volumes.dart';
import 'package:garden/widgets/docker/container_links.dart';
import 'package:garden/widgets/docker/container_networks.dart';
import 'package:garden/widgets/docker/container_envs.dart';
import 'package:garden/widgets/docker/container_processes.dart';
import 'package:garden/widgets/docker/log_date_selector.dart';
import 'package:garden/widgets/docker/log_list.dart';
import 'package:signals_hooks/signals_hooks.dart';

class ContainerDetail extends HookWidget {
  final String name;
  const ContainerDetail(this.name, {super.key});

  @override
  Widget build(BuildContext context) {
    final tickerProvider = useSingleTickerProvider();
    final tabController = useMemoized(
      () => TabController(length: 3, vsync: tickerProvider),
      const [],
    );
    final scrollController = useScrollController();
    final loading = useSignal(true);
    final ports = useSignal<List>([]);
    final networks = useSignal<List>([]);
    final links = useSignal<List>([]);
    final envs = useSignal<List>([]);
    final cmd = useSignal("");
    final volumes = useSignal<List>([]);
    final memory = useSignal(0);
    final memoryPercent = useSignal(0.0);
    final cpuPriority = useSignal(0);
    final status = useSignal("");
    final upTime = useSignal(0);
    final shortcut = useSignal<Map>({});
    final logDates = useSignal<List>([]);
    final logs = useSignal<List>([]);
    final selectedDate = useSignal("");
    final processes = useSignal<List>([]);

    getLog() async {
      var log = await DsmApi.dockerLog(name, "get", date: selectedDate.value);
      if (log['success']) {
        logs.value = log['data']['logs'];
      }
    }

    getLogDates() async {
      var res = await DsmApi.dockerLog(name, "get_date_list");
      if (res['success']) {
        logDates.value = res['data']['dates'];
        if (logDates.value.isNotEmpty) {
          selectedDate.value = logDates.value[0];
        }

        getLog();
      }
    }

    getData() async {
      var res = await DsmApi.dockerDetail(name, "get");
      if (res['success']) {
        loading.value = false;
        ports.value = res['data']['profile']['port_bindings'];
        networks.value = res['data']['profile']['network'];
        volumes.value = res['data']['profile']['volume_bindings'];
        envs.value = res['data']['profile']['env_variables'];
        memory.value = res['data']['profile']['memory_limit'];
        shortcut.value = res['data']['profile']['shortcut'];
        cpuPriority.value = res['data']['profile']['cpu_priority'];
        links.value = res['data']['profile']['links'];
        memoryPercent.value =
            (res['data']['details']['memoryPercent'] ?? 0) * 1.0;

        upTime.value = res['data']['details']['up_time'] ?? 0;
        status.value = res['data']['details']['status'];
        cmd.value = res['data']['details']['exe_cmd'];

        var process = await DsmApi.dockerDetail(name, "get_process");
        if (process['success']) {
          processes.value = process['data']['processes'];
        }
        getLogDates();
      } else {
        UiUtil.toast("获取详情失败");
      }
    }

    void onDateSelected(String date) {
      selectedDate.value = date;
      getLog();
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
        title: Text(name),
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
                        padding:
                            EdgeInsets.symmetric(vertical: 10, horizontal: 5),
                        child: Text("总览"),
                      ),
                      Padding(
                        padding:
                            EdgeInsets.symmetric(vertical: 10, horizontal: 5),
                        child: Text("进程"),
                      ),
                      Padding(
                        padding:
                            EdgeInsets.symmetric(vertical: 10, horizontal: 5),
                        child: Text("日志"),
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
                          ContainerBasicInfo(
                            upTime: upTime.value,
                            shortcut: shortcut.value,
                            cpuPriority: cpuPriority.value,
                            memory: memory.value,
                            cmd: cmd.value,
                          ),
                          ContainerPorts(ports: ports.value),
                          ContainerVolumes(volumes: volumes.value),
                          ContainerLinks(links: links.value),
                          ContainerNetworks(networks: networks.value),
                          ContainerEnvs(envs: envs.value),
                        ],
                      ),
                      ContainerProcesses(processes: processes.value),
                      Row(
                        children: [
                          LogDateSelector(
                            logDates: logDates.value,
                            selectedDate: selectedDate.value,
                            onDateSelected: onDateSelected,
                          ),
                          LogList(
                            logs: logs.value,
                            scrollController: scrollController,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
