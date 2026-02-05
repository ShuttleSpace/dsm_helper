import 'package:garden/util/ui_util.dart';
import 'package:garden/util/storage_util.dart';
import 'package:garden/widgets/neu_back_button.dart';
import 'package:flutter/material.dart';
import 'package:gesture_password_widget/gesture_password_widget.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';

class GesturePasswordPage extends StatefulWidget {
  const GesturePasswordPage({super.key, this.title});

  final String? title;

  @override
  GesturePasswordPageState createState() => GesturePasswordPageState();
}

class GesturePasswordPageState extends State<GesturePasswordPage> {
  int step = 1;
  String newPassword = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: AppBackButton(context),
        title: Text(widget.title ?? '设置密码'),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const SizedBox(
              height: 40,
            ),
            Text(
              step == 1 ? "请绘制图案" : "请再绘制一遍",
              style: const TextStyle(fontSize: 26),
            ),
            const SizedBox(
              height: 80,
            ),
            Center(
              child: GesturePasswordWidget(
                lineColor: Colors.white,
                errorLineColor: Colors.redAccent,
                singleLineCount: 4,
                identifySize: 80.0,
                minLength: 4,
                onComplete: (s) {
                  if (step == 1) {
                    UiUtil.vibrate(FeedbackType.light);
                    setState(() {
                      newPassword = s.join('');
                      step = 2;
                    });
                  } else if (step == 2) {
                    if (s.join('') == newPassword) {
                      UiUtil.vibrate(FeedbackType.success);
                      StorageUtil.setString("gesture_password", s.join(''));
                      Navigator.of(context).pop(true);
                    } else {
                      UiUtil.toast("两次图案不一致，请重新设置");
                      UiUtil.vibrate(FeedbackType.warning);
                      setState(() {
                        step = 1;
                        newPassword = "";
                      });
                    }
                  }
                },
                // failCallback: () {
                //   HttpUtil.toast("至少连接4个点");
                //   HttpUtil.vibrate(FeedbackType.warning);
                //   miniGesturePassword.currentState?.setSelected('');
                // },
                // selectedCallback: (str) {
                //   miniGesturePassword.currentState?.setSelected(str);
                // },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
