import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dsm_helper/pages/common/browser.dart' as dsm;
import 'package:dsm_helper/pages/login/accounts.dart';
import 'package:dsm_helper/pages/setting/license.dart';
import 'package:dsm_helper/pages/update/update.dart';
import 'package:dsm_helper/providers/flux_provider.dart';
import 'package:dsm_helper/util/function.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

class Login extends StatefulWidget {
  final Map? server;
  final String? type;
  Login({this.server, this.type = "login"});
  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  TapGestureRecognizer _licenseRecognizer = TapGestureRecognizer();
  TapGestureRecognizer _privacyRecognizer = TapGestureRecognizer();
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
  bool rememberDevice = false;
  bool read = false;
  TextEditingController _hostController = TextEditingController();
  TextEditingController _accountController = TextEditingController();
  TextEditingController _noteController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();
  TextEditingController _portController = TextEditingController();
  TextEditingController _otpController = TextEditingController();
  List servers = [];
  List qcAddresses = [];
  CancelToken cancelToken = CancelToken();
  @override
  initState() {
    Util.instance.getStorage("read").then((value) {
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
    Util.instance.getStorage("servers").then((serverString) {
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
        Util.instance.cookie = widget.server?['cookie'];
        Util.instance.sid = widget.server?['sid'];
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

  checkAgreement() async {
    String agreement = await Util.instance.getStorage("agreement") ?? '';
    if (agreement != '1') {
      showCupertinoDialog(
        context: context,
        builder: (context) {
          return Material(
            color: Colors.transparent,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Card(
                  shape: RoundedRectangleBorder(
                      side: BorderSide(),
                      borderRadius: BorderRadius.circular(5)),
                  margin: EdgeInsets.symmetric(horizontal: 50),
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Card(
                          shape: RoundedRectangleBorder(
                              side: BorderSide(),
                              borderRadius: BorderRadius.circular(5)),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                      text:
                                          "感谢您使用${Util.instance.appName}，为保护您的个人信息安全，我们将依据${Util.instance.appName}的"),
                                  TextSpan(
                                    text: "用户协议",
                                    style: TextStyle(
                                        decoration: TextDecoration.underline,
                                        color: Colors.blue),
                                    recognizer: _licenseRecognizer
                                      ..onTap = () {
                                        FocusScope.of(context).unfocus();
                                        Navigator.of(context).push(
                                            CupertinoPageRoute(
                                                builder: (context) {
                                          return License();
                                        }));
                                      },
                                  ),
                                  TextSpan(text: " 和 "),
                                  TextSpan(
                                    text: "隐私政策",
                                    style: TextStyle(
                                        decoration: TextDecoration.underline,
                                        color: Colors.blue),
                                    recognizer: _privacyRecognizer
                                      ..onTap = () {
                                        FocusScope.of(context).unfocus();
                                        Navigator.of(context).push(
                                            CupertinoPageRoute(
                                                builder: (context) {
                                          return dsm.Browser(
                                            url:
                                                '${Util.instance.appUrl}/privacy',
                                            title: "隐私政策",
                                          );
                                        }));
                                      },
                                  ),
                                  TextSpan(
                                      text:
                                          "来帮助您了解：我们如何收集个人信息、如何使用及存储个人信息以及您享有的相关权利\n"),
                                  TextSpan(
                                      text:
                                          "在您使用${Util.instance.appName}前，请务必仔细阅读"),
                                  TextSpan(
                                    text: "用户协议",
                                    style: TextStyle(
                                        decoration: TextDecoration.underline,
                                        color: Colors.blue),
                                    recognizer: _licenseRecognizer
                                      ..onTap = () {
                                        FocusScope.of(context).unfocus();
                                        Navigator.of(context).push(
                                            CupertinoPageRoute(
                                                builder: (context) {
                                          return License();
                                        }));
                                      },
                                  ),
                                  TextSpan(text: "和 "),
                                  TextSpan(
                                    text: "隐私政策",
                                    style: TextStyle(
                                        decoration: TextDecoration.underline,
                                        color: Colors.blue),
                                    recognizer: _privacyRecognizer
                                      ..onTap = () {
                                        FocusScope.of(context).unfocus();
                                        Navigator.of(context).push(
                                            CupertinoPageRoute(
                                                builder: (context) {
                                          return dsm.Browser(
                                            url:
                                                '${Util.instance.appUrl}/privacy',
                                            title: "隐私政策",
                                          );
                                        }));
                                      },
                                  ),
                                  TextSpan(
                                      text: "以了解详细内容，如您同意，请点击'同意并继续'开始使用我们的服务"),
                                ],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 20,
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () async {
                                  Navigator.of(context).pop();
                                  Util.instance.setStorage("read", "1");
                                  Util.instance.setStorage(
                                      "agreement", read ? "1" : "0");
                                  context.read<FluwxProvider>().wx.registerApi(
                                      appId: "wxabdf23571f34b49b",
                                      universalLink:
                                          "https://dsm.apaipai.top/app/");
                                },
                                child: Text(
                                  "同意并继续",
                                  style: TextStyle(fontSize: 18),
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 16,
                            ),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () async {
                                  SystemNavigator.pop();
                                },
                                child: Text(
                                  "不同意",
                                  style: TextStyle(fontSize: 18),
                                ),
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    }
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
    sid = await Util.instance.getStorage("sid") ?? '';
    smid = await Util.instance.getStorage("smid") ?? '';
    String httpsString = await Util.instance.getStorage("https") ?? '';
    host = await Util.instance.getStorage("host") ?? "";
    baseUrl = await Util.instance.getStorage("base_url") ?? '';
    String portString = await Util.instance.getStorage("port") ?? '';
    account = await Util.instance.getStorage("account") ?? '';
    note = await Util.instance.getStorage("note") ?? '';
    password = await Util.instance.getStorage("password") ?? '';
    String autoLoginString = await Util.instance.getStorage("auto_login") ?? '';

    String rememberPasswordString =
        await Util.instance.getStorage("remember_password") ?? '';
    String checkSslString = await Util.instance.getStorage("check_ssl") ?? '';
    Util.instance.cookie = smid;

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
    Util.instance.account = account;
    if (sid.isNotBlank && host.isNotBlank) {
      if (baseUrl.isNotBlank) {
        Util.instance.baseUrl = baseUrl;
      } else {
        Util.instance.baseUrl = "${https ? "https" : "http"}://$host:$port";
      }
      //开始自动登录
      debugPrint("BaseUrl:$baseUrl");
      debugPrint("Util.BaseUrl:${Util.instance.baseUrl}");
      Util.instance.sid = sid;
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
            debugPrint("尝试重新登录");
            _login();
          }
        } else {
          //登录有效，进入首页
          Navigator.of(context)
              .pushNamedAndRemoveUntil("/home", (route) => false);
        }
      }
    }
  }

  _login() async {
    Util.instance.checkSsl = checkSsl;
    FocusScope.of(context).unfocus();
    if (host.trim() == "") {
      Util.instance.toast("请输入网址/IP/QuickConnect ID");
      return;
    }
    if (account == "") {
      Util.instance.toast("请输入账号");
      return;
    }
    setState(() {
      login = true;
    });
    if (host.contains(".") || host.contains(':')) {
      String baseUri =
          "${https ? "https" : "http"}://${host.trim()}:${port.trim()}";
      debugPrint(baseUri);
      doLogin(baseUri);
    } else {
      qcLogin();
    }
  }

  qcLogin({String qcHost = "global.quickconnect.cn"}) async {
    debugPrint("QuickConnectID:$host");
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
        print(qcAddresses);
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
      Util.instance.toast("无法连接到服务器，请检查QuickConnect ID是否正确");
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
      Util.instance.account = account;
      Util.instance.setStorage("https", https ? "1" : "0");
      Util.instance.setStorage("host", host.trim());
      Util.instance.setStorage("port", port);
      Util.instance.setStorage("base_url", baseUri);
      Util.instance.setStorage("account", account);
      Util.instance.setStorage("note", note);
      Util.instance
          .setStorage("remember_password", rememberPassword ? "1" : "0");
      Util.instance.setStorage("auto_login", autoLogin ? "1" : "0");
      Util.instance.setStorage("check_ssl", checkSsl ? "1" : "0");
      Util.instance.sid = res['data']['sid'];
      if (rememberPassword) {
        Util.instance.setStorage("password", password);
      } else {
        Util.instance.removeStorage("password");
      }
      if (autoLogin) {
        Util.instance.setStorage("sid", res['data']['sid']);
      }

      Util.instance.baseUrl = baseUri;

      //添加服务器记录
      bool exist = false;
      for (int i = 0; i < servers.length; i++) {
        if (servers[i]['https'] == https &&
            servers[i]['host'] == host &&
            servers[i]['port'] == port &&
            servers[i]['account'] == account) {
          debugPrint("账号已存在，更新信息");
          if (rememberPassword) {
            servers[i]['password'] = password;
          } else {
            servers[i]['password'] = "";
          }

          servers[i]['remember_password'] = rememberPassword;
          servers[i]['note'] = note;
          servers[i]['auto_login'] = autoLogin;
          servers[i]['check_ssl'] = checkSsl;
          servers[i]['cookie'] = Util.instance.cookie;
          servers[i]['sid'] = res['data']['sid'];
          servers[i]['base_url'] = baseUri;
          exist = true;
        }
      }
      if (!exist) {
        debugPrint("账号不存在");
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
          "cookie": Util.instance.cookie,
          "sid": res['data']['sid'],
        };
        if (rememberPassword) {
          server['password'] = password;
        } else {
          server['password'] = "";
        }
        servers.add(server);
      }
      Util.instance.setStorage("servers", jsonEncode(servers));
      if (widget.type == "login") {
        Navigator.of(context)
            .pushNamedAndRemoveUntil("/home", (route) => false);
      } else {
        Navigator.of(context).pop(true);
      }
    } else {
      Util.instance.vibrate(FeedbackType.warning);
      if (res['error']['code'] == 400) {
        Util.instance.toast("用户名/密码有误");
      } else if (res['error']['code'] == 403) {
        Util.instance.toast("请输入二次验证代码");
        setState(() {
          needOtp = true;
        });
      } else if (res['error']['code'] == 404) {
        _otpController.clear();
        Util.instance.toast("错误的验证代码。请再试一次。");
      } else {
        Util.instance.toast("登录失败，code:${res['error']['code']}");
      }
    }
  }

  // wakeup() async {
  //   print("wakeup");
  //   // final client = HttpDnsClient("http://180.76.76.76");
  //   // final result = await client.lookup("baidu.com");
  //   // print(result);
  //   String ipv4 = '192.168.0.100';
  //   IPv4Address ipv4Address;
  //   MACAddress macAddress;
  //   if (IPv4Address.validate(ipv4)) {
  //     ipv4Address = IPv4Address(ipv4);
  //     //Continue execution
  //   } else {
  //     Util.toast("IP地址有误");
  //     return;
  //     // Handle invalid address case
  //   }
  //   String mac = '02-11-32-27-31-2F';
  //   if (MACAddress.validate(mac)) {
  //     macAddress = MACAddress(mac);
  //     //Continue execution
  //   } else {
  //     Util.toast("MAC地址有误");
  //     return;
  //     // Handle invalid address case
  //   }
  //   WakeOnLAN wol = WakeOnLAN(ipv4Address, macAddress, port: 1234);
  //   await wol.wake().then((v) => print('sent'));
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: EdgeInsets.only(left: 10, top: 8, bottom: 8),
          child: OutlinedButton(
            onPressed: () {
              Navigator.of(context).push(CupertinoPageRoute(builder: (context) {
                return Update(updateInfo);
              }));
            },
            child: Image.asset(
              "assets/icons/update.png",
              width: 20,
              height: 20,
              color: Colors.redAccent,
            ),
          ),
        ),
        title: Text(
          widget.type == "login" ? "账号登录" : "添加账号",
        ),
        actions: [
          // Padding(
          //   padding: EdgeInsets.only(right: 10, top: 8, bottom: 8),
          //   child: NeuButton(
          //     decoration: NeumorphicDecoration(
          //       color: Theme.of(context).scaffoldBackgroundColor,
          //       borderRadius: BorderRadius.circular(10),
          //     ),
          //     padding: EdgeInsets.all(10),
          //     bevel: 5,
          //     onPressed: wakeup,
          //     child: Image.asset(
          //       "assets/icons/history.png",
          //       width: 20,
          //       height: 20,
          //     ),
          //   ),
          // ),
          if (servers.length > 0)
            Padding(
              padding: EdgeInsets.only(right: 10, top: 8, bottom: 8),
              child: OutlinedButton(
                onPressed: () {
                  Navigator.of(context)
                      .push(CupertinoPageRoute(builder: (context) {
                    return Accounts();
                  }));
                },
                child: Image.asset(
                  "assets/icons/history.png",
                  width: 20,
                  height: 20,
                ),
              ),
            )
        ],
      ),
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: ListView(
          padding: EdgeInsets.all(20),
          children: <Widget>[
            SizedBox(
              height: 20,
            ),
            Card(
              shape: RoundedRectangleBorder(
                  side: BorderSide(), borderRadius: BorderRadius.circular(5)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
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
                            SizedBox(
                              height: 4,
                            ),
                            Text(
                              "协议",
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey, height: 1),
                            ),
                            Text(
                              https ? "https" : "http",
                              style: TextStyle(fontSize: 16),
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
                        decoration: InputDecoration(
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
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            labelText: '端口',
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            SizedBox(
              height: 20,
            ),
            Row(
              children: [
                Expanded(
                  child: Card(
                    shape: RoundedRectangleBorder(
                        side: BorderSide(),
                        borderRadius: BorderRadius.circular(5)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: TextField(
                        autocorrect: false,
                        keyboardAppearance: Brightness.light,
                        controller: _accountController,
                        onChanged: (v) => account = v,
                        textInputAction: TextInputAction.next,
                        onEditingComplete: () {
                          FocusScope.of(context).nextFocus();
                        },
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          labelText: '账号',
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: 20,
                ),
                Expanded(
                  child: Card(
                    shape: RoundedRectangleBorder(
                        side: BorderSide(),
                        borderRadius: BorderRadius.circular(5)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: TextField(
                        keyboardAppearance: Brightness.light,
                        controller: _noteController,
                        onChanged: (v) => note = v,
                        textInputAction: TextInputAction.next,
                        onEditingComplete: () {
                          FocusScope.of(context).nextFocus();
                        },
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          labelText: '备注',
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(
              height: 20,
            ),
            Card(
              shape: RoundedRectangleBorder(
                  side: BorderSide(), borderRadius: BorderRadius.circular(5)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: TextField(
                  controller: _passwordController,
                  onChanged: (v) => password = v,
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  onEditingComplete: () {
                    FocusScope.of(context).unfocus();
                  },
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    labelText: '密码',
                  ),
                ),
              ),
            ),
            SizedBox(
              height: 20,
            ),
            if (needOtp) ...[
              Row(
                children: [
                  Expanded(
                    child: Card(
                      shape: RoundedRectangleBorder(
                          side: BorderSide(),
                          borderRadius: BorderRadius.circular(5)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: TextField(
                          controller: _otpController,
                          onChanged: (v) => otpCode = v,
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.done,
                          onEditingComplete: () {
                            FocusScope.of(context).unfocus();
                          },
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            labelText: '二步验证代码',
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
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
                            side: BorderSide(),
                            borderRadius: BorderRadius.circular(5)),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            children: [
                              Text("记住设备"),
                              Spacer(),
                              if (rememberDevice)
                                Icon(
                                  CupertinoIcons.checkmark_alt,
                                  color: Color(0xffff9813),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(
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
                          side: BorderSide(),
                          borderRadius: BorderRadius.circular(5)),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            Text("记住密码"),
                            Spacer(),
                            if (rememberPassword)
                              Icon(
                                CupertinoIcons.checkmark_alt,
                                color: Color(0xffff9813),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(
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
                          side: BorderSide(),
                          borderRadius: BorderRadius.circular(5)),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            Text("自动登录"),
                            Spacer(),
                            if (autoLogin)
                              Icon(
                                CupertinoIcons.checkmark_alt,
                                color: Color(0xffff9813),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(
              height: 20,
            ),
            if (https)
              Padding(
                padding: EdgeInsets.only(bottom: 20),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      checkSsl = !checkSsl;
                    });
                  },
                  child: Card(
                    shape: RoundedRectangleBorder(
                        side: BorderSide(),
                        borderRadius: BorderRadius.circular(5)),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          Text("验证SSL证书"),
                          Spacer(),
                          if (checkSsl)
                            Icon(
                              CupertinoIcons.checkmark_alt,
                              color: Color(0xffff9813),
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
                print(login);
                if (!read) {
                  Util.instance.toast("请先阅读并同意用户协议和隐私政策");
                  return;
                }
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
                  ? Row(
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
                      style: TextStyle(fontSize: 18),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
