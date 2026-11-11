import 'package:garden/api/dsm_api.dart';
import 'package:garden/pages/security_scan/result_card.dart';
import 'package:garden/stores/connection_store.dart';
import 'package:garden/util/http_util.dart';
import 'package:garden/util/strings.dart';
import 'package:garden/widgets/bubble_tab_indicator.dart';
import 'package:garden/widgets/neu_back_button.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:garden/constants/app_constants.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:signals_hooks/signals_hooks.dart';

class SecurityScan extends HookWidget {
  const SecurityScan({super.key});

  @override
  Widget build(BuildContext context) {
    final tickerProvider = useSingleTickerProvider();
    final tabController = useMemoized(
      () => TabController(length: 4, vsync: tickerProvider),
      const [],
    );
    useEffect(() => tabController.dispose, const []);
    final Map colors = useMemoized(() => {
          "safe": Colors.green,
          "risk": Colors.red,
          "warning": Colors.orange,
          "info": Colors.orangeAccent,
          "outOfDate": Colors.amber,
        }, const []);
    final Map texts = useMemoized(() => {
          "safe": {"title": "良好", "content": "DSM 的安全性良好"},
          "risk": {"title": "有风险", "content": "有安全风险需您注意"},
          "warning": {"title": "警告", "content": "部分安全保护设置未启用"},
          "info": {"title": "信息", "content": "信息"},
          "outOfDate": {"title": "版本过旧", "content": "有软件需更新"},
          "running": {"title": "正在扫描", "content": "正在进行扫描..."},
          "stop": {"title": "正在停止", "content": "停止扫描..."},
          "update": {"title": "正在更新", "content": "正在更新安全数据库..."},
        }, const []);
    final Map icons = useMemoized(() => {
          "safe": Icons.check_circle,
          "risk": Icons.info,
          "warning": Icons.info,
          "info": Icons.info,
          "outOfDate": Icons.info,
        }, const []);
    final Map severities = useMemoized(() => {
          "risk": 0,
          "danger": 1,
          "warning": 2,
          "outOfDate": 3,
          "info": 4,
        }, const []);
    final Map status = useMemoized(() => {
          "running": 0,
          "fail": 1,
          "pass": 2,
        }, const []);

    final ruleItems = useSignal<Map>({});
    final rules = useSignal<List>([]);
    final ruleUpdating = useSignal(true);
    final systemItems = useSignal<Map>({});
    final lastScanTime = useSignal("");
    final startTime = useSignal("");
    final sysProgress = useSignal(0);
    final sysStatus = useSignal("");
    final loading = useSignal(true);

    useEffect(() {
      () async {
        var rule = await dsmCoreSecurityScanStatusRuleGet();
        if (rule['success']) {
          ruleItems.value = rule['data']['items'];
          ruleItems.value.removeWhere((key, value) => value['status'] == "skip");
          rules.value = ruleItems.value.values.toList();
          for (var element in rules.value) {
            element['severity'] = severities[element['severity']];
            element['status'] = status[element['status']];
          }
          rules.value.sort((v1, v2) {
            try {
              if (v1['status'] > v2['status']) {
                return 1;
              } else if (v1['status'] < v2['status']) {
                return -1;
              } else {
                if (v1['severity'] > v2['severity']) {
                  return 1;
                } else if (v1['severity'] < v2['severity']) {
                  return -1;
                } else {
                  return 0;
                }
              }
            } catch (e) {
              return 0;
            }
          });
          ruleUpdating.value = rule['data']['isUpdating'];
        }
        var system = await dsmCoreSecurityScanStatusSystemGet();
        if (system['success']) {
          loading.value = false;
          systemItems.value = system['data']['items'];
          lastScanTime.value = system['data']['lastScanTime'];
          startTime.value = system['data']['startTime'];
          sysProgress.value = system['data']['sysProgress'];
          sysStatus.value = system['data']['sysStatus'];
        }
      }();
      return null;
    }, const []);

    String getTitle(String strId, int scanStatus) {
      if (webManagerStrings['rules'][
              "${strId}_desc_${scanStatus == 2 ? "good" : scanStatus == 0 ? "running" : "bad"}"] !=
          null) {
        return webManagerStrings['rules'][
            "${strId}_desc_${scanStatus == 2 ? "good" : scanStatus == 0 ? "running" : "bad"}"];
      } else {
        if (connectionStore.strings
                    .watch(context)['SYNO.SDS.SecurityScan.Instance'] !=
                null &&
            connectionStore.strings['SYNO.SDS.SecurityScan.Instance']
                    ['rules'] !=
                null) {
          return (connectionStore.strings['SYNO.SDS.SecurityScan.Instance']
                      ['rules'][
                  "${strId}_desc_${scanStatus == 2 ? "good" : scanStatus == 0 ? "running" : "bad"}"] ??
              strId);
        } else {
          return strId;
        }
      }
    }

    List<Widget> buildItemList() {
      List<Widget> list = [];

      for (var value in rules.value) {
        value['strId'] = value['strId'].replaceAll("_v2", "");
        list.add(Card(
          shape: RoundedRectangleBorder(
              side: const BorderSide(), borderRadius: BorderRadius.circular(18)),
          margin: const EdgeInsets.only(bottom: 20),
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.paddingLarge),
            child: Row(
              children: [
                Expanded(
                  child: Text(getTitle(value['strId'], value['status'])),
                ),
                value['status'] == 2
                    ? const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                      )
                    : value['status'] == 0
                        ? const CupertinoActivityIndicator()
                        : const Icon(
                            Icons.info,
                            color: Colors.red,
                          ),
              ],
            ),
          ),
        ));
      }
      return list;
    }

    return Scaffold(
      appBar: AppBar(
        leading: AppBackButton(context),
        title: const Text("安全顾问"),
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
                        child: Text("总览"),
                      ),
                      Padding(
                        padding:
                            EdgeInsets.symmetric(vertical: 10, horizontal: 5),
                        child: Text("结果"),
                      ),
                      Padding(
                        padding:
                            EdgeInsets.symmetric(vertical: 10, horizontal: 5),
                        child: Text("登录分析"),
                      ),
                      Padding(
                        padding:
                            EdgeInsets.symmetric(vertical: 10, horizontal: 5),
                        child: Text("高级设置"),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    controller: tabController,
                    children: [
                      ListView(
                        padding: const EdgeInsets.all(20),
                        children: [
                          Card(
                            shape: RoundedRectangleBorder(
                                side: const BorderSide(),
                                borderRadius: BorderRadius.circular(18)),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Row(
                                children: [
                                  sysStatus.value == "running"
                                      ? CircularPercentIndicator(
                                          radius: 40,
                                          // progressColor: Colors.lightBlueAccent,
                                          animation: true,
                                          linearGradient: LinearGradient(
                                            colors: sysProgress.value < 90
                                                ? [
                                                    Colors.blue,
                                                    Colors.blueAccent,
                                                  ]
                                                : [
                                                    Colors.green,
                                                    Colors.greenAccent,
                                                  ],
                                          ),
                                          animateFromLastPercent: true,
                                          circularStrokeCap:
                                              CircularStrokeCap.round,
                                          lineWidth: 12,
                                          backgroundColor: Colors.black12,
                                          percent: sysProgress.value / 100,
                                          center: Text(
                                            "${sysProgress.value}%",
                                            style: TextStyle(
                                                color: sysProgress.value < 90
                                                    ? Colors.blue
                                                    : Colors.red,
                                                fontSize: 22),
                                          ),
                                        )
                                      : Icon(
                                          icons[sysStatus.value],
                                          color: colors[sysStatus.value],
                                          size: 70,
                                        ),
                                  const SizedBox(
                                    width: 10,
                                  ),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        texts[sysStatus.value] != null
                                            ? texts[sysStatus.value]['title']
                                            : "未知状态",
                                        style: TextStyle(
                                            fontSize: 20,
                                            color: colors[sysStatus.value]),
                                      ),
                                      Text(
                                        texts[sysStatus.value] != null
                                            ? texts[sysStatus.value]['content']
                                            : "未知状态",
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                      if (lastScanTime.value.isNotBlank)
                                        Text(
                                          "上次扫描：${DateTime.fromMillisecondsSinceEpoch(int.parse(lastScanTime.value) * 1000).timeAgo}",
                                          style: const TextStyle(fontSize: 14),
                                        )
                                      else
                                        Text(
                                          "已运行：${(DateTime.now().secondsSinceEpoch - int.parse(startTime.value)).timeRemaining()}",
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                    ],
                                  )
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(
                            height: 20,
                          ),
                          ResultCard(systemItems.value['malware']),
                          ResultCard(systemItems.value['systemCheck']),
                          ResultCard(systemItems.value['userInfo']),
                          ResultCard(systemItems.value['network']),
                          ResultCard(systemItems.value['update']),
                        ],
                      ),
                      ListView(
                        padding: const EdgeInsets.all(20),
                        children: buildItemList(),
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
