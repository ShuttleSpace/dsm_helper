import 'package:garden/util/function.dart';
import 'package:garden/widgets/bubble_tab_indicator.dart';
import 'package:garden/widgets/label.dart';
import 'package:garden/widgets/neu_back_button.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class LogCenter extends StatefulWidget {
  @override
  _LogCenterState createState() => _LogCenterState();
}

class _LogCenterState extends State<LogCenter>
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

  Widget _buildRecentLogItem(log) {
    return Card(
      shape: RoundedRectangleBorder(
          side: BorderSide(), borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Label(log['prio'] == "info" ? "信息" : log['prio'],
                    log['prio'] == "info" ? Colors.green : Colors.red),
                SizedBox(
                  width: 5,
                ),
                Text(
                  log['fac'],
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(
                  width: 10,
                ),
                Expanded(
                  child: Text(
                    "${log['ldate']}${log['ltime']}",
                    textAlign: TextAlign.right,
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ],
            ),
            SizedBox(
              height: 10,
            ),
            Text("${log['msg'].trim()}"),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryItem(log) {
    return Card(
      shape: RoundedRectangleBorder(
          side: BorderSide(), borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Label(log['level'] == 0 ? "信息" : "${log['level']}",
                    log['level'] == 0 ? Colors.green : Colors.red),
                SizedBox(
                  width: 5,
                ),
                Text(
                  log['user'],
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(
                  width: 10,
                ),
                Expanded(
                  child: Text(
                    "${log['time']}",
                    textAlign: TextAlign.right,
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ],
            ),
            SizedBox(
              height: 10,
            ),
            Text("${log['event'].trim()}"),
          ],
        ),
      ),
    );
  }

  Widget _buildLogItem(log) {
    return Card(
      shape: RoundedRectangleBorder(
          side: BorderSide(), borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Label(
                    log['level'] == "info"
                        ? "信息"
                        : log['level'] == "warn"
                            ? "警告"
                            : log['level'] == "error"
                                ? "错误"
                                : log['level'],
                    log['level'] == "info"
                        ? Colors.green
                        : log['level'] == "warn"
                            ? Colors.orange
                            : log['level'] == "error"
                                ? Colors.red
                                : Colors.red),
                SizedBox(
                  width: 5,
                ),
                Label(log['logtype'], Colors.lightBlueAccent),
                SizedBox(
                  width: 5,
                ),
                Text(
                  log['who'],
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(
                  width: 10,
                ),
                Expanded(
                  child: Text(
                    "${log['time']}",
                    textAlign: TextAlign.right,
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ],
            ),
            SizedBox(
              height: 10,
            ),
            Text("${log['descr'].trim()}"),
          ],
        ),
      ),
    );
  }

  Widget _buildLogLevelFilter(
      int count, String type, IconData icondata, Color color) {
    return InkWell(
      onTap: () {
        setState(() {
          if (logsDisplayLevel == type) {
            logsDisplayLevel = '';
          } else {
            logsDisplayLevel = type;
          }
          logsDisplay
            ..clear()
            ..addAll(logs.takeWhile((t) => t['level'] == type));
        });
      },
      child: ColorFiltered(
        colorFilter: logsDisplayLevel == type
            ? ColorFilter.mode(Colors.transparent, BlendMode.multiply)
            : ColorFilter.mode(Colors.grey[100]!, BlendMode.saturation),
        child: Row(
          children: [
            Icon(
              icondata,
              color: color,
              size: 20,
            ),
            SizedBox(
              width: 5,
            ),
            Text("$count"),
            SizedBox(
              width: 5,
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
        title: Text("日志中心"),
      ),
      body: Column(
        children: [
          Card(
            shape: RoundedRectangleBorder(
                side: BorderSide(), borderRadius: BorderRadius.circular(18)),
            margin: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: TabBar(
                dividerHeight: 0,
                isScrollable: true,
                controller: _tabController,
                indicatorSize: TabBarIndicatorSize.label,
                labelColor: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black,
                unselectedLabelColor: Colors.grey,
                indicator: BubbleTabIndicator(
                  indicatorColor: Theme.of(context).scaffoldBackgroundColor,
                  shadowColor: Util.instance.getAdjustColor(
                      Theme.of(context).scaffoldBackgroundColor, -20),
                ),
                tabs: [
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
                    ? Center(
                        child: CupertinoActivityIndicator(
                          radius: 14,
                        ),
                      )
                    : Column(
                        children: [
                          SizedBox(
                            height: 20,
                          ),
                          Expanded(
                            child: RefreshIndicator(
                              onRefresh: () {
                                return getData(start: lastLogs.length);
                              },
                              child: ListView.separated(
                                padding: EdgeInsets.symmetric(horizontal: 20),
                                itemBuilder: (context, i) {
                                  return _buildRecentLogItem(lastLogs[i]);
                                },
                                itemCount: lastLogs.length,
                                separatorBuilder: (context, i) {
                                  return SizedBox(
                                    height: 20,
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                loadingLogs
                    ? Center(
                        child: CupertinoActivityIndicator(
                          radius: 14,
                        ),
                      )
                    : Column(
                        children: [
                          SizedBox(
                            height: 20,
                          ),
                          Card(
                            shape: RoundedRectangleBorder(
                                side: BorderSide(),
                                borderRadius: BorderRadius.circular(18)),
                            margin: EdgeInsets.symmetric(horizontal: 20),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Row(
                                children: [
                                  _buildLogLevelFilter(infoCount, 'info',
                                      Icons.info, Colors.lightBlueAccent),
                                  _buildLogLevelFilter(warnCount, 'warning',
                                      Icons.warning, Colors.orange),
                                  _buildLogLevelFilter(errorCount, 'error',
                                      Icons.cancel, Colors.red),
                                  Expanded(
                                      child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: TextField(
                                      style: TextStyle(
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
                                      decoration: InputDecoration(
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
                          SizedBox(
                            height: 20,
                          ),
                          Expanded(
                            child: ListView.separated(
                              padding: EdgeInsets.symmetric(horizontal: 20),
                              itemBuilder: (context, i) {
                                return _buildLogItem(logsDisplay[i]);
                              },
                              itemCount: logsDisplay.length,
                              separatorBuilder: (context, i) {
                                return SizedBox(
                                  height: 20,
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                loadingHistory
                    ? Center(
                        child: CupertinoActivityIndicator(
                          radius: 14,
                        ),
                      )
                    : ListView.separated(
                        padding: EdgeInsets.all(20),
                        itemBuilder: (context, i) {
                          return _buildHistoryItem(histories[i]);
                        },
                        itemCount: histories.length,
                        separatorBuilder: (context, i) {
                          return SizedBox(
                            height: 20,
                          );
                        },
                      ),
                Center(
                  child: Text("暂未开发"),
                ),
                Center(
                  child: Text("暂未开发"),
                ),
                Center(
                  child: Text("暂未开发"),
                ),
                Center(
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
