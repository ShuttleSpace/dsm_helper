import 'dart:async';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:garden/constants/app_constants.dart';
import 'package:garden/pages/login/login.dart';
import 'package:garden/stores/connection_store.dart';
import 'package:garden/util/http_util.dart';
import 'package:garden/util/log.dart';
import 'package:garden/util/storage_util.dart';
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
  late final servers = createListSignal([]);
  late final visible = createSignal(false);

  Timer? timer;
  @override
  void initState() {
    getData();
    super.initState();
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  getData() async {
    String serverString = await StorageUtil.getString("servers") ?? '';
    if (serverString.isNotBlank) {
      servers.value = json.decode(serverString);
      getServerInfo();
    }
  }

  getServerInfo() async {
    timer ??= Timer.periodic(const Duration(seconds: 5), (timer) {
      getServerInfo();
    });
    final list = List.from(servers.value);
    for (var server in list) {
      server['loading'] = server['loading'] ?? true;
      server['is_login'] = server['is_login'] ?? false;
      server['base_url'] = server['base_url'] ??
          "${server['https'] ? "https" : "http"}://${server['host']}:${server['port']}/";
      if (server['is_login']) {
        await refreshServerInfo(server);
      } else {
        //仅首次重新登录
        if (server['loading']) {
          String host = server['base_url'];
          final checkLogin = await DsmApi.shareList(
              sid: server['sid'],
              checkSsl: server['check_ssl'],
              cookie: server['smid'],
              host: host);
          if (checkLogin['success']) {
            server['is_login'] = true;
            //获取系统信息
            await refreshServerInfo(server);
          } else {
            //登录失败，尝试重新登录
            final res = await DsmApi.login(
                host: host,
                account: server['account'],
                password: server['password'],
                otpCode: "",
                rememberDevice: false,
                cookie: server['smid']);
            Log.info("accounts: login: $res");
            if (res['success']) {
              server['is_login'] = true;
              server['sid'] = res['data']['sid'];
              await refreshServerInfo(server);
            } else {
              server['loading'] = false;
              server['error'] = '登录失败';
            }
          }
        }
      }
    }
    servers.value = list;
    await saveServers();
  }

  saveServers() async {
    List accounts = [];
    for (var server in servers.value) {
      accounts.add({
        "https": server['https'],
        "host": server['host'],
        "base_url": server['base_url'],
        "port": server['port'],
        "account": server['account'] ?? '',
        "note": server['note'],
        "remember_password": server['remember_password'],
        "password": server['password'],
        "auto_login": server['auto_login'],
        "check_ssl": server['check_ssl'],
        "cookie": server['cookie'],
        "sid": server['sid'],
      });
    }
    StorageUtil.setString("servers", json.encode(accounts));
  }

  refreshServerInfo(server) async {
    var res = await DsmApi.utilization(
        sid: server['sid'],
        checkSsl: server['check_ssl'],
        cookie: server['smid'],
        host: "${server['base_url']}");
    Log.info("accounts: serverInfo: $res");
    if (res['success']) {
      if (!mounted) {
        return;
      }
      server['cpu'] =
          (res['data']['cpu']['user_load'] + res['data']['cpu']['system_load']);
      server['ram'] = res['data']['memory']['real_usage'];
      if (res['data']['network'].length > 0) {
        server['rx'] = res['data']['network'][0]['rx'];
        server['tx'] = res['data']['network'][0]['tx'];
      }
      if (res['data']['disk']['total'] != null) {
        server['read'] = res['data']['disk']['total']['read_byte'];
        server['write'] = res['data']['disk']['total']['write_byte'];
      }
      server['loading'] = false;
    } else if (res['error']['code'] == 105) {
      server['loading'] = false;
      server['error'] = "权限不足，无法获取资源监控信息";
    } else {
      server['loading'] = false;
      server['error'] = '获取资源监控信息失败';
    }
  }

  Widget _buildServerItem(server) {
    server['loading'] = server['loading'] ?? true;
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
          connectionStore.setBaseUrl("${server['base_url']}");
          connectionStore.setCheckSsl(server['check_ssl']);
          StorageUtil.setString("base_url", connectionStore.baseUrl.value);

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
        shape: RoundedRectangleBorder(
            side: const BorderSide(), borderRadius: BorderRadius.circular(18)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  if (server['note'] != null &&
                                      server['note'] != "") ...[
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
                            Log.info(server);
                            server['action'] = "edit";
                            Navigator.of(context)
                                .push(CupertinoPageRoute(builder: (context) {
                              return Login(server: server);
                            }));
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
                            setState(() {
                              servers.remove(server);
                            });

                            saveServers();
                            UiUtil.toast("删除成功");
                          },
                          child: Image.asset(
                            "assets/icons/delete.png",
                            width: 20,
                          ),
                        ),
                      ],
                    ),
                    if (server['error'] == null)
                      Row(
                        children: [
                          Column(
                            children: [
                              Card(
                                shape: RoundedRectangleBorder(
                                    side: const BorderSide(),
                                    borderRadius: BorderRadius.circular(18)),
                                margin:
                                    const EdgeInsets.only(top: 10, right: 10),
                                child: Padding(
                                  padding: const EdgeInsets.all(
                                      AppConstants.paddingSmall),
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
                                                color: server['cpu'] <= 90
                                                    ? Colors.blue
                                                    : Colors.red,
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
                          ),
                          Column(
                            children: [
                              Card(
                                shape: RoundedRectangleBorder(
                                    side: const BorderSide(),
                                    borderRadius: BorderRadius.circular(18)),
                                margin:
                                    const EdgeInsets.only(top: 10, right: 10),
                                child: Padding(
                                  padding: const EdgeInsets.all(
                                      AppConstants.paddingSmall),
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
                                                color: server['ram'] <= 90
                                                    ? Colors.blue
                                                    : Colors.red,
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
                          ),
                          Expanded(
                            child: Column(
                              children: [
                                SizedBox(
                                  height: 85,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
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
                                            style: const TextStyle(
                                                color: Colors.blue,
                                                fontSize: 12),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(
                                        height: 10,
                                      ),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
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
                                            style: const TextStyle(
                                                color: Colors.green,
                                                fontSize: 12),
                                          ),
                                        ],
                                      )
                                    ],
                                  ),
                                ),
                                const Text("网络"),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              children: [
                                SizedBox(
                                  height: 85,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        "R:${server['loading'] ? "-" : "${(int.parse(server['read'])).formatSize(fixed: 0)}/S"}",
                                        style: const TextStyle(
                                            color: Colors.blue, fontSize: 12),
                                      ),
                                      const SizedBox(
                                        height: 10,
                                      ),
                                      Text(
                                        "W:${server['loading'] ? "-" : "${(int.parse(server['write'])).formatSize(fixed: 0)}/S"}",
                                        style: const TextStyle(
                                            color: Colors.green, fontSize: 12),
                                      )
                                    ],
                                  ),
                                ),
                                const Text("磁盘"),
                              ],
                            ),
                          ),
                        ],
                      )
                    else
                      SizedBox(
                        height: 108,
                        child: Center(child: Text(server['error'])),
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
                  getData();
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
