import 'package:flutter/cupertino.dart';
import 'package:garden/util/ui_util.dart';
import 'package:flutter/material.dart';
import 'package:garden/util/http_util.dart';

/// Dashboard 登录用户列表项
class DashboardUserItem extends StatelessWidget {
  final Map user;
  final Function()? onKickSuccess;

  const DashboardUserItem({
    super.key,
    required this.user,
    this.onKickSuccess,
  });

  @override
  Widget build(BuildContext context) {
    user['running'] = user['running'] ?? false;
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
          children: [
            Expanded(
              child: Text(
                "${user['who']}",
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              child: Text(
                "${user['type']}",
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
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
                if (user['running']) {
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
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: () async {
                                          Navigator.of(context).pop();
                                          user['running'] = true;
                                          var res =
                                              await DsmApi.kickConnection({
                                            "who": user['who'],
                                            "from": user['from']
                                          });
                                          user['running'] = false;

                                          if (res['success']) {
                                            UiUtil.toast("连接已终止");
                                            onKickSuccess?.call();
                                          }
                                        },
                                        child: const Text(
                                          "终止连接",
                                          style: TextStyle(color: Colors.red),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(
                                      width: 10,
                                    ),
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                        },
                                        child: const Text("取消"),
                                      ),
                                    ),
                                  ],
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
              child: SizedBox(
                width: 20,
                height: 20,
                child: user['running']
                    ? const CupertinoActivityIndicator()
                    : Icon(
                        CupertinoIcons.clear,
                        color: Theme.of(context).colorScheme.primary,
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
