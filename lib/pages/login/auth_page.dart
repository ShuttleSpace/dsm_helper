import 'dart:io';
import 'package:garden/util/ui_util.dart';
import 'package:garden/util/storage_util.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';
import 'package:gesture_password_widget/widget/gesture_password_widget.dart';
import 'package:local_auth/error_codes.dart' as auth_error;
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';
import 'package:local_auth_darwin/local_auth_darwin.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:signals_hooks/signals_hooks.dart';

class AuthPage extends HookWidget {
  final bool launch;
  final bool launchAccountPage;
  const AuthPage(
      {super.key, this.launch = true, this.launchAccountPage = false});

  static const Map<BiometricType, String> biometricTypeName = {
    BiometricType.face: "FaceId",
    BiometricType.fingerprint: "指纹",
    BiometricType.iris: "人脸",
  };

  @override
  Widget build(BuildContext context) {
    final auth = useMemoized(() => LocalAuthentication(), const []);
    final biometricsType =
        useSignal<BiometricType>(BiometricType.fingerprint);
    final errorCount = useSignal(0);
    final password = useSignal("");

    useEffect(() {
      () async {
        password.value =
            await StorageUtil.getString("gesture_password") ?? '';

        bool launchAuthBiometric =
            await StorageUtil.getBool("launch_auth_biometrics") ?? false;

        if (launchAuthBiometric) {
          final canCheckBiometrics = await auth.canCheckBiometrics;
          if (canCheckBiometrics) {
            List<BiometricType> availableBiometrics =
                await auth.getAvailableBiometrics();
            if (Platform.isIOS) {
              if (availableBiometrics.contains(BiometricType.face)) {
                biometricsType.value = BiometricType.face;
              } else if (availableBiometrics
                  .contains(BiometricType.fingerprint)) {
                biometricsType.value = BiometricType.fingerprint;
              } else if (availableBiometrics.contains(BiometricType.iris)) {
                biometricsType.value = BiometricType.iris;
              }
            }
          }
          if (Platform.isIOS) {
            await Future.delayed(const Duration(milliseconds: 300));
          }
          try {
            bool didAuthenticate = await auth.authenticate(
              options: const AuthenticationOptions(
                biometricOnly: true,
                sensitiveTransaction: false,
              ),
              authMessages: [
                IOSAuthMessages(
                  lockOut: "认证失败次数过多，请稍后再试",
                  goToSettingsButton: "设置",
                  goToSettingsDescription:
                      "系统未设置${biometricTypeName[biometricsType.value]}，点击设置按钮前往系统设置页面",
                  cancelButton: "取消",
                ),
                const AndroidAuthMessages(
                  biometricNotRecognized: "系统未设置指纹",
                  biometricRequiredTitle: "请触摸指纹传感器",
                  signInTitle: "验证指纹",
                  cancelButton: "取消",
                  biometricHint: "如果验证失败5次请等待30秒后重试",
                  goToSettingsButton: "设置",
                  goToSettingsDescription: "点击设置按钮前往系统指纹设置页面",
                  biometricSuccess: "指纹验证成功",
                )
              ],
              localizedReason: '请触摸指纹传感器',
            );
            auth.stopAuthentication();
            if (didAuthenticate) {
              //验证成功
              UiUtil.vibrate(FeedbackType.light);
              if (launch) {
                if (context.mounted) {
                  // ignore: use_build_context_synchronously
                  Navigator.of(context).pushReplacementNamed("/login");
                }
              } else {
                if (context.mounted) {
                  // ignore: use_build_context_synchronously
                  Navigator.of(context).pop();
                }
              }
            } else {
              UiUtil.vibrate(FeedbackType.warning);
              UiUtil.toast(
                  "${biometricTypeName[biometricsType.value]}验证失败，请使用图形密码登录");
            }
          } on PlatformException catch (e) {
            UiUtil.vibrate(FeedbackType.warning);
            if (e.code == auth_error.notAvailable) {
              UiUtil.toast(
                  "${biometricTypeName[biometricsType.value]}验证不可用，请使用图形密码登录");
            } else if (e.code == auth_error.passcodeNotSet) {
              UiUtil.toast("系统未设置密码");
            } else if (e.code == auth_error.lockedOut) {
              UiUtil.toast("认证失败次数过多，请使用图形密码登录");
            } else {
              UiUtil.toast(e.message ?? '');
            }
          }
        }
      }();
      return null;
    }, const []);

    useEffect(() {
      return () {
        auth.stopAuthentication();
      };
    }, const []);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('安全验证'),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const SizedBox(
              height: 40,
            ),
            const Text(
              "请绘制解锁图案",
              style: TextStyle(fontSize: 26),
            ),
            const SizedBox(
              height: 80,
            ),
            Center(
              child: GesturePasswordWidget(
                onComplete: (s) {
                  if (s.join('') == password.value) {
                    //密码验证通过
                    if (launch) {
                      if (launchAccountPage) {
                        Navigator.of(context).pushReplacementNamed("/accounts");
                      } else {
                        Navigator.of(context).pushReplacementNamed("/login");
                      }
                    } else {
                      Navigator.of(context).pop();
                    }
                  } else {
                    //密码验证不通过
                    if (errorCount.value < 2) {
                      UiUtil.toast("密码错误");
                      UiUtil.vibrate(FeedbackType.warning);
                    } else if (errorCount.value < 5) {
                      errorCount.value++;
                      UiUtil.toast("密码错误，连续错误5次将清空登录历史");
                      UiUtil.vibrate(FeedbackType.warning);
                    } else {
                      UiUtil.toast("密码错误已达5次");
                      UiUtil.vibrate(FeedbackType.warning);
                      StorageUtil.removes([
                        "servers",
                        "https",
                        "host",
                        "port",
                        "account",
                        "remember_password",
                        "auto_login",
                        "check_ssl"
                      ]);
                      Navigator.of(context).pushReplacementNamed("/login");
                    }
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
