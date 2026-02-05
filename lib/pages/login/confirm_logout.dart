import 'package:garden/util/http_util.dart';
import 'package:garden/util/storage_util.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:garden/constants/app_constants.dart';
import 'package:garden/theme/app_colors.dart';

class ConfirmLogout extends StatefulWidget {
  final bool otpEnable;
  const ConfirmLogout(this.otpEnable, {super.key});
  @override
  ConfirmLogoutState createState() => ConfirmLogoutState();
}

class ConfirmLogoutState extends State<ConfirmLogout> {
  bool forget = false;
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Card(
        shape: RoundedRectangleBorder(
            side: const BorderSide(), borderRadius: BorderRadius.circular(18)),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Text(
                  "退出登录",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                ),
                const SizedBox(
                  height: 12,
                ),
                const Text(
                  "确认要退出登录当前账号吗？",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w400),
                ),
                const SizedBox(
                  height: 22,
                ),
                if (widget.otpEnable) ...[
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        forget = !forget;
                      });
                    },
                    child: Card(
                      shape: RoundedRectangleBorder(
                          side: const BorderSide(),
                          borderRadius: BorderRadius.circular(18)),
                      child: Padding(
                        padding:
                            const EdgeInsets.all(AppConstants.paddingSmall),
                        child: Row(
                          children: [
                            const Text("取消记住本设备"),
                            const Spacer(),
                            if (forget)
                              const Icon(
                                CupertinoIcons.checkmark_alt,
                                color: AppColors.primaryAction,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 22,
                  ),
                ],
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          if (forget) {
                            Api.trustDevice("delete");
                          }
                          StorageUtil.remove("sid");
                          // HttpUtil.removeStorage("smid");
                          Navigator.of(context).pushNamedAndRemoveUntil(
                              "/login", (route) => false);
                        },
                        child: const Text(
                          "退出登录",
                          style:
                              TextStyle(fontSize: 18, color: Colors.redAccent),
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
  }
}
