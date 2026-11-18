import 'package:flutter/cupertino.dart';
import 'package:garden/widgets/bottom_confirm_sheet.dart';
import 'package:garden/util/ui_util.dart';
import 'package:flutter/material.dart';
import 'package:garden/api/dsm_api.dart';
import 'package:garden/extensions/int.dart';
import 'package:garden/theme/app_colors.dart';

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
                  builder: (context) => BottomConfirmSheet(
                    title: "终止连接",
                    content: "确认要终止此连接？",
                    confirmText: "终止连接",
                    confirmColor: Colors.red,
                    textColor: Colors.black,
                    padding: 20,
                    buttonSpacing: 10,
                    onConfirm: () async {
                      user['running'] = true;
                      try {
                        await dsmCoreCurrentConnectionKickConnection(
                            {"who": user['who'], "from": user['from']});
                        UiUtil.toast("连接已终止");
                        onKickSuccess?.call();
                      } catch (e) {
                        // 旧层失败时静默，不提示。
                      } finally {
                        user['running'] = false;
                      }
                    },
                  ),
                );
              },
              child: SizedBox(
                width: 20,
                height: 20,
                child: user['running']
                    ? const CupertinoActivityIndicator()
                    : const Icon(
                        CupertinoIcons.clear,
                        color: AppColors.primaryAction,
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
