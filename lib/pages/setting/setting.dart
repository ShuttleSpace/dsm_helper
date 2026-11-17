import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:garden/pages/backup/backup.dart';
import 'package:garden/pages/control_panel/ssh/ssh.dart';
import 'package:garden/pages/login/accounts.dart';
import 'package:garden/pages/login/confirm_logout.dart';
import 'package:garden/pages/setting/helper_setting.dart';
import 'package:garden/pages/terminal/select_server.dart';
import 'package:garden/pages/user/setting.dart';
import 'package:garden/stores/connection_store.dart';
import 'package:garden/stores/settings_store.dart';
import 'package:garden/api/dsm_api.dart';
import 'package:garden/extensions/string.dart';
import 'package:garden/util/log.dart';
import 'package:garden/util/storage_util.dart';
import 'package:garden/util/ui_util.dart';
import 'package:garden/widgets/terminal_button.dart';
import 'package:garden/constants/app_constants.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:signals_hooks/signals_hooks.dart';

class SettingButton extends StatelessWidget {
  final bool loading;
  final String? name;
  final String? icon;
  final OnPressed? onPressed;
  const SettingButton(
      {super.key, this.name, this.icon, this.onPressed, this.loading = false});

  @override
  Widget build(BuildContext context) {
    double width = (MediaQuery.sizeOf(context).width - 81) / 3;
    return SizedBox(
      width: width,
      child: OutlinedButton(
        onPressed: onPressed,
        style: ButtonStyle(
          padding:
              WidgetStateProperty.all(const EdgeInsets.symmetric(vertical: 12)),
        ),
        child: Column(
          children: [
            loading
                ? const CupertinoActivityIndicator(radius: 20)
                : Image.asset(
                    "assets/icons/$icon.png",
                    width: 24,
                  ),
            const SizedBox(
              height: 5,
            ),
            Text(
              "$name",
              style: const TextStyle(fontSize: 12),
            )
          ],
        ),
      ),
    );
  }
}

class ThemeButton extends StatelessWidget {
  const ThemeButton(this.image, this.type, this.text, {super.key});
  final String image;
  final int type;
  final String text;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: () {
        Navigator.of(context).pop();
        settingsStore.setDarkMode(type);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Column(
          children: [
            Image.asset(
              image,
              height: 48,
            ),
            const SizedBox(
              height: 10,
            ),
            Text(
              text,
              style: const TextStyle(fontSize: 14),
            )
          ],
        ),
      ),
    );
  }
}

class Setting extends HookWidget {
  const Setting({super.key});

  @override
  Widget build(BuildContext context) {
    final ssh = useSignal(false);
    final telnet = useSignal(false);
    final sshLoading = useSignal(true);
    final shutdowning = useSignal(false);
    final rebooting = useSignal(false);
    final sshPort = useSignal('');
    final servers = useSignal<List>([]);
    final account = useSignal("");
    final host = useSignal("");
    final otpEnable = useSignal(false);
    final otpEnforced = useSignal(false);
    final email = useSignal("");

    getServers() async {
      String serverString = await StorageUtil.getString("servers") ?? '';
      if (serverString.isNotBlank) {
        servers.value = json.decode(serverString);
      }
    }

    getData() async {
      try {
        final data = await dsmCoreTerminalInfoForPage();
        ssh.value = data['enable_ssh'] ?? false;
        telnet.value = data['enable_telnet'] ?? false;
        sshPort.value = (data['ssh_port'] ?? '').toString();
      } catch (e) {
        ssh.value = false;
      } finally {
        sshLoading.value = false;
      }
    }

    getNormalUser() async {
      try {
        final data = await dsmCoreNormalUser('get');
        otpEnable.value = data['OTP_enable'] ?? false;
        otpEnforced.value = data['OTP_enforced'] ?? false;
        email.value = data['email'] ?? '';
      } catch (e) {
        // 旧层失败时保持默认值。
      }
    }

    power(String type, bool force) async {
      if (type == "shutdown") {
        shutdowning.value = true;
      } else {
        rebooting.value = true;
      }

      Map<String, dynamic>? errorData;
      try {
        await dsmCoreSystemPowerForPage(type, force);
        UiUtil.toast("已发送指令");
      } on DSMException catch (e) {
        errorData = e.rawError;
        if (e.code != 117) {
          UiUtil.toast("操作失败，代码：${e.code}");
        }
      } catch (_) {}

      if (type == "shutdown") {
        shutdowning.value = false;
      } else {
        rebooting.value = false;
      }

      if (errorData != null && errorData['code'] == 117) {
        final rawErrors = errorData['errors'];
        List errors = rawErrors is Map
            ? (rawErrors['runningTasks'] as List? ?? [])
            : [];
        List msgs = [];
        for (int i = 0; i < errors.length; i++) {
          List titles = errors[i].split(":");
          if (titles.length == 3) {
            msgs.add(
                connectionStore.strings.value[titles[0]][titles[1]][titles[2]]);
          }
          //系统正在处理下列任务。现在关机可能会导致套件异常或数据丢失。是否确定要继续？
          if (context.mounted) {
            showCupertinoModalPopup(
              // ignore: use_build_context_synchronously
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
                              "系统正在处理下列任务。现在关机可能会导致套件异常或数据丢失。是否确定要继续？",
                              style: TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(
                              height: 12,
                            ),
                            Text(
                              msgs.join("\n"),
                              style: const TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.w400),
                            ),
                            const SizedBox(
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
                                      style: const TextStyle(
                                          fontSize: 18,
                                          color: Colors.redAccent),
                                    ),
                                  ),
                                ),
                                const SizedBox(
                                  width: 16,
                                ),
                                Expanded(
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
      }
    }

    onShutdown() async {
      if (shutdowning.value) {
        return;
      }
      showCupertinoModalPopup(
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
                        "确认关机",
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(
                        height: 12,
                      ),
                      const Text(
                        "确认要关闭设备吗？",
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w400),
                      ),
                      const SizedBox(
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
                              child: const Text(
                                "确认关机",
                                style: TextStyle(
                                    fontSize: 18, color: Colors.redAccent),
                              ),
                            ),
                          ),
                          const SizedBox(
                            width: 16,
                          ),
                          Expanded(
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

    onReboot() async {
      if (rebooting.value) {
        return;
      }
      showCupertinoModalPopup(
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
                        "确认重启",
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(
                        height: 12,
                      ),
                      const Text(
                        "确认要重新启动设备？",
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w400),
                      ),
                      const SizedBox(
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
                              child: const Text(
                                "确认重启",
                                style: TextStyle(
                                    fontSize: 18, color: Colors.redAccent),
                              ),
                            ),
                          ),
                          const SizedBox(
                            width: 16,
                          ),
                          Expanded(
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

    onTheme() async {
      showCupertinoModalPopup(
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
                  padding: const EdgeInsets.all(6),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      const Text(
                        "主题颜色",
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(
                        height: 12,
                      ),
                      const Row(
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
                      const SizedBox(
                        height: 20,
                      ),
                      OutlinedButton(
                        onPressed: () async {
                          Navigator.of(context).pop();
                        },
                        child: const Text(
                          "取消",
                          style: TextStyle(fontSize: 18),
                        ),
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

    useEffect(() {
      getData();
      getServers();
      getNormalUser();
      StorageUtil.getString("account")
          .then((value) => account.value = value ?? '');
      StorageUtil.getString("host").then((value) => host.value = value ?? '');
      return null;
    }, const []);

    double width = (MediaQuery.sizeOf(context).width - 81) / 3;
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "设置",
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10, top: 8, bottom: 8),
            child: OutlinedButton(
              onPressed: () {
                Navigator.of(context)
                    .push(
                      CupertinoPageRoute(
                        builder: (context) {
                          return const HelperSetting();
                        },
                        settings: const RouteSettings(name: "helper_setting"),
                      ),
                    )
                    .then((_) {});
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
        padding:
            const EdgeInsets.symmetric(horizontal: AppConstants.paddingLarge),
        children: [
          const SizedBox(
            height: 30,
          ),
          GestureDetector(
            onTap: () {
              Navigator.of(context)
                  .push(CupertinoPageRoute(
                      builder: (context) {
                        return const UserSetting();
                      },
                      settings: const RouteSettings(name: "user_setting")))
                  .then((res) {
                if (res != null && res) {
                  getNormalUser();
                }
              });
            },
            child: Card(
              shape: RoundedRectangleBorder(
                  side: const BorderSide(),
                  borderRadius: BorderRadius.circular(18)),
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.paddingLarge),
                child: Row(
                  children: [
                    const CircleAvatar(
                      backgroundImage: AssetImage("assets/logo.png"),
                      radius: 30,
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            account.value,
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(
                            height: 5,
                          ),
                          Text(
                            host.value,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.grey),
                          )
                        ],
                      ),
                    ),
                    OutlinedButton(
                      onPressed: () {
                        showCupertinoModalPopup(
                          context: context,
                          builder: (context) {
                            return ConfirmLogout(otpEnable.value);
                          },
                        );
                      },
                      // margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      child: Image.asset(
                        "assets/icons/exit.png",
                        width: 16,
                      ),
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                    OutlinedButton(
                      onPressed: () {
                        Navigator.of(context)
                            .push(CupertinoPageRoute(builder: (context) {
                          return const Accounts();
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
          const SizedBox(
            height: 30,
          ),
          Wrap(
            spacing: 20,
            runSpacing: 20,
            children: [
              SettingButton(name: "主题", icon: "theme", onPressed: onTheme),
              SettingButton(
                name: "终端",
                icon: "ssh",
                onPressed: () {
                  Navigator.of(context).push(
                    CupertinoPageRoute(
                        builder: (context) {
                          return const SelectServer();
                        },
                        settings: const RouteSettings(name: "select_server")),
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
                          return const Backup();
                        },
                        settings: const RouteSettings(name: "backup")),
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
