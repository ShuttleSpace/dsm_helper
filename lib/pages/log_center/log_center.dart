import 'package:garden/util/http_util.dart';
import 'package:garden/widgets/bubble_tab_indicator.dart';
import 'package:garden/widgets/log_center/log_item.dart';
import 'package:garden/widgets/log_center/log_level_filter.dart';
import 'package:garden/widgets/neu_back_button.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:garden/constants/app_constants.dart';

class LogCenter extends StatefulWidget {
  const LogCenter({super.key});

  @override
  LogCenterState createState() => LogCenterState();
}

class LogCenterState extends State<LogCenter>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List lastLogs = [];
  List logs = [];
  List logsDisplay = [];
  String logsDisplayLevel = ''; // null, info, warn, error
  List histories = [];
  bool loadingRecent = true;
  bool loadingLogs = true;
  bool loadingHistory = true;
  int errorCount = 0;
  int warnCount = 0;
  int infoCount = 0;
  int totalCount = 0;
  @override
  void initState() {
    _tabController = TabController(length: 7, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        if (_tabController.index == 1 && loadingLogs) {
          getLogs();
        }
        if (_tabController.index == 2 && loadingHistory) {
          getHistories();
        }
      }
    });
    getData();
    super.initState();
  }

  getData({int start = 0, int limit = 50}) async {
    var res = await Api.lastLog(start, limit);
    if (res['success']) {
      setState(() {
        loadingRecent = false;
        lastLogs = res['data']['logs'];
      });
    }
  }

  getLogs() async {
    var res = await Api.log(0, 1000);
    if (res['success']) {
      setState(() {
        loadingLogs = false;
        logs = res['data']['items'];
        logsDisplay.clear();
        logsDisplay.addAll(logs);
        errorCount = res['data']['errorCount'];
        warnCount = res['data']['warnCount'];
        infoCount = res['data']['infoCount'];
        totalCount = res['data']['total'];
      });
    }
  }

  getHistories() async {
    var res = await Api.logHistory();
    if (res['success']) {
      setState(() {
        loadingHistory = false;
        histories = res['data']['items'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: AppBackButton(context),
        title: const Text("日志中心"),
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
                isScrollable: true,
                controller: _tabController,
                indicatorSize: TabBarIndicatorSize.label,
                labelColor: Theme.brightnessOf(context) == Brightness.dark
                    ? Colors.white
                    : Colors.black,
                unselectedLabelColor: Colors.grey,
                indicator: BubbleTabIndicator(
                  indicatorColor: Theme.of(context).scaffoldBackgroundColor,
                  shadowColor: HttpUtil.getAdjustColor(
                      Theme.of(context).scaffoldBackgroundColor, -20),
                ),
                tabs: const [
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 10, horizontal: 5),
                    child: Text("概述"),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 10, horizontal: 5),
                    child: Text("日志"),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 10, horizontal: 5),
                    child: Text("设置历史记录"),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 10, horizontal: 5),
                    child: Text("通知"),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 10, horizontal: 5),
                    child: Text("归档设置"),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 10, horizontal: 5),
                    child: Text("日志发送"),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 10, horizontal: 5),
                    child: Text("接收日志"),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                loadingRecent
                    ? const Center(
                        child: CupertinoActivityIndicator(
                          radius: 14,
                        ),
                      )
                    : Column(
                        children: [
                          const SizedBox(
                            height: 20,
                          ),
                          Expanded(
                            child: RefreshIndicator(
                              onRefresh: () {
                                return getData(start: lastLogs.length);
                              },
                              child: ListView.separated(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: AppConstants.paddingLarge),
                                itemBuilder: (context, i) {
                                  return LogItem(
                                      log: lastLogs[i], logType: 'recent');
                                },
                                itemCount: lastLogs.length,
                                separatorBuilder: (context, i) {
                                  return const SizedBox(
                                    height: 20,
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                loadingLogs
                    ? const Center(
                        child: CupertinoActivityIndicator(
                          radius: 14,
                        ),
                      )
                    : Column(
                        children: [
                          const SizedBox(
                            height: 20,
                          ),
                          Card(
                            shape: RoundedRectangleBorder(
                                side: const BorderSide(),
                                borderRadius: BorderRadius.circular(18)),
                            margin: const EdgeInsets.symmetric(
                                horizontal: AppConstants.paddingLarge),
                            child: Padding(
                              padding: const EdgeInsets.all(
                                  AppConstants.paddingSmall),
                              child: Row(
                                children: [
                                  LogLevelFilter(
                                    count: infoCount,
                                    type: 'info',
                                    iconData: Icons.info,
                                    color: Colors.lightBlueAccent,
                                    isActive: logsDisplayLevel == 'info',
                                    onTap: () {
                                      setState(() {
                                        if (logsDisplayLevel == 'info') {
                                          logsDisplayLevel = '';
                                        } else {
                                          logsDisplayLevel = 'info';
                                        }
                                        logsDisplay
                                          ..clear()
                                          ..addAll(logs.takeWhile(
                                              (t) => t['level'] == 'info'));
                                      });
                                    },
                                  ),
                                  LogLevelFilter(
                                    count: warnCount,
                                    type: 'warning',
                                    iconData: Icons.warning,
                                    color: Colors.orange,
                                    isActive: logsDisplayLevel == 'warning',
                                    onTap: () {
                                      setState(() {
                                        if (logsDisplayLevel == 'warning') {
                                          logsDisplayLevel = '';
                                        } else {
                                          logsDisplayLevel = 'warning';
                                        }
                                        logsDisplay
                                          ..clear()
                                          ..addAll(logs.takeWhile(
                                              (t) => t['level'] == 'warning'));
                                      });
                                    },
                                  ),
                                  LogLevelFilter(
                                    count: errorCount,
                                    type: 'error',
                                    iconData: Icons.cancel,
                                    color: Colors.red,
                                    isActive: logsDisplayLevel == 'error',
                                    onTap: () {
                                      setState(() {
                                        if (logsDisplayLevel == 'error') {
                                          logsDisplayLevel = '';
                                        } else {
                                          logsDisplayLevel = 'error';
                                        }
                                        logsDisplay
                                          ..clear()
                                          ..addAll(logs.takeWhile(
                                              (t) => t['level'] == 'error'));
                                      });
                                    },
                                  ),
                                  Expanded(
                                      child: Padding(
                                    padding: const EdgeInsets.all(
                                        AppConstants.paddingSmall),
                                    child: TextField(
                                      style: const TextStyle(
                                        fontSize: 12,
                                      ),
                                      onChanged: (value) {
                                        setState(() {
                                          logsDisplay
                                            ..clear()
                                            ..addAll(logs.takeWhile((t) =>
                                                t['descr'].contains(value)));
                                        });
                                      },
                                      decoration: const InputDecoration(
                                          contentPadding:
                                              EdgeInsets.only(left: 3),
                                          isCollapsed: true,
                                          border: OutlineInputBorder(),
                                          hintText: '搜索'),
                                    ),
                                  )),
                                  Text("共$totalCount项"),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(
                            height: 20,
                          ),
                          Expanded(
                            child: ListView.separated(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: AppConstants.paddingLarge),
                              itemBuilder: (context, i) {
                                return LogItem(
                                    log: logsDisplay[i], logType: 'log');
                              },
                              itemCount: logsDisplay.length,
                              separatorBuilder: (context, i) {
                                return const SizedBox(
                                  height: 20,
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                loadingHistory
                    ? const Center(
                        child: CupertinoActivityIndicator(
                          radius: 14,
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(20),
                        itemBuilder: (context, i) {
                          return LogItem(log: histories[i], logType: 'history');
                        },
                        itemCount: histories.length,
                        separatorBuilder: (context, i) {
                          return const SizedBox(
                            height: 20,
                          );
                        },
                      ),
                const Center(
                  child: Text("暂未开发"),
                ),
                const Center(
                  child: Text("暂未开发"),
                ),
                const Center(
                  child: Text("暂未开发"),
                ),
                const Center(
                  child: Text("暂未开发"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
