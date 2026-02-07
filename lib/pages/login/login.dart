import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';
import 'package:garden/util/log.dart';
import 'package:garden/pages/common/device_finder.dart';
import 'package:garden/pages/login/accounts.dart';
import 'package:garden/stores/connection_store.dart';
import 'package:garden/theme/app_colors.dart';
import 'package:garden/util/http_util.dart';
import 'package:garden/util/storage_util.dart';
import 'package:garden/util/ui_util.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:wake_on_lan/wake_on_lan.dart';

class Login extends StatefulWidget {
  final Map? server;
  final String? type;
  const Login({super.key, this.server, this.type = "login"});
  @override
  LoginState createState() => LoginState();
}

class LoginState extends State<Login> with SignalsMixin {
  final TapGestureRecognizer _licenseRecognizer = TapGestureRecognizer();
  final TapGestureRecognizer _privacyRecognizer = TapGestureRecognizer();
  final TextEditingController _hostController = TextEditingController();
  final TextEditingController _accountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _portController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  CancelToken cancelToken = CancelToken();

  final host = signal('');
  final baseUrl = signal('');
  final account = signal('');
  final note = signal('');
  final password = signal('');
  final port = signal("5000");
  final needOtp = signal(false);
  final otpCode = signal('');
  final sid = signal('');
  final smid = signal('');
  final https = signal(false);
  final hasLogined = signal(false);
  final rememberPassword = signal(true);
  final autoLogin = signal(true);
  final checkSsl = signal(true);
  final rememberDevice = signal(true);
  final passwordVisible = signal(false);
  final servers = listSignal([]);
  final qcAddresses = listSignal([]);

  @override
  initState() {
    StorageUtil.getString("servers").then((serverString) {
      if (serverString != null && serverString.isNotBlank) {
        servers.value = jsonDecode(serverString);
      }
      if (widget.server != null) {
        setState(() {
          https.value = widget.server?['https'];
          host.value = widget.server?['host'];
          port.value = widget.server?['port'];
          account.value = widget.server?['account'];
          note.value = widget.server?['note'] ?? '';
          password.value = widget.server?['password'];
          autoLogin.value = widget.server?['auto_login'];
          rememberPassword.value = widget.server?['remember_password'];
          checkSsl.value = widget.server?['check_ssl'];
          if (host.value.isNotBlank) {
            _hostController.value = TextEditingValue(text: host.value);
          }
          if (port.value.isNotBlank) {
            _portController.value = TextEditingValue(text: port.value);
          }
          if (account.value.isNotBlank) {
            _accountController.value = TextEditingValue(text: account.value);
          }
          if (note.value.isNotBlank) {
            _noteController.value = TextEditingValue(text: note.value);
          }
          if (password.value.isNotBlank) {
            _passwordController.value = TextEditingValue(text: password.value);
          }
        });
        connectionStore.setCookie(widget.server?['cookie']);
        connectionStore.setSid(widget.server?['sid']);
        if (widget.server?['action'] == "login") {
          _login();
        }
      } else {
        if (widget.type == "login") {
          readAccountInfo();
        } else {
          _portController.value = TextEditingValue(text: port.value);
        }
      }
    });

    super.initState();
  }

  @override
  void dispose() {
    _licenseRecognizer.dispose();
    _privacyRecognizer.dispose();
    super.dispose();
  }

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
      _hostController.value = TextEditingValue(text: host.value);
    }
    _portController.value = TextEditingValue(text: port.value);

    if (account.value.isNotBlank) {
      _accountController.value = TextEditingValue(text: account.value);
    }
    if (note.value.isNotBlank) {
      _noteController.value = TextEditingValue(text: note.value);
    }
    if (password.value.isNotBlank) {
      _passwordController.value = TextEditingValue(text: password.value);
    }
    checkLogin();
  }

  checkLogin() async {
    connectionStore.setAccount(account.value);
    if (sid.value.isNotBlank && host.value.isNotBlank) {
      if (baseUrl.value.isNotBlank) {
        connectionStore.setBaseUrl(baseUrl.value);
      } else {
        connectionStore
            .setBaseUrl("${https.value ? "https" : "http"}://$host:$port");
      }
      //开始自动登录
      Log.info("BaseUrl:$baseUrl");
      Log.info("HttpUtil.BaseUrl:${connectionStore.baseUrl}");
      connectionStore.setSid(sid.value);
      //如果开启了自动登录，则判断当前登录状态
      if (autoLogin.value) {
        hasLogined.value = true;
        final checkLoginResult =
            await DsmApi.shareList(cancelToken: cancelToken);
        if (!checkLoginResult['success']) {
          if (checkLoginResult['code'] == "用户取消") {
            hasLogined.value = false;
          } else {
            //如果登录失效，尝试重新登录
            Log.info("尝试重新登录");
            _login();
          }
        } else {
          //登录有效，进入首页
          if (context.mounted) {
            // ignore: use_build_context_synchronously
            Navigator.of(context)
                .pushNamedAndRemoveUntil("/home", (route) => false);
          }
        }
      }
    }
  }

  _login() async {
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
      Log.info("baseUri: $baseUri");
      doLogin(baseUri);
    } else {
      qcLogin();
    }
  }

  qcLogin({String qcHost = "global.quickconnect.cn"}) async {
    final res = await DsmApi.quickConnect(host.value, baseUrl: qcHost);
    Log.info("QuickConnectID:$host $res");
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
              addrs.add("http://[${v6['address']}]:${res['service']['port']}/");
            }
          }
        }
      }
      if (res['service']['relay_ip'] == null) {
        final cnRes = await DsmApi.quickConnectCn(host.value,
            baseUrl: res['env']['control_host']);
        if (cnRes['errno'] == 0) {
          if (cnRes['service']['relay_ip'] != null) {
            addrs.add(
                "http://${cnRes['service']['relay_ip']}:${cnRes['service']['relay_port']}/");
          }
        }
      }

      bool finded = false;
      for (final address in addrs) {
        Log.info(addrs);
        DsmApi.pingpong(address, (res) {
          if (res != null) {
            if (!finded) {
              doLogin(res);
            }
          }
        });
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
  }

  doLogin(String baseUri) async {
    final res = await DsmApi.login(
        host: baseUri,
        account: account.value,
        password: password.value,
        otpCode: otpCode.value,
        cancelToken: cancelToken,
        rememberDevice: rememberDevice.value);
    hasLogined.value = false;
    Log.debug("doLogin: $res");
    if (res['success'] == true) {
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
      connectionStore.setSid(res['data']['sid']);
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
      StorageUtil.setBool('is_portal_port', res['data']['is_portal_port']);

      connectionStore.setBaseUrl(baseUri);

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
        Log.info("账号不存在");
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
      if (widget.type == "login") {
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
    } else {
      UiUtil.vibrate(FeedbackType.warning);
      if (res['error']['code'] == ErrorCode.noAccountOrIncorrectPassword.code) {
        UiUtil.toast("用户名/密码有误");
      } else if (res['error']['code'] == ErrorCode.twoFactorAuthRequired.code) {
        UiUtil.toast("请输入二次验证代码");
        needOtp.value = true;
      } else if (res['error']['code'] == ErrorCode.twoFactorAuthFailed.code) {
        _otpController.clear();
        UiUtil.toast("错误的验证代码。请再试一次。");
      } else {
        UiUtil.toast("登录失败，code:${res['error']['code']}");
      }
    }
  }

  wakeup() async {
    Log.info("wakeup");
    // final client = HttpDnsClient("http://180.76.76.76");
    // final result = await client.lookup("baidu.com");
    // Log.info(result);
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

  _openDeviceFinder() async {
    FocusScope.of(context).unfocus();
    final result = await Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (context) {
          return const DeviceFinder(
            url: "https://finds.synology.com",
            title: "设备发现",
          );
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
        _hostController.value = TextEditingValue(text: host.value);
        _portController.value = TextEditingValue(text: port.value);
        UiUtil.toast("已选择设备: ${data['name'] ?? host}");
      } catch (e) {
        Log.info("Error parsing device info: $e");
        UiUtil.toast("解析设备信息失败");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.type == "login" ? "账号登录" : "添加账号",
        ),
        actions: [
          if (servers.watch(context).isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 10, top: 8, bottom: 8),
              child: OutlinedButton(
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
          Padding(
            padding:
                const EdgeInsetsGeometry.only(right: 10, top: 8, bottom: 8),
            child: OutlinedButton(
              onPressed: _openDeviceFinder,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(36, 36),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Icon(
                Icons.open_in_browser,
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
              shape: RoundedRectangleBorder(
                  side: const BorderSide(),
                  borderRadius: BorderRadius.circular(18)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: Row(
                  children: [
                    SizedBox(
                      width: 60,
                      child: GestureDetector(
                        onTap: () {
                          https.value = !https.value;
                          if (https.value && port.value == "5000") {
                            port.value = "5001";
                            _portController.value =
                                TextEditingValue(text: port.value);
                          } else if (!https.value && port.value == "5001") {
                            port.value = "5000";
                            _portController.value =
                                TextEditingValue(text: port.value);
                          }
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(
                              height: 4,
                            ),
                            const Text(
                              "协议",
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey, height: 1),
                            ),
                            Text(
                              https.value ? "https" : "http",
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: TextField(
                        autocorrect: false,
                        controller: _hostController,
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
                    if (host.contains(".") || host.contains(":"))
                      Expanded(
                        flex: 1,
                        child: TextField(
                          onChanged: (v) => port.value = v,
                          controller: _portController,
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
                    shape: RoundedRectangleBorder(
                        side: const BorderSide(),
                        borderRadius: BorderRadius.circular(18)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      child: TextField(
                        autocorrect: false,
                        keyboardAppearance: Brightness.light,
                        controller: _accountController,
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
                    shape: RoundedRectangleBorder(
                        side: const BorderSide(),
                        borderRadius: BorderRadius.circular(18)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      child: TextField(
                        keyboardAppearance: Brightness.light,
                        controller: _noteController,
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
              shape: RoundedRectangleBorder(
                  side: const BorderSide(),
                  borderRadius: BorderRadius.circular(18)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: TextField(
                  controller: _passwordController,
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
                          icon: Icon(passwordVisible.watch(context)
                              ? Icons.visibility
                              : Icons.visibility_off_outlined))),
                ),
              ),
            ),
            const SizedBox(
              height: 20,
            ),
            if (needOtp.watch(context)) ...[
              Row(
                children: [
                  Expanded(
                    child: Card(
                      shape: RoundedRectangleBorder(
                          side: const BorderSide(),
                          borderRadius: BorderRadius.circular(18)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0),
                        child: TextField(
                          controller: _otpController,
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
                        shape: RoundedRectangleBorder(
                            side: const BorderSide(),
                            borderRadius: BorderRadius.circular(18)),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            children: [
                              const Text("记住设备"),
                              const Spacer(),
                              if (rememberDevice.watch(context))
                                const Icon(
                                  CupertinoIcons.checkmark_alt,
                                  color: AppColors.primaryAction,
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
                      shape: RoundedRectangleBorder(
                          side: const BorderSide(),
                          borderRadius: BorderRadius.circular(18)),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          children: [
                            const Text("记住密码"),
                            const Spacer(),
                            if (rememberPassword.watch(context))
                              const Icon(
                                CupertinoIcons.checkmark_alt,
                                color: AppColors.primaryAction,
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
                      shape: RoundedRectangleBorder(
                          side: const BorderSide(),
                          borderRadius: BorderRadius.circular(18)),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          children: [
                            const Text("自动登录"),
                            const Spacer(),
                            if (autoLogin.watch(context))
                              const Icon(
                                CupertinoIcons.checkmark_alt,
                                color: AppColors.primaryAction,
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
            if (https.watch(context))
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: GestureDetector(
                  onTap: () {
                    checkSsl.value = !checkSsl.value;
                  },
                  child: Card(
                    shape: RoundedRectangleBorder(
                        side: const BorderSide(),
                        borderRadius: BorderRadius.circular(18)),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        children: [
                          const Text("验证SSL证书"),
                          const Spacer(),
                          if (checkSsl.watch(context))
                            const Icon(
                              CupertinoIcons.checkmark_alt,
                              color: AppColors.primaryAction,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            // SizedBox(
            //   height: 20,
            // ),

            OutlinedButton(
              onPressed: () {
                Log.info(hasLogined.value);
                if (hasLogined.watch(context)) {
                  cancelToken.cancel("取消登录");
                  cancelToken = CancelToken();
                  hasLogined.value = false;
                  return;
                } else {
                  _login();
                }
              },
              child: hasLogined.watch(context)
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
                      widget.type == "login" ? ' 登录 ' : ' 添加 ',
                      style: const TextStyle(fontSize: 18),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
