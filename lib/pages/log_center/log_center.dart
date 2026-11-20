import 'package:garden/api/dsm_api.dart';
import 'package:garden/extensions/color.dart';
import 'package:garden/widgets/bubble_tab_indicator.dart';
import 'package:garden/widgets/log_center/log_item.dart';
import 'package:garden/widgets/log_center/log_level_filter.dart';
import 'package:garden/widgets/neu_back_button.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:garden/constants/app_constants.dart';
import 'package:signals_hooks/signals_hooks.dart';

class LogCenter extends HookWidget {
  const LogCenter({super.key});

  @override
  Widget build(BuildContext context) {
    final tickerProvider = useSingleTickerProvider();
    final tabController = useMemoized(
      () => TabController(length: 7, vsync: tickerProvider),
      const [],
    );
    final lastLogs = useSignal<List>([]);
    final logs = useSignal<List>([]);
    final logsDisplay = useSignal<List>([]);
    final logsDisplayLevel = useSignal(''); // null, info, warn, error
    final histories = useSignal<List>([]);
    final loadingRecent = useSignal(true);
    final loadingLogs = useSignal(true);
    final loadingHistory = useSignal(true);
    final errorCount = useSignal(0);
    final warnCount = useSignal(0);
    final infoCount = useSignal(0);
    final totalCount = useSignal(0);

    Future<void> getData({int start = 0, int limit = 50}) async {
      try {
        final data = await dsmCoreSyslogClientLatestLogs(start, limit);
        lastLogs.value = data['logs'] ?? [];
      } catch (e) {
        // 旧层失败时保持空列表，这里同样不打断页面。
      } finally {
        loadingRecent.value = false;
      }
    }

    Future<void> getLogs() async {
      try {
        final data = await dsmCoreSyslogClientLogs(0, 1000);
        logs.value = data['items'] ?? [];
        logsDisplay.value = List.of(logs.value);
        errorCount.value = data['errorCount'] ?? 0;
        warnCount.value = data['warnCount'] ?? 0;
        infoCount.value = data['infoCount'] ?? 0;
        totalCount.value = data['total'] ?? 0;
      } catch (e) {
        // 同上，失败时保留空列表。
      } finally {
        loadingLogs.value = false;
      }
    }

    Future<void> getHistories() async {
      try {
        final data = await dsmLogCenterHistoryList();
        histories.value = data['items'] ?? [];
      } catch (e) {
        // 同上。
      } finally {
        loadingHistory.value = false;
      }
    }

    useEffect(() {
      void listener() {
        if (!tabController.indexIsChanging) {
          if (tabController.index == 1 && loadingLogs.value) {
            getLogs();
          }
          if (tabController.index == 2 && loadingHistory.value) {
            getHistories();
          }
        }
      }

      tabController.addListener(listener);
      getData();
      return () {
        tabController.removeListener(listener);
        tabController.dispose();
      };
    }, const []);

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
                controller: tabController,
                indicatorSize: TabBarIndicatorSize.label,
                labelColor: Theme.brightnessOf(context) == Brightness.dark
                    ? Colors.white
                    : Colors.black,
                unselectedLabelColor: Colors.grey,
                indicator: BubbleTabIndicator(
                  indicatorColor: Theme.of(context).scaffoldBackgroundColor,
                  shadowColor:
                      Theme.of(context).scaffoldBackgroundColor.adjust(-20),
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
              controller: tabController,
              children: [
                loadingRecent.value
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
                                return getData(start: lastLogs.value.length);
                              },
                              child: ListView.separated(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: AppConstants.paddingLarge),
                                itemBuilder: (context, i) {
                                  return LogItem(
                                      log: lastLogs.value[i], logType: 'recent');
                                },
                                itemCount: lastLogs.value.length,
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
                loadingLogs.value
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
                                    count: infoCount.value,
                                    type: 'info',
                                    iconData: Icons.info,
                                    color: Colors.lightBlueAccent,
                                    isActive: logsDisplayLevel.value == 'info',
                                    onTap: () {
                                      if (logsDisplayLevel.value == 'info') {
                                        logsDisplayLevel.value = '';
                                      } else {
                                        logsDisplayLevel.value = 'info';
                                      }
                                      logsDisplay.value = logs.value
                                          .takeWhile((t) => t['level'] == 'info')
                                          .toList();
                                    },
                                  ),
                                  LogLevelFilter(
                                    count: warnCount.value,
                                    type: 'warning',
                                    iconData: Icons.warning,
                                    color: Colors.orange,
                                    isActive:
                                        logsDisplayLevel.value == 'warning',
                                    onTap: () {
                                      if (logsDisplayLevel.value == 'warning') {
                                        logsDisplayLevel.value = '';
                                      } else {
                                        logsDisplayLevel.value = 'warning';
                                      }
                                      logsDisplay.value = logs.value
                                          .takeWhile(
                                              (t) => t['level'] == 'warning')
                                          .toList();
                                    },
                                  ),
                                  LogLevelFilter(
                                    count: errorCount.value,
                                    type: 'error',
                                    iconData: Icons.cancel,
                                    color: Colors.red,
                                    isActive: logsDisplayLevel.value == 'error',
                                    onTap: () {
                                      if (logsDisplayLevel.value == 'error') {
                                        logsDisplayLevel.value = '';
                                      } else {
                                        logsDisplayLevel.value = 'error';
                                      }
                                      logsDisplay.value = logs.value
                                          .takeWhile((t) => t['level'] == 'error')
                                          .toList();
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
                                        logsDisplay.value = logs.value
                                            .takeWhile((t) =>
                                                t['descr'].contains(value))
                                            .toList();
                                      },
                                      decoration: const InputDecoration(
                                          contentPadding:
                                              EdgeInsets.only(left: 3),
                                          isCollapsed: true,
                                          border: OutlineInputBorder(),
                                          hintText: '搜索'),
                                    ),
                                  )),
                                  Text("共${totalCount.value}项"),
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
                                    log: logsDisplay.value[i], logType: 'log');
                              },
                              itemCount: logsDisplay.value.length,
                              separatorBuilder: (context, i) {
                                return const SizedBox(
                                  height: 20,
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                loadingHistory.value
                    ? const Center(
                        child: CupertinoActivityIndicator(
                          radius: 14,
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(20),
                        itemBuilder: (context, i) {
                          return LogItem(
                              log: histories.value[i], logType: 'history');
                        },
                        itemCount: histories.value.length,
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
