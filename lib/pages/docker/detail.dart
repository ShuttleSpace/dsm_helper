import 'package:garden/api/dsm_api.dart';
import 'package:garden/util/ui_util.dart';
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

    Future<void> getLog() async {
      try {
        final data = await dsmDockerContainerLog(name, "get",
            date: selectedDate.value);
        logs.value = data['logs'] ?? [];
      } catch (e) {
        // 旧层在日志失败时静默返回；保持行为不变。
      }
    }

    Future<void> getLogDates() async {
      try {
        final data = await dsmDockerContainerLog(name, "get_date_list");
        logDates.value = data['dates'] ?? [];
        if (logDates.value.isNotEmpty) {
          selectedDate.value = logDates.value[0];
        }
        await getLog();
      } catch (e) {
        // 同上，旧层静默失败。
      }
    }

    Future<void> getData() async {
      late Map data;
      try {
        data = await dsmDockerContainerDetail(name, "get");
      } catch (e) {
        UiUtil.toast("获取详情失败");
        return;
      }

      loading.value = false;
      final profile = data['profile'] as Map? ?? const {};
      final details = data['details'] as Map? ?? const {};
      ports.value = profile['port_bindings'] ?? [];
      networks.value = profile['network'] ?? [];
      volumes.value = profile['volume_bindings'] ?? [];
      envs.value = profile['env_variables'] ?? [];
      memory.value = profile['memory_limit'] ?? 0;
      shortcut.value = profile['shortcut'] ?? {};
      cpuPriority.value = profile['cpu_priority'] ?? 0;
      links.value = profile['links'] ?? [];
      memoryPercent.value = (details['memoryPercent'] ?? 0) * 1.0;

      upTime.value = details['up_time'] ?? 0;
      status.value = details['status'] ?? '';
      cmd.value = details['exe_cmd'] ?? '';

      try {
        final processData = await dsmDockerContainerProcesses(name);
        processes.value = processData['processes'] ?? [];
      } catch (e) {
        // 进程列表失败不影响详情展示（旧层同样静默跳过）。
      }
      await getLogDates();
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
