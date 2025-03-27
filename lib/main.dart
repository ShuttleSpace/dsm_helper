// ignore_for_file: unused_import

import 'dart:async';
import 'dart:io';

import 'package:cool_ui/cool_ui.dart';
import 'package:garden/pages/home.dart';
import 'package:garden/pages/login/accounts.dart';
import 'package:garden/pages/login/auth_page.dart';
import 'package:garden/pages/login/login.dart';
import 'package:garden/providers/audio_player_provider.dart';
import 'package:garden/providers/flux_provider.dart';
import 'package:garden/providers/setting.dart';
import 'package:garden/providers/shortcut.dart';
import 'package:garden/providers/wallpaper.dart';
import 'package:garden/themes/light.dart';
import 'package:garden/themes/dark.dart';
import 'package:garden/util/function.dart';
import 'package:garden/util/log.dart';
import 'package:garden/widgets/keyboard_dismisser.dart';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:fluwx/fluwx.dart';
import 'package:oktoast/oktoast.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import '/providers/dark_mode.dart';

void main() async {
  HttpClient client = ExtendedNetworkImageProvider.httpClient as HttpClient;
  client.badCertificateCallback =
      (X509Certificate cert, String host, int port) {
    return true;
  };

  WidgetsFlutterBinding.ensureInitialized();
  String agreement = await Util.instance.getStorage("agreement") ?? '';
  Fluwx fluwx = Fluwx();
  Log.init();
  if (agreement == "1") {
    fluwx
        .registerApi(
            appId: "wxabdf23571f34b49b",
            universalLink: "https://dsm.apaipai.top/app/")
        .then((value) {
      // stopLog();
    });
    Util.instance.appUrl = '';
    Util.instance.baseUrl = '';
    // 是否关闭广告
    // 判断是否登录
    bool isForever = true;
    DateTime noAdTime = DateTime.now();
    Util.instance.isWechatInstalled = await fluwx.isWeChatInstalled;
    String userToken = await Util.instance.getStorage("user_token") ?? '';
    String noAdTimeStr = await Util.instance.getStorage("no_ad_time") ?? '';
    if (noAdTimeStr.isNotBlank) {
      noAdTime = DateTime.parse(noAdTimeStr);
    }
    if (userToken.isNotBlank) {
      isForever = Util.instance.vipForever = true;
    }

    if (isForever || (noAdTime.isAfter(DateTime.now()))) {
      // 处于关闭广告有效期内
      if (kDebugMode) {
        debugPrint("免广告有效期内");
      }
    } else {
      Util.instance.removeStorage("no_ad_time");
    }
  }

  Util.instance.downloadSavePath =
      await Util.instance.getStorage("download_save_path") ??
          "/storage/emulated/0/garden/Download";
  Util.instance.getStorage("download_wifi_only").then((value) {
    Util.instance.downloadWifiOnly = value == "1";
  });
  //判断是否需要启动密码
  bool launchAuth = false;
  bool password = false;
  bool biometrics = false;
  bool showShortcuts = true;
  bool showWallpaper = true;
  int refreshDuration = 10;
  bool launchAccountPage = false;
  String launchAuthStr = await Util.instance.getStorage("launch_auth") ?? '';
  String launchAuthPasswordStr =
      await Util.instance.getStorage("launch_auth_password") ?? '';
  String launchAuthBiometricsStr =
      await Util.instance.getStorage("launch_auth_biometrics") ?? '';
  String launchAccountPageStr =
      await Util.instance.getStorage('launch_account_page') ?? '';
  PackageInfo packageInfo = await PackageInfo.fromPlatform();
  Util.instance.appName = packageInfo.appName;
  launchAuth = launchAuthStr == "1";
  password = launchAuthPasswordStr == "1";
  biometrics = launchAuthBiometricsStr == "1";

  launchAccountPage = launchAccountPageStr == "1";

  bool authPage = launchAuth && (password || biometrics);

  //暗色模式
  String darkModeStr = await Util.instance.getStorage("dark_mode") ?? '';
  int darkMode = 2;
  if (darkModeStr.isNotBlank) {
    darkMode = int.parse(darkModeStr);
  }

  //震动开关
  String vibrateOn = await Util.instance.getStorage("vibrate_on") ?? '';
  String vibrateNormal = await Util.instance.getStorage("vibrate_normal") ?? '';
  String vibrateWarning =
      await Util.instance.getStorage("vibrate_warning") ?? '';
  String showShortcutsStr =
      await Util.instance.getStorage("show_shortcut") ?? '';
  if (showShortcutsStr.isNotBlank) {
    showShortcuts = showShortcutsStr == "1";
  }
  String showWallpaperStr =
      await Util.instance.getStorage("show_wallpaper") ?? '';
  if (showWallpaperStr.isNotBlank) {
    showWallpaper = showWallpaperStr == "1";
  }
  String refreshDurationStr =
      await Util.instance.getStorage("refresh_duration") ?? '';
  if (refreshDurationStr.isNotBlank) {
    refreshDuration = int.parse(refreshDurationStr);
  }
  if (vibrateOn.isNotBlank) {
    Util.instance.vibrateOn = vibrateOn == "1";
  } else {
    Util.instance.vibrateOn = true;
  }
  if (vibrateNormal.isNotBlank) {
    Util.instance.vibrateNormal = vibrateNormal == "1";
  } else {
    Util.instance.vibrateNormal = true;
  }
  if (vibrateWarning.isNotBlank) {
    Util.instance.vibrateWarning = vibrateWarning == "1";
  } else {
    Util.instance.vibrateWarning = true;
  }
  String checkSsl = await Util.instance.getStorage("check_ssl") ?? '';
  if (checkSsl.isNotBlank) {
    Util.instance.checkSsl = checkSsl == "1";
  } else {
    Util.instance.checkSsl = true;
  }
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: DarkModeProvider(darkMode)),
        ChangeNotifierProvider.value(value: ShortcutProvider(showShortcuts)),
        ChangeNotifierProvider.value(value: WallpaperProvider(showWallpaper)),
        ChangeNotifierProvider.value(value: SettingProvider(refreshDuration)),
        ChangeNotifierProvider.value(value: AudioPlayerProvider()),
        ChangeNotifierProvider.value(value: FluwxProvider(fluwx))
      ],
      child: MyApp(authPage, launchAccountPage),
    ),
  );

  if (Platform.isAndroid) {
    // 以下两行 设置android状态栏为透明的沉浸。写在组件渲染之后，是为了在渲染后进行set赋值，覆盖状态栏，写在渲染之前MaterialApp组件会覆盖掉这个值。
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
    ));
  }
}

class MyApp extends StatefulWidget {
  final bool authPage;
  final bool launchAccountPage;
  MyApp(this.authPage, this.launchAccountPage);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DarkModeProvider>(
      builder: (context, darkModeProvider, _) {
        return OKToast(
          child: KeyboardDismisser(
            child: WeuiToastConfig(
              data: WeuiToastConfigData(
                toastAlignment: Alignment.center,
                loadingText: "请稍后",
                loadingBackButtonClose: true,
              ),
              child: MaterialApp(
                title: '${Util.instance.appName}',
                debugShowCheckedModeBanner: false,
                theme: darkModeProvider.darkMode == 2
                    ? lightTheme
                    : (darkModeProvider.darkMode == 0 ? lightTheme : darkTheme),
                darkTheme: darkModeProvider.darkMode == 2 ? darkTheme : null,
                localizationsDelegates: [
                  GlobalCupertinoLocalizations.delegate,
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                ],
                supportedLocales: [
                  const Locale('zh', 'CN'),
                ],
                home: widget.authPage
                    ? AuthPage(
                        launchAccountPage: widget.launchAccountPage,
                      )
                    : widget.launchAccountPage
                        ? Accounts()
                        : Login(),
                routes: {
                  "/login": (BuildContext context) => Login(),
                  "/home": (BuildContext context) => Home(),
                  "/accounts": (BuildContext context) => Accounts(),
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
