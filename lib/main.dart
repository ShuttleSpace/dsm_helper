// ignore_for_file: unused_import

import 'dart:async';
import 'dart:io';

import 'package:cool_ui/cool_ui.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';
import 'package:garden/pages/home.dart';
import 'package:garden/pages/login/accounts.dart';
import 'package:garden/pages/login/auth_page.dart';
import 'package:garden/pages/login/login.dart';
import 'package:garden/stores/connection_store.dart';
import 'package:garden/stores/settings_store.dart';
import 'package:garden/theme/light_theme.dart';
import 'package:garden/theme/dark_theme.dart';
import 'package:garden/util/http_util.dart';
import 'package:garden/util/log.dart';
import 'package:garden/util/storage_util.dart';
import 'package:garden/util/ui_util.dart';
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
import 'package:garden/services/transfer_engine.dart';
import 'package:garden/stores/transfer_store.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  SignalsObserver.instance = LoggingSignalsObserver();

  await settingsStore.initialize();
  await connectionStore.initialize();
  await initTransferEngine();
  transferStore.listenUpdates();
  transferStore.startBackupTimeSync(); // app 生命周期内持续写回备份时间
  await transferStore.resumeUnfinishedOnStartup();
  final autPage = await settingsStore.authPage.value;
  final launchAccountPage = await settingsStore.launchAccountPage.value;
  runApp(MyApp(autPage, launchAccountPage));
  if (Platform.isAndroid) {
    // 以下两行 设置android状态栏为透明的沉浸。写在组件渲染之后，是为了在渲染后进行set赋值，覆盖状态栏，写在渲染之前MaterialApp组件会覆盖掉这个值。
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
    ));
  }
}

class MyApp extends StatelessWidget {
  final bool authPage;
  final bool launchAccountPage;
  const MyApp(this.authPage, this.launchAccountPage, {super.key});

  @override
  Widget build(BuildContext context) {
    return OKToast(
      child: KeyboardDismisser(
        child: WeuiToastConfig(
          data: const WeuiToastConfigData(
            toastAlignment: Alignment.center,
            loadingText: "请稍后",
            loadingBackButtonClose: true,
          ),
          child: MaterialApp(
            title: connectionStore.appName.watch(context),
            debugShowCheckedModeBanner: false,
            theme: settingsStore.darkMode.watch(context) == 2
                ? lightTheme
                : (settingsStore.darkMode.watch(context) == 0
                    ? lightTheme
                    : darkTheme),
            darkTheme:
                settingsStore.darkMode.watch(context) == 2 ? darkTheme : null,
            localizationsDelegates: const [
              GlobalCupertinoLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('zh', 'CN'),
            ],
            home: authPage
                ? AuthPage(
                    launchAccountPage: launchAccountPage,
                  )
                : launchAccountPage
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
  }
}
