import 'dart:async';
import 'package:garden/stores/settings_store.dart';
import 'package:garden/util/log.dart';
import 'package:garden/util/ui_util.dart';
import 'package:garden/stores/connection_store.dart';
import 'dart:io';

import 'package:garden/pages/download/download.dart';
import 'package:garden/pages/download/download_state.dart';
import 'package:garden/pages/file/file.dart';
import 'package:garden/pages/setting/setting.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_sharing_intent/flutter_sharing_intent.dart';
import 'package:flutter_sharing_intent/model/sharing_file.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';
import 'package:signals/signals_flutter.dart';

import 'dashborad/dashboard.dart';
import 'download_station/add_task.dart';
import 'file/upload.dart';
import 'login/auth_page.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  HomeState createState() => HomeState();
}

class HomeState extends State<Home> with WidgetsBindingObserver, SignalsMixin {
  final GlobalKey<FilesState> _filesStateKey = GlobalKey<FilesState>();
  final GlobalKey<DashboardState> _dashboardStateKey =
      GlobalKey<DashboardState>();

  late final _navIndex = createSignal(0);
  DateTime lastPopTime = DateTime.now();

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    if (Platform.isAndroid || Platform.isIOS) {
      FlutterSharingIntent.instance
          .getInitialSharing()
          .then((List<SharedFile> value) {
        Log.info(
            "Shared: getInitialMedia ${value.map((f) => f.value).join(",")}");
        _handleSharedFiles(value);
      });
      // For sharing images coming from outside the app while the app is in the memory
      FlutterSharingIntent.instance.getMediaStream().listen(
          (List<SharedFile> value) {
        _handleSharedFiles(value);
        Log.info(
            "Shared: getMediaStream ${value.map((f) => f.value).join(",")}");
      }, onError: (err) {
        Log.info("getIntentDataStream error: $err");
      });
    }
    super.initState();
  }

  _handleSharedFiles(List<SharedFile> files) async {
    if (files.isNotEmpty) {
      if (files.length == 1 && files.first.value!.endsWith(".torrent")) {
        String filePath = '';
        if (Platform.isAndroid) {
          filePath = (await FlutterSharingIntent().getMediaStream().first)
                  .first
                  .value ??
              '';
        } else {
          filePath = files.first.value ?? '';
        }
        UiUtil.toast("Shared: $filePath, ready to download 🐶");
        if (context.mounted) {
          // ignore: use_build_context_synchronously
          Navigator.of(context).push(CupertinoPageRoute(builder: (context) {
            return AddDownloadTask(
              torrentPath: filePath,
            );
          }));
        }
      } else {
        Navigator.of(context).push(CupertinoPageRoute(builder: (context) {
          UiUtil.toast(
              "Shared: ${files.map((f) => f.value).join(",")}, ready to upload 💗");
          return Upload(
            "",
            selectedFilesPath: files
                .takeWhile((t) => t.value != null)
                .map((e) => e.value!)
                .toList(),
          );
        }));
      }
    }
  }

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
    if (await settingsStore.launchAccountPage.value == false &&
        await settingsStore.authPage.value &&
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
    if (_navIndex.value == 0) {
      if (_dashboardStateKey.currentState?.isDrawerOpen.value == true) {
        _dashboardStateKey.currentState?.closeDrawer();
        return;
      }
    } else if (_navIndex.value == 1) {
      if (_filesStateKey.currentState?.isDrawerOpen == true) {
        _filesStateKey.currentState?.closeDrawer();
        return;
      }
      value = _filesStateKey.currentState?.onWillPop() ?? Future.value(false);
    } else if (_navIndex.value == 2) {
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
      // FIXME: with onPopInvokedWithResult notifier
      canPop:
          DateTime.now().difference(lastPopTime) > const Duration(seconds: 2),
      onPopInvokedWithResult: onWillPop,
      child: Scaffold(
        body: DownloadStateInherited(
          notifier: DownloadStateNotifier(),
          child: Watch(
            (context) => IndexedStack(
              index: _navIndex.value,
              children: [
                Dashboard(key: _dashboardStateKey),
                Files(key: _filesStateKey),
                Download(key: UniqueKey()),
                const Setting(),
              ],
            ),
          ),
        ),
        bottomNavigationBar: Watch(
          (context) => BottomNavigationBar(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            type: BottomNavigationBarType.fixed,
            selectedItemColor: Theme.of(context).colorScheme.primary,
            onTap: (v) {
              Log.info('[selected] $v');
              _navIndex.value = v;
            },
            currentIndex: _navIndex.value,
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
      ),
    );
  }
}
