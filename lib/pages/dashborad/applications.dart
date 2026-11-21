import 'package:garden/pages/common/browser.dart';
import 'package:garden/stores/connection_store.dart';
import 'package:garden/pages/control_panel/control_panel.dart';
import 'package:garden/pages/docker/docker.dart';
import 'package:garden/pages/download_station/download_station.dart';
import 'package:garden/pages/log_center/log_center.dart';
import 'package:garden/pages/moments/moments.dart';
import 'package:garden/pages/packages/packages.dart';
import 'package:garden/pages/photos/photos.dart';
import 'package:garden/pages/resource_monitor/resource_monitor.dart';
import 'package:garden/pages/security_scan/security_scan.dart';
import 'package:garden/pages/storage_manager/storage_manager.dart';
import 'package:garden/pages/virtual_machine/virtual_machine.dart';
import 'package:garden/constants/app_constants.dart';
import 'package:garden/widgets/application_tile.dart';
import 'package:garden/widgets/badge.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' hide Badge;
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:signals_hooks/signals_hooks.dart';

class ApplicationList extends HookWidget {
  const ApplicationList(
      this.applications, this.system, this.volumes, this.disks, this.appNotify,
      {super.key});
  final ReadonlySignal<List> applications;
  final ReadonlySignal<Map> system;
  final ReadonlySignal<List> volumes;
  final ReadonlySignal<List> disks;
  final ReadonlySignal<Map> appNotify;
  @override
  Widget build(BuildContext context) {
    final useGridLayout = useSignal(true);
    return Container(
      width: MediaQuery.sizeOf(context).width * 0.8,
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        child: Watch(
          (_) {
            final tiles = _buildApplicationList(context);
            return ListView(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.paddingLarge),
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Tooltip(
                      message: '点击切换布局',
                      child: IconButton(
                        onPressed: () =>
                            useGridLayout.value = !useGridLayout.value,
                        icon: useGridLayout.value
                            ? const Icon(Icons.grid_view_outlined)
                            : const Icon(Icons.view_list_outlined),
                      ),
                    ),
                  ],
                ),
                useGridLayout.value
                    ? Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: tiles
                            .map((tile) => SizedBox(width: 88, child: tile))
                            .toList(),
                      )
                    : Column(
                        children: tiles
                            .map((tile) => SizedBox(
                                  width: double.infinity,
                                  child: tile.copyWith(listLayout: true),
                                ))
                            .toList(),
                      ),
              ],
            );
          },
        ),
      ),
    );
  }

  List<ApplicationTile> _buildApplicationList(BuildContext context) {
    List<ApplicationTile> apps = [];
    for (var application in applications.value) {
      switch (application) {
        case "SYNO.SDS.AdminCenter.Application":
          apps.add(
            ApplicationTile(
              iconAsset:
                  "assets/applications/${connectionStore.dsmVersion}/control_panel.png",
              label: "控制面板",
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(CupertinoPageRoute(
                    builder: (context) {
                      return ControlPanel(system, volumes, disks, appNotify);
                    },
                    settings: const RouteSettings(name: "control_panel")));
              },
              badge: Badge(
                appNotify['SYNO.SDS.AdminCenter.Application']['unread'],
                size: 20,
              ),
            ),
          );
          break;

        case "SYNO.SDS.PkgManApp.Instance":
          apps.add(
            ApplicationTile(
              iconAsset:
                  "assets/applications/${connectionStore.dsmVersion}/package_center.png",
              label: "套件中心",
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(CupertinoPageRoute(
                    builder: (context) {
                      return Packages(system['firmware_ver']);
                    },
                    settings: const RouteSettings(name: "packages")));
              },
              badge: Badge(
                appNotify['SYNO.SDS.PkgManApp.Instance']['unread'],
                size: 20,
              ),
            ),
          );
          break;

        case "SYNO.SDS.ResourceMonitor.Instance":
          apps.add(
            ApplicationTile(
              iconAsset:
                  "assets/applications/${connectionStore.dsmVersion}/resource_monitor.png",
              label: "资源监控",
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(CupertinoPageRoute(
                    builder: (context) {
                      return const ResourceMonitor();
                    },
                    settings: const RouteSettings(name: "resource_monitor")));
              },
            ),
          );
          break;

        case "SYNO.SDS.StorageManager.Instance":
          apps.add(
            ApplicationTile(
              iconAsset:
                  "assets/applications/${connectionStore.dsmVersion}/storage_manager.png",
              label: "存储空间管理员",
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(CupertinoPageRoute(
                    builder: (context) {
                      return const StorageManager();
                    },
                    settings: const RouteSettings(name: "storage_manager")));
              },
            ),
          );
          break;

        case "SYNO.SDS.LogCenter.Instance":
          apps.add(
            ApplicationTile(
              iconAsset:
                  "assets/applications/${connectionStore.dsmVersion}/log_center.png",
              label: "日志中心",
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(CupertinoPageRoute(
                    builder: (context) {
                      return const LogCenter();
                    },
                    settings: const RouteSettings(name: "log_center")));
              },
            ),
          );
          break;

        case "SYNO.SDS.SecurityScan.Instance":
          apps.add(
            ApplicationTile(
              iconAsset:
                  "assets/applications/${connectionStore.dsmVersion}/security_scan.png",
              label: "安全顾问",
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  CupertinoPageRoute(
                      builder: (context) {
                        return const SecurityScan();
                      },
                      settings: const RouteSettings(name: "security_scan")),
                );
              },
              badge: Badge(
                appNotify['SYNO.SDS.SecurityScan.Instance']['unread'],
                size: 20,
              ),
            ),
          );
          break;

        case "SYNO.SDS.XLPan.Application":
          apps.add(
            ApplicationTile(
              iconAsset: "assets/applications/xunlei.png",
              label: "迅雷",
              onTap: () {
                Navigator.of(context).push(
                  CupertinoPageRoute(builder: (context) {
                    return const Browser(
                      title: "迅雷-远程设备",
                      url: "https://pan.xunlei.com/yc",
                    );
                  }),
                );
              },
            ),
          );
          break;

        case "SYNO.SDS.Virtualization.Application":
          apps.add(
            ApplicationTile(
              iconAsset:
                  "assets/applications/${connectionStore.dsmVersion}/virtual_machine.png",
              label: "Virtual Machine Manager",
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(CupertinoPageRoute(
                  builder: (context) {
                    return const VirtualMachine();
                  },
                  settings:
                      const RouteSettings(name: "virtual_machine_manager"),
                ));
              },
            ),
          );
          break;

        case "SYNO.SDS.Docker.Application":
          apps.add(
            ApplicationTile(
              iconAsset: "assets/applications/docker.png",
              label: "Docker",
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(CupertinoPageRoute(
                  builder: (context) {
                    return const Docker();
                  },
                  settings: const RouteSettings(name: "docker"),
                ));
              },
            ),
          );
          break;

        case "SYNO.SDS.ContainerManager.Application":
          apps.add(
            ApplicationTile(
              iconAsset: "assets/applications/container_manager.png",
              label: "Container Manager",
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(CupertinoPageRoute(
                  builder: (context) {
                    return const Docker(title: "Container Manager");
                  },
                  settings: const RouteSettings(name: "Container Manager"),
                ));
              },
            ),
          );
          break;

        case "SYNO.SDS.DownloadStation.Application":
          apps.add(
            ApplicationTile(
              iconAsset: "assets/applications/download_station.png",
              label: "Download Station",
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(CupertinoPageRoute(
                  builder: (context) {
                    return const DownloadStation();
                  },
                  settings: const RouteSettings(name: "download_station"),
                ));
              },
            ),
          );
          break;

        case "SYNO.Photo.AppInstance":
          apps.add(
            ApplicationTile(
              iconAsset: "assets/applications/6/moments.png",
              label: "Moments",
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(CupertinoPageRoute(
                  builder: (context) {
                    return const Moments();
                  },
                  settings: const RouteSettings(name: "moments"),
                ));
              },
            ),
          );
          break;

        case "SYNO.Foto.AppInstance":
          apps.add(
            ApplicationTile(
              iconAsset: "assets/applications/7/synology_photos.png",
              label: "Synology Photos",
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(CupertinoPageRoute(
                  builder: (context) {
                    return const Photos();
                  },
                  settings: const RouteSettings(name: "photos"),
                ));
              },
            ),
          );
          break;
      }
    }
    // if (applications.contains("SYNO.SDS.EzInternet.Instance")) {
    //   apps.add(
    //     NeuCard(
    //       width: (MediaQuery.sizeOf(context).width * 0.8 - 60) / 2,
    //       height: 110,
    //       padding: EdgeInsets.symmetric(vertical: 20),
    //       curveType: CurveType.flat,
    //       decoration: NeumorphicDecoration(
    //         color: Theme.of(context).scaffoldBackgroundColor,
    //         borderRadius: BorderRadius.circular(20),
    //       ),
    //       bevel: 20,
    //       child: Column(
    //         children: [
    //           Image.asset(
    //             "assets/applications/ez_internet.png",
    //             height: 45,
    //             width: 45,
    //             fit: BoxFit.contain,
    //           ),
    //           SizedBox(
    //             height: 5,
    //           ),
    //           Text("EZ-Internet"),
    //         ],
    //       ),
    //     ),
    //   );
    // }
    // if (applications.contains("SYNO.SDS.SupportForm.Application")) {
    //   apps.add(
    //     NeuCard(
    //       width: (MediaQuery.sizeOf(context).width * 0.8 - 60) / 2,
    //       curveType: CurveType.flat,
    //       decoration: NeumorphicDecoration(
    //         color: Theme.of(context).scaffoldBackgroundColor,
    //         borderRadius: BorderRadius.circular(20),
    //       ),
    //       bevel: 20,
    //       padding: EdgeInsets.symmetric(vertical: 20),
    //       child: Column(
    //         children: [
    //           Image.asset(
    //             "assets/applications/support_center.png",
    //             height: 45,
    //             width: 45,
    //             fit: BoxFit.contain,
    //           ),
    //           SizedBox(
    //             height: 5,
    //           ),
    //           Text("技术支持中心"),
    //         ],
    //       ),
    //     ),
    //   );
    // }

    // if (applications.contains("SYNO.SDS.iSCSI.Application")) {
    //   apps.add(
    //     GestureDetector(
    //       onTap: () {
    //         Navigator.of(context).pop();
    //         Navigator.of(context).push(CupertinoPageRoute(
    //             builder: (context) {
    //               return ISCSIManger();
    //             },
    //             settings: RouteSettings(name: "iSCSI_manager")));
    //       },
    //       child: NeuCard(
    //         width: (MediaQuery.sizeOf(context).width * 0.8 - 60) / 2,
    //         curveType: CurveType.flat,
    //         decoration: NeumorphicDecoration(
    //           color: Theme.of(context).scaffoldBackgroundColor,
    //           borderRadius: BorderRadius.circular(20),
    //         ),
    //         bevel: 20,
    //         padding: EdgeInsets.symmetric(vertical: 20),
    //         child: Column(
    //           children: [
    //             Image.asset(
    //               "assets/applications/iSCSI_manager.png",
    //               height: 45,
    //               width: 45,
    //               fit: BoxFit.contain,
    //             ),
    //             SizedBox(
    //               height: 5,
    //             ),
    //             Text("iSCSI Manager"),
    //           ],
    //         ),
    //       ),
    //     ),
    //   );
    // }

    // if (applications.contains("SYNO.SDS.App.FileStation3.Instance")) {
    //   apps.add(
    //     NeuCard(
    //       width: (MediaQuery.sizeOf(context).width * 0.8 - 60) / 2,
    //       curveType: CurveType.flat,
    //       decoration: NeumorphicDecoration(
    //         color: Theme.of(context).scaffoldBackgroundColor,
    //         borderRadius: BorderRadius.circular(20),
    //       ),
    //       bevel: 20,
    //       padding: EdgeInsets.symmetric(vertical: 20),
    //       child: Column(
    //         children: [
    //           Image.asset(
    //             "assets/applications/file_browser.png",
    //             height: 45,
    //             width: 45,
    //             fit: BoxFit.contain,
    //           ),
    //           SizedBox(
    //             height: 5,
    //           ),
    //           Text("File Station"),
    //         ],
    //       ),
    //     ),
    //   );
    // }

    // if (applications.contains("SYNO.Finder.Application")) {
    //   apps.add(
    //     GestureDetector(
    //       onTap: () {
    //         Navigator.of(context).pop();
    //         Navigator.of(context).push(CupertinoPageRoute(
    //             builder: (context) {
    //               return UniversalSearch();
    //             },
    //             settings: RouteSettings(name: "universal_search")));
    //       },
    //       child: NeuCard(
    //         width: (MediaQuery.sizeOf(context).width * 0.8 - 60) / 2,
    //         curveType: CurveType.flat,
    //         decoration: NeumorphicDecoration(
    //           color: Theme.of(context).scaffoldBackgroundColor,
    //           borderRadius: BorderRadius.circular(20),
    //         ),
    //         bevel: 20,
    //         padding: EdgeInsets.symmetric(vertical: 20),
    //         child: Column(
    //           children: [
    //             Image.asset(
    //               "assets/applications/${HttpUtil.version}/universal_search.png",
    //               height: 45,
    //               width: 45,
    //               fit: BoxFit.contain,
    //             ),
    //             SizedBox(
    //               height: 5,
    //             ),
    //             Text("Universal Search"),
    //           ],
    //         ),
    //       ),
    //     ),
    //   );
    // }
    // print(applications);

    //SYNO.SDS.PhotoStation  6.0 photo station
    //SYNO.Foto.AppInstance  7.0 photo
    // print(applications);
    return apps;
  }
}
