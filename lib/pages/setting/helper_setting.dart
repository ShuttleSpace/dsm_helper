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
import 'package:garden/api/dsm_api.dart';
import 'package:garden/stores/connection_store.dart';
import 'package:garden/stores/settings_store.dart';
import 'package:garden/util/storage_util.dart';
import 'package:garden/util/ui_util.dart';
import 'package:garden/widgets/bottom_confirm_sheet.dart';
import 'package:garden/widgets/neu_back_button.dart';
import 'package:garden/widgets/neu_picker.dart';
import 'package:garden/widgets/status_checkbox.dart';
import 'package:local_auth/error_codes.dart' as auth_error;
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:signals_hooks/signals_hooks.dart';
import 'package:local_auth_darwin/local_auth_darwin.dart';

class HelperSetting extends HookWidget {
  const HelperSetting({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = useMemoized(() => LocalAuthentication(), const []);
    final launchAuth = useSignal(false);
    final password = useSignal(false);
    final biometrics = useSignal(false);
    final canCheckBiometrics = useSignal(false);
    final videoPlayer = useSignal(false);
    final launchAccountPage = useSignal(false);
    final biometricsType = useSignal(BiometricType.fingerprint);
    final ssh = useSignal(false);
    final telnet = useSignal(false);
    final sshLoading = useSignal(true);
    final sshPort = useSignal('');
    final shutdowning = useSignal(false);
    final rebooting = useSignal(false);

    final Map<BiometricType, String> biometricTypeName = {
      BiometricType.face: "FaceId",
      BiometricType.fingerprint: "指纹",
      BiometricType.iris: "人脸",
    };

    getData() async {
      try {
        final data = await dsmCoreTerminalInfoForPage();
        ssh.value = data['enable_ssh'] ?? false;
        telnet.value = data['enable_telnet'] ?? false;
        sshPort.value = (data['ssh_port'] ?? '').toString();
      } catch (e) {
        ssh.value = false;
      } finally {
        sshLoading.value = false;
      }
    }

    power(String type, bool force) async {
      if (type == "shutdown") {
        shutdowning.value = true;
      } else {
        rebooting.value = true;
      }

      Map<String, dynamic>? errorData;
      try {
        await dsmCoreSystemPowerForPage(type, force);
        UiUtil.toast("已发送指令");
      } on DSMException catch (e) {
        errorData = e.rawError;
        if (e.code != 117) {
          UiUtil.toast("操作失败，代码：${e.code}");
        }
      } catch (_) {}

      if (type == "shutdown") {
        shutdowning.value = false;
      } else {
        rebooting.value = false;
      }

      if (errorData != null && errorData['code'] == 117) {
        final rawErrors = errorData['errors'];
        final errors = rawErrors is Map
            ? (rawErrors['runningTasks'] as List? ?? [])
            : <dynamic>[];
        final msgs = <String>[];
        for (final error in errors) {
          final titles = error.toString().split(":");
          if (titles.length == 3) {
            msgs.add(
                connectionStore.strings.value[titles[0]][titles[1]][titles[2]]);
          }
        }
        if (context.mounted) {
          showCupertinoModalPopup(
            context: context,
            builder: (context) => BottomConfirmSheet(
              title: "系统正在处理下列任务。现在关机可能会导致套件异常或数据丢失。是否确定要继续？",
              content: msgs.join("\n"),
              confirmText: "强制${type == "shutdown" ? "关机" : "重启"}",
              padding: 20,
              buttonSpacing: 16,
              showTrailingSpace: true,
              onConfirm: () => power(type, true),
            ),
          );
        }
      }
    }

    void showPowerConfirm(String type) {
      final isShutdown = type == "shutdown";
      showCupertinoModalPopup(
        context: context,
        builder: (context) => BottomConfirmSheet(
          title: isShutdown ? "确认关机" : "确认重启",
          content: isShutdown ? "确认要关闭设备吗？" : "确认要重新启动设备？",
          confirmText: isShutdown ? "确认关机" : "确认重启",
          padding: 20,
          buttonSpacing: 16,
          showTrailingSpace: true,
          onConfirm: () => power(type, false),
        ),
      );
    }

    initAuth() async {
      launchAuth.value = await StorageUtil.getBool("launch_auth") ?? false;
      password.value =
          await StorageUtil.getBool("launch_auth_password") ?? false;
      biometrics.value =
          await StorageUtil.getBool("launch_auth_biometrics") ?? false;
      videoPlayer.value =
          await StorageUtil.getBool("use_embeed_video_player") ?? false;
      launchAccountPage.value =
          await StorageUtil.getBool('launch_account_page') ?? false;
      canCheckBiometrics.value = await auth.canCheckBiometrics;

      if (canCheckBiometrics.value) {
        List<BiometricType> availableBiometrics =
            await auth.getAvailableBiometrics();
        if (Platform.isIOS) {
          if (availableBiometrics.contains(BiometricType.face)) {
            biometricsType.value = BiometricType.face;
          } else if (availableBiometrics.contains(BiometricType.fingerprint)) {
            biometricsType.value = BiometricType.fingerprint;
          } else if (availableBiometrics.contains(BiometricType.iris)) {
            biometricsType.value = BiometricType.iris;
          }
        }
      }
    }

    useEffect(() {
      initAuth();
      getData();
      return null;
    }, const []);

    return Scaffold(
      appBar: AppBar(
        leading: AppBackButton(context),
        title: const Text("Garden设置"),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            shape: RoundedRectangleBorder(
                side: const BorderSide(),
                borderRadius: BorderRadius.circular(18)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  const Text("关机", style: TextStyle(fontSize: 16)),
                  const Spacer(),
                  OutlinedButton(
                    onPressed: () => showPowerConfirm("shutdown"),
                    child: shutdowning.value
                        ? const CupertinoActivityIndicator(radius: 10)
                        : const Text("关机",
                            style: TextStyle(color: Colors.redAccent)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Card(
            shape: RoundedRectangleBorder(
                side: const BorderSide(),
                borderRadius: BorderRadius.circular(18)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  const Text("重启", style: TextStyle(fontSize: 16)),
                  const Spacer(),
                  OutlinedButton(
                    onPressed: () => showPowerConfirm("reboot"),
                    child: rebooting.value
                        ? const CupertinoActivityIndicator(radius: 10)
                        : const Text("重启",
                            style: TextStyle(color: Colors.redAccent)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Card(
            shape: RoundedRectangleBorder(
                side: const BorderSide(),
                borderRadius: BorderRadius.circular(18)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  const Text("SSH", style: TextStyle(fontSize: 16)),
                  const Spacer(),
                  sshLoading.value
                      ? const CupertinoActivityIndicator(radius: 12)
                      : CupertinoSwitch(
                          value: ssh.value,
                          onChanged: (v) async {
                            sshLoading.value = true;
                            try {
                              await dsmCoreTerminalSetForPage(
                                  v, telnet.value, sshPort.value);
                            } catch (e) {
                              final code = e is DSMException ? e.code : -1;
                              UiUtil.toast("操作失败，代码：$code");
                            }
                            await getData();
                          },
                        ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () {
              settingsStore
                  .setVibrateOn(!settingsStore.vibrateOn.watch(context));
              StorageUtil.setBool(
                  "vibrate_on", settingsStore.vibrateOn.watch(context));
              if (settingsStore.vibrateOn.watch(context)) {
                UiUtil.vibrate(FeedbackType.light);
              }
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
                        StatusCheckbox(
                          value: settingsStore.vibrateOn.watch(context),
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
                                  settingsStore.setVibrateNormal(!settingsStore
                                      .vibrateNormal
                                      .watch(context));
                                  StorageUtil.setBool(
                                      "vibrate_warning",
                                      settingsStore.vibrateNormal
                                          .watch(context));
                                  if (settingsStore.vibrateNormal
                                      .watch(context)) {
                                    UiUtil.vibrate(FeedbackType.light);
                                  }
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
                                        StatusCheckbox(
                                          value: settingsStore.vibrateNormal
                                              .watch(context),
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
                                  settingsStore.setVibrateWarning(!settingsStore
                                      .vibrateWarning
                                      .watch(context));
                                  StorageUtil.setBool(
                                      "vibrate_warning",
                                      settingsStore.vibrateWarning
                                          .watch(context));
                                  if (settingsStore.vibrateWarning
                                      .watch(context)) {
                                    UiUtil.vibrate(FeedbackType.warning);
                                  }
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
                                        StatusCheckbox(
                                          value: settingsStore.vibrateWarning
                                              .watch(context),
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

              videoPlayer.value = !videoPlayer.value;
              StorageUtil.setBool("use_embeed_video_player", videoPlayer.value);
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
                    StatusCheckbox(
                      value: videoPlayer.value,
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
              launchAccountPage.value = !launchAccountPage.value;
              StorageUtil.setBool(
                  "launch_account_page", launchAccountPage.value);
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
                    StatusCheckbox(
                      value: launchAccountPage.value,
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
              launchAuth.value = !launchAuth.value;
              StorageUtil.setBool("launch_auth", launchAuth.value);
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
                        StatusCheckbox(
                          value: launchAuth.value,
                        ),
                      ],
                    ),
                    if (launchAuth.value)
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
                                  if (password.value) {
                                    password.value = false;
                                    StorageUtil.setBool(
                                        "launch_auth_password", false);
                                    biometrics.value = false;
                                    StorageUtil.setBool(
                                        "launch_auth_biometrics", false);
                                  } else {
                                    Navigator.of(context).push(
                                        CupertinoPageRoute(builder: (context) {
                                      return const GesturePasswordPage();
                                    })).then((res) {
                                      if (res != null && res) {
                                        password.value = true;
                                        StorageUtil.setBool(
                                            "launch_auth_password",
                                            password.value);
                                      }
                                    });
                                  }
                                  // password.value = !password.value;
                                  // HttpUtil.setStorage("launch_password", password.value ? "1" : "0");
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
                                            StatusCheckbox(
                                              value: password.value,
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              if (canCheckBiometrics.value) ...[
                                const SizedBox(
                                  height: 20,
                                ),
                                GestureDetector(
                                  onTap: () async {
                                    if (biometrics.value == false) {
                                      if (password.value == false) {
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
                                                  "系统未设置${biometricTypeName[biometricsType.value]}，点击设置按钮前往系统设置页面",
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

                                        biometrics.value = didAuthenticate;
                                        StorageUtil.setBool(
                                            "launch_auth_biometrics",
                                            biometrics.value);
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
                                      biometrics.value = false;
                                      StorageUtil.setBool(
                                          "launch_auth_biometrics",
                                          biometrics.value);
                                    }

                                    //
                                    //   biometrics.value = !biometrics.value;
                                    //   HttpUtil.setStorage("launch_biometrics", biometrics.value ? "1" : "0");
                                    //
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
                                                "${biometricTypeName[biometricsType.value]}验证",
                                                style: const TextStyle(
                                                    fontSize: 16, height: 1.6),
                                              ),
                                              const Spacer(),
                                              StatusCheckbox(
                                                value: biometrics.value,
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
          Card(
            shape: RoundedRectangleBorder(
                side: const BorderSide(),
                borderRadius: BorderRadius.circular(18)),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.paddingLarge,
                  vertical: AppConstants.paddingSmall),
              child: Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "下载角标",
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                        SizedBox(height: 4),
                        Text(
                          "在「下载」标签上显示进行中的下载数量",
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  CupertinoSwitch(
                    value: settingsStore.showDownloadBadge.watch(context),
                    onChanged: (v) => settingsStore.setShowDownloadBadge(v),
                  ),
                ],
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
              settingsStore.setDashboardCardCollapseSwitch(
                  !settingsStore.dashboardCardCollapseSwitch.watch(context));
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
                StatusCheckbox(
                  value:
                      settingsStore.dashboardCardCollapseSwitch.watch(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
