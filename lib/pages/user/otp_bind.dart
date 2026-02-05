import 'dart:convert';
import 'package:garden/util/ui_util.dart';
import 'package:garden/stores/connection_store.dart';

import 'package:garden/util/http_util.dart';
import 'package:garden/widgets/neu_back_button.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:garden/constants/app_constants.dart';
import 'package:garden/theme/app_colors.dart';
import 'package:flutter/services.dart';

class OtpBind extends StatefulWidget {
  final String username;
  final String email;
  const OtpBind(this.username, this.email, {super.key});
  @override
  OtpBindState createState() => OtpBindState();
}

class OtpBindState extends State<OtpBind> {
  final TextEditingController _emailController = TextEditingController();
  String email = '';
  int step = 0;
  Uint8List qrData = Uint8List(0);
  String key = "";
  String code = "";
  bool emailSaving = false;
  bool codeChecking = false;
  @override
  void initState() {
    setState(() {
      email = widget.email;
    });
    _emailController.value = TextEditingValue(text: email);
    super.initState();
  }

  getData() async {}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: AppBackButton(context),
        title: const Text("二步验证"),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (step == 0) ...[
            const Text("请输入电子邮件地址。如果您的移动设备遗失，可将紧急验证代码发送到在此提供的电子邮件地址。"),
            const SizedBox(
              height: 20,
            ),
            Card(
              shape: RoundedRectangleBorder(
                  side: const BorderSide(),
                  borderRadius: BorderRadius.circular(18)),
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.paddingSmall),
                child: TextField(
                  controller: _emailController,
                  onChanged: (v) => email = v,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    labelText: '电子邮件',
                  ),
                ),
              ),
            ),
            const SizedBox(
              height: 20,
            ),
            OutlinedButton(
              onPressed: () async {
                if (email.isBlank) {
                  UiUtil.toast("请输入邮箱");
                  return;
                }
                if (emailSaving) {
                  return;
                }
                setState(() {
                  emailSaving = true;
                });
                var res = await Api.saveMail(email);

                if (res['success']) {
                  var qrcode = await Api.getQrCode(
                      "${widget.username}@${connectionStore.hostname}");
                  if (qrcode['success']) {
                    setState(() {
                      qrData =
                          const Base64Decoder().convert(qrcode['data']['img']);
                      key = qrcode['data']['key'];
                      step = 1;
                    });
                  } else {
                    UiUtil.toast("获取二部验证数据出错，代码${res['error']['code']}");
                  }
                } else {
                  UiUtil.toast("保存邮箱出错，代码${res['error']['code']}");
                }
                setState(() {
                  emailSaving = false;
                });
              },
              child: emailSaving
                  ? const CupertinoActivityIndicator(
                      radius: 13,
                    )
                  : const Text(
                      ' 下一步 ',
                      style: TextStyle(fontSize: 18),
                    ),
            ),
          ] else if (step == 1) ...[
            const Text(
                "DSM 支持以下验证器应用程序： Google Authenticator, Authy等，打开验证器，扫描以下二维码，或者手动输入秘钥"),
            const SizedBox(
              height: 20,
            ),
            Center(
              child: Image.memory(qrData),
            ),
            const SizedBox(
              height: 20,
            ),
            Card(
              shape: RoundedRectangleBorder(
                  side: const BorderSide(),
                  borderRadius: BorderRadius.circular(18)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        "账号：${widget.username}@${connectionStore.hostname}",
                      ),
                    ),
                    OutlinedButton(
                      onPressed: () async {
                        ClipboardData data = ClipboardData(
                            text:
                                "${widget.username}@${connectionStore.hostname}");
                        Clipboard.setData(data);
                        UiUtil.toast("已复制到剪贴板");
                      },
                      child: const SizedBox(
                        width: 20,
                        height: 20,
                        child: Icon(
                          Icons.copy,
                          color: AppColors.primaryAction,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(
              height: 20,
            ),
            Card(
              shape: RoundedRectangleBorder(
                  side: const BorderSide(),
                  borderRadius: BorderRadius.circular(18)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        "秘钥：$key",
                      ),
                    ),
                    OutlinedButton(
                      onPressed: () async {
                        ClipboardData data = ClipboardData(text: key);
                        Clipboard.setData(data);
                        UiUtil.toast("已复制到剪贴板");
                      },
                      child: const SizedBox(
                        width: 20,
                        height: 20,
                        child: Icon(
                          Icons.copy,
                          color: AppColors.primaryAction,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(
              height: 20,
            ),
            Card(
              shape: RoundedRectangleBorder(
                  side: const BorderSide(),
                  borderRadius: BorderRadius.circular(18)),
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.paddingSmall),
                child: TextField(
                  onChanged: (v) => code = v,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    labelText: '6位验证代码',
                  ),
                ),
              ),
            ),
            const SizedBox(
              height: 20,
            ),
            OutlinedButton(
              onPressed: () async {
                if (code.isBlank) {
                  UiUtil.toast("请输入6位验证代码");
                  return;
                }
                if (codeChecking) {
                  return;
                }
                setState(() {
                  codeChecking = true;
                });
                var res = await Api.authOtpCode(code);

                if (res['success']) {
                  setState(() {
                    step = 2;
                  });
                } else {
                  UiUtil.toast("保存邮箱出错，代码${res['error']['code']}");
                }
                setState(() {
                  emailSaving = false;
                });
              },
              child: codeChecking
                  ? const CupertinoActivityIndicator(
                      radius: 13,
                    )
                  : const Text(
                      ' 下一步 ',
                      style: TextStyle(fontSize: 18),
                    ),
            ),
          ] else if (step == 2) ...[
            const Text(
                "两步骤验证设置完成。下次登录 DSM 时，将提示您输入验证器应用程序生成的验证代码。两步骤验证对于用某些移动应用程序进行登录有影响。为避免遇到任何难题，请确认您已安装任何需要登录 DSM 的移动应用程序的最新版本。"),
            const Text("注意：您可在“帐户活动” &gt; “记住的设备”中管理最常用的设备。"),
            OutlinedButton(
              onPressed: () async {
                Navigator.of(context).pop(true);
              },
              child: const Text(
                ' 完成 ',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ]
        ],
      ),
    );
  }
}
