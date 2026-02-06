import 'package:garden/util/ui_util.dart';
import 'package:garden/util/http_util.dart';
import 'package:garden/widgets/bubble_tab_indicator.dart';
import 'package:garden/widgets/neu_back_button.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:garden/widgets/docker/container_basic_info.dart';
import 'package:garden/widgets/docker/container_ports.dart';
import 'package:garden/widgets/docker/container_volumes.dart';
import 'package:garden/widgets/docker/container_links.dart';
import 'package:garden/widgets/docker/container_networks.dart';
import 'package:garden/widgets/docker/container_envs.dart';
import 'package:garden/widgets/docker/container_processes.dart';
import 'package:garden/widgets/docker/log_date_selector.dart';
import 'package:garden/widgets/docker/log_list.dart';

class ContainerDetail extends StatefulWidget {
  final String name;
  const ContainerDetail(this.name, {super.key});
  @override
  ContainerDetailState createState() => ContainerDetailState();
}

class ContainerDetailState extends State<ContainerDetail>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();
  bool loading = true;
  List ports = [];
  List networks = [];
  List links = [];
  List envs = [];
  String cmd = "";
  List volumes = [];
  int memory = 0;
  double memoryPercent = 0;
  int cpuPriority = 0;
  String status = "";
  int upTime = 0;
  Map shortcut = {};
  List logDates = [];
  List logs = [];
  String selectedDate = "";
  List processes = [];
  @override
  void initState() {
    _tabController = TabController(length: 3, vsync: this);
    getData();
    super.initState();
  }

  getData() async {
    var res = await DsmApi.dockerDetail(widget.name, "get");
    if (res['success']) {
      setState(() {
        loading = false;
        ports = res['data']['profile']['port_bindings'];
        networks = res['data']['profile']['network'];
        volumes = res['data']['profile']['volume_bindings'];
        envs = res['data']['profile']['env_variables'];
        memory = res['data']['profile']['memory_limit'];
        shortcut = res['data']['profile']['shortcut'];
        cpuPriority = res['data']['profile']['cpu_priority'];
        links = res['data']['profile']['links'];
        memoryPercent = res['data']['details']['memoryPercent'] * 1.0;

        upTime = res['data']['details']['up_time'];
        status = res['data']['details']['status'];
        cmd = res['data']['details']['exe_cmd'];
      });

      var process = await DsmApi.dockerDetail(widget.name, "get_process");
      if (process['success']) {
        setState(() {
          processes = process['data']['processes'];
        });
      }
      getLogDates();
    } else {
      UiUtil.toast("获取详情失败");
    }
  }

  getLogDates() async {
    var res = await DsmApi.dockerLog(widget.name, "get_date_list");
    if (res['success']) {
      setState(() {
        logDates = res['data']['dates'];
        if (logDates.isNotEmpty) {
          selectedDate = logDates[0];
        }
      });

      getLog();
    }
  }

  getLog() async {
    var log = await DsmApi.dockerLog(widget.name, "get", date: selectedDate);
    if (log['success']) {
      setState(() {
        logs = log['data']['logs'];
      });
    }
  }

  void _onDateSelected(String date) {
    setState(() {
      selectedDate = date;
    });
    getLog();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: AppBackButton(context),
        title: Text(widget.name),
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
                    isScrollable: false,
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
                    controller: _tabController,
                    children: [
                      ListView(
                        children: [
                          ContainerBasicInfo(
                            upTime: upTime,
                            shortcut: shortcut,
                            cpuPriority: cpuPriority,
                            memory: memory,
                            cmd: cmd,
                          ),
                          ContainerPorts(ports: ports),
                          ContainerVolumes(volumes: volumes),
                          ContainerLinks(links: links),
                          ContainerNetworks(networks: networks),
                          ContainerEnvs(envs: envs),
                        ],
                      ),
                      ContainerProcesses(processes: processes),
                      Row(
                        children: [
                          LogDateSelector(
                            logDates: logDates,
                            selectedDate: selectedDate,
                            onDateSelected: _onDateSelected,
                          ),
                          LogList(
                            logs: logs,
                            scrollController: _scrollController,
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
