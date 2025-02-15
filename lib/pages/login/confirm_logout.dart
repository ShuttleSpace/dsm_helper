import 'package:humphrey_garden/util/function.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ConfirmLogout extends StatefulWidget {
  final bool otpEnable;
  ConfirmLogout(this.otpEnable);
  @override
  _ConfirmLogoutState createState() => _ConfirmLogoutState();
}

class _ConfirmLogoutState extends State<ConfirmLogout> {
  bool forget = false;
  @override
  Widget build(BuildContext context) {
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
                  "退出登录",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                ),
                SizedBox(
                  height: 12,
                ),
                Text(
                  "确认要退出登录当前账号吗？",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w400),
                ),
                SizedBox(
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
                          side: BorderSide(),
                          borderRadius: BorderRadius.circular(18)),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            Text("取消记住本设备"),
                            Spacer(),
                            if (forget)
                              Icon(
                                CupertinoIcons.checkmark_alt,
                                color: Color(0xffff9813),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
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
                          Util.instance.removeStorage("sid");
                          // Util.removeStorage("smid");
                          Navigator.of(context).pushNamedAndRemoveUntil(
                              "/login", (route) => false);
                        },
                        child: Text(
                          "退出登录",
                          style:
                              TextStyle(fontSize: 18, color: Colors.redAccent),
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
  }
}
