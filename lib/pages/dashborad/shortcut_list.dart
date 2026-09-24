import 'package:garden/models/shortcut_item_model.dart';
import 'package:garden/stores/connection_store.dart';
import 'package:garden/pages/common/browser.dart';
import 'package:garden/pages/control_panel/control_panel.dart';
import 'package:garden/pages/docker/detail.dart';
import 'package:garden/pages/docker/docker.dart';
import 'package:garden/pages/download_station/download_station.dart';
import 'package:garden/pages/log_center/log_center.dart';
import 'package:garden/pages/moments/moments.dart';
import 'package:garden/pages/packages/packages.dart';
import 'package:garden/pages/resource_monitor/resource_monitor.dart';
import 'package:garden/pages/storage_manager/storage_manager.dart';
import 'package:garden/pages/virtual_machine/virtual_machine.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:garden/constants/app_constants.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../photos/photos.dart';

List supportedShortcuts = [
  "SYNO.SDS.PkgManApp.Instance",
  "SYNO.SDS.AdminCenter.Application",
  "SYNO.SDS.StorageManager.Instance",
  "SYNO.SDS.Docker.Application",
  "SYNO.SDS.Docker.ContainerDetail.Instance",
  "SYNO.SDS.LogCenter.Instance",
  "SYNO.SDS.ResourceMonitor.Instance",
  "SYNO.SDS.Virtualization.Application",
  "SYNO.SDS.DownloadStation.Application",
  "SYNO.SDS.XLPan.Application",
];

class ShortcutList extends StatelessWidget {
  const ShortcutList(this.shortcutItems, this.systemData, this.storageVolumes,
      this.storageDisks, this.appNotify,
      {super.key, this.validAppViewOrder});
  final ReadonlySignal<List<Map>> shortcutItems;
  final ReadonlySignal<Map> systemData;
  final ReadonlySignal<List> storageVolumes;
  final ReadonlySignal<List> storageDisks;
  final ReadonlySignal<Map> appNotify;
  final ReadonlySignal<List>? validAppViewOrder;
  @override
  Widget build(BuildContext ctx) {
    final shortcutItemsValue = shortcutItems.watch(ctx);
    final appNotifyValue = appNotify.watch(ctx);
    final systemValue = systemData.watch(ctx);
    final storageVolumesValue = storageVolumes.watch(ctx);
    final storageDisksValue = storageDisks.watch(ctx);
    final validAppViewOrderValue = validAppViewOrder?.watch(ctx);
    return Card(
      shape: RoundedRectangleBorder(
          side: const BorderSide(), borderRadius: BorderRadius.circular(18)),
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: SizedBox(
        height: 140,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemBuilder: (ctx, i) {
            return _buildShortcutItem(
                ctx,
                shortcutItemsValue[i],
                systemValue,
                storageVolumesValue,
                storageDisksValue,
                appNotifyValue,
                validAppViewOrderValue);
          },
          itemCount: shortcutItemsValue.length,
        ),
      ),
    );
  }

  Widget _buildShortcutItem(
      BuildContext context,
      Map shortcut,
      Map systemValue,
      List storageVolumesValue,
      List storageDisksValue,
      Map appNotifyValue,
      List? validAppViewOrderValue) {
    String icon = "";
    String name = "";
    int unread = 0;
    Widget page = const Placeholder(
      child: Center(
        child: Text('空空如也~'),
      ),
    );
    String routerName = '';
    switch (shortcut['className']) {
      case "SYNO.SDS.PkgManApp.Instance":
        icon =
            "assets/applications/${connectionStore.dsmVersion}/package_center.png";
        name = "套件中心";
        page = Packages('DSM ${connectionStore.dsmVersion}.0-10049');
        routerName = "packages";
        if (appNotifyValue['SYNO.SDS.PkgManApp.Instance'] != null) {
          unread = appNotifyValue['SYNO.SDS.PkgManApp.Instance']['unread'];
        }
        break;
      case "SYNO.SDS.AdminCenter.Application":
        icon =
            "assets/applications/${connectionStore.dsmVersion}/control_panel.png";
        name = "控制面板";
        page = ControlPanel(
            systemValue.toSignal(),
            storageVolumesValue.toSignal(),
            storageDisksValue.toSignal(),
            appNotifyValue.toSignal());
        routerName = "control_panel";
        if (appNotifyValue['SYNO.SDS.AdminCenter.Application'] != null) {
          unread = appNotifyValue['SYNO.SDS.AdminCenter.Application']['unread'];
        }
        break;
      case "SYNO.SDS.StorageManager.Instance":
        icon =
            "assets/applications/${connectionStore.dsmVersion}/storage_manager.png";
        name = "存储空间管理员";
        page = const StorageManager();
        routerName = "storage_manager";
        break;
      case "SYNO.SDS.Docker.Application":
        if (validAppViewOrderValue
                ?.contains("SYNO.SDS.ContainerManager.Application") ==
            true) {
          icon = "assets/applications/container_manager.png";
          name = "Container Manager";
          page = const Docker(
            title: "Container Manager",
          );
        } else {
          icon = "assets/applications/docker.png";
          name = "Docker";
          page = const Docker();
        }

        routerName = "docker";
        break;
      case "SYNO.SDS.Docker.ContainerDetail.Instance":
        if (validAppViewOrderValue
                ?.contains("SYNO.SDS.ContainerManager.Application") ==
            true) {
          icon = "assets/applications/container_manager.png";
        } else {
          icon = "assets/applications/docker.png";
        }
        name = "${shortcut['param']?['data']?['name']}";
        if (shortcut['type'] == 'url') {
          page = Browser(
            url: shortcut['url'] ?? '',
            title: name,
          );
          routerName = "browser";
        } else {
          page = ContainerDetail(name);
          routerName = "docker_container_detail";
        }

        break;
      case "SYNO.SDS.LogCenter.Instance":
        icon =
            "assets/applications/${connectionStore.dsmVersion}/log_center.png";
        name = "日志中心";
        page = const LogCenter();
        routerName = "log_center";
        break;
      case "SYNO.SDS.ResourceMonitor.Instance":
        icon =
            "assets/applications/${connectionStore.dsmVersion}/resource_monitor.png";
        name = "资源监控";
        page = const ResourceMonitor();
        routerName = "resource_monitor";

        break;
      // case "SYNO.SDS.SecurityScan.Instance":
      //   icon = "assets/applications/security_scan.png";
      //   break;
      case "SYNO.SDS.Virtualization.Application":
        icon =
            "assets/applications/${connectionStore.dsmVersion}/virtual_machine.png";
        name = "Virtual Machine Manager";
        page = const VirtualMachine();
        routerName = "virtual_machine_manager";
        break;
      case "SYNO.Photo.AppInstance":
        icon = "assets/applications/6/moments.png";
        name = "Moments";
        page = const Moments();
        routerName = "moments";
        break;
      case "SYNO.Foto.AppInstance":
        icon = "assets/applications/7/synology_photos.png";
        name = "Synology Photos";
        page = const Photos();
        routerName = "photos";
        break;
      case "SYNO.SDS.DownloadStation.Application":
        icon = "assets/applications/download_station.png";
        name = "Download Station";
        page = const DownloadStation();
        routerName = "download_station";
        break;
      case "SYNO.SDS.XLPan.Application":
        icon = "assets/applications/xunlei.png";
        name = "迅雷";
        page = const Browser(
          title: "迅雷-远程设备",
          url: "https://pan.xunlei.com/yc/?fromApp=paipai",
        );
        routerName = "xunlei";
        break;
    }
    if (icon != "") {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
        child: GestureDetector(
          onTap: () {
            Navigator.of(context).push(CupertinoPageRoute(
                builder: (context) {
                  return page;
                },
                settings: RouteSettings(name: routerName)));
          },
          child: Card(
            shape: RoundedRectangleBorder(
                side: const BorderSide(),
                borderRadius: BorderRadius.circular(18)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Stack(
                children: [
                  Align(
                    alignment: Alignment.center,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: AppConstants.paddingSmall + 2),
                      child: Column(
                        children: [
                          Image.asset(
                            icon,
                            width: 50,
                          ),
                          const SizedBox(
                            height: 5,
                          ),
                          Text(
                            name,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (unread > 0)
                    Positioned(
                      right: 20,
                      top: 10,
                      child: Container(
                        alignment: Alignment.center,
                        height: 15,
                        width: 15,
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withValues(alpha: .5),
                                offset: const Offset(1, 1)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    } else {
      return const SizedBox();
    }
  }
}
