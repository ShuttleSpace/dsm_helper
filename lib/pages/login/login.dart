import 'dart:collection';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';
import 'package:garden/api/dsm_api.dart';
import 'package:garden/extensions/string.dart';
import 'package:garden/util/log.dart';
import 'package:garden/pages/common/device_finder.dart';
import 'package:garden/pages/login/accounts.dart';
import 'package:garden/stores/connection_store.dart';
import 'package:garden/util/storage_util.dart';
import 'package:garden/util/ui_util.dart';
import 'package:garden/extensions/context.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:signals_hooks/signals_hooks.dart';
import 'package:wake_on_lan/wake_on_lan.dart';

class Login extends HookWidget {
  final Map? server;
  final String? type;
  const Login({super.key, this.server, this.type = "login"});

  @override
  Widget build(BuildContext context) {
    final hostController = useTextEditingController();
    final accountController = useTextEditingController();
    final noteController = useTextEditingController();
    final passwordController = useTextEditingController();
    final portController = useTextEditingController();
    final otpController = useTextEditingController();
    final licenseRecognizer = useMemoized(() => TapGestureRecognizer(), const []);
    final privacyRecognizer =
        useMemoized(() => TapGestureRecognizer(), const []);
    final cancelToken = useRef(CancelToken());

    final host = useSignal('');
    final baseUrl = useSignal('');
    final account = useSignal('');
    final note = useSignal('');
    final password = useSignal('');
    final port = useSignal("5000");
    final needOtp = useSignal(false);
    final otpCode = useSignal('');
    final sid = useSignal('');
    final smid = useSignal('');
    final https = useSignal(false);
    final hasLogined = useSignal(false);
    final rememberPassword = useSignal(true);
    final autoLogin = useSignal(true);
    final checkSsl = useSignal(true);
    final rememberDevice = useSignal(false);
    final passwordVisible = useSignal(false);
    final servers = useListSignal([]);
    final qcAddresses = useListSignal([]);

    readAccountInfo() async {
      sid.value = await StorageUtil.getString("sid") ?? '';
      smid.value = await StorageUtil.getString("smid") ?? '';
      https.value = await StorageUtil.getBool("https") ?? false;
      host.value = await StorageUtil.getString("host") ?? "";
      baseUrl.value = await StorageUtil.getString("base_url") ?? '';
      port.value = await StorageUtil.getString("port") ?? '5000';
      account.value = await StorageUtil.getString("account") ?? '';
      note.value = await StorageUtil.getString("note") ?? '';
      password.value = await StorageUtil.getString("password") ?? '';
      autoLogin.value = await StorageUtil.getBool("auto_login") ?? true;

      rememberPassword.value =
          await StorageUtil.getBool("remember_password") ?? true;
      checkSsl.value = await StorageUtil.getBool("check_ssl") ?? false;
      connectionStore.setCookie(smid.value);

      if (host.value.isNotBlank) {
        hostController.value = TextEditingValue(text: host.value);
      }
      portController.value = TextEditingValue(text: port.value);

      if (account.value.isNotBlank) {
        accountController.value = TextEditingValue(text: account.value);
      }
      if (note.value.isNotBlank) {
        noteController.value = TextEditingValue(text: note.value);
      }
      if (password.value.isNotBlank) {
        passwordController.value = TextEditingValue(text: password.value);
      }
    }

    accountLogin(String baseUri) async {
      try {
        final res = await dsmAuthLogin(account.value, password.value,
            host: baseUri,
            otpCode: otpCode.value,
            cancelToken: cancelToken.value,
            rememberDevice: rememberDevice.value);
        hasLogined.value = false;
        Log.debug("_accountLogin: $res");
        //记住登录信息
        connectionStore.setAccount(account.value);
        StorageUtil.setBool("https", https.value);
        StorageUtil.setString("host", host.trim());
        StorageUtil.setString("port", port.value);
        StorageUtil.setString("base_url", baseUri);
        StorageUtil.setString("account", account.value);
        StorageUtil.setString("note", note.value);
        StorageUtil.setBool("remember_password", rememberPassword.value);
        StorageUtil.setBool("auto_login", autoLogin.value);
        StorageUtil.setBool("check_ssl", checkSsl.value);
        StorageUtil.setBool('is_portal_port', res['data']['is_portal_port']);
        if (rememberPassword.value) {
          StorageUtil.setString("password", password.value);
        } else {
          StorageUtil.remove("password");
        }
        if (autoLogin.value) {
          connectionStore.setSid(res['data']['sid']);
          StorageUtil.setString("sid", connectionStore.sid.value);
          if (res['data'].containsKey("sidsynoken")) {
            StorageUtil.setString("synotoken", res['data']?['sidsynoken']);
          }
        }
        connectionStore.setSid(res['data']['sid']);
        connectionStore.setBaseUri(baseUri);

        final servers2 = List.from(servers.value);
        //添加服务器记录
        bool exist = false;
        for (int i = 0; i < servers2.length; i++) {
          if (servers2[i]['https'] == https.value &&
              servers2[i]['host'] == host.value &&
              servers2[i]['port'] == port.value &&
              servers2[i]['account'] == account.value) {
            Log.info("账号已存在，更新信息");
            if (rememberPassword.value) {
              servers2[i]['password'] = password.value;
            } else {
              servers2[i]['password'] = "";
            }

            servers2[i]['remember_password'] = rememberPassword.value;
            servers2[i]['note'] = note.value;
            servers2[i]['auto_login'] = autoLogin.value;
            servers2[i]['check_ssl'] = checkSsl.value;
            servers2[i]['cookie'] = connectionStore.cookie.value;
            servers2[i]['sid'] = connectionStore.sid.value;
            servers2[i]['base_url'] = baseUri;
            exist = true;
          }
        }
        if (!exist) {
          Log.info("此账号${account.value}不存在");
          Map server = {
            "https": https.value,
            "host": host.value,
            "base_url": baseUri,
            "port": port.value,
            "note": note.value,
            "account": account.value,
            "remember_password": rememberPassword.value,
            "auto_login": autoLogin.value,
            "check_ssl": checkSsl.value,
            "cookie": connectionStore.cookie,
            "sid": connectionStore.sid.value,
          };
          if (rememberPassword.value) {
            server['password'] = password.value;
          } else {
            server['password'] = "";
          }
          servers2.add(server);
        }
        servers.value = servers2;
        StorageUtil.setString("servers", jsonEncode(servers2));
        if (type == "login") {
          if (context.mounted) {
            // ignore: use_build_context_synchronously
            Navigator.of(context)
                .pushNamedAndRemoveUntil("/home", (route) => false);
          }
        } else {
          if (context.mounted) {
            // ignore: use_build_context_synchronously
            Navigator.of(context).pop();
          }
        }
      } on DioException catch (e) {
        hasLogined.value = false;
        Log.error("login error: $e");
        UiUtil.toast("登录失败，$e");
      } on DSMException catch (e) {
        hasLogined.value = false;
        Log.error("login error: $e");
        UiUtil.vibrate(FeedbackType.warning);
        if (e.code == 400) {
          UiUtil.toast("用户名/密码有误");
        } else if (e.code == 403) {
          UiUtil.toast("请输入二次验证代码");
          needOtp.value = true;
        } else if (e.code == 404) {
          otpController.clear();
          UiUtil.toast("错误的验证代码。请再试一次。");
        } else {
          UiUtil.toast("登录失败，$e");
        }
      }
    }

    qcLogin({String qcHost = "quickconnect.to/"}) async {
      try {
        final res = await dsmAuthQuickConnectLogin(host.value, baseUri: qcHost);
        Log.info("qcLogin:$host $res");
        final addrs = List.from(qcAddresses.value);
        if (res['errno'] == 0) {
          if (res['server']['fqdn'] != "NULL") {
            addrs.add("http://${res['server']['fqdn']}/");
          }
          if (res['server']['external']["ip"] != null) {
            addrs.add(
                "http://${res['server']['external']["ip"]}:${res['service']['ext_port']}/");
          }
          if (res['service']['relay_ip'] != null) {
            addrs.add(
                "http://${res['service']['relay_ip']}:${res['service']['relay_port']}/");
          }
          if (res['server']['ddns'] != "NULL") {
            addrs.add(
                "http://${res['server']['ddns']}:${res['service']['ext_port']}/");
          }
          if (res['server']['interface'].length > 0) {
            for (final interface in res['server']['interface']) {
              addrs.add("http://${interface['ip']}:${res['service']['port']}/");
              if (interface['ipv6'].length > 0) {
                for (final v6 in interface['ipv6']) {
                  addrs.add(
                      "http://[${v6['address']}]:${res['service']['port']}/");
                }
              }
            }
          }
          if (res['service']['relay_ip'] == null) {
            try {
              final cnRes = await dsmAuthQuickConnectCnRequestTunnel(host.value,
                  baseUrl: res['env']['control_host']);
              if (cnRes['errno'] == 0 && cnRes['service'] != null) {
                final service = cnRes['service'] as Map;
                if (service['relay_ip'] != null) {
                  addrs.add(
                      "http://${service['relay_ip']}:${service['relay_port']}/");
                }
              }
            } catch (e) {
              Log.info("quickConnectCn failed: $e");
            }
          }

          Log.info("qcLogin: $addrs");
          for (final address in addrs) {
            try {
              await dsmPingpong(host: address);
              await accountLogin(address);
              break;
            } on Exception catch (e) {
              Log.error("qcLogin: pingpong failed: $e");
            }
          }
        } else if (res['errno'] == 4 &&
            res['errinfo'].startsWith("get_server_info.go") &&
            res['sites'].length > 0) {
          qcLogin(qcHost: res['sites'][0]);
        } else {
          UiUtil.toast("无法连接到服务器，请检查QuickConnect ID是否正确");
          hasLogined.value = false;
        }
        qcAddresses.value = addrs;
      } on DioException catch (e) {
        Log.error("qcLogin: $e");
        UiUtil.toast("无法连接到服务器，请检查QuickConnect ID是否正确");
        hasLogined.value = false;
      } on DSMException catch (e) {
        Log.error("qcLogin: $e");
        UiUtil.toast("无法连接到服务器，请检查QuickConnect ID是否正确");
        hasLogined.value = false;
      }
    }

    login() async {
      connectionStore.setCheckSsl(checkSsl.value);
      FocusScope.of(context).unfocus();
      if (host.value.trim() == "") {
        UiUtil.toast("请输入网址/IP/QuickConnect ID");
        return;
      }
      if (account.value == "") {
        UiUtil.toast("请输入账号");
        return;
      }
      hasLogined.value = true;
      if (host.contains(".") || host.contains(':')) {
        String baseUri =
            "${https.value ? "https" : "http"}://${host.trim()}:${port.trim()}";
        Log.info("_login: baseUri: $baseUri");
        accountLogin(baseUri);
      } else {
        qcLogin();
      }
    }

    tryLogin() async {
      connectionStore.setAccount(account.value);
      if (sid.value.isNotBlank && host.value.isNotBlank) {
        if (baseUrl.value.isNotBlank) {
          connectionStore.setBaseUri(baseUrl.value);
        } else {
          connectionStore
              .setBaseUri("${https.value ? "https" : "http"}://$host:$port");
        }
        //开始自动登录
        Log.info(
            "connectionStore.BaseUrl:${connectionStore.baseUri}, widget.baseUrl:$baseUrl");
        connectionStore.setSid(sid.value);
        //如果开启了自动登录，则判断当前登录状态
        if (autoLogin.value) {
          hasLogined.value = true;
          try {
            await dsmFileStationListListShare(
                additional: const ['perm', 'time', 'size'],
                limit: 1000,
                cancelToken: cancelToken.value);
            if (context.mounted) {
              // ignore: use_build_context_synchronously
              Navigator.of(context)
                  .pushNamedAndRemoveUntil("/home", (route) => false);
            }
          } on DSMException catch (e) {
            Log.info("登录失败:${e.message}，尝试重新登录");
            login();
          } on DioException catch (e) {
            if (e.type == DioExceptionType.cancel) {
              Log.info("用户取消登录");
              hasLogined.value = false;
            }
          }
        }
      }
    }

    openDeviceFinder() async {
      FocusScope.of(context).unfocus();
      final result = await Navigator.of(context).push(
        CupertinoPageRoute(
          builder: (context) {
            return const DeviceFinder(title: "设备发现");
          },
        ),
      );
      Log.info("_openDeviceFinder: $result");
      if (result != null && result is String) {
        try {
          final data = jsonDecode(result) as Map<String, dynamic>;
          batch(() {
            host.value = data['host'] ?? '';
            port.value = data['port'] ?? (https.value ? '5001' : '5000');
          });
          hostController.value = TextEditingValue(text: host.value);
          portController.value = TextEditingValue(text: port.value);
          UiUtil.toast("已选择设备: ${data['name'] ?? host}");
        } catch (e) {
          Log.info("Error parsing device info: $e");
          UiUtil.toast("解析设备信息失败");
        }
      }
    }

    useEffect(() {
      if (server != null) {
        https.value = server?['https'];
        host.value = server?['host'];
        port.value = server?['port'];
        account.value = server?['account'];
        note.value = server?['note'] ?? '';
        password.value = server?['password'];
        autoLogin.value = server?['auto_login'];
        rememberPassword.value = server?['remember_password'];
        checkSsl.value = server?['check_ssl'];

        if (host.value.isNotBlank) {
          hostController.value = TextEditingValue(text: host.value);
        }
        if (port.value.isNotBlank) {
          portController.value = TextEditingValue(text: port.value);
        }
        if (account.value.isNotBlank) {
          accountController.value = TextEditingValue(text: account.value);
        }
        if (note.value.isNotBlank) {
          noteController.value = TextEditingValue(text: note.value);
        }
        if (password.value.isNotBlank) {
          passwordController.value = TextEditingValue(text: password.value);
        }
        final ck = server?['cookie'];
        if (ck != null && ck.isNotBlank) {
          connectionStore.setCookie(ck);
        }
        final sid = server?['sid'];
        if (sid != null && sid.isNotBlank) {
          connectionStore.setSid(sid);
        }
        if (server?['action'] == "login") {
          login();
        }
      } else {
        if (type == "login") {
          (() async {
            await readAccountInfo();
            await tryLogin();
          })();
        } else {
          portController.value = TextEditingValue(text: port.value);
        }
      }

      StorageUtil.getString("servers").then((serverString) {
        if (serverString != null && serverString.isNotBlank) {
          servers.value = jsonDecode(serverString);
        }
      });

      return () {
        licenseRecognizer.dispose();
        privacyRecognizer.dispose();
      };
    }, const []);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          type == "login" ? "账号登录" : "添加账号",
        ),
        actions: [
          // 历史记录
          if (servers.value.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 10, top: 8, bottom: 8),
              child: OutlinedButton(
                style: context.stadiumButtonStyle,
                onPressed: () {
                  Navigator.of(context)
                      .push(CupertinoPageRoute(builder: (context) {
                    return const Accounts();
                  }));
                },
                child: Image.asset(
                  "assets/icons/history.png",
                  width: 20,
                  height: 20,
                ),
              ),
            ),
          // 设备发现
          Padding(
            padding:
                const EdgeInsetsGeometry.only(right: 10, top: 8, bottom: 8),
            child: OutlinedButton(
              onPressed: openDeviceFinder,
              style: context.stadiumButtonStyle,
              child: const Icon(
                Icons.radar,
                size: 20,
              ),
            ),
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: <Widget>[
            const SizedBox(
              height: 20,
            ),
            Card(
              shape: StadiumBorder(
                side: BorderSide(
                    color: Theme.of(context).colorScheme.primary, width: 1.0),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                child: Row(
                  children: [
                    DropdownMenu<String>(
                        initialSelection: 'http',
                        requestFocusOnTap: true,
                        label: const Text('协议'),
                        inputDecorationTheme: InputDecorationTheme(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        dropdownMenuEntries: UnmodifiableListView([
                          const DropdownMenuEntry(
                            value: 'http',
                            label: 'http',
                          ),
                          const DropdownMenuEntry(
                              value: 'https', label: 'https')
                        ]),
                        onSelected: (value) {
                          https.value = value == 'https';
                          if (https.value && port.value == "5000") {
                            port.value = "5001";
                            portController.value =
                                TextEditingValue(text: port.value);
                          } else if (!https.value && port.value == "5001") {
                            port.value = "5000";
                            portController.value =
                                TextEditingValue(text: port.value);
                          }
                        }),
                    Expanded(
                      flex: 3,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: TextField(
                          autocorrect: false,
                          controller: hostController,
                          onChanged: (v) => host.value = v,
                          textInputAction: TextInputAction.next,
                          onEditingComplete: () {
                            FocusScope.of(context).nextFocus();
                          },
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            labelText: '网址/IP/QuickConnect ID',
                          ),
                        ),
                      ),
                    ),
                    if (host.contains(".") || host.contains(":"))
                      Expanded(
                        flex: 1,
                        child: TextField(
                          onChanged: (v) => port.value = v,
                          controller: portController,
                          textInputAction: TextInputAction.next,
                          onEditingComplete: () {
                            FocusScope.of(context).nextFocus();
                          },
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            labelText: '端口',
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
            Row(
              children: [
                Expanded(
                  child: Card(
                    shape: context.stadiumShapeBorder,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      child: TextField(
                        autocorrect: false,
                        keyboardAppearance: Brightness.light,
                        controller: accountController,
                        onChanged: (v) => account.value = v,
                        textInputAction: TextInputAction.next,
                        onEditingComplete: () {
                          FocusScope.of(context).nextFocus();
                        },
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          labelText: '账号',
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(
                  width: 20,
                ),
                Expanded(
                  child: Card(
                    shape: context.stadiumShapeBorder,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      child: TextField(
                        keyboardAppearance: Brightness.light,
                        controller: noteController,
                        onChanged: (v) => note.value = v,
                        textInputAction: TextInputAction.next,
                        onEditingComplete: () {
                          FocusScope.of(context).nextFocus();
                        },
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          labelText: '备注',
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(
              height: 20,
            ),
            Card(
              shape: context.stadiumShapeBorder,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: TextField(
                  controller: passwordController,
                  onChanged: (v) => password.value = v,
                  obscureText: !passwordVisible.value,
                  textInputAction: TextInputAction.done,
                  onEditingComplete: () {
                    FocusScope.of(context).unfocus();
                  },
                  decoration: InputDecoration(
                      border: InputBorder.none,
                      labelText: '密码',
                      suffixIcon: IconButton(
                          onPressed: () {
                            passwordVisible.value = !passwordVisible.value;
                          },
                          icon: Icon(
                            passwordVisible.value
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            size: 18,
                          ))),
                ),
              ),
            ),
            const SizedBox(
              height: 20,
            ),
            if (needOtp.value) ...[
              Row(
                children: [
                  Expanded(
                    child: Card(
                      shape: context.stadiumShapeBorder,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0),
                        child: TextField(
                          controller: otpController,
                          onChanged: (v) => otpCode.value = v,
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.done,
                          onEditingComplete: () {
                            FocusScope.of(context).unfocus();
                          },
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            labelText: '二步验证代码',
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        FocusScope.of(context).unfocus();
                        rememberDevice.value = !rememberDevice.value;
                      },
                      child: Card(
                        shape: context.stadiumShapeBorder,
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            children: [
                              const Text("记住设备"),
                              const Spacer(),
                              if (rememberDevice.value)
                                Icon(
                                  CupertinoIcons.checkmark_alt,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(
                height: 20,
              ),
            ],
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      rememberPassword.value = !rememberPassword.value;
                      if (!rememberPassword.value) {
                        autoLogin.value = false;
                      }
                    },
                    child: Card(
                      shape: StadiumBorder(
                          side: BorderSide(
                              color: Theme.of(context).colorScheme.primary)),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          children: [
                            const Text("记住密码"),
                            const Spacer(),
                            if (rememberPassword.value)
                              Icon(
                                CupertinoIcons.checkmark_alt,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(
                  width: 20,
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      autoLogin.value = !autoLogin.value;
                      if (autoLogin.value) {
                        rememberPassword.value = true;
                      }
                    },
                    child: Card(
                      shape: context.stadiumShapeBorder,
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          children: [
                            const Text("自动登录"),
                            const Spacer(),
                            if (autoLogin.value)
                              Icon(
                                CupertinoIcons.checkmark_alt,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(
              height: 20,
            ),
            if (https.value)
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: GestureDetector(
                  onTap: () {
                    checkSsl.value = !checkSsl.value;
                  },
                  child: Card(
                    shape: context.stadiumShapeBorder,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        children: [
                          const Text("验证SSL证书"),
                          const Spacer(),
                          if (checkSsl.value)
                            Icon(
                              CupertinoIcons.checkmark_alt,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            OutlinedButton(
              style: context.stadiumButtonStyle,
              onPressed: () {
                Log.info(hasLogined.value);
                if (hasLogined.value) {
                  cancelToken.value.cancel("取消登录");
                  cancelToken.value = CancelToken();
                  hasLogined.value = false;
                  return;
                } else {
                  login();
                }
              },
              child: hasLogined.value
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CupertinoActivityIndicator(
                          radius: 13,
                        ),
                        SizedBox(
                          width: 10,
                        ),
                        Text(
                          "取消",
                          style: TextStyle(fontSize: 18),
                        ),
                      ],
                    )
                  : Text(
                      type == "login" ? ' 登录 ' : ' 添加 ',
                      style: const TextStyle(fontSize: 18),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  wakeup() async {
    Log.info("wakeup");
    String ipv4 = '192.168.0.100';
    IPAddress ipv4Address;
    MACAddress macAddress;
    if (IPAddress.validate(ipv4).state) {
      ipv4Address = IPAddress(ipv4);
      //Continue execution
    } else {
      UiUtil.toast("IP地址有误");
      return;
      // Handle invalid address case
    }
    String mac = '02-11-24-27-31-2F';
    if (MACAddress.validate(mac).state) {
      macAddress = MACAddress(mac);
      //Continue execution
    } else {
      UiUtil.toast("MAC地址有误");
      return;
      // Handle invalid address case
    }
    WakeOnLAN wol = WakeOnLAN(ipv4Address, macAddress, port: 1234);
    await wol.wake().then((v) => Log.info('sent'));
  }
}
