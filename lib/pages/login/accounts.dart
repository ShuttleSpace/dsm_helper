import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:garden/api/dsm_api.dart';
import 'package:garden/constants/app_constants.dart';
import 'package:garden/pages/login/login.dart';
import 'package:garden/stores/connection_store.dart';
import 'package:garden/util/http_util.dart';
import 'package:garden/util/log.dart';
import 'package:garden/util/storage_util.dart';
import 'package:garden/extensions/context.dart';
import 'package:garden/util/ui_util.dart';
import 'package:garden/widgets/label.dart';
import 'package:garden/widgets/neu_back_button.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:signals/signals_flutter.dart';

class Accounts extends StatefulWidget {
  const Accounts({super.key});

  @override
  AccountsState createState() => AccountsState();
}

class AccountsState extends State<Accounts> with SignalsMixin {
  late final servers = createListSignal<MapSignal<String, dynamic>>([]);
  late final visible = createSignal(false);
  late final timer = createSignal<Timer?>(null);
  late final hasLogined = createSignal(false);

  @override
  void initState() {
    super.initState();
    _initState();
  }

  @override
  void dispose() {
    timer.value?.cancel();
    timer.value = null;
    super.dispose();
  }

  _initState() async {
    final result = await StorageUtil.getString("servers") ?? '';
    if (result.isNotBlank) {
      servers.value = json.decode(result);
      timer.value ??= Timer.periodic(const Duration(seconds: 5), (timer) {
        // _fetchData();
      });
    }
  }

  _fetchData() async {
    if (!mounted) return;
    for (final server in servers) {
      server['loading'] = true;
      server['base_url'] = server['base_url'] ??
          '${server['https'] ? 'https' : 'http'}://${server['host']}:${server['port']}/';
      if (hasLogined.value) {
        final m = await _fetchServerInfo();
        _mapToServer(m, server);
      } else {
        //仅首次重新登录
        if (server['has_logined'] == true) {
          try {
            final res = await dsmFileStationListListShare(
                additional: const ["perm", "time", "size"]);
            Log.info('accounts: dsmFileStationListListShare: $res');
            hasLogined.value = true;
            //获取系统信息
            final m = await _fetchServerInfo();
            _mapToServer(m, server);
          } catch (e) {
            //登录失败，尝试重新登录
            try {
              final res = await dsmAuthLogin(
                  server['account'], server['password'],
                  cookie: server['smid'], host: server['base_url']);
              Log.info("try login: $res");
              final m = await _fetchServerInfo();
              _mapToServer(m, server);
            } on DioException catch (e) {
              Log.error("getServerInfo failed: ${e.message}");
            } on DSMException catch (e) {
              Log.error("getServerInfo failed: ${e.message}");
              server['loading'] = false;
              server['error'] = '登录失败';
            }
          }
        }
      }
    }
    await _saveServers();
  }

  _saveServers() async {
    if (servers.isNotEmpty) {
      await StorageUtil.setString(
          "servers",
          json.encode(servers.value
              .map((e) => {
                    "https": e['https'],
                    "host": e['host'],
                    "base_url": e['base_url'],
                    "port": e['port'],
                    "account": e['account'] ?? '',
                    "note": e['note'],
                    "remember_password": e['remember_password'],
                    "password": e['password'],
                    "auto_login": e['auto_login'],
                    "check_ssl": e['check_ssl'],
                    "cookie": e['cookie'],
                    "sid": e['sid'],
                  })
              .toList()));
    }
  }

  /// {"data":{"cpu":{"15min_load":9,"1min_load":11,"5min_load":11,"device":"System","other_load":2,"system_load":0,"user_load":1},"disk":{"disk":[{"device":"sdc","display_name":"Drive 3","read_access":1,"read_byte":63902,"type":"internal","utilization":4,"write_access":4,"write_byte":63856},{"device":"sdd","display_name":"Drive 4","read_access":0,"read_byte":17163,"type":"internal","utilization":4,"write_access":4,"write_byte":63856}],"total":{"device":"total","read_access":1,"read_byte":81065,"utilization":4,"write_access":8,"write_byte":127712}},"lun":[],"memory":{"avail_real":142048,"avail_swap":4123504,"buffer":26996,"cached":1891992,"device":"Memory","memory_size":4194304,"real_usage":46,"si_disk":0,"so_disk":0,"swap_usage":6,"total_real":3866684,"total_swap":4419500},"network":[{"device":"total","rx":2473,"tx":42563},{"device":"eth0","rx":2473,"tx":42563},{"device":"eth1","rx":0,"tx":0}],"space":{"total":{"device":"total","read_access":0,"read_byte":32755,"utilization":0,"write_access":2,"write_byte":44746},"volume":[{"device":"dm-0","display_name":"volume1","read_access":0,"read_byte":32755,"utilization":0,"write_access":2,"write_byte":44746}]},"time":1770828360},"success":true}
  Future<Map?> _fetchServerInfo() async {
    try {
      final res = await dsmCoreSystemUtilization(
          ["cpu", "memory", "network", "lun", "disk", "space"]);
      Log.info("accounts: serverInfo: $res");
      if (!mounted) {
        return null;
      }
    } on DioException catch (e) {
      Log.error("fetchServerInfo failed: ${e.message}");
      return null;
    } on DSMException catch (e) {
      Log.error("fetchServerInfo failed: ${e.message}");
      final res = {};
      res['loading'] = false;
      if (e.code == 105) {
        res['error'] = "权限不足，无法获取资源监控信息";
      } else {
        res['error'] = '获取资源监控信息失败';
      }
      return null;
    }
    return null;
  }

  _mapToServer(Map? m, MapSignal<String, dynamic> server) {
    if (!mounted || m == null) {
      Log.warn('_mapToServer: wrong state $mounted ${m == null}');
      return;
    }
    server['cpu'] = (m['cpu']['user_load'] + m['cpu']['system_load']) ?? 0.0;
    server['ram'] = m['memory']['real_usage'] ?? 0.0;
    if (m['network'].length > 0) {
      server['rx'] = m['network'][0]['rx'] ?? 0.0;
      server['tx'] = m['network'][0]['tx'] ?? 0.0;
    }
    if (m['disk']['total'] != null) {
      server['read'] = m['disk']['total']['read_byte'] ?? 0.0;
      server['write'] = m['disk']['total']['write_byte'] ?? 0.0;
    }
    server['loading'] = false;
    if (m['error'] != null) {
      server['error'] = m['error'];
    }
  }

  Widget _buildServerItem(MapSignal server) {
    server['cpu'] = server['cpu'] ?? 0.0;
    server['ram'] = server['ram'] ?? 0.0;
    server['tx'] = server['tx'] ?? 0.0;
    server['rx'] = server['rx'] ?? 0.0;
    server['read'] = server['read'] ?? 0.0;
    server['write'] = server['write'] ?? 0.0;
    return GestureDetector(
      onTap: () {
        Log.info(server);
        if (server['is_login']) {
          connectionStore.setAccount("${server['account']}");
          connectionStore.setBaseUri("${server['base_url']}");
          connectionStore.setCheckSsl(server['check_ssl']);
          StorageUtil.setString("base_url", connectionStore.baseUri.value);

          StorageUtil.setBool("https", server['https'] ? true : false);
          StorageUtil.setString("host", server['host']);
          StorageUtil.setString("port", server['port']);
          StorageUtil.setString("account", server['account']);
          StorageUtil.setString("note", server['note'] ?? '');
          StorageUtil.setBool(
              "remember_password", server['remember_password'] ? true : false);
          if (server['remember_password']) {
            StorageUtil.setString("password", server['password']);
          } else {
            StorageUtil.setString("password", "");
          }
          StorageUtil.setBool(
              "auto_login", server['auto_login'] ? true : false);
          StorageUtil.setBool("check_ssl", server['check_ssl'] ? true : false);
          StorageUtil.setString("sid", server['sid']);
          connectionStore.setSid(server['sid']);
          connectionStore.setCookie(server['cookie']);
          Navigator.of(context)
              .pushNamedAndRemoveUntil("/home", (route) => false);
        } else {
          server['action'] = "login";
          Navigator.of(context).push(CupertinoPageRoute(builder: (context) {
            return Login(server: server);
          }));
        }
      },
      child: Card(
        shape: context.stadiumShapeBorder,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _AccountInfo(
                      server,
                      visible: visible,
                      onDelete: (v) async {
                        servers.remove(server);
                        await _saveServers();
                        UiUtil.toast('删除成功!');
                      },
                      onEdit: (v) => {
                        server['action'] = "edit",
                        Navigator.of(context).push(CupertinoPageRoute(
                            builder: (context) => Login(server: server)))
                      },
                    ),
                    if (server.select((val) => val['error']).watch(context) ==
                        null)
                      Row(
                        children: [
                          _ServerCpu(server),
                          _ServerRam(server),
                          _ServerNetwork(server),
                          _ServerDisk(server),
                        ],
                      )
                    else
                      SizedBox(
                        height: 108,
                        child: Center(
                            child: Text(server
                                    .select((val) => val['error'])
                                    .watch(context) ??
                                '')),
                      ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: AppBackButton(context),
        title: const Text("选择账号"),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10, top: 8, bottom: 8),
            child: GestureDetector(
              onTap: () {
                visible.value = !visible.value;
              },
              child: Card(
                shape: RoundedRectangleBorder(
                    side: const BorderSide(),
                    borderRadius: BorderRadius.circular(18)),
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.paddingSmall),
                  child: Icon(visible.value
                      ? CupertinoIcons.eye_slash_fill
                      : CupertinoIcons.eye_fill),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 10, top: 8, bottom: 8),
            child: OutlinedButton(
              onPressed: () {
                Navigator.of(context)
                    .push(CupertinoPageRoute(builder: (context) {
                  return const Login(
                    type: "add",
                  );
                })).then((_) {
                  _initState();
                });
                return;
              },
              child: const Icon(Icons.add),
            ),
          )
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemBuilder: (context, i) {
          return _buildServerItem(servers.value[i]);
        },
        itemCount: servers.value.length,
        separatorBuilder: (context, i) {
          return const SizedBox(
            height: 20,
          );
        },
      ),
    );
  }
}

class _ServerDisk extends StatelessWidget {
  const _ServerDisk(this.server);
  final ReadonlySignal<Map> server;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          SizedBox(
            height: 85,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "R:${server['loading'] ? "-" : "${(int.parse(server['read'])).formatSize(fixed: 0)}/S"}",
                  style: const TextStyle(color: Colors.blue, fontSize: 12),
                ),
                const SizedBox(
                  height: 10,
                ),
                Text(
                  "W:${server['loading'] ? "-" : "${(int.parse(server['write'])).formatSize(fixed: 0)}/S"}",
                  style: const TextStyle(color: Colors.green, fontSize: 12),
                )
              ],
            ),
          ),
          const Text("磁盘"),
        ],
      ),
    );
  }
}

class _ServerNetwork extends StatelessWidget {
  const _ServerNetwork(this.server);
  final ReadonlySignal<Map> server;
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          SizedBox(
            height: 85,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.upload_sharp,
                      color: Colors.blue,
                      size: 16,
                    ),
                    Text(
                      server['loading']
                          ? "-"
                          : "${(int.parse(server['tx'])).formatSize(fixed: 0)}/S",
                      style: const TextStyle(color: Colors.blue, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(
                  height: 10,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.download_sharp,
                      color: Colors.green,
                      size: 16,
                    ),
                    Text(
                      server['loading']
                          ? "-"
                          : "${(int.parse(server['rx'])).formatSize(fixed: 0)}/S",
                      style: const TextStyle(color: Colors.green, fontSize: 12),
                    ),
                  ],
                )
              ],
            ),
          ),
          const Text("网络"),
        ],
      ),
    );
  }
}

class _ServerRam extends StatelessWidget {
  const _ServerRam(this.server);
  final ReadonlySignal<Map> server;
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Card(
          shape: RoundedRectangleBorder(
              side: const BorderSide(),
              borderRadius: BorderRadius.circular(18)),
          margin: const EdgeInsets.only(top: 10, right: 10),
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.paddingSmall),
            child: CircularPercentIndicator(
              radius: 30,
              // progressColor: Colors.lightBlueAccent,
              animation: true,
              linearGradient: LinearGradient(
                colors: server['ram'] <= 90
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
              lineWidth: 8,
              backgroundColor: Colors.black12,
              percent: server['ram'] / 100,
              center: server['loading']
                  ? const CupertinoActivityIndicator()
                  : Text(
                      "${server['ram']}%",
                      style: TextStyle(
                          color: server['ram'] <= 90 ? Colors.blue : Colors.red,
                          fontSize: 16),
                    ),
            ),
          ),
        ),
        const SizedBox(
          height: 10,
        ),
        const Text("RAM"),
      ],
    );
  }
}

class _ServerCpu extends StatelessWidget {
  const _ServerCpu(this.server);
  final ReadonlySignal<Map> server;
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Card(
          shape: RoundedRectangleBorder(
              side: const BorderSide(),
              borderRadius: BorderRadius.circular(18)),
          margin: const EdgeInsets.only(top: 10, right: 10),
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.paddingSmall),
            child: CircularPercentIndicator(
              radius: 30,
              // progressColor: Colors.lightBlueAccent,
              animation: true,
              linearGradient: LinearGradient(
                colors: server['cpu'] <= 90
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
              lineWidth: 8,
              backgroundColor: Colors.black12,
              percent: server['cpu'] / 100,
              center: server['loading']
                  ? const CupertinoActivityIndicator()
                  : Text(
                      "${server['cpu']}%",
                      style: TextStyle(
                          color: server['cpu'] <= 90 ? Colors.blue : Colors.red,
                          fontSize: 16),
                    ),
            ),
          ),
        ),
        const SizedBox(
          height: 10,
        ),
        const Text("CPU"),
      ],
    );
  }
}

class _AccountInfo extends StatelessWidget {
  const _AccountInfo(this.server,
      {required this.visible, required this.onEdit, required this.onDelete});
  final ReadonlySignal<Map> server;
  final ReadonlySignal<bool> visible;
  final ValueChanged<Map> onEdit;
  final ValueChanged<Map> onDelete;
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (server['note'] != null && server['note'] != "") ...[
                    Label("${server['note']}", Colors.blue),
                    const SizedBox(
                      width: 5,
                    ),
                  ],
                  Text(
                    "${visible.value ? server['account'] : "*****"}",
                    style: const TextStyle(fontSize: 18),
                  ),
                ],
              ),
              const SizedBox(
                height: 5,
              ),
              Row(
                children: [
                  if (server['https'])
                    const Icon(
                      Icons.lock,
                      color: Colors.green,
                      size: 12,
                    ),
                  Text(
                    "${visible.value ? server['host'] : "*****"}",
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              )
            ],
          ),
        ),
        if (server['loading'])
          const CupertinoActivityIndicator()
        else if (!server['is_login'])
          const Label("失效", Colors.red),
        const SizedBox(
          width: 10,
        ),
        OutlinedButton(
          onPressed: () {
            onEdit(server.value);
            // Log.info(server);
            // server['action'] = "edit";
            // Navigator.of(context).push(CupertinoPageRoute(builder: (context) {
            //   return Login(server: server);
            // }));
          },
          child: Image.asset(
            "assets/icons/edit.png",
            width: 20,
          ),
        ),
        const SizedBox(
          width: 10,
        ),
        OutlinedButton(
          onPressed: () {
            onDelete(server.value);
            // servers.remove(server);
            // saveServers();
            // UiUtil.toast("删除成功");
          },
          child: Image.asset(
            "assets/icons/delete.png",
            width: 20,
          ),
        ),
      ],
    );
  }
}
