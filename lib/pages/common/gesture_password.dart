import 'package:garden/util/ui_util.dart';
import 'package:garden/util/storage_util.dart';
import 'package:garden/widgets/neu_back_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gesture_password_widget/gesture_password_widget.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';
import 'package:signals_hooks/signals_hooks.dart';

class GesturePasswordPage extends HookWidget {
  const GesturePasswordPage({super.key, this.title});

  final String? title;

  @override
  Widget build(BuildContext context) {
    final step = useSignal(1);
    final newPassword = useSignal("");

    return Scaffold(
      appBar: AppBar(
        leading: AppBackButton(context),
        title: Text(title ?? '设置密码'),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const SizedBox(
              height: 40,
            ),
            Text(
              step.value == 1 ? "请绘制图案" : "请再绘制一遍",
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
                  if (step.value == 1) {
                    UiUtil.vibrate(FeedbackType.light);
                    newPassword.value = s.join('');
                    step.value = 2;
                  } else if (step.value == 2) {
                    if (s.join('') == newPassword.value) {
                      UiUtil.vibrate(FeedbackType.success);
                      StorageUtil.setString("gesture_password", s.join(''));
                      Navigator.of(context).pop(true);
                    } else {
                      UiUtil.toast("两次图案不一致，请重新设置");
                      UiUtil.vibrate(FeedbackType.warning);
                      step.value = 1;
                      newPassword.value = "";
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
