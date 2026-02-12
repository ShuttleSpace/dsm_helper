import 'dart:async';
import 'package:garden/api/dsm_api.dart';
import 'package:garden/util/log.dart';
import 'package:garden/util/ui_util.dart';

import 'package:garden/theme/app_theme.dart';
import 'package:garden/util/http_util.dart';
import 'package:garden/widgets/bubble_tab_indicator.dart';
import 'package:garden/widgets/label.dart';
import 'package:garden/widgets/neu_back_button.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:garden/constants/app_constants.dart';
import 'package:garden/theme/app_colors.dart';

class Smart extends StatefulWidget {
  final Map disk;
  const Smart(this.disk, {super.key});
  @override
  SmartState createState() => SmartState();
}

class SmartState extends State<Smart> with SingleTickerProviderStateMixin {
  Timer? timer;
  late TabController _tabController;
  bool loading = true;
  Map history = {};
  Map overview = {};
  List smartInfo = [];
  List logs = [];
  bool logLoading = true;

  bool testing = false;
  String remain = "";
  String quickLast = "";
  String extendLast = "";
  List testInfo = [];
  @override
  void initState() {
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (_tabController.index == 3 && logLoading) {
        getLog();
      }
    });
    getData();
    getSmartLog();
    super.initState();
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  doSmartTest(String type) async {
    setState(() {
      testing = true;
    });
    if (timer != null) {
      return;
    }
    var res = await dsmCoreStorageDiskDoSmartTest(
        device: widget.disk['device'], type: type);
    if (res['success']) {
      getSmartLog();
      timer = Timer.periodic(const Duration(seconds: 4), (timer) {
        // getSmartLog();
      });
    } else {
      UiUtil.toast("执行检测失败，代码${res['error']['code']}");
      setState(() {
        testing = false;
      });
    }
  }

  getLog() async {
    var res =
        await dsmCoreStorageDiskDiskTestLogGet(device: widget.disk['device']);
    if (res['success']) {
      setState(() {
        logLoading = false;
        logs = res['data']['testLog'];
      });
    }
  }

  getData() async {
    var res = await dsmStorageCGISmartGetHealthInfo(widget.disk['device']);
    if (res['success']) {
      setState(() {
        loading = false;
        history = res['data']['healthInfo']['history'];
        overview = res['data']['healthInfo']['overview'];
        smartInfo = res['data']['healthInfo']['smartInfo'];
      });
    } else {
      UiUtil.toast("获取失败");
    }
  }

  getSmartLog() async {
    var res =
        await dsmCoreStorageDiskGetSmartTestLog(device: widget.disk['device']);
    Log.info(res);
    if (res['success']) {
      setState(() {
        quickLast = res['data']['quick_last'];
        extendLast = res['data']['extend_last'];
        testInfo = res['data']['testInfo'];
        testing = res['data']['testInfo'].last['testing'];
        remain = res['data']['testInfo'].last['remain'];
        if (!testing) {
          timer?.cancel();
        }
      });
    }
  }

  Widget _buildSmartItem(smart) {
    return Card(
      shape: RoundedRectangleBorder(
          side: const BorderSide(), borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingSmall),
        child: Column(
          children: [
            Row(
              children: [
                Label(smart['id'], Colors.lightBlueAccent),
                const SizedBox(
                  width: 5,
                ),
                Label(
                  smart['status'],
                  smart['status'] == "OK" ? Colors.green : Colors.red,
                  fill: true,
                ),
                const SizedBox(
                  width: 5,
                ),
                Text(smart['name']),
              ],
            ),
            const SizedBox(
              height: 5,
            ),
            Row(
              children: [
                SizedBox(
                  width: 100,
                  child: Text.rich(
                    TextSpan(
                      children: [
                        const TextSpan(
                            text: "现值：",
                            style: TextStyle(fontWeight: FontWeight.w600)),
                        TextSpan(text: "${smart['current']}"),
                      ],
                    ),
                  ),
                ),
                Text.rich(
                  TextSpan(
                    children: [
                      const TextSpan(
                          text: "最差值：",
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      TextSpan(text: "${smart['worst']}"),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(
              height: 5,
            ),
            Row(
              children: [
                SizedBox(
                  width: 100,
                  child: Text.rich(
                    TextSpan(
                      children: [
                        const TextSpan(
                            text: "临界值：",
                            style: TextStyle(fontWeight: FontWeight.w600)),
                        TextSpan(text: "${smart['threshold']}"),
                      ],
                    ),
                  ),
                ),
                Text.rich(
                  TextSpan(
                    children: [
                      const TextSpan(
                          text: "原始资料：",
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      TextSpan(text: "${smart['raw']}"),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogItem(log) {
    return Card(
      shape: RoundedRectangleBorder(
          side: const BorderSide(), borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingSmall),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("${log['time']}"),
            const SizedBox(
              height: 10,
            ),
            Row(
              children: [
                Label(
                  log['result'] == "smart_complete" ? "正常" : log['result'],
                  log['result'] == "smart_complete" ? Colors.green : Colors.red,
                  fill: true,
                ),
                const SizedBox(
                  width: 10,
                ),
                Text(
                    "${log['test_type'] == "quick" ? "S.M.A.R.T. 快速测试" : log['test_type']}"),
              ],
            )
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
        title: Text("${widget.disk['name']} 状况信息"),
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
                        child: Text("概述"),
                      ),
                      Padding(
                        padding:
                            EdgeInsets.symmetric(vertical: 10, horizontal: 5),
                        child: Text("S.M.A.R.T. 检测"),
                      ),
                      Padding(
                        padding:
                            EdgeInsets.symmetric(vertical: 10, horizontal: 5),
                        child: Text("S.M.A.R.T. 状态"),
                      ),
                      Padding(
                        padding:
                            EdgeInsets.symmetric(vertical: 10, horizontal: 5),
                        child: Text("历史记录"),
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
                              padding: const EdgeInsets.all(20),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 30,
                                    backgroundColor:
                                        widget.disk['overview_status'] ==
                                                "normal"
                                            ? Colors.green
                                            : Colors.red,
                                    child: Icon(
                                      widget.disk['overview_status'] == "normal"
                                          ? Icons.check
                                          : Icons.clear,
                                      color: Colors.white,
                                      size: 40,
                                    ),
                                  ),
                                  const SizedBox(
                                    width: 20,
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "${widget.disk['overview_status'] == "normal" ? "正常" : widget.disk['overview_status']}",
                                          style: TextStyle(
                                              fontSize: 20,
                                              color: widget.disk[
                                                          'overview_status'] ==
                                                      "normal"
                                                  ? Colors.green
                                                  : Colors.red),
                                        ),
                                        const SizedBox(
                                          height: 5,
                                        ),
                                        Text(
                                            "${widget.disk['overview_status'] == "normal" ? "此硬盘的运行状况正常" : widget.disk['overview_status']}"),
                                      ],
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
                            margin: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 15),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      const SizedBox(
                                        width: 150,
                                        child: Text(
                                          "温度",
                                          style: TextStyle(
                                              fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                      Text("${widget.disk['temp']} 摄氏度"),
                                    ],
                                  ),
                                  const SizedBox(
                                    height: 5,
                                  ),
                                  Row(
                                    children: [
                                      const SizedBox(
                                        width: 150,
                                        child: Text(
                                          "开机时间",
                                          style: TextStyle(
                                              fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                      Text("${overview['poweron'] ?? "-"} 小时"),
                                    ],
                                  ),
                                  const SizedBox(
                                    height: 5,
                                  ),
                                  Row(
                                    children: [
                                      const SizedBox(
                                        width: 150,
                                        child: Text(
                                          "硬盘重新连接次数",
                                          style: TextStyle(
                                              fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                      Text("${overview['retry']}"),
                                    ],
                                  ),
                                  const SizedBox(
                                    height: 5,
                                  ),
                                  Row(
                                    children: [
                                      const SizedBox(
                                        width: 150,
                                        child: Text(
                                          "坏扇区数量",
                                          style: TextStyle(
                                              fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                      Text("${overview['unc']}"),
                                    ],
                                  ),
                                  const SizedBox(
                                    height: 5,
                                  ),
                                  Row(
                                    children: [
                                      const SizedBox(
                                        width: 150,
                                        child: Text(
                                          "硬盘重新识别次数",
                                          style: TextStyle(
                                              fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                      Text("${overview['idnf']}"),
                                    ],
                                  ),
                                  const SizedBox(
                                    height: 5,
                                  ),
                                  Row(
                                    children: [
                                      const SizedBox(
                                        width: 150,
                                        child: Text(
                                          "S.M.A.R.T. 状态",
                                          style: TextStyle(
                                              fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                      Text(
                                        "${overview['smart'] == "normal" ? "正常" : overview['smart_status']}",
                                        style: TextStyle(
                                            color: overview['smart'] == "normal"
                                                ? Colors.green
                                                : Colors.red),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(
                                    height: 5,
                                  ),
                                ],
                              ),
                            ),
                          )
                        ],
                      ),
                      ListView(
                        padding: const EdgeInsets.all(20),
                        children: [
                          Card(
                            shape: RoundedRectangleBorder(
                                side: const BorderSide(),
                                borderRadius: BorderRadius.circular(18)),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "检测结果",
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(
                                    height: 10,
                                  ),
                                  const Text(
                                    "上次快速检测结果",
                                    style:
                                        TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(
                                    height: 5,
                                  ),
                                  Row(
                                    children: [
                                      Text(
                                        quickLast.isNotBlank
                                            ? quickLast
                                            : "暂无快速检测结果",
                                        style: TextStyle(
                                            color: AppTheme.of(context)
                                                .placeholderColor),
                                      ),
                                      const SizedBox(
                                        width: 10,
                                      ),
                                      if (quickLast.isNotBlank)
                                        Label(
                                          testInfo.last['quick_error_before'] ==
                                                  false
                                              ? "正常"
                                              : "错误",
                                          testInfo.last['quick_error_before'] ==
                                                  false
                                              ? Colors.green
                                              : Colors.red,
                                          fill: true,
                                        ),
                                    ],
                                  ),
                                  const SizedBox(
                                    height: 10,
                                  ),
                                  const Text(
                                    "上次完整检测结果",
                                    style:
                                        TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(
                                    height: 5,
                                  ),
                                  Row(
                                    children: [
                                      Text(
                                        extendLast.isNotBlank
                                            ? extendLast
                                            : "暂无完整检测结果",
                                        style: TextStyle(
                                            color: AppTheme.of(context)
                                                .placeholderColor),
                                      ),
                                      const SizedBox(
                                        width: 10,
                                      ),
                                      if (extendLast.isNotBlank)
                                        Label(
                                          testInfo.last['quick_error_before'] ==
                                                  false
                                              ? "正常"
                                              : "错误",
                                          testInfo.last['quick_error_before'] ==
                                                  false
                                              ? Colors.green
                                              : Colors.red,
                                          fill: true,
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(
                            height: 20,
                          ),
                          Card(
                            shape: RoundedRectangleBorder(
                                side: const BorderSide(),
                                borderRadius: BorderRadius.circular(18)),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "S.M.A.R.T. 测试",
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(
                                    height: 10,
                                  ),
                                  const Text(
                                    "S.M.A.R.T. 测试是硬盘的内置测试程序，是专为检测机械和电气误差而设计的。",
                                  ),
                                  const SizedBox(
                                    height: 20,
                                  ),
                                  if (testing) ...[
                                    Card(
                                      shape: RoundedRectangleBorder(
                                          side: const BorderSide(),
                                          borderRadius:
                                              BorderRadius.circular(5)),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 15, horizontal: 20),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Text("检测进度：$remain"),
                                            ),
                                            const SizedBox(
                                              width: 10,
                                            ),
                                            OutlinedButton(
                                              onPressed: () async {
                                                doSmartTest("stop");
                                              },
                                              child: const SizedBox(
                                                width: 20,
                                                height: 20,
                                                child: Icon(
                                                  CupertinoIcons.stop_circle,
                                                  color:
                                                      AppColors.primaryAction,
                                                  size: 16,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ] else ...[
                                    Card(
                                      shape: RoundedRectangleBorder(
                                          side: const BorderSide(),
                                          borderRadius:
                                              BorderRadius.circular(5)),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 15, horizontal: 20),
                                        child: Row(
                                          children: [
                                            const Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    "快速检测",
                                                    style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.w600),
                                                  ),
                                                  Text("将执行基本诊断测试，以检测机械和电气误差。")
                                                ],
                                              ),
                                            ),
                                            const SizedBox(
                                              width: 10,
                                            ),
                                            OutlinedButton(
                                              onPressed: () async {
                                                doSmartTest("quick");
                                              },
                                              child: const SizedBox(
                                                width: 20,
                                                height: 20,
                                                child: Icon(
                                                  CupertinoIcons
                                                      .play_arrow_solid,
                                                  color:
                                                      AppColors.primaryAction,
                                                  size: 16,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(
                                      height: 20,
                                    ),
                                    Card(
                                      shape: RoundedRectangleBorder(
                                          side: const BorderSide(),
                                          borderRadius:
                                              BorderRadius.circular(5)),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 15, horizontal: 20),
                                        child: Row(
                                          children: [
                                            const Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    "完整检测",
                                                    style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.w600),
                                                  ),
                                                  Text("将扫描整个硬盘以确保更准确的结果。"),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(
                                              width: 10,
                                            ),
                                            OutlinedButton(
                                              onPressed: () async {
                                                doSmartTest("extend");
                                              },
                                              child: const SizedBox(
                                                width: 20,
                                                height: 20,
                                                child: Icon(
                                                  CupertinoIcons
                                                      .play_arrow_solid,
                                                  color:
                                                      AppColors.primaryAction,
                                                  size: 16,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      ListView.separated(
                        padding: const EdgeInsets.all(20),
                        itemBuilder: (context, i) {
                          return _buildSmartItem(smartInfo[i]);
                        },
                        itemCount: smartInfo.length,
                        separatorBuilder: (context, i) {
                          return const SizedBox(
                            height: 20,
                          );
                        },
                      ),
                      logLoading
                          ? const Center(
                              child: Center(
                                child: CupertinoActivityIndicator(
                                  radius: 14,
                                ),
                              ),
                            )
                          : logs.isNotEmpty
                              ? ListView.separated(
                                  padding: const EdgeInsets.all(20),
                                  itemBuilder: (context, i) {
                                    return _buildLogItem(logs[i]);
                                  },
                                  separatorBuilder: (context, i) {
                                    return const SizedBox(
                                      height: 20,
                                    );
                                  },
                                  itemCount: logs.length)
                              : Center(
                                  child: Text(
                                    "暂无历史记录",
                                    style: TextStyle(
                                        color: AppTheme.of(context)
                                            .placeholderColor),
                                  ),
                                ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
