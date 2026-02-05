import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';
import 'package:garden/util/log.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:garden/pages/common/device_finder.dart';
import 'package:garden/pages/login/accounts.dart';
import 'package:garden/stores/connection_store.dart';
import 'package:garden/theme/app_colors.dart';
import 'package:garden/util/http_util.dart';
import 'package:garden/util/storage_util.dart';
import 'package:garden/util/ui_util.dart';

class Login extends StatefulWidget {
  final Map? server;
  final String? type;
  const Login({super.key, this.server, this.type = "login"});
  @override
  LoginState createState() => LoginState();
}

class LoginState extends State<Login> {
  final TapGestureRecognizer _licenseRecognizer = TapGestureRecognizer();
  final TapGestureRecognizer _privacyRecognizer = TapGestureRecognizer();
  Map updateInfo = {};
  String host = "";
  String baseUrl = '';
  String account = "";
  String note = "";
  String password = "";
  String port = "5000";
  bool needOtp = false;
  String otpCode = "";
  String sid = "";
  String smid = "";
  bool https = false;
  bool login = false;
  bool rememberPassword = true;
  bool autoLogin = true;
  bool checkSsl = true;
  bool rememberDevice = true;
  bool read = true;
  bool passwordVisible = false;
  final TextEditingController _hostController = TextEditingController();
  final TextEditingController _accountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _portController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  List servers = [];
  List qcAddresses = [];
  CancelToken cancelToken = CancelToken();
  @override
  initState() {
    StorageUtil.getString("read").then((value) {
      if (value != null && value.isNotBlank && value == "1") {
        setState(() {
          read = true;
        });
      }
    });
    // checkAgreement();
    if (Platform.isAndroid) {
      // checkUpdate();
    } else {
      setState(() {
        read = true;
      });
    }
    StorageUtil.getString("servers").then((serverString) {
      if (serverString != null && serverString.isNotBlank) {
        servers = jsonDecode(serverString);
      }
      if (widget.server != null) {
        setState(() {
          https = widget.server?['https'];
          host = widget.server?['host'];
          port = widget.server?['port'];
          account = widget.server?['account'];
          note = widget.server?['note'] ?? '';
          password = widget.server?['password'];
          autoLogin = widget.server?['auto_login'];
          rememberPassword = widget.server?['remember_password'];
          checkSsl = widget.server?['check_ssl'];
          if (host.isNotBlank) {
            _hostController.value = TextEditingValue(text: host);
          }
          if (port.isNotBlank) {
            _portController.value = TextEditingValue(text: port);
          }
          if (account.isNotBlank) {
            _accountController.value = TextEditingValue(text: account);
          }
          if (note.isNotBlank) {
            _noteController.value = TextEditingValue(text: note);
          }
          if (password.isNotBlank) {
            _passwordController.value = TextEditingValue(text: password);
          }
        });
        connectionStore.setCookie(widget.server?['cookie']);
        connectionStore.setSid(widget.server?['sid']);
        if (widget.server?['action'] == "login") {
          _login();
        }
      } else {
        if (widget.type == "login") {
          getInfo();
        } else {
          _portController.value = TextEditingValue(text: port);
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

  checkUpdate() async {
    if (Platform.isAndroid) {
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      String buildNumber = packageInfo.buildNumber;
      if (kDebugMode) {
        buildNumber = '1';
      }
      var res = await Api.update(buildNumber); //packageInfo.buildNumber
      if (res['code'] == 1) {
        setState(() {
          updateInfo = res['data'];
        });
      }
    }
  }

  getInfo() async {
    sid = await StorageUtil.getString("sid") ?? '';
    smid = await StorageUtil.getString("smid") ?? '';
    String httpsString = await StorageUtil.getString("https") ?? '';
    host = await StorageUtil.getString("host") ?? "";
    baseUrl = await StorageUtil.getString("base_url") ?? '';
    String portString = await StorageUtil.getString("port") ?? '';
    account = await StorageUtil.getString("account") ?? '';
    note = await StorageUtil.getString("note") ?? '';
    password = await StorageUtil.getString("password") ?? '';
    String autoLoginString = await StorageUtil.getString("auto_login") ?? '';

    String rememberPasswordString =
        await StorageUtil.getString("remember_password") ?? '';
    String checkSslString = await StorageUtil.getString("check_ssl") ?? '';
    connectionStore.setCookie(smid);

    if (httpsString.isNotBlank) {
      setState(() {
        https = httpsString == "1";
      });
    }
    if (checkSslString.isNotBlank) {
      setState(() {
        checkSsl = checkSslString == "1";
      });
    }
    if (host.isNotBlank) {
      _hostController.value = TextEditingValue(text: host);
    }
    if (portString.isNotBlank) {
      port = portString;
      _portController.value = TextEditingValue(text: portString);
    } else {
      _portController.value = TextEditingValue(text: port);
    }
    if (account.isNotBlank) {
      _accountController.value = TextEditingValue(text: account);
    }
    if (note.isNotBlank) {
      _noteController.value = TextEditingValue(text: note);
    }
    if (password.isNotBlank) {
      _passwordController.value = TextEditingValue(text: password);
    }
    if (autoLoginString.isNotBlank) {
      setState(() {
        autoLogin = autoLoginString == "1";
      });
    }
    if (rememberPasswordString.isNotBlank) {
      setState(() {
        rememberPassword = rememberPasswordString == "1";
      });
    }
    checkLogin();
  }

  checkLogin() async {
    connectionStore.setAccount(account);
    if (sid.isNotBlank && host.isNotBlank) {
      if (baseUrl.isNotBlank) {
        connectionStore.setBaseUrl(baseUrl);
      } else {
        connectionStore.setBaseUrl("${https ? "https" : "http"}://$host:$port");
      }
      //开始自动登录
      Log.info("BaseUrl:$baseUrl");
      Log.info("HttpUtil.BaseUrl:${connectionStore.baseUrl}");
      connectionStore.setSid(sid);
      //如果开启了自动登录，则判断当前登录状态
      if (autoLogin) {
        setState(() {
          login = true;
        });
        var checkLogin = await Api.shareList(cancelToken: cancelToken);
        if (!checkLogin['success']) {
          if (checkLogin['code'] == "用户取消") {
            //如果用户主动取消登录
            setState(() {
              login = false;
            });
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
    connectionStore.setCheckSsl(checkSsl);
    FocusScope.of(context).unfocus();
    if (host.trim() == "") {
      UiUtil.toast("请输入网址/IP/QuickConnect ID");
      return;
    }
    if (account == "") {
      UiUtil.toast("请输入账号");
      return;
    }
    setState(() {
      login = true;
    });
    if (host.contains(".") || host.contains(':')) {
      String baseUri =
          "${https ? "https" : "http"}://${host.trim()}:${port.trim()}";
      Log.info("baseUri: $baseUri");
      doLogin(baseUri);
    } else {
      qcLogin();
    }
  }

  qcLogin({String qcHost = "global.quickconnect.cn"}) async {
    Log.info("QuickConnectID:$host");
    var res = await Api.quickConnect(host, baseUrl: qcHost);
    if (res['errno'] == 0) {
      if (res['server']['fqdn'] != "NULL") {
        qcAddresses.add("http://${res['server']['fqdn']}/");
      }
      if (res['server']['external']["ip"] != null) {
        qcAddresses.add(
            "http://${res['server']['external']["ip"]}:${res['service']['ext_port']}/");
      }
      if (res['service']['relay_ip'] != null) {
        qcAddresses.add(
            "http://${res['service']['relay_ip']}:${res['service']['relay_port']}/");
      }
      if (res['server']['ddns'] != "NULL") {
        qcAddresses.add(
            "http://${res['server']['ddns']}:${res['service']['ext_port']}/");
      }
      if (res['server']['interface'].length > 0) {
        for (var interface in res['server']['interface']) {
          qcAddresses
              .add("http://${interface['ip']}:${res['service']['port']}/");
          if (interface['ipv6'].length > 0) {
            for (var v6 in interface['ipv6']) {
              qcAddresses
                  .add("http://[${v6['address']}]:${res['service']['port']}/");
            }
          }
        }
      }
      if (res['service']['relay_ip'] == null) {
        var cnRes =
            await Api.quickConnectCn(host, baseUrl: res['env']['control_host']);
        if (cnRes['errno'] == 0) {
          if (cnRes['service']['relay_ip'] != null) {
            qcAddresses.add(
                "http://${cnRes['service']['relay_ip']}:${cnRes['service']['relay_port']}/");
          }
        }
      }

      bool finded = false;
      for (var address in qcAddresses) {
        Log.info(qcAddresses);
        Api.pingpong(address, (res) {
          if (res != null) {
            if (!finded) {
              setState(() {
                finded = true;
              });
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
      setState(() {
        login = false;
      });
    }
  }

  doLogin(String baseUri) async {
    var res = await Api.login(
        host: baseUri,
        account: account,
        password: password,
        otpCode: otpCode,
        cancelToken: cancelToken,
        rememberDevice: rememberDevice);
    setState(() {
      login = false;
    });
    if (res['success'] == true) {
      //记住登录信息
      connectionStore.setAccount(account);
      StorageUtil.setString("https", https ? "1" : "0");
      StorageUtil.setString("host", host.trim());
      StorageUtil.setString("port", port);
      StorageUtil.setString("base_url", baseUri);
      StorageUtil.setString("account", account);
      StorageUtil.setString("note", note);
      HttpUtil.instance
          .setStorage("remember_password", rememberPassword ? "1" : "0");
      StorageUtil.setString("auto_login", autoLogin ? "1" : "0");
      StorageUtil.setString("check_ssl", checkSsl ? "1" : "0");
      connectionStore.setSid(res['data']['sid']);
      if (rememberPassword) {
        StorageUtil.setString("password", password);
      } else {
        StorageUtil.remove("password");
      }
      if (autoLogin) {
        StorageUtil.setString("sid", res['data']['sid']);
      }

      connectionStore.setBaseUrl(baseUri);

      //添加服务器记录
      bool exist = false;
      for (int i = 0; i < servers.length; i++) {
        if (servers[i]['https'] == https &&
            servers[i]['host'] == host &&
            servers[i]['port'] == port &&
            servers[i]['account'] == account) {
          Log.info("账号已存在，更新信息");
          if (rememberPassword) {
            servers[i]['password'] = password;
          } else {
            servers[i]['password'] = "";
          }

          servers[i]['remember_password'] = rememberPassword;
          servers[i]['note'] = note;
          servers[i]['auto_login'] = autoLogin;
          servers[i]['check_ssl'] = checkSsl;
          servers[i]['cookie'] = connectionStore.cookie;
          servers[i]['sid'] = res['data']['sid'];
          servers[i]['base_url'] = baseUri;
          exist = true;
        }
      }
      if (!exist) {
        Log.info("账号不存在");
        Map server = {
          "https": https,
          "host": host,
          "base_url": baseUri,
          "port": port,
          "note": note,
          "account": account,
          "remember_password": rememberPassword,
          "auto_login": autoLogin,
          "check_ssl": checkSsl,
          "cookie": connectionStore.cookie,
          "sid": res['data']['sid'],
        };
        if (rememberPassword) {
          server['password'] = password;
        } else {
          server['password'] = "";
        }
        servers.add(server);
      }
      StorageUtil.setString("servers", jsonEncode(servers));
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
      if (res['error']['code'] == 400) {
        UiUtil.toast("用户名/密码有误");
      } else if (res['error']['code'] == 403) {
        UiUtil.toast("请输入二次验证代码");
        setState(() {
          needOtp = true;
        });
      } else if (res['error']['code'] == 404) {
        _otpController.clear();
        UiUtil.toast("错误的验证代码。请再试一次。");
      } else {
        UiUtil.toast("登录失败，code:${res['error']['code']}");
      }
    }
  }

  // wakeup() async {
  //   Log.info("wakeup");
  //   // final client = HttpDnsClient("http://180.76.76.76");
  //   // final result = await client.lookup("baidu.com");
  //   // Log.info(result);
  //   String ipv4 = '192.168.0.100';
  //   IPv4Address ipv4Address;
  //   MACAddress macAddress;
  //   if (IPv4Address.validate(ipv4)) {
  //     ipv4Address = IPv4Address(ipv4);
  //     //Continue execution
  //   } else {
  //     HttpUtil.toast("IP地址有误");
  //     return;
  //     // Handle invalid address case
  //   }
  //   String mac = '02-11-24-27-31-2F';
  //   if (MACAddress.validate(mac)) {
  //     macAddress = MACAddress(mac);
  //     //Continue execution
  //   } else {
  //     HttpUtil.toast("MAC地址有误");
  //     return;
  //     // Handle invalid address case
  //   }
  //   WakeOnLAN wol = WakeOnLAN(ipv4Address, macAddress, port: 1234);
  //   await wol.wake().then((v) => Log.info('sent'));
  // }

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

    if (result != null && result is String) {
      try {
        final data = jsonDecode(result) as Map<String, dynamic>;
        // 用户选择的设备信息
        setState(() {
          host = data['host'] ?? '';
          port = data['port'] ?? (https ? '5001' : '5000');
          _hostController.value = TextEditingValue(text: host);
          _portController.value = TextEditingValue(text: port);
        });
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
          if (servers.isNotEmpty)
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
                          setState(() {
                            https = !https;
                            if (https && port == "5000") {
                              port = "5001";
                              _portController.value =
                                  TextEditingValue(text: port);
                            } else if (!https && port == "5001") {
                              port = "5000";
                              _portController.value =
                                  TextEditingValue(text: port);
                            }
                          });
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
                              https ? "https" : "http",
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
                        onChanged: (v) {
                          setState(() {
                            host = v;
                          });
                        },
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
                          onChanged: (v) => port = v,
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
                        onChanged: (v) => account = v,
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
                        onChanged: (v) => note = v,
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
                  onChanged: (v) => password = v,
                  obscureText: !passwordVisible,
                  textInputAction: TextInputAction.done,
                  onEditingComplete: () {
                    FocusScope.of(context).unfocus();
                  },
                  decoration: InputDecoration(
                      border: InputBorder.none,
                      labelText: '密码',
                      suffixIcon: IconButton(
                          onPressed: () {
                            setState(() {
                              passwordVisible = !passwordVisible;
                            });
                          },
                          icon: Icon(passwordVisible
                              ? Icons.visibility
                              : Icons.visibility_off_outlined))),
                ),
              ),
            ),
            const SizedBox(
              height: 20,
            ),
            if (needOtp) ...[
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
                          onChanged: (v) => otpCode = v,
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
                        setState(() {
                          rememberDevice = !rememberDevice;
                        });
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
                              if (rememberDevice)
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
                      setState(() {
                        rememberPassword = !rememberPassword;
                        if (!rememberPassword) {
                          autoLogin = false;
                        }
                      });
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
                            if (rememberPassword)
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
                      setState(() {
                        autoLogin = !autoLogin;
                        if (autoLogin) {
                          rememberPassword = true;
                        }
                      });
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
                            if (autoLogin)
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
            if (https)
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      checkSsl = !checkSsl;
                    });
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
                          if (checkSsl)
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
                Log.info(login);
                // if (!read) {
                //   UiUtil.toast("请先阅读并同意用户协议和隐私政策");
                //   return;
                // }
                if (login) {
                  cancelToken.cancel("取消登录");
                  cancelToken = CancelToken();
                  setState(() {
                    login = false;
                  });
                  return;
                } else {
                  _login();
                }
              },
              child: login
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
