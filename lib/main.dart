// ignore_for_file: unused_import

import 'dart:async';
import 'dart:io';

import 'package:cool_ui/cool_ui.dart';
import 'package:garden/pages/home.dart';
import 'package:garden/pages/login/accounts.dart';
import 'package:garden/pages/login/auth_page.dart';
import 'package:garden/pages/login/login.dart';
import 'package:garden/stores/app_store.dart';
import 'package:garden/stores/connection_store.dart';
import 'package:garden/stores/settings_store.dart';
import 'package:garden/theme/light_theme.dart';
import 'package:garden/theme/dark_theme.dart';
import 'package:garden/util/http_util.dart';
import 'package:garden/util/log.dart';
import 'package:garden/util/storage_util.dart';
import 'package:garden/widgets/keyboard_dismisser.dart';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:media_kit/media_kit.dart';
import 'package:oktoast/oktoast.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:signals_flutter/signals_flutter.dart';

void main() async {
  HttpClient client = ExtendedNetworkImageProvider.httpClient as HttpClient;
  client.badCertificateCallback =
      (X509Certificate cert, String host, int port) {
    return true;
  };

  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  Log.init();

  settingsStore.setDownloadSavePath(
      await StorageUtil.getString("download_save_path") ??
          "/storage/emulated/0/garden/Download");
  StorageUtil.getString("download_wifi_only").then((value) {
    settingsStore.setDownloadWifiOnly(value == "1");
  });
  //判断是否需要启动密码
  bool launchAuth = false;
  bool password = false;
  bool biometrics = false;
  bool launchAccountPage = false;
  String launchAuthStr = await StorageUtil.getString("launch_auth") ?? '';
  String launchAuthPasswordStr =
      await StorageUtil.getString("launch_auth_password") ?? '';
  String launchAuthBiometricsStr =
      await StorageUtil.getString("launch_auth_biometrics") ?? '';
  String launchAccountPageStr =
      await StorageUtil.getString('launch_account_page') ?? '';
  PackageInfo packageInfo = await PackageInfo.fromPlatform();
  connectionStore.setAppName(packageInfo.appName);
  launchAuth = launchAuthStr == "1";
  password = launchAuthPasswordStr == "1";
  biometrics = launchAuthBiometricsStr == "1";

  launchAccountPage = launchAccountPageStr == "1";

  bool authPage = launchAuth && (password || biometrics);

  //暗色模式
  String darkModeStr = await StorageUtil.getString("dark_mode") ?? '';
  if (int.tryParse(darkModeStr) != null) {
    appStore.changeMode(int.parse(darkModeStr));
  } else {
    Log.error("parse dark_mode failed: $darkModeStr");
  }

  //震动开关
  String vibrateOn = await StorageUtil.getString("vibrate_on") ?? '';
  String vibrateNormal = await StorageUtil.getString("vibrate_normal") ?? '';
  String vibrateWarning = await StorageUtil.getString("vibrate_warning") ?? '';
  String showShortcutsStr = await StorageUtil.getString("show_shortcut") ?? '';
  if (showShortcutsStr.isNotBlank) {}
  String showWallpaperStr = await StorageUtil.getString("show_wallpaper") ?? '';
  if (showWallpaperStr.isNotBlank) {}
  String refreshDurationStr =
      await StorageUtil.getString("refresh_duration") ?? '';
  if (refreshDurationStr.isNotBlank) {}
  if (vibrateOn.isNotBlank) {
    settingsStore.setVibrateOn(vibrateOn == "1");
  } else {
    settingsStore.setVibrateOn(true);
  }
  if (vibrateNormal.isNotBlank) {
    settingsStore.setVibrateNormal(vibrateNormal == "1");
  } else {
    settingsStore.setVibrateNormal(true);
  }
  if (vibrateWarning.isNotBlank) {
    settingsStore.setVibrateWarning(vibrateWarning == "1");
  } else {
    settingsStore.setVibrateWarning(true);
  }
  String checkSsl = await StorageUtil.getString("check_ssl") ?? '';
  if (checkSsl.isNotBlank) {
    connectionStore.setCheckSsl(checkSsl == "1");
  } else {
    connectionStore.setCheckSsl(true);
  }

  // 初始化 AppStore
  await appStore.initialize();

  runApp(MyApp(authPage, launchAccountPage));

  if (Platform.isAndroid) {
    // 以下两行 设置android状态栏为透明的沉浸。写在组件渲染之后，是为了在渲染后进行set赋值，覆盖状态栏，写在渲染之前MaterialApp组件会覆盖掉这个值。
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
    ));
  }
}

class MyApp extends StatefulWidget {
  final bool authPage;
  final bool launchAccountPage;
  const MyApp(this.authPage, this.launchAccountPage, {super.key});

  @override
  MyAppState createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Watch((context) {
      return OKToast(
        child: KeyboardDismisser(
          child: WeuiToastConfig(
            data: const WeuiToastConfigData(
              toastAlignment: Alignment.center,
              loadingText: "请稍后",
              loadingBackButtonClose: true,
            ),
            child: MaterialApp(
              title: connectionStore.appName,
              debugShowCheckedModeBanner: false,
              theme: appStore.darkMode == 2
                  ? lightTheme
                  : (appStore.darkMode == 0 ? lightTheme : darkTheme),
              darkTheme: appStore.darkMode == 2 ? darkTheme : null,
              localizationsDelegates: const [
                GlobalCupertinoLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
              ],
              supportedLocales: const [
                Locale('zh', 'CN'),
              ],
              home: widget.authPage
                  ? AuthPage(
                      launchAccountPage: widget.launchAccountPage,
                    )
                  : widget.launchAccountPage
                      ? const Accounts()
                      : const Login(),
              routes: {
                "/login": (BuildContext context) => const Login(),
                "/home": (BuildContext context) => const Home(),
                "/accounts": (BuildContext context) => const Accounts(),
              },
            ),
          ),
        ),
      );
    });
  }
}
