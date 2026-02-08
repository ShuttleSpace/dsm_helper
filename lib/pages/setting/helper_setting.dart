import 'dart:io';

import 'package:cool_ui/cool_ui.dart';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';
import 'package:garden/constants/app_constants.dart';
import 'package:garden/pages/common/gesture_password.dart';
import 'package:garden/pages/setting/player_setting.dart';
import 'package:garden/stores/settings_store.dart';
import 'package:garden/theme/app_colors.dart';
import 'package:garden/util/storage_util.dart';
import 'package:garden/util/ui_util.dart';
import 'package:garden/widgets/neu_back_button.dart';
import 'package:garden/widgets/neu_picker.dart';
import 'package:local_auth/error_codes.dart' as auth_error;
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:local_auth_darwin/local_auth_darwin.dart';

class HelperSetting extends StatefulWidget {
  const HelperSetting({super.key});

  @override
  HelperSettingState createState() => HelperSettingState();
}

class HelperSettingState extends State<HelperSetting> {
  final LocalAuthentication auth = LocalAuthentication();
  bool launchAuth = false;
  bool password = false;
  bool biometrics = false;
  bool canCheckBiometrics = false;
  bool videoPlayer = false;
  bool launchAccountPage = false;
  BiometricType biometricsType = BiometricType.fingerprint;

  Map<BiometricType, String> biometricTypeName = {
    BiometricType.face: "FaceId",
    BiometricType.fingerprint: "指纹",
    BiometricType.iris: "人脸",
  };
  @override
  void initState() {
    initAuth();
    super.initState();
  }

  initAuth() async {
    launchAuth = await StorageUtil.getBool("launch_auth") ?? false;
    password = await StorageUtil.getBool("launch_auth_password") ?? false;
    biometrics = await StorageUtil.getBool("launch_auth_biometrics") ?? false;
    videoPlayer = await StorageUtil.getBool("use_embeed_video_player") ?? false;
    launchAccountPage =
        await StorageUtil.getBool('launch_account_page') ?? false;
    canCheckBiometrics = await auth.canCheckBiometrics;
    setState(() {});
    if (canCheckBiometrics) {
      List<BiometricType> availableBiometrics =
          await auth.getAvailableBiometrics();
      if (Platform.isIOS) {
        setState(() {
          if (availableBiometrics.contains(BiometricType.face)) {
            biometricsType = BiometricType.face;
          } else if (availableBiometrics.contains(BiometricType.fingerprint)) {
            biometricsType = BiometricType.fingerprint;
          } else if (availableBiometrics.contains(BiometricType.iris)) {
            biometricsType = BiometricType.iris;
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: AppBackButton(context),
        title: const Text("Garden设置"),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          GestureDetector(
            onTap: () {
              setState(() {
                settingsStore
                    .setVibrateOn(!settingsStore.vibrateOn.watch(context));
                StorageUtil.setBool(
                    "vibrate_on", settingsStore.vibrateOn.watch(context));
                if (settingsStore.vibrateOn.watch(context)) {
                  UiUtil.vibrate(FeedbackType.light);
                }
              });
            },
            child: Card(
              shape: RoundedRectangleBorder(
                  side: const BorderSide(),
                  borderRadius: BorderRadius.circular(18)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Image.asset(
                          "assets/icons/vibrate.png",
                          width: 30,
                        ),
                        const SizedBox(
                          width: 8,
                        ),
                        const Text(
                          "震动",
                          style: TextStyle(fontSize: 16),
                        ),
                        const Spacer(),
                        if (settingsStore.vibrateOn.watch(context))
                          Icon(
                            CupertinoIcons.checkmark_alt,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                      ],
                    ),
                    if (settingsStore.vibrateOn.watch(context))
                      Card(
                        shape: RoundedRectangleBorder(
                            side: const BorderSide(),
                            borderRadius: BorderRadius.circular(18)),
                        margin: const EdgeInsets.only(top: 20),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    settingsStore.setVibrateNormal(
                                        !settingsStore.vibrateNormal
                                            .watch(context));
                                    StorageUtil.setBool(
                                        "vibrate_warning",
                                        settingsStore.vibrateNormal
                                            .watch(context));
                                    if (settingsStore.vibrateNormal
                                        .watch(context)) {
                                      UiUtil.vibrate(FeedbackType.light);
                                    }
                                  });
                                },
                                child: Card(
                                  shape: RoundedRectangleBorder(
                                      side: const BorderSide(),
                                      borderRadius: BorderRadius.circular(18)),
                                  // margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                  child: Padding(
                                    padding: const EdgeInsets.all(
                                        AppConstants.paddingSmall),
                                    child: Row(
                                      children: [
                                        const Text(
                                          "基础操作震动",
                                          style: TextStyle(
                                              fontSize: 16, height: 1.6),
                                        ),
                                        const Spacer(),
                                        if (settingsStore.vibrateNormal
                                            .watch(context))
                                          Icon(
                                            CupertinoIcons.checkmark_alt,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary,
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(
                                height: 20,
                              ),
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    settingsStore.setVibrateWarning(
                                        !settingsStore.vibrateWarning
                                            .watch(context));
                                    StorageUtil.setBool(
                                        "vibrate_warning",
                                        settingsStore.vibrateWarning
                                            .watch(context));
                                    if (settingsStore.vibrateWarning
                                        .watch(context)) {
                                      UiUtil.vibrate(FeedbackType.warning);
                                    }
                                  });
                                },
                                child: Card(
                                  shape: RoundedRectangleBorder(
                                      side: const BorderSide(),
                                      borderRadius: BorderRadius.circular(18)),
                                  // margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                  child: Padding(
                                    padding: const EdgeInsets.all(
                                        AppConstants.paddingSmall),
                                    child: Row(
                                      children: [
                                        const Text(
                                          "敏感操作震动",
                                          style: TextStyle(
                                              fontSize: 16, height: 1.6),
                                        ),
                                        const Spacer(),
                                        if (settingsStore.vibrateWarning
                                            .watch(context))
                                          Icon(
                                            CupertinoIcons.checkmark_alt,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary,
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(
            height: 20,
          ),
          GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) {
                    return const PlayerSettingPage();
                  },
                  settings: const RouteSettings(name: "player_setting"),
                ),
              );
              setState(() {
                videoPlayer = !videoPlayer;
                StorageUtil.setBool("use_embeed_video_player", videoPlayer);
              });
            },
            child: Card(
              shape: RoundedRectangleBorder(
                  side: const BorderSide(),
                  borderRadius: BorderRadius.circular(18)),
              // margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.paddingSmall),
                child: Row(
                  children: [
                    Image.asset(
                      "assets/icons/player.png",
                      width: 25,
                    ),
                    const SizedBox(
                      width: 8,
                    ),
                    const Text(
                      "播放器设置",
                      style: TextStyle(fontSize: 16, height: 1.6),
                    ),
                    const Spacer(),
                    if (videoPlayer)
                      Icon(
                        CupertinoIcons.checkmark_alt,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(
            height: 20,
          ),
          Watch((context) {
            return GestureDetector(
              onTap: () {
                showCupertinoModalPopup(
                  context: context,
                  builder: (context) {
                    return Padding(
                      padding: EdgeInsets.only(
                          top: MediaQuery.viewPaddingOf(context).top),
                      child: NeuPicker(
                        List.generate(20, (index) => "${index + 1}"),
                        value: List.generate(20, (index) => index + 1).indexOf(
                            settingsStore.refreshDuration.watch(context)),
                        onConfirm: (v) {
                          settingsStore.setRefreshDuration(v + 1);
                        },
                      ),
                    );
                  },
                );
              },
              child: Card(
                shape: RoundedRectangleBorder(
                    side: const BorderSide(),
                    borderRadius: BorderRadius.circular(18)),
                // margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.paddingSmall),
                  child: Row(
                    children: [
                      Image.asset(
                        "assets/icons/player.png",
                        width: 25,
                      ),
                      const SizedBox(
                        width: 8,
                      ),
                      const Text(
                        "控制台/资源监控更新频率",
                        style: TextStyle(fontSize: 16, height: 1.6),
                      ),
                      const Spacer(),
                      Text("${settingsStore.refreshDuration}秒")
                    ],
                  ),
                ),
              ),
            );
          }),
          const SizedBox(
            height: 20,
          ),
          GestureDetector(
            onTap: () {
              setState(() {
                launchAccountPage = !launchAccountPage;
                StorageUtil.setBool("launch_account_page", launchAccountPage);
              });
            },
            child: Card(
              shape: RoundedRectangleBorder(
                  side: const BorderSide(),
                  borderRadius: BorderRadius.circular(18)),
              // margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.paddingSmall),
                child: Row(
                  children: [
                    Image.asset(
                      "assets/icons/change.png",
                      width: 25,
                    ),
                    const SizedBox(
                      width: 8,
                    ),
                    const Text(
                      "启动时默认进入选择账号页面",
                      style: TextStyle(fontSize: 16, height: 1.6),
                    ),
                    const Spacer(),
                    if (launchAccountPage)
                      Icon(
                        CupertinoIcons.checkmark_alt,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(
            height: 20,
          ),
          GestureDetector(
            onTap: () {
              setState(() {
                launchAuth = !launchAuth;
                StorageUtil.setBool("launch_auth", launchAuth);
              });
            },
            child: Card(
              shape: RoundedRectangleBorder(
                  side: const BorderSide(),
                  borderRadius: BorderRadius.circular(18)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Image.asset(
                          "assets/icons/safe.png",
                          width: 30,
                        ),
                        const SizedBox(
                          width: 8,
                        ),
                        const Text(
                          "启动密码",
                          style: TextStyle(fontSize: 16),
                        ),
                        const Spacer(),
                        if (launchAuth)
                          Icon(
                            CupertinoIcons.checkmark_alt,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                      ],
                    ),
                    if (launchAuth)
                      Card(
                        shape: RoundedRectangleBorder(
                            side: const BorderSide(),
                            borderRadius: BorderRadius.circular(18)),
                        margin: const EdgeInsets.only(top: 20),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    if (password) {
                                      setState(() {
                                        password = false;
                                        StorageUtil.setBool(
                                            "launch_auth_password", false);
                                        biometrics = false;
                                        StorageUtil.setBool(
                                            "launch_auth_biometrics", false);
                                      });
                                    } else {
                                      Navigator.of(context).push(
                                          CupertinoPageRoute(
                                              builder: (context) {
                                        return const GesturePasswordPage();
                                      })).then((res) {
                                        if (res != null && res) {
                                          setState(() {
                                            password = true;
                                            StorageUtil.setBool(
                                                "launch_auth_password",
                                                password);
                                          });
                                        }
                                      });
                                    }
                                    // password = !password;
                                    // HttpUtil.setStorage("launch_password", password ? "1" : "0");
                                  });
                                },
                                child: Card(
                                  shape: RoundedRectangleBorder(
                                      side: const BorderSide(),
                                      borderRadius: BorderRadius.circular(18)),
                                  // margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                  child: Padding(
                                    padding: const EdgeInsets.all(
                                        AppConstants.paddingSmall),
                                    child: Column(
                                      children: [
                                        Row(
                                          children: [
                                            const Text(
                                              "图形密码",
                                              style: TextStyle(
                                                  fontSize: 16, height: 1.6),
                                            ),
                                            const Spacer(),
                                            if (password)
                                              Icon(
                                                CupertinoIcons.checkmark_alt,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .primary,
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              if (canCheckBiometrics) ...[
                                const SizedBox(
                                  height: 20,
                                ),
                                GestureDetector(
                                  onTap: () async {
                                    if (biometrics == false) {
                                      if (password == false) {
                                        UiUtil.vibrate(FeedbackType.warning);
                                        UiUtil.toast("请先开启图形密码后再开启指纹");
                                        return;
                                      }
                                      try {
                                        bool didAuthenticate =
                                            await auth.authenticate(
                                          options: const AuthenticationOptions(
                                            biometricOnly: true,
                                            sensitiveTransaction: false,
                                          ),
                                          authMessages: [
                                            IOSAuthMessages(
                                              lockOut: "认证失败次数过多，请稍后再试",
                                              goToSettingsButton: "设置",
                                              goToSettingsDescription:
                                                  "系统未设置${biometricTypeName[biometricsType]}，点击设置按钮前往系统设置页面",
                                              cancelButton: "取消",
                                            ),
                                            const AndroidAuthMessages(
                                              biometricNotRecognized: "系统未设置指纹",
                                              biometricRequiredTitle:
                                                  "请触摸指纹传感器",
                                              signInTitle: "验证指纹",
                                              cancelButton: "取消",
                                              biometricHint:
                                                  "如果验证失败5次请等待30秒后重试",
                                              goToSettingsButton: "设置",
                                              goToSettingsDescription:
                                                  "点击设置按钮前往系统指纹设置页面",
                                              biometricSuccess: "指纹验证成功",
                                            )
                                          ],
                                          localizedReason: '请触摸指纹传感器',
                                        );
                                        auth.stopAuthentication();
                                        setState(() {
                                          biometrics = didAuthenticate;
                                          StorageUtil.setBool(
                                              "launch_auth_biometrics",
                                              biometrics);
                                        });
                                      } on PlatformException catch (e) {
                                        if (e.code == auth_error.notAvailable) {
                                          UiUtil.toast("生物验证不可用");
                                        } else if (e.code ==
                                            auth_error.passcodeNotSet) {
                                          UiUtil.toast("系统未设置密码");
                                        } else if (e.code ==
                                            auth_error.lockedOut) {
                                          UiUtil.toast("认证失败次数过多，请稍后再试");
                                        } else {
                                          UiUtil.toast(e.message ?? '');
                                        }
                                      }
                                    } else {
                                      setState(() {
                                        biometrics = false;
                                        StorageUtil.setBool(
                                            "launch_auth_biometrics",
                                            biometrics);
                                      });
                                    }

                                    // setState(() {
                                    //   biometrics = !biometrics;
                                    //   HttpUtil.setStorage("launch_biometrics", biometrics ? "1" : "0");
                                    // });
                                  },
                                  child: Card(
                                    shape: RoundedRectangleBorder(
                                        side: const BorderSide(),
                                        borderRadius:
                                            BorderRadius.circular(18)),
                                    // margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                    child: Padding(
                                      padding: const EdgeInsets.all(
                                          AppConstants.paddingSmall),
                                      child: Column(
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                "${biometricTypeName[biometricsType]}验证",
                                                style: const TextStyle(
                                                    fontSize: 16, height: 1.6),
                                              ),
                                              const Spacer(),
                                              if (biometrics)
                                                const Icon(
                                                  CupertinoIcons.checkmark_alt,
                                                  color:
                                                      AppColors.primaryAction,
                                                ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(
            height: 20,
          ),
          OutlinedButton(
            onPressed: () {
              var hide = showWeuiLoadingToast(context: context);
              clearDiskCachedImages();
              hide();
              UiUtil.toast("图片缓存清理完成");
            },
            // margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: [
                Image.asset(
                  "assets/icons/clear_cache.png",
                  width: 25,
                ),
                const SizedBox(
                  width: 8,
                ),
                const Text(
                  "清理图片缓存",
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
          const SizedBox(
            height: 20,
          ),
          OutlinedButton(
            onPressed: () {
              setState(() {
                settingsStore.setDashboardCardCollapseSwitch(
                    !settingsStore.dashboardCardCollapseSwitch.watch(context));
              });
            },
            // margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: [
                const Icon(Icons.unfold_less_sharp),
                const SizedBox(
                  width: 8,
                ),
                const Text(
                  "仪表盘卡片默认折叠",
                  style: TextStyle(fontSize: 16),
                ),
                const Spacer(),
                if (settingsStore.dashboardCardCollapseSwitch.watch(context))
                  Icon(
                    CupertinoIcons.checkmark_alt,
                    color: Theme.of(context).colorScheme.primary,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
