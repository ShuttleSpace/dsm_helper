import 'package:garden/api/dsm_api.dart';
import 'package:garden/pages/dashborad/dashboard_appbar_title.dart';
import 'package:garden/pages/dashborad/dashboard_cards.dart';
import 'package:garden/stores/settings_store.dart';
import 'package:garden/stores/connection_store.dart';

import 'package:garden/pages/dashborad/applications.dart';
import 'package:garden/pages/dashborad/shortcut_list.dart';
import 'package:garden/pages/dashborad/widget_setting.dart';
import 'package:garden/util/log.dart';
import 'package:garden/util/ui_util.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:signals_hooks/signals_hooks.dart';

class Dashboard extends HookWidget {
  final Signal<bool> dashboardDrawerOpen;
  const Dashboard({super.key, required this.dashboardDrawerOpen});

  @override
  Widget build(BuildContext context) {
    final scaffoldKey = useMemoized(() => GlobalKey<ScaffoldState>(), const []);
    final loading = useSignal<bool>(true);
    final success = useSignal<bool>(true);
    final msg = useSignal<String>('');
    // sds data
    final storageVolumes = useListSignal([]);
    final storageDisks = useListSignal([]);
    final storageSsdCaches = useListSignal([]);

    /// desktop init data
    final sdsWidgetModuleList = useListSignal([]);
    final sdsWidgetRestoreSizePos = useMapSignal({});

    final desktopAppViewOrder = useListSignal([]);
    final desktopShortcutItems = useListSignal<Map>([]);
    final desktopValidAppViewOrder = useListSignal([]);
    final desktopWallpaper = useMapSignal({});
    final sessionHostname = useSignal("获取中");

    final appNotify = useMapSignal({});
    final systemData = useMapSignal({});

    // Resource refresh duration keeps this page subscribed to the setting.
    // ignore: unnecessary_statements
    settingsStore.refreshDuration.watch(context);

    fetchDesktopInitdata() async {
      try {
        final res = await dsmCoreDesktopInitdata();
        if (res['UserSettings'] != null) {
          if (res['UserSettings']['SYNO.SDS._Widget.Instance'] != null) {
            sdsWidgetModuleList.value = res['UserSettings']
                    ['SYNO.SDS._Widget.Instance']['modulelist'] ??
                [];
            sdsWidgetRestoreSizePos.value = res['UserSettings']
                    ['SYNO.SDS._Widget.Instance']['restoreSizePos'] ??
                {};
          }
          if (res['UserSettings']['Desktop'] != null) {
            desktopAppViewOrder.value =
                res['UserSettings']['Desktop']['appview_order'] ?? [];
            desktopShortcutItems.value =
                (res['UserSettings']?['Desktop']?['ShortcutItems'] as List?)
                        ?.cast<Map<dynamic, dynamic>>() ??
                    [];
            desktopValidAppViewOrder.value =
                res['UserSettings']['Desktop']['valid_appview_order'];
            desktopWallpaper.value = res['UserSettings']['Desktop']['wallpaper'];
          }
        }
        if (res['Session'] != null) {
          sessionHostname.value = res['Session']['hostname'];
          connectionStore.setHostname(sessionHostname.value);
        }
        if (res['Strings'] != null) {
          connectionStore.setStrings(res['Strings'] ?? {});
        }
      } catch (e) {
        Log.error('fetchDesktopInitdata error: $e');
        UiUtil.toast('fetchDesktopInitdata error: $e');
        success.value = false;
        msg.value = 'fetchDesktopInitdata error: $e';
      }
    }

    fetchWidgetModuleList() async {
      try {
        final res =
            await dsmSDSWidgetModuleListDetail(sdsWidgetModuleList.value);
        List result = res['result'];
        batch(() {
          for (final item in result) {
            if (item['success'] == true) {
              switch (item['api']) {
                case "SYNO.Core.System.Utilization":
                  break;
                case "SYNO.Core.CurrentConnection":
                  break;
                case 'SYNO.Core.TaskScheduler':
                  break;
                case 'SYNO.Core.SyslogClient.Status':
                  break;
                case "SYNO.Core.DSMNotify":
                  break;
                case "SYNO.Core.SyslogClient.Log":
                  break;
                case "SYNO.Core.System":
                  systemData.value = item['data'];
                  settingsStore.setFirmwareVersion(systemData['firmware_ver']);
                  break;
                case "SYNO.Storage.CGI.Storage":
                  storageSsdCaches.value = item['data']['ssdCaches'];
                  storageVolumes.value = item['data']['volumes'];
                  storageVolumes.sort((a, b) {
                    final aid = a['num_id'] as int;
                    final bid = b['num_id'] as int;
                    return aid.compareTo(bid);
                  });
                  storageDisks.value = item['data']['disks'];
                  break;
                case "SYNO.Core.AppNotify":
                  appNotify.value = item['data'];
                  break;
              }
            }
          }
        });
      } catch (e) {
        Log.error('dsmSDSWidgetModuleListDetail error: $e');
        success.value = false;
        msg.value = 'dsmSDSWidgetModuleListDetail error: $e';
      }
    }

    Widget buildWidgetItem(String widget) {
      switch (widget) {
        case 'SYNO.SDS.SystemInfoApp.SystemHealthWidget':
          return DashboardSystemHealthCard(
              storageVolumes: storageVolumes,
              storageDisks: storageDisks,
              storageSsdCaches: storageSsdCaches,
              systemData: systemData,
              wallpaper: desktopWallpaper,
              sessionHostname: sessionHostname);
        case 'SYNO.SDS.SystemInfoApp.ConnectionLogWidget':
          return const DashboardConnectionLogCard();
        case 'SYNO.SDS.TaskScheduler.TaskSchedulerWidget':
          return const DashboardTaskSchedulerCard();
        case 'SYNO.SDS.SystemInfoApp.RecentLogWidget':
          return const DashboardRecentLogCard();
        case 'SYNO.SDS.ResourceMonitor.Widget':
          return const DashboardResourceMonitorCard();
        case 'SYNO.SDS.SystemInfoApp.FileChangeLogWidget':
          return const DashboardFileChangeLogCard();
        case 'SYNO.SDS.SystemInfoApp.StorageUsageWidget':
          return DashboardStorageUsageCard(
              sdsWidgetModuleList: sdsWidgetModuleList,
              systemData: systemData,
              appNotify: appNotify,
              storageVolumes: storageVolumes,
              storageDisks: storageDisks,
              storageSsdCaches: storageSsdCaches);
        default:
          return const SizedBox.shrink();
      }
    }

    useEffect(() {
      (() async {
        loading.value = true;
        success.value = true;
        await fetchDesktopInitdata();
        await fetchWidgetModuleList();
        loading.value = false;
      })();
      return null;
    }, const []);

    // Keep the real drawer in sync when the owning page closes it externally.
    useSignalEffect(() {
      if (!dashboardDrawerOpen.value) {
        final state = scaffoldKey.currentState;
        if (state != null && state.isDrawerOpen) {
          state.closeDrawer();
        }
      }
    }, keys: const []);

    final loadingValue = loading.watch(context);
    final successValue = success.watch(context);
    final msgValue = msg.watch(context);
    final widgetList = sdsWidgetModuleList.watch(context);
    return Scaffold(
      key: scaffoldKey,
      onDrawerChanged: (isOpened) => dashboardDrawerOpen.value = isOpened,
      appBar: AppBar(
        title: Stack(
          alignment: Alignment.center,
          children: [
            Row(
              children: [
                DashboardAppbarTitleDrawer(
                  onOpenDrawer: scaffoldKey.currentState?.openDrawer,
                ),
                DashboardAppbarTitleExternalDevice(
                  onEjectSuccess: fetchWidgetModuleList,
                ),
                const DashboardAppbarTitleMediaConverter(),
                const Spacer(),
                DashboardAppbarTitleEdit(onEditClick: () {
                  Navigator.of(context)
                      .push(CupertinoPageRoute(builder: (context) {
                    return WidgetSetting(
                        sdsWidgetModuleList, sdsWidgetRestoreSizePos);
                  })).then((res) {
                    if (res != null) {
                      sdsWidgetModuleList.value = res;
                      fetchWidgetModuleList();
                    }
                  });
                }),
                const DashboardAppbarTitleNotifier(),
              ],
            ),
            const Text("控制台")
          ],
        ),
        automaticallyImplyLeading: false,
      ),
      body: loadingValue
          ? const Center(
              child: CupertinoActivityIndicator(
                radius: 14,
              ),
            )
          : successValue
              ? ListView(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  children: [
                    if (desktopShortcutItems
                            .watch(context)
                            .where((element) => supportedShortcuts
                                .contains(element['className']))
                            .isNotEmpty &&
                        connectionStore.notVisitorAccount.watch(context) &&
                        settingsStore.showShortcut.watch(context))
                      ShortcutList(
                        desktopShortcutItems,
                        systemData,
                        storageVolumes,
                        storageDisks,
                        appNotify,
                        validAppViewOrder: desktopValidAppViewOrder,
                      ),
                    if (widgetList.isNotEmpty)
                      ...widgetList.map((widget) {
                        return buildWidgetItem(widget);
                      })
                    else
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              "未添加小组件",
                            ),
                            const SizedBox(
                              height: 20,
                            ),
                            SizedBox(
                              width: 200,
                              child: OutlinedButton(
                                onPressed: () {
                                  Navigator.of(context).push(
                                      CupertinoPageRoute(builder: (context) {
                                    return WidgetSetting(sdsWidgetModuleList,
                                        sdsWidgetRestoreSizePos);
                                  })).then((res) {
                                    if (res != null) {
                                      sdsWidgetModuleList.value = res;
                                      fetchWidgetModuleList();
                                    }
                                  });
                                },
                                child: const Text(
                                  ' 添加 ',
                                  style: TextStyle(fontSize: 18),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                  ],
                )
              : Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(msgValue),
                      const SizedBox(
                        height: 20,
                      ),
                      SizedBox(
                        width: 200,
                        child: OutlinedButton(
                          onPressed: () {
                            loading.value = true;
                            success.value = true;
                            fetchDesktopInitdata().then((_) {
                              fetchWidgetModuleList().then((_) {
                                loading.value = false;
                              });
                            });
                          },
                          child: const Text(
                            ' 刷新 ',
                            style: TextStyle(fontSize: 18),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
      drawer: desktopAppViewOrder.isNotEmpty
          ? ApplicationList(desktopAppViewOrder, systemData, storageVolumes,
              storageDisks, appNotify)
          : null,
    );
  }
}