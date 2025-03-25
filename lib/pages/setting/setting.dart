import 'dart:convert';

import 'package:garden/pages/backup/backup.dart';
import 'package:garden/pages/control_panel/ssh/ssh.dart';
import 'package:garden/pages/login/accounts.dart';
import 'package:garden/pages/login/confirm_logout.dart';
import 'package:garden/providers/dark_mode.dart';
import 'package:garden/pages/setting/helper_setting.dart';
import 'package:garden/pages/terminal/select_server.dart';
import 'package:garden/pages/user/setting.dart';
import 'package:garden/util/function.dart';
import 'package:garden/widgets/terminal_button.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SettingButton extends StatelessWidget {
  final bool loading;
  final String? name;
  final String? icon;
  final OnPressed? onPressed;
  const SettingButton(
      {this.name, this.icon, this.onPressed, this.loading = false});

  @override
  Widget build(BuildContext context) {
    double width = (MediaQuery.sizeOf(context).width - 81) / 3;
    return SizedBox(
      width: width,
      child: OutlinedButton(
        onPressed: onPressed,
        style: ButtonStyle(
          padding: WidgetStateProperty.all(EdgeInsets.symmetric(vertical: 6)),
        ),
        child: Column(
          children: [
            loading
                ? CupertinoActivityIndicator(radius: 20)
                : Image.asset(
                    "assets/icons/$icon.png",
                    width: 24,
                  ),
            SizedBox(
              height: 5,
            ),
            Text(
              "$name",
              style: TextStyle(fontSize: 12),
            )
          ],
        ),
      ),
    );
  }
}

class ThemeButton extends StatelessWidget {
  const ThemeButton(this.image, this.type, this.text);
  final String image;
  final int type;
  final String text;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: () {
        Navigator.of(context).pop();
        Provider.of<DarkModeProvider>(context, listen: false).changeMode(type);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(image),
              ),
            ),
            SizedBox(
              height: 10,
            ),
            Text(
              text,
              style: TextStyle(fontSize: 14),
            )
          ],
        ),
      ),
    );
  }
}

class Setting extends StatefulWidget {
  @override
  _SettingState createState() => _SettingState();
}

class _SettingState extends State<Setting> {
  bool checking = false;
  bool ssh = false;
  bool telnet = false;

  bool sshLoading = true;
  bool shutdowning = false;
  bool rebooting = false;
  String sshPort = '';

  List servers = [];

  String account = "";
  String host = "";
  bool otpEnable = false;
  bool otpEnforced = false;

  String email = "";
  @override
  void initState() {
    getData();
    getServers();
    getNormalUser();
    Util.instance
        .getStorage("account")
        .then((value) => setState(() => account = value ?? ''));
    Util.instance
        .getStorage("host")
        .then((value) => setState(() => host = value ?? ''));
    super.initState();
  }

  getServers() async {
    String serverString = await Util.instance.getStorage("servers") ?? '';
    if (serverString.isNotBlank) {
      servers = json.decode(serverString);
    }
  }

  getData() async {
    var res = await Api.terminalInfo();
    if (res['success']) {
      setState(() {
        ssh = res['data']['enable_ssh'];
        telnet = res['data']['enable_telnet'];
        sshPort = res['data']['ssh_port'].toString();
        sshLoading = false;
      });
    } else {
      setState(() {
        sshLoading = false;
        ssh = false;
      });
    }
  }

  getNormalUser() async {
    var res = await Api.normalUser("get");
    if (res['success']) {
      setState(() {
        otpEnable = res['data']['OTP_enable'];
        otpEnforced = res['data']['OTP_enforced'];
        email = res['data']['email'];
      });
    }
  }

  power(String type, bool force) async {
    setState(() {
      if (type == "shutdown") {
        shutdowning = true;
      } else {
        rebooting = true;
      }
    });
    var res = await Api.power(type, force);
    setState(() {
      if (type == "shutdown") {
        shutdowning = false;
      } else {
        rebooting = false;
      }
    });
    if (res['success']) {
      Util.instance.toast("已发送指令");
    } else if (res['error']['code'] == 117) {
      List errors = res['error']['errors']['runningTasks'];
      List msgs = [];
      for (int i = 0; i < errors.length; i++) {
        List titles = errors[i].split(":");
        if (titles.length == 3) {
          msgs.add(Util.instance.strings[titles[0]][titles[1]][titles[2]]);
        }
        //系统正在处理下列任务。现在关机可能会导致套件异常或数据丢失。是否确定要继续？
        showCupertinoModalPopup(
          context: context,
          builder: (context) {
            return Material(
              color: Colors.transparent,
              child: Card(
                shape: RoundedRectangleBorder(
                    side: BorderSide(),
                    borderRadius: BorderRadius.circular(18)),
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          "系统正在处理下列任务。现在关机可能会导致套件异常或数据丢失。是否确定要继续？",
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.w500),
                        ),
                        SizedBox(
                          height: 12,
                        ),
                        Text(
                          "${msgs.join("\n")}",
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.w400),
                        ),
                        SizedBox(
                          height: 22,
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () async {
                                  Navigator.of(context).pop();
                                  power(type, true);
                                },
                                child: Text(
                                  "强制${type == "shutdown" ? "关机" : "重启"}",
                                  style: TextStyle(
                                      fontSize: 18, color: Colors.redAccent),
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 16,
                            ),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () async {
                                  Navigator.of(context).pop();
                                },
                                child: Text(
                                  "取消",
                                  style: TextStyle(fontSize: 18),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(
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
    } else {
      Util.instance.toast("操作失败，code:${res['error']['code']}");
    }
  }

  onShutdown() async {
    if (shutdowning) {
      return;
    }
    showCupertinoModalPopup(
      context: context,
      builder: (context) {
        return Material(
          color: Colors.transparent,
          child: Card(
            shape: RoundedRectangleBorder(
                side: BorderSide(), borderRadius: BorderRadius.circular(18)),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      "确认关机",
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                    ),
                    SizedBox(
                      height: 12,
                    ),
                    Text(
                      "确认要关闭设备吗？",
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.w400),
                    ),
                    SizedBox(
                      height: 22,
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () async {
                              Navigator.of(context).pop();
                              power("shutdown", false);
                            },
                            child: Text(
                              "确认关机",
                              style: TextStyle(
                                  fontSize: 18, color: Colors.redAccent),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 16,
                        ),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () async {
                              Navigator.of(context).pop();
                            },
                            child: Text(
                              "取消",
                              style: TextStyle(fontSize: 18),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(
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

  onReboot() async {
    if (rebooting) {
      return;
    }
    showCupertinoModalPopup(
      context: context,
      builder: (context) {
        return Material(
          color: Colors.transparent,
          child: Card(
            shape: RoundedRectangleBorder(
                side: BorderSide(), borderRadius: BorderRadius.circular(18)),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      "确认重启",
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                    ),
                    SizedBox(
                      height: 12,
                    ),
                    Text(
                      "确认要重新启动设备？",
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.w400),
                    ),
                    SizedBox(
                      height: 22,
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () async {
                              Navigator.of(context).pop();
                              power("reboot", false);
                            },
                            child: Text(
                              "确认重启",
                              style: TextStyle(
                                  fontSize: 18, color: Colors.redAccent),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 16,
                        ),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () async {
                              Navigator.of(context).pop();
                            },
                            child: Text(
                              "取消",
                              style: TextStyle(fontSize: 18),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(
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

  onTheme() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) {
        return Material(
          color: Colors.transparent,
          child: Card(
            shape: RoundedRectangleBorder(
                side: BorderSide(), borderRadius: BorderRadius.circular(18)),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      "主题颜色",
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                    ),
                    SizedBox(
                      height: 12,
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: ThemeButton("assets/light.png", 0, "亮色"),
                        ),
                        SizedBox(
                          width: 16,
                        ),
                        Expanded(
                          child: ThemeButton("assets/dark.png", 1, "暗色"),
                        ),
                        SizedBox(
                          width: 16,
                        ),
                        Expanded(
                          child: ThemeButton("assets/auto.png", 2, "跟随系统"),
                        ),
                      ],
                    ),
                    SizedBox(
                      height: 20,
                    ),
                    OutlinedButton(
                      onPressed: () async {
                        Navigator.of(context).pop();
                      },
                      child: Text(
                        "取消",
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                    SizedBox(
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

  @override
  Widget build(BuildContext context) {
    double width = (MediaQuery.sizeOf(context).width - 81) / 3;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "设置",
        ),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 10, top: 8, bottom: 8),
            child: OutlinedButton(
              onPressed: () {
                Navigator.of(context)
                    .push(
                  CupertinoPageRoute(
                    builder: (context) {
                      return HelperSetting();
                    },
                    settings: RouteSettings(name: "helper_setting"),
                  ),
                )
                    .then((_) {
                  setState(() {});
                });
              },
              child: Image.asset(
                "assets/icons/setting.png",
                width: 20,
                height: 20,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.symmetric(horizontal: 20),
        children: [
          SizedBox(
            height: 30,
          ),
          GestureDetector(
            onTap: () {
              Navigator.of(context)
                  .push(CupertinoPageRoute(
                      builder: (context) {
                        return UserSetting();
                      },
                      settings: RouteSettings(name: "user_setting")))
                  .then((res) {
                if (res != null && res) {
                  getNormalUser();
                }
              });
            },
            child: Card(
              shape: RoundedRectangleBorder(
                  side: BorderSide(), borderRadius: BorderRadius.circular(18)),
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundImage: AssetImage("assets/logo.png"),
                      radius: 30,
                    ),
                    SizedBox(
                      width: 10,
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "$account",
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.w600),
                          ),
                          SizedBox(
                            height: 5,
                          ),
                          Text(
                            "$host",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: Colors.grey),
                          )
                        ],
                      ),
                    ),
                    OutlinedButton(
                      onPressed: () {
                        showCupertinoModalPopup(
                          context: context,
                          builder: (context) {
                            return ConfirmLogout(otpEnable);
                          },
                        );
                      },
                      // margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      child: Image.asset(
                        "assets/icons/exit.png",
                        width: 16,
                      ),
                    ),
                    SizedBox(
                      width: 10,
                    ),
                    OutlinedButton(
                      onPressed: () {
                        Navigator.of(context)
                            .push(CupertinoPageRoute(builder: (context) {
                          return Accounts();
                        }));
                      },
                      // margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      child: Image.asset(
                        "assets/icons/change.png",
                        width: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(
            height: 30,
          ),
          Wrap(
            spacing: 20,
            runSpacing: 20,
            children: [
              if (Util.instance.notReviewAccount) ...[
                SettingButton(
                    name: "关机",
                    icon: "shutdown",
                    loading: shutdowning,
                    onPressed: onShutdown),
                SettingButton(
                    name: "重启",
                    icon: "reboot",
                    loading: rebooting,
                    onPressed: onReboot),
              ],
              SizedBox(
                width: width,
                child: GestureDetector(
                  onTap: () async {
                    showCupertinoModalPopup(
                      context: context,
                      builder: (context) {
                        return Material(
                          color: Colors.transparent,
                          child: Card(
                            shape: RoundedRectangleBorder(
                                side: BorderSide(),
                                borderRadius: BorderRadius.circular(12)),
                            child: SafeArea(
                              top: false,
                              child: Padding(
                                padding: EdgeInsets.all(20),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    Text(
                                      "提示",
                                      style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w500),
                                    ),
                                    SizedBox(
                                      height: 12,
                                    ),
                                    Text(
                                      "确认${ssh ? '关闭' : '开启'}SSH吗？",
                                      style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w400),
                                    ),
                                    SizedBox(
                                      height: 22,
                                    ),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: OutlinedButton(
                                            onPressed: () async {
                                              Navigator.of(context).pop();
                                              setState(() {
                                                sshLoading = true;
                                              });
                                              var res = await Api.setTerminal(
                                                  !ssh, telnet, sshPort);
                                              print(res);
                                              if (!res['success']) {
                                                Util.instance.toast(
                                                    "操作失败，代码：${res['error']['code']}");
                                              }
                                              await getData();
                                            },
                                            child: Text(
                                              "确认${ssh ? '关闭' : '开启'}SSH",
                                              style: TextStyle(
                                                  fontSize: 18,
                                                  color: Colors.redAccent),
                                            ),
                                          ),
                                        ),
                                        SizedBox(
                                          width: 16,
                                        ),
                                        Expanded(
                                          child: OutlinedButton(
                                            onPressed: () async {
                                              Navigator.of(context).pop();
                                            },
                                            child: Text(
                                              "取消",
                                              style: TextStyle(fontSize: 18),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(
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
                  },
                  onLongPress: () {
                    Navigator.of(context).push(CupertinoPageRoute(
                        builder: (context) {
                          return SshSetting();
                        },
                        settings: RouteSettings(name: "ssh_setting")));
                  },
                  child: Card(
                    margin: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                        side: BorderSide(),
                        borderRadius: BorderRadius.circular(18)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6.0),
                      child: Column(
                        children: [
                          sshLoading
                              ? Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: CupertinoActivityIndicator(
                                    radius: 20,
                                  ),
                                )
                              : Image.asset(
                                  "assets/icons/ssh.png",
                                  width: 24,
                                ),
                          SizedBox(
                            height: 2,
                          ),
                          Text(
                            "SSH${ssh ? "已开启" : "已关闭"}",
                            style: TextStyle(fontSize: 12),
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              SettingButton(name: "主题", icon: "theme", onPressed: onTheme),
              SettingButton(
                name: "终端",
                icon: "ssh",
                onPressed: () {
                  Navigator.of(context).push(
                    CupertinoPageRoute(
                        builder: (context) {
                          return SelectServer();
                        },
                        settings: RouteSettings(name: "select_server")),
                  );
                },
              ),
              SettingButton(
                name: "相册备份",
                icon: "upload",
                onPressed: () {
                  Navigator.of(context).push(
                    CupertinoPageRoute(
                        builder: (context) {
                          return Backup();
                        },
                        settings: RouteSettings(name: "backup")),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
