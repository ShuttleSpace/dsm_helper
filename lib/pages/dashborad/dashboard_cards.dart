import 'dart:math';

import 'package:extended_image/extended_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:garden/api/dsm_api.dart';
import 'package:garden/constants/app_constants.dart';
import 'package:garden/extensions/context.dart';
import 'package:garden/extensions/int.dart';
import 'package:garden/extensions/signal.dart';
import 'package:garden/extensions/string.dart';
import 'package:garden/pages/control_panel/info/info.dart';
import 'package:garden/pages/control_panel/task_scheduler/task_scheduler.dart';
import 'package:garden/pages/dashborad/dashboard_monitor_resource_widget.dart';
import 'package:garden/pages/log_center/log_center.dart';
import 'package:garden/pages/resource_monitor/resource_monitor.dart';
import 'package:garden/stores/connection_store.dart';
import 'package:garden/stores/settings_store.dart';
import 'package:garden/theme/app_theme.dart';
import 'package:garden/util/log.dart';
import 'package:garden/util/ui_util.dart';
import 'package:garden/widgets/label.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:signals_hooks/signals_hooks.dart';

class DashboardSystemHealthCard extends HookWidget {
  const DashboardSystemHealthCard(
      {super.key,
      required this.storageVolumes,
      required this.storageDisks,
      required this.storageSsdCaches,
      required this.systemData,
      required this.wallpaper,
      required this.sessionHostname});

  final ReadonlySignal<List> storageVolumes;
  final ReadonlySignal<List> storageDisks;
  final ReadonlySignal<List> storageSsdCaches;
  final ReadonlySignal<Map> systemData;
  final ReadonlySignal<Map> wallpaper;
  final ReadonlySignal<String> sessionHostname;

  static const widget = 'SYNO.SDS.SystemInfoApp.SystemHealthWidget';

  @override
  Widget build(BuildContext context) {
    final heatDissipation = useComputed(() =>
        "${systemData['sys_temp']}℃ ${systemData['temperature_warning'] == null ? (systemData['sys_temp'] > 80 ? "警告" : "正常") : (systemData['temperature_warning'] ? "警告" : "正常")}");
    return GestureDetector(
      onTap: () {
        if (connectionStore.notVisitorAccount.value) {
          Navigator.of(context).push(CupertinoPageRoute(builder: (context) {
            return SystemInfo(0, systemData, storageVolumes,
                storageDisks);
          }));
        }
      },
      child: Card(
        shape: RoundedRectangleBorder(
            side: const BorderSide(), borderRadius: BorderRadius.circular(18)),
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Stack(
            children: [
              /* wallpaper */
              Watch((context) {
                final customize = wallpaper.select((v) =>
                    v['customizeWallpaper'] == true ||
                    v['customizeBackground'] == true);
                if (settingsStore.showWallpaper.value && customize.value) {
                  return ExtendedImage.network(
                    AppConstants.wallpaper,
                    height: 170,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    shape: BoxShape.rectangle,
                    borderRadius: BorderRadius.circular(20),
                  );
                }
                return const SizedBox.shrink();
              }),
              /* dark theme */
              Builder(builder: (context) {
                if (Theme.brightnessOf(context) == Brightness.dark) {
                  return Container(
                    height: 170,
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .scaffoldBackgroundColor
                          .withValues(alpha: .1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  );
                }
                return const SizedBox.shrink();
              }),
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: DefaultTextStyle(
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Image.asset(
                              "assets/icons/info.png",
                              width: 26,
                              height: 26,
                            ),
                            const SizedBox(
                              width: 10,
                            ),
                            const Text(
                              "系统状态",
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        const SizedBox(
                          height: 5,
                        ),
                        // product model
                        Watch<Widget>((context) {
                          final model =
                              systemData.select((v) => v['model']);
                          if (model.value != null) {
                            Padding(
                              padding: const EdgeInsets.only(top: 5),
                              child: Row(
                                children: [
                                  const Text("产品型号："),
                                  Text("${model.value}"),
                                ],
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        }),
                        const SizedBox(
                          height: 5,
                        ),
                        Watch<Widget>(
                          (context) => Row(
                            children: [
                              const Text("系统名称："),
                              Text(sessionHostname.value),
                            ],
                          ),
                        ),
                        // 散热
                        Watch<Widget>((context) {
                          final sysTemp =
                              systemData.select((v) => v['sys_temp']);
                          final temperatureWarning = systemData
                              .select((v) => v['temperature_warning']);
                          if (sysTemp.value != null) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 5),
                              child: Row(
                                children: [
                                  const Text("散热状态："),
                                  Text(
                                    heatDissipation.value,
                                    style: TextStyle(
                                        color: sysTemp.value == null
                                            ? (sysTemp.value > 80
                                                ? context.errorColor
                                                : context.successColor)
                                            : (temperatureWarning.value
                                                ? context.errorColor
                                                : context.successColor)),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            );
                          } else {
                            return const SizedBox.shrink();
                          }
                        }),
                        // 运行时间
                        Watch<Widget>((context) {
                          final upTime =
                              systemData.select((v) => v['up_time']);
                          if (upTime.value != null && upTime.value.isNotEmpty) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 5),
                              child: Row(
                                children: [
                                  const Text("运行时间："),
                                  Text(parseOpTime(upTime.value)),
                                ],
                              ),
                            );
                          } else {
                            return const SizedBox.shrink();
                          }
                        })
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DashboardConnectionLogCard extends HookWidget {
  const DashboardConnectionLogCard({super.key});

  @override
  Widget build(BuildContext context) {
    final connectedUsers = useListSignal<Map>([]);
    final error = useSignal('');

    fetchData() {
      dsmCoreCurrentConnectionList().then((res) {
        final data = (res['items'] as List).map((e) {
          e['running'] = true;
          return e as Map;
        }).toList();
        connectedUsers.value = data;
        debugPrint('✍️🌹 ${connectedUsers.length}');
      }).catchError((e) {
        error.value = e.toString();
      });
    }

    onKickout(Map e) async {
      // TODO: set running = true, update user in list
      connectedUsers.update1(e, (ov) {
        ov['running'] = true;
        return ov;
      });
      try {
        await dsmCoreCurrentConnectionKickConnection(
            {"who": e['who'], "from": e['from']});
        UiUtil.toast("连接已终止");
        // TODO: set running = true, update user in list
        connectedUsers.update1(e, (ov) {
          ov['running'] = false;
          return ov;
        });
      } on Exception catch (e) {
        UiUtil.toast("连接终止失败：${e.toString()}");
      }
      if (context.mounted) {
        Navigator.of(context).pop();
      }
    }

    useEffect(() {
      fetchData();
      return null;
    }, const []);

    return Card(
      shape: RoundedRectangleBorder(
          side: const BorderSide(), borderRadius: BorderRadius.circular(18)),
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              height: 20,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Image.asset(
                    "assets/icons/user.png",
                    width: 26,
                    height: 26,
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  const Text(
                    "登录用户",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  const _CardItemCollapse("ConnectionLog")
                ],
              ),
            ),
            Builder(builder: (context) {
              if (connectedUsers.watch(context).isEmpty) {
                return TextButton(
                    onPressed: () {},
                    child: Text.rich(TextSpan(
                        text: error.isNotEmpty ? error.value : "暂无用户登录",
                        children: [
                          TextSpan(
                              text: "\t\t点击重试", style: _retryTextStyle(context))
                        ])));
              } else if (context.isCardItemCollapsed('ConnectionLog')) {
                return Flexible(
                    child: Column(
                  children: connectedUsers
                      .map((e) => _DashboardConnectionLogItem(
                            user: (e).toSignal(),
                            onKickout: () {
                              onKickout(e);
                            },
                          ))
                      .toList(),
                ));
              } else {
                return const SizedBox.shrink();
              }
            }),
            const SizedBox(
              height: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardConnectionLogItem extends StatelessWidget {
  const _DashboardConnectionLogItem(
      {required this.user, required this.onKickout});
  /* {
    "can_be_kicked": true,
    "descr": "File Station",
    "did": "xAc77ylaoHQ",
    "first_login_time": "2026/03/03 11:31:46",
    "from": "192.168.8.76",
    "is_amfa": false,
    "is_current_connected": false,
    "is_otp_trusted": false,
    "location": "",
    "pid": 1,
    "protocol": "HTTP/HTTPS",
    "time": "2026/03/03 11:31:46",
    "type": "HTTP/HTTPS",
    "user_agent": "",
    "user_can_be_disabled": true,
    "who": "humphrey"
  } */
  final ReadonlySignal<Map> user;
  final VoidCallback onKickout;

  @override
  Widget build(BuildContext context) {
    DateTime loginTime =
        DateTime.parse(user['time'].toString().replaceAll("/", "-"));
    DateTime currentTime = DateTime.now();
    Map timeLong = currentTime.difference(loginTime).inSeconds.formatTime();
    return Card(
      shape: RoundedRectangleBorder(
          side: const BorderSide(), borderRadius: BorderRadius.circular(18)),
      margin: const EdgeInsets.only(top: 20, left: 20, right: 20),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Flexible(
              child: Text(
                "${user['who']}",
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Flexible(
              child: Text(
                "${user['type']}",
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Flexible(
              child: Text(
                "${timeLong['hours'].toString().padLeft(2, "0")}:${timeLong['minutes'].toString().padLeft(2, "0")}:${timeLong['seconds'].toString().padLeft(2, "0")}",
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
              ),
            ),
            const SizedBox(
              width: 5,
            ),
            OutlinedButton(
              onPressed: () async {
                if (!user['can_be_kicked']) {
                  UiUtil.toast("当前用户无法被踢出!");
                  return;
                }
                if (user['running'] == true) {
                  UiUtil.toast("当前用户正在运行中!");
                  return;
                }
                onDisconnectAlert(context);
              },
              child: SizedBox(
                width: 20,
                height: 20,
                child: user.select((v) => v['running']).watch(context) != true
                    ? const CupertinoActivityIndicator()
                    : const Icon(
                        Icons.remove_circle_outline,
                        color: Colors.red,
                        size: 18,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<dynamic> onDisconnectAlert(BuildContext context) {
    return showCupertinoModalPopup(
      context: context,
      builder: (context) {
        return Material(
          color: Colors.transparent,
          child: Card(
            shape: RoundedRectangleBorder(
                side: const BorderSide(),
                borderRadius: BorderRadius.circular(18)),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const Text(
                      "终止连接",
                      style: TextStyle(
                          fontSize: 20,
                          color: Colors.black,
                          fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(
                      height: 12,
                    ),
                    const Text(
                      "确认要终止此连接？",
                      style: TextStyle(
                          fontSize: 20,
                          color: Colors.black,
                          fontWeight: FontWeight.w400),
                    ),
                    const SizedBox(
                      height: 22,
                    ),
                    Row(
                      children: [
                        Flexible(
                          child: OutlinedButton(
                            onPressed: onKickout,
                            child: Text(
                              "终止连接",
                              style: TextStyle(
                                  fontSize: 18,
                                  color: AppTheme.of(context).errorColor),
                            ),
                          ),
                        ),
                        const SizedBox(
                          width: 16,
                        ),
                        Flexible(
                          child: OutlinedButton(
                            onPressed: () async {
                              Navigator.of(context).pop();
                            },
                            child: const Text(
                              "取消",
                              style: TextStyle(fontSize: 18),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: 8,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class DashboardTaskSchedulerCard extends HookWidget {
  const DashboardTaskSchedulerCard({super.key});

  @override
  Widget build(BuildContext context) {
    final schedulerTasks = useListSignal([]);
    final error = useSignal('');

    fetchData() {
      dsmCoreTaskSchedulerList(
        sortBy: 'next_trigger_time',
        sortDirection: 'ASC',
      ).then((res) {
        schedulerTasks.value = res['tasks'] as List;
        debugPrint("哇咔咔🎊🎊🎊");
      }).catchError((e) {
        error.value = e.toString();
      });
    }

    useEffect(() {
      fetchData();
      return null;
    }, const []);

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(CupertinoPageRoute(builder: (context) {
          return const TaskScheduler();
        }));
      },
      child: Card(
        shape: RoundedRectangleBorder(
            side: const BorderSide(), borderRadius: BorderRadius.circular(18)),
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              const SizedBox(
                height: 20,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Image.asset(
                      "assets/icons/task.png",
                      width: 26,
                      height: 26,
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                    const Text(
                      "计划任务",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    const Spacer(),
                    const _CardItemCollapse("TaskScheduler")
                  ],
                ),
              ),
              Builder(builder: (context) {
                if (schedulerTasks.watch(context).isEmpty) {
                  return Text.rich(TextSpan(
                      text: error.isNotEmpty ? error.value : '暂无任务',
                      children: [
                        TextSpan(
                            text: '\t\t点击重试', style: _retryTextStyle(context)),
                      ]));
                }
                if (context.isCardItemCollapsed('TaskScheduler')) {
                  return Flexible(
                      child: Column(
                    children: schedulerTasks
                        .map((e) => _DashboardTashSchedulerItem(e))
                        .toList(),
                  ));
                }
                return const SizedBox.shrink();
              }),
              const SizedBox(
                height: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardTashSchedulerItem extends StatelessWidget {
  _DashboardTashSchedulerItem(this.task);
  final ReadonlySignal<Map> task;
  final running = signal(false);
  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
          side: const BorderSide(), borderRadius: BorderRadius.circular(18)),
      margin: const EdgeInsets.only(top: 20, left: 20, right: 20),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            Flexible(
              child: Text(
                "${task['name']}",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(
              width: 5,
            ),
            Text(
              "${task['next_trigger_time']}",
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(
              width: 5,
            ),
            OutlinedButton(
              onPressed: () async {
                if (running.value) {
                  return;
                }
                running.value = true;
                dsmCoreTaskSchedulerRun(task['id']).then((res) {
                  UiUtil.toast('任务计划执行成功');
                }).catchError((e) {
                  UiUtil.toast('任务计划执行失败，code：${e.toString()}');
                });
              },
              child: SizedBox(
                width: 20,
                height: 20,
                child: running.watch(context)
                    ? const CupertinoActivityIndicator()
                    : const Icon(
                        CupertinoIcons.play_arrow_solid,
                        color: Color(0xffff9813),
                        size: 16,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DashboardRecentLogCard extends HookWidget {
  const DashboardRecentLogCard({super.key});

  @override
  Widget build(BuildContext context) {
    final recentLogs = useListSignal([]);
    final error = useSignal('');

    fetchData() {
      dsmCoreSyslogClientLogList(
              logtype: 'ftp,filestation,webdav,cifs,tftp,afp',
              target: 'LOCAL',
              sortDirection: 'desc',
              limit: 50,
              offset: 0)
          .then((res) {
        recentLogs.value = res['items'] as List;
      }).catchError((e) {
        error.value = e.toString();
      });
    }

    useEffect(() {
      fetchData();
      return null;
    }, const []);

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(CupertinoPageRoute(
            builder: (context) {
              return const LogCenter();
            },
            settings: const RouteSettings(name: "log_center")));
      },
      child: Card(
        shape: RoundedRectangleBorder(
            side: const BorderSide(), borderRadius: BorderRadius.circular(18)),
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              const SizedBox(
                height: 20,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Image.asset(
                      "assets/icons/log.png",
                      width: 26,
                      height: 26,
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                    const Text(
                      "最新日志",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    const Spacer(),
                    const _CardItemCollapse("RecentLog")
                  ],
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              Builder(builder: (context) {
                if (recentLogs.watch(context).isEmpty) {
                  return TextButton(
                      onPressed: fetchData,
                      child: Text.rich(TextSpan(
                          text: error.isEmpty ? '暂无日志' : error.value,
                          children: [
                            TextSpan(
                                text: '\t\t点击重试',
                                style: _retryTextStyle(context))
                          ])));
                }
                if (context.isCardItemCollapsed('RecentLog')) {
                  return CupertinoScrollbar(
                    child: ListView.builder(
                      itemCount: recentLogs.length,
                      itemBuilder: (context, i) {
                        return Card(
                          shape: RoundedRectangleBorder(
                              side: const BorderSide(),
                              borderRadius: BorderRadius.circular(18)),
                          clipBehavior: Clip.hardEdge,
                          margin: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Text(
                              maxLines: 3,
                              "${recentLogs.value[i]?['msg'] ?? ''}",
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                }
                return const SizedBox.shrink();
              }),
              const SizedBox(
                height: 10,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DashboardResourceMonitorCard extends HookWidget {
  const DashboardResourceMonitorCard({super.key});

  @override
  Widget build(BuildContext context) {
    final monitoredResources = useMapSignal({});
    final error = useSignal('');

    final networks = useMemoized(
        () => List.generate(20, (i) => {"tx": 0, "rx": 0}), const []);

    int maxNetworkSpeed() {
      int maxSpeed = 0;
      for (int i = 0; i < networks.length; i++) {
        int maxVal = max(networks[i]['rx'] ?? 0, networks[i]['tx'] ?? 0);
        if (maxSpeed < maxVal) {
          maxSpeed = maxVal;
        }
      }
      return maxSpeed;
    }

    fetchData() {
      dsmCoreSystemUtilization(
          ["cpu", "memory", "network", "lun", "disk", "space"]).then((res) {
        monitoredResources.value = res as Map<String, dynamic>;
        if (networks.length > 20) {
          networks.removeAt(0);
        }
        Log.debug('🌊: ${monitoredResources.isEmpty}');
        final networkData = res['network'][0] as Map;
        networks.add({
          "tx": (networkData['tx'] as num?)?.toInt() ?? 0,
          "rx": (networkData['rx'] as num?)?.toInt() ?? 0
        });
      }).catchError((e) {
        error.value = e.toString();
      });
    }

    useEffect(() {
      fetchData();
      return null;
    }, const []);

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(CupertinoPageRoute(builder: (context) {
          return const ResourceMonitor();
        }));
      },
      child: Card(
        shape: RoundedRectangleBorder(
            side: const BorderSide(), borderRadius: BorderRadius.circular(18)),
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              const SizedBox(
                height: 20,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Image.asset(
                      "assets/icons/resources.png",
                      width: 26,
                      height: 26,
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                    const Text(
                      "资源监控",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    const Spacer(),
                    const _CardItemCollapse("ResourceMonitor")
                  ],
                ),
              ),
              Builder(builder: (context) {
                if (monitoredResources.watch(context).isEmpty) {
                  return TextButton(
                      onPressed: fetchData,
                      child: Text.rich(TextSpan(
                          text: error.isEmpty ? '暂时获取不到系统数据' : error.value,
                          children: [
                            TextSpan(
                                text: '\t\t点击重试',
                                style: _retryTextStyle(context))
                          ])));
                }
                if (context.isCardItemCollapsed('ResourceMonitor')) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        height: 10,
                      ),
                      PerformanceCpuWidget(
                          monitoredResources: monitoredResources),
                      const SizedBox(
                        height: 15,
                      ),
                      PerformanceRamWidget(
                          monitoredResources: monitoredResources),
                      const SizedBox(
                        height: 15,
                      ),
                      PerformanceNetowrkWidget(
                          monitoredResources: monitoredResources),
                      const SizedBox(
                        height: 15,
                      ),
                      PerformanceNetworkChartWidget(
                          networks: networks, maxNetworkSpeed: maxNetworkSpeed())
                    ],
                  );
                }
                return const SizedBox.shrink();
              }),
            ],
          ),
        ),
      ),
    );
  }
}

class DashboardStorageUsageCard extends StatelessWidget {
  const DashboardStorageUsageCard(
      {super.key,
      required this.sdsWidgetModuleList,
      required this.systemData,
      required this.appNotify,
      required this.storageVolumes,
      required this.storageDisks,
      required this.storageSsdCaches});
  final ReadonlySignal<List> sdsWidgetModuleList;
  final ReadonlySignal<Map> systemData;
  final ReadonlySignal<Map> appNotify;
  final ReadonlySignal<List> storageVolumes;
  final ReadonlySignal<List> storageDisks;
  final ReadonlySignal<List> storageSsdCaches;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: () {
            Navigator.of(context).push(CupertinoPageRoute(builder: (context) {
              return SystemInfo(2, systemData, storageVolumes, storageDisks);
            }));
          },
          child: Card(
            shape: RoundedRectangleBorder(
                side: const BorderSide(),
                borderRadius: BorderRadius.circular(18)),
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    height: 20,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Image.asset(
                          "assets/icons/pie.png",
                          width: 26,
                          height: 26,
                        ),
                        const SizedBox(
                          width: 10,
                        ),
                        const Text(
                          "存储",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w600),
                        ),
                        const Spacer(),
                        const _CardItemCollapse("StorageUsage")
                      ],
                    ),
                  ),
                  Builder(builder: (context) {
                    if (storageVolumes.watch(context).isEmpty) {
                      return const Text.rich(TextSpan(
                        text: '暂无存储数据',
                      ));
                    }
                    if (context.isCardItemCollapsed('StorageUsage')) {
                      return Flexible(
                        child: Column(
                          children: storageVolumes
                              .map((e) => _DashboardStorageVolumeItem(
                                  (e as Map).toSignal()))
                              .toList(),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  }),
                  const SizedBox(
                    height: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (storageSsdCaches.watch(context).isNotEmpty)
          Card(
            shape: RoundedRectangleBorder(
                side: const BorderSide(),
                borderRadius: BorderRadius.circular(18)),
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  const SizedBox(
                    height: 20,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Image.asset(
                          "assets/icons/cache.png",
                          width: 26,
                          height: 26,
                        ),
                        const SizedBox(
                          width: 10,
                        ),
                        const Text(
                          "缓存",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w600),
                        ),
                        const Spacer(),
                        const _CardItemCollapse("StorageUsage")
                      ],
                    ),
                  ),
                  Builder(builder: (context) {
                    if (storageSsdCaches.watch(context).isEmpty) {
                      return const Text.rich(TextSpan(
                        text: '暂无缓存数据',
                      ));
                    }
                    if (context.isCardItemCollapsed('StorageUsage')) {
                      return Flexible(
                          child: Column(
                        children: storageSsdCaches
                            .map((e) => _DashboardStorageSsdCacheItem(e))
                            .toList(),
                      ));
                    }
                    return const SizedBox.shrink();
                  }),
                  const SizedBox(
                    height: 20,
                  ),
                ],
              ),
            ),
          )
      ],
    );
  }
}

class _DashboardStorageVolumeItem extends StatelessWidget {
  const _DashboardStorageVolumeItem(this.volume);
  final ReadonlySignal<Map> volume;
  @override
  Widget build(BuildContext context) {
    final used = volume.select((v) =>
        int.parse(v['size']?['used'] ?? '0') /
        int.parse(v['size']?['total'] ?? '1'));
    return Card(
      shape: RoundedRectangleBorder(
          side: const BorderSide(), borderRadius: BorderRadius.circular(5)),
      margin: const EdgeInsets.only(top: 20, left: 20, right: 20),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            CircularPercentIndicator(
              radius: 40,
              animation: true,
              linearGradient: LinearGradient(
                colors: used.watch(context) <= 0.9
                    ? [
                        Colors.blue,
                        Colors.blueAccent,
                      ]
                    : [
                        Colors.red,
                        Colors.orangeAccent,
                      ],
              ),
              animateFromLastPercent: true,
              circularStrokeCap: CircularStrokeCap.round,
              lineWidth: 12,
              backgroundColor: Colors.black12,
              percent: used.watch(context),
              center: Text(
                "${(used.watch(context) * 100).toStringAsFixed(0)}%",
                style: TextStyle(
                    color:
                        used.watch(context) <= 0.9 ? Colors.blue : Colors.red,
                    fontSize: 22),
              ),
            ),
            const SizedBox(
              width: 10,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        volume.select((v) => v['deploy_path'] ?? '').value !=
                                null
                            ? volume
                                .select((v) => v['deploy_path'] ?? '')
                                .value
                                .toString()
                                .replaceFirst("volume_", "存储空间 ")
                            : volume
                                .select((v) => v['id'] ?? '')
                                .value
                                .toString()
                                .replaceFirst("volume_", "存储空间 "),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(
                        width: 5,
                      ),
                      Builder(builder: (context) {
                        final status = volume.select((v) => v['status']);
                        return status.watch(context) == "normal"
                            ? const Label(
                                "正常",
                                Colors.green,
                                fill: true,
                              )
                            : status.value == "background"
                                ? const Label(
                                    "正在检查硬盘",
                                    Colors.lightBlueAccent,
                                    fill: true,
                                  )
                                : status.value == "attention"
                                    ? const Label(
                                        "注意",
                                        Colors.orangeAccent,
                                        fill: true,
                                      )
                                    : Label(
                                        status.value,
                                        Colors.red,
                                        fill: true,
                                      );
                      })
                    ],
                  ),
                  const SizedBox(
                    height: 5,
                  ),
                  Text(
                      "已用：${int.parse(volume.select((v) => v['size']?['used'] ?? '0').watch(context)).formatSize()}"),
                  const SizedBox(
                    height: 5,
                  ),
                  Builder(builder: (context) {
                    final total =
                        volume.select((v) => v['size']?['total'] ?? '0');
                    final used =
                        volume.select((v) => v['size']?['used'] ?? '0');
                    return Text(
                      "可用：${(int.parse(total.watch(context)) - int.parse(used.watch(context))).formatSize()}",
                    );
                  }),
                  const SizedBox(
                    height: 5,
                  ),
                  Text(
                      "容量：${int.parse(volume.select((v) => v['size']?['total'] ?? '0').watch(context)).formatSize()}"),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

class _DashboardStorageSsdCacheItem extends StatelessWidget {
  const _DashboardStorageSsdCacheItem(this.ssd);
  final ReadonlySignal<Map> ssd;
  @override
  Widget build(BuildContext context) {
    final percent = ssd.select((v) =>
        int.parse(v['size']?['used'] ?? v['size']?['reusable'] ?? '0') /
        int.parse(v['size']?['total'] ?? '1'));
    return Card(
      shape: RoundedRectangleBorder(
          side: const BorderSide(), borderRadius: BorderRadius.circular(18)),
      margin: const EdgeInsets.only(top: 20, left: 20, right: 20),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            CircularPercentIndicator(
              radius: 40,
              animation: true,
              linearGradient: LinearGradient(
                colors: percent.watch(context) <= 0.9
                    ? [
                        Colors.blue,
                        Colors.blueAccent,
                      ]
                    : [
                        Colors.red,
                        Colors.orangeAccent,
                      ],
              ),
              animateFromLastPercent: true,
              circularStrokeCap: CircularStrokeCap.round,
              lineWidth: 12,
              backgroundColor: Colors.black12,
              percent: percent.watch(context),
              center: Text(
                "${(percent.watch(context) * 100).toStringAsFixed(0)}%",
                style: TextStyle(
                    color: percent.watch(context) <= 0.9
                        ? Colors.blue
                        : Colors.red,
                    fontSize: 22),
              ),
            ),
            const SizedBox(
              width: 10,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        ssd
                            .select((v) => v['id'] ?? '')
                            .toString()
                            .replaceFirst("ssd_", "SSD 缓存 "),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(
                        width: 5,
                      ),
                      Builder(builder: (context) {
                        final status = ssd.select((v) => v['status']);
                        return status.watch(context) == "normal"
                            ? const Label(
                                "正常",
                                Colors.green,
                                fill: true,
                              )
                            : status.watch(context) == "background"
                                ? const Label(
                                    "正在检查硬盘",
                                    Colors.lightBlueAccent,
                                    fill: true,
                                  )
                                : status.watch(context) == "attention"
                                    ? const Label(
                                        "注意",
                                        Colors.orangeAccent,
                                        fill: true,
                                      )
                                    : Label(
                                        status.watch(context),
                                        Colors.red,
                                        fill: true,
                                      );
                      }),
                    ],
                  ),
                  const SizedBox(
                    height: 5,
                  ),
                  Watch((context) {
                    final used = ssd.select((v) => v['size']?['used']);
                    final reusable = ssd.select((v) => v['size']?['reusable']);
                    return Text(
                        "已用：${int.parse(used.value ?? reusable.value ?? '0').formatSize()}");
                  }),
                  const SizedBox(
                    height: 5,
                  ),
                  Watch((context) {
                    final total = ssd.select((v) => v['size']?['total'] ?? '0');
                    final used = ssd.select((v) => v['size']?['used']);
                    final reusable = ssd.select((v) => v['size']?['reusable']);
                    return Text(
                      "可用：${(int.parse(total.value) - int.parse(used.value ?? reusable.value ?? '0')).formatSize()}",
                    );
                  }),
                  const SizedBox(
                    height: 5,
                  ),
                  Text(
                      "容量：${int.parse(ssd.select((v) => v['size']?['total'] ?? '0').value).formatSize()}"),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

class DashboardFileChangeLogCard extends HookWidget {
  const DashboardFileChangeLogCard({super.key});

  @override
  Widget build(BuildContext context) {
    final fileChangeLogs = useListSignal([]);
    final error = useSignal('');

    fetchData() {
      dsmCoreSyslogClientLogList()
          .then((res) => {fileChangeLogs.value = res['items']})
          .catchError((e) {
        error.value = e.toString();
        return <dynamic>{};
      });
    }

    useEffect(() {
      fetchData();
      return null;
    }, const []);

    return Card(
      shape: RoundedRectangleBorder(
          side: const BorderSide(), borderRadius: BorderRadius.circular(18)),
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            const SizedBox(
              height: 20,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Image.asset(
                    "assets/icons/file_change.png",
                    width: 26,
                    height: 26,
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  const Text(
                    "文件更改日志",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  const _CardItemCollapse("FileChangeLog")
                ],
              ),
            ),
            const SizedBox(
              height: 10,
            ),
            Builder(builder: (context) {
              if (fileChangeLogs.watch(context).isEmpty) {
                return Text(error.isNotEmpty ? error.value : '暂无文件更新日志');
              }
              if (context.isCardItemCollapsed('FileChangeLog')) {
                return SizedBox(
                  height: 300,
                  child: CupertinoScrollbar(
                    child: ListView.builder(
                      itemBuilder: (context, i) {
                        return _DashboardFileChangeLogItem(fileChangeLogs[i]);
                      },
                      itemCount: fileChangeLogs.length,
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            }),
            const SizedBox(
              height: 10,
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardFileChangeLogItem extends StatelessWidget {
  const _DashboardFileChangeLogItem(this.log);
  final ReadonlySignal<Map> log;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
          side: const BorderSide(), borderRadius: BorderRadius.circular(18)),
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            Watch((context) {
              final cmd = log.select((v) => v['cmd']);
              return Icon(cmd.value == "delete"
                  ? Icons.delete
                  : cmd.value == "copy"
                      ? Icons.copy
                      : cmd.value == "edit"
                          ? Icons.edit
                          : cmd.value == "move"
                              ? Icons.drive_file_move_outline
                              : cmd.value == "download"
                                  ? Icons.download_outlined
                                  : cmd.value == "upload"
                                      ? Icons.upload_outlined
                                      : cmd.value == "rename"
                                          ? Icons.drive_file_rename_outline
                                          : Icons.code);
            }),
            Expanded(
              child: Text(
                "${log.watch(context)['descr']}",
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension CardItemCollapsed on BuildContext {
  bool isCardItemCollapsed(String item) {
    if (!mounted) return false;
    return settingsStore.dashboardCardCollapseState
            .select((v) => v[item])
            .watch(this, debugLabel: "$item - CardItemCollapsed") ==
        true;
  }
}

class _CardItemCollapse extends StatelessWidget {
  const _CardItemCollapse(this.item);
  final String item;

  @override
  Widget build(BuildContext context) {
    return IconButton(
        onPressed: () {
          batch(() => settingsStore.toggleCardItemCollapse(item));
        },
        icon: Icon(settingsStore.dashboardCardCollapseState
                    .select((v) => v[item])
                    .watch(context) ==
                true
            ? Icons.unfold_less
            : Icons.unfold_more));
  }
}

TextStyle _retryTextStyle(BuildContext context) {
  return TextStyle(
      fontSize: 8,
      color: Theme.brightnessOf(context) == Brightness.dark
          ? Colors.grey[800]
          : Colors.grey[300]);
}
