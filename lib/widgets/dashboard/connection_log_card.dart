
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:garden/api/dsm_api.dart';
import 'package:garden/extensions/int.dart';
import 'package:garden/extensions/signal.dart';
import 'package:garden/theme/app_theme.dart';
import 'package:garden/util/ui_util.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:signals_hooks/signals_hooks.dart';
import 'package:garden/widgets/dashboard/dashboard_card_parts.dart';

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
                  const DashboardCardItemCollapse("ConnectionLog")
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
                              text: "\t\t点击重试", style: dashboardRetryTextStyle(context))
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
        return SizedBox(
          width: double.infinity,
          child: Material(
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
        ),
        );
      },
    );
  }
}

