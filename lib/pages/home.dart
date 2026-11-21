import 'dart:async';
import 'package:garden/stores/settings_store.dart';
import 'package:garden/util/log.dart';
import 'package:garden/util/ui_util.dart';
import 'package:garden/stores/connection_store.dart';
import 'dart:io';

import 'package:garden/pages/media/media_library.dart';
import 'package:garden/pages/backup/backup.dart';
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
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:signals_hooks/signals_hooks.dart';

import 'dashborad/dashboard.dart';
import 'download_station/add_task.dart';
import 'file/upload.dart';
import 'login/auth_page.dart';

class Home extends HookWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    final navIndex = useSignal(0);
    // Shared mutable state objects owned by Home and mutated by the child pages.
    // They are not rendered by Home, so they must not subscribe Home to rebuilds
    // (children write them from initState during the first build).
    final filesDrawerOpen = useMemoized(() => signal<bool>(false), const []);
    final dashboardDrawerOpen =
        useMemoized(() => signal<bool>(false), const []);
    final filesOnWillPop =
        useMemoized(() => signal<Future<bool> Function()?>(null), const []);
    final lastPopTime = useSignal(DateTime.now());

    handleSharedFiles(List<SharedFile> files) async {
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

    onWillPop(bool didPop, dynamic result) {
      if (didPop) return;

      UiUtil.vibrate(FeedbackType.light);
      Future<bool> value = Future.value(true);
      if (navIndex.value == 0) {
        if (dashboardDrawerOpen.value == true) {
          dashboardDrawerOpen.value = false;
          return;
        }
      } else if (navIndex.value == 1) {
        if (filesDrawerOpen.value == true) {
          filesDrawerOpen.value = false;
          return;
        }
        value = filesOnWillPop.value?.call() ?? Future.value(false);
      } else if (navIndex.value == 3) {
        value = DownloadStateInherited.of(context)?.notifier.onWillPop() ??
            Future.value(false);
      }
      value.then((v) {
        if (v) {
          if (DateTime.now().difference(lastPopTime.value) >
              const Duration(seconds: 2)) {
            lastPopTime.value = DateTime.now();
            UiUtil.toast('再按一次退出${connectionStore.appName}');
          } else {
            lastPopTime.value = DateTime.now();
            // 退出app
            SystemNavigator.pop();
          }
        }
      });
    }

    useEffect(() {
      if (Platform.isAndroid || Platform.isIOS) {
        FlutterSharingIntent.instance
            .getInitialSharing()
            .then((List<SharedFile> value) {
          Log.info(
              "Shared: getInitialMedia ${value.map((f) => f.value).join(",")}");
          handleSharedFiles(value);
        });
        // For sharing images coming from outside the app while the app is in the memory
        final subscription = FlutterSharingIntent.instance
            .getMediaStream()
            .listen((List<SharedFile> value) {
          handleSharedFiles(value);
          Log.info(
              "Shared: getMediaStream ${value.map((f) => f.value).join(",")}");
        }, onError: (err) {
          Log.info("getIntentDataStream error: $err");
        });
        return subscription.cancel;
      }
      return null;
    }, const []);

    useOnAppLifecycleStateChange((previous, current) {
      if (current == AppLifecycleState.paused) {
        checkAuth();
      }
    });

    useEffect(() {
      runAutoBackup();
      return null;
    }, const []);

    return PopScope(
      // 交给 onWillPop 统一判定：文件页先回上一级，根目录下才走退出确认。
      canPop: false,
      onPopInvokedWithResult: onWillPop,
      child: Scaffold(
        body: DownloadStateInherited(
          notifier: DownloadStateNotifier(),
          child: Watch(
            (context) => IndexedStack(
              index: navIndex.value,
              children: [
                Dashboard(dashboardDrawerOpen: dashboardDrawerOpen),
                Files(
                    filesDrawerOpen: filesDrawerOpen,
                    filesOnWillPop: filesOnWillPop),
                const MediaLibrary(),
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
              navIndex.value = v;
            },
            currentIndex: navIndex.value,
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
                  "assets/tabbar/media.png",
                  width: 30,
                  height: 30,
                ),
                label: '多媒体',
              ),
              BottomNavigationBarItem(
                icon: Image.asset(
                  "assets/tabbar/save.png",
                  width: 30,
                  height: 30,
                ),
                label: '传输',
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
