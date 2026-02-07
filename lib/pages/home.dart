import 'dart:async';
import 'package:garden/stores/settings_store.dart';
import 'package:garden/util/log.dart';
import 'package:garden/util/ui_util.dart';
import 'package:garden/util/storage_util.dart';
import 'package:garden/stores/connection_store.dart';
import 'dart:io';

import 'package:garden/pages/download/download.dart';
import 'package:garden/pages/download/download_state.dart';
import 'package:garden/pages/file/file.dart';
import 'package:garden/pages/setting/setting.dart';
import 'package:garden/util/http_util.dart';
import 'package:garden/widgets/update_dialog.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_sharing_intent/flutter_sharing_intent.dart';
import 'package:flutter_sharing_intent/model/sharing_file.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'dashborad/dashboard.dart';
import 'download_station/add_task.dart';
import 'file/upload.dart';
import 'login/auth_page.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  HomeState createState() => HomeState();
}

class HomeState extends State<Home> with WidgetsBindingObserver {
  int _currentIndex = 0;
  DateTime lastPopTime = DateTime.now();
  PackageInfo? packageInfo;
  final GlobalKey<FilesState> _filesStateKey = GlobalKey<FilesState>();
  final GlobalKey<DashboardState> _dashboardStateKey =
      GlobalKey<DashboardState>();
  //判断是否需要启动密码
  bool launchAuth = false;
  bool password = false;
  bool biometrics = false;
  bool authPage = false;
  List<SharedFile> _sharedFiles = [];
  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    if (Platform.isAndroid || Platform.isIOS) {
      FlutterSharingIntent.instance
          .getInitialSharing()
          .then((List<SharedFile> value) {
        Log.info(
            "Shared: getInitialMedia ${value.map((f) => f.value).join(",")}");
        handleFiles(value);
      });
      // For sharing images coming from outside the app while the app is in the memory
      FlutterSharingIntent.instance.getMediaStream().listen(
          (List<SharedFile> value) {
        handleFiles(value);
        Log.info(
            "Shared: getMediaStream ${value.map((f) => f.value).join(",")}");
      }, onError: (err) {
        Log.info("getIntentDataStream error: $err");
      });
    }

    // For sharing images coming from outside the app while the app is in the memory
    // ReceiveSharingIntent.getMediaStream().listen((List<SharedMediaFile> value) {
    //   handleFiles(value);
    // }, onError: (err) {
    //   Log.debug("getIntentDataStream error: $err");
    // });
    //
    // // For sharing images coming from outside the app while the app is closed
    // ReceiveSharingIntent.getInitialMedia().then((List<SharedMediaFile> value) {
    //   handleFiles(value);
    // });
    // // For sharing or opening urls/text coming from outside the app while the app is in the memory
    // ReceiveSharingIntent.getTextStream().listen((String value) {
    //   // HttpUtil.toast("getTextStream:$value");
    //   if (value != null) {
    //     handleTorrent(value);
    //   }
    // }, onError: (err) {
    //   Log.debug("getLinkStream error: $err");
    // });
    //
    // // For sharing or opening urls/text coming from outside the app while the app is closed
    // ReceiveSharingIntent.getInitialText().then((String value) {
    //   if (value != null) {
    //     handleTorrent(value);
    //   }
    // });
    super.initState();
  }

  handleFiles(List<SharedFile> files) async {
    _sharedFiles = files;
    if (_sharedFiles.isNotEmpty) {
      if (_sharedFiles.length == 1 &&
          _sharedFiles.first.value!.endsWith(".torrent")) {
        String filePath = '';
        if (Platform.isAndroid) {
          filePath = (await FlutterSharingIntent().getMediaStream().first)
                  .first
                  .value ??
              '';
        } else {
          filePath = _sharedFiles.first.value ?? '';
        }
        if (context.mounted) {
          // ignore: use_build_context_synchronously
          Navigator.of(context).push(CupertinoPageRoute(builder: (context) {
            return AddDownloadTask(
              torrentPath: filePath,
            );
          }));
        }
        //   if (content.startsWith("content://") && content.endsWith(".torrent")) {
        //     // final filePath = await FlutterSharingIntent.getAbsolutePath(content);
        //
        //     }));
        //     // if (filePath.endsWith("torrent")) {}
        //   }
      } else {
        Navigator.of(context).push(CupertinoPageRoute(builder: (context) {
          return Upload(
            "",
            selectedFilesPath: _sharedFiles
                .takeWhile((t) => t.value != null)
                .map((e) => e.value!)
                .toList(),
          );
        }));
      }
    }
  }

  // handleTorrent(String content) async {
  //   if (content.startsWith("content://") && content.endsWith(".torrent")) {
  //     // final filePath = await FlutterSharingIntent.getAbsolutePath(content);
  //     Navigator.of(context).push(CupertinoPageRoute(builder: (context) {
  //       return AddDownloadTask(
  //         torrentPath: ,
  //       );
  //     }));
  //     // if (filePath.endsWith("torrent")) {}
  //   }
  // }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      checkAuth();
    }
  }

  checkAuth() async {
    // Log.info("是否需要启动密码")
    launchAuth = await StorageUtil.getBool("launch_auth") ?? false;
    password = await StorageUtil.getBool("launch_auth_password") ?? false;
    biometrics = await StorageUtil.getBool("launch_auth_biometrics") ?? false;

    authPage = launchAuth && (password || biometrics);
    if (await settingsStore.launchAccountPage.value == false &&
        authPage &&
        context.mounted) {
      // ignore: use_build_context_synchronously
      Navigator.of(context).push(CupertinoPageRoute(builder: (context) {
        return const AuthPage(
          launch: false,
        );
      }));
    }
  }

  void onWillPop(bool didPop, dynamic result) {
    if (didPop) return;

    UiUtil.vibrate(FeedbackType.light);
    Future<bool> value = Future.value(true);
    if (_currentIndex == 0) {
      if (_dashboardStateKey.currentState?.isDrawerOpen == true) {
        _dashboardStateKey.currentState?.closeDrawer();
        return;
      }
    } else if (_currentIndex == 1) {
      if (_filesStateKey.currentState?.isDrawerOpen == true) {
        _filesStateKey.currentState?.closeDrawer();
        return;
      }
      value = _filesStateKey.currentState?.onWillPop() ?? Future.value(false);
    } else if (_currentIndex == 2) {
      value = DownloadStateInherited.of(context)?.notifier.onWillPop() ??
          Future.value(false);
    }
    value.then((v) {
      if (v) {
        if (DateTime.now().difference(lastPopTime) >
            const Duration(seconds: 2)) {
          lastPopTime = DateTime.now();
          UiUtil.toast('再按一次退出${connectionStore.appName}');
        } else {
          lastPopTime = DateTime.now();
          // 退出app
          SystemNavigator.pop();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: onWillPop,
      child: Scaffold(
        appBar: null,
        body: DownloadStateInherited(
          notifier: DownloadStateNotifier(),
          child: IndexedStack(
            index: _currentIndex,
            children: [
              Dashboard(key: _dashboardStateKey),
              Files(key: _filesStateKey),
              Download(key: UniqueKey()),
              const Setting(),
            ],
          ),
        ),
        bottomNavigationBar: BottomNavigationBar(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Colors.blue,
          onTap: (v) {
            Log.info('[selected] $v');
            setState(() {
              _currentIndex = v;
            });
          },
          currentIndex: _currentIndex,
          items: [
            BottomNavigationBarItem(
              label: "控制台",
              icon: Image.asset(
                "assets/tabbar/meter.png",
                width: 30,
                height: 30,
              ),
            ),
            BottomNavigationBarItem(
              icon: Image.asset(
                "assets/tabbar/folder.png",
                width: 30,
                height: 30,
              ),
              label: "文件",
            ),
            BottomNavigationBarItem(
              icon: Image.asset(
                "assets/tabbar/save.png",
                width: 30,
                height: 30,
              ),
              label: '下载',
            ),
            BottomNavigationBarItem(
              icon: Image.asset(
                "assets/tabbar/setting.png",
                width: 30,
                height: 30,
              ),
              label: '设置',
            ),
          ],
        ),
      ),
    );
  }
}
