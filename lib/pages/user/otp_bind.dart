import 'dart:convert';
import 'package:garden/util/ui_util.dart';
import 'package:garden/stores/connection_store.dart';

import 'package:garden/api/dsm_api.dart';
import 'package:garden/extensions/string.dart';
import 'package:garden/widgets/neu_back_button.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:garden/constants/app_constants.dart';
import 'package:garden/theme/app_colors.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:signals_hooks/signals_hooks.dart';

String _errorCode(Object e) => e is DSMException ? '${e.code}' : '-1';

class OtpBind extends HookWidget {
  final String username;
  final String email;
  const OtpBind(this.username, this.email, {super.key});
  @override
  Widget build(BuildContext context) {
    final email = useSignal(this.email);
    final emailController = useTextEditingController(text: email.value);
    final step = useSignal(0);
    final qrData = useSignal<Uint8List>(Uint8List(0));
    final key = useSignal("");
    final code = useSignal("");
    final emailSaving = useSignal(false);
    final codeChecking = useSignal(false);
    return Scaffold(
      appBar: AppBar(
        leading: AppBackButton(context),
        title: const Text("二步验证"),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (step.value == 0) ...[
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
                  controller: emailController,
                  onChanged: (v) => email.value = v,
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
                if (email.value.isBlank) {
                  UiUtil.toast("请输入邮箱");
                  return;
                }
                if (emailSaving.value) {
                  return;
                }
                emailSaving.value = true;
                try {
                  await dsmCoreOTPSaveMail(mail: email.value);
                } catch (e) {
                  UiUtil.toast("保存邮箱出错，代码${_errorCode(e)}");
                  emailSaving.value = false;
                  return;
                }

                try {
                  final qrcode = await dsmCoreOTPGetQrcode(
                      account: "$username@${connectionStore.hostname}");
                  qrData.value =
                      const Base64Decoder().convert(qrcode['img'] as String);
                  key.value = qrcode['key'];
                  step.value = 1;
                } catch (e) {
                  UiUtil.toast("获取二部验证数据出错，代码${_errorCode(e)}");
                } finally {
                  emailSaving.value = false;
                }
              },
              child: emailSaving.value
                  ? const CupertinoActivityIndicator(
                      radius: 13,
                    )
                  : const Text(
                      ' 下一步 ',
                      style: TextStyle(fontSize: 18),
                    ),
            ),
          ] else if (step.value == 1) ...[
            const Text(
                "DSM 支持以下验证器应用程序： Google Authenticator, Authy等，打开验证器，扫描以下二维码，或者手动输入秘钥"),
            const SizedBox(
              height: 20,
            ),
            Center(
              child: Image.memory(qrData.value),
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
                        "账号：$username@${connectionStore.hostname}",
                      ),
                    ),
                    OutlinedButton(
                      onPressed: () async {
                        ClipboardData data = ClipboardData(
                            text: "$username@${connectionStore.hostname}");
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
                        "秘钥：$key.value",
                      ),
                    ),
                    OutlinedButton(
                      onPressed: () async {
                        ClipboardData data = ClipboardData(text: key.value);
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
                  onChanged: (v) => code.value = v,
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
                if (code.value.isBlank) {
                  UiUtil.toast("请输入6位验证代码");
                  return;
                }
                if (codeChecking.value) {
                  return;
                }
                codeChecking.value = true;
                try {
                  await dsmCoreOTPAuthTmpCode(code: code.value);
                  step.value = 2;
                } catch (e) {
                  UiUtil.toast("保存邮箱出错，代码${_errorCode(e)}");
                } finally {
                  emailSaving.value = false;
                }
              },
              child: codeChecking.value
                  ? const CupertinoActivityIndicator(
                      radius: 13,
                    )
                  : const Text(
                      ' 下一步 ',
                      style: TextStyle(fontSize: 18),
                    ),
            ),
          ] else if (step.value == 2) ...[
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
