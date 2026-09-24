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
import 'package:garden/widgets/badge.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' hide Badge;
import 'package:signals_flutter/signals_flutter.dart';

class ApplicationList extends StatelessWidget {
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
    return Container(
      width: MediaQuery.sizeOf(context).width * 0.8,
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        child: Watch(
          (_) => ListView(
            padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.paddingLarge),
            children: [
              Wrap(
                spacing: 20,
                runSpacing: 20,
                children: _buildApplicationList(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildApplicationList(BuildContext context) {
    List<Widget> apps = [];
    for (var application in applications.value) {
      switch (application) {
        case "SYNO.SDS.AdminCenter.Application":
          apps.add(
            GestureDetector(
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(CupertinoPageRoute(
                    builder: (context) {
                      return ControlPanel(
                          system,
                          volumes,
                          disks,
                          appNotify['SYNO.SDS.AdminCenter.Application'] == null
                              ? null
                              : appNotify['SYNO.SDS.AdminCenter.Application']
                                  ['fn']);
                    },
                    settings: const RouteSettings(name: "control_panel")));
              },
              child: Card(
                shape: RoundedRectangleBorder(
                    side: const BorderSide(),
                    borderRadius: BorderRadius.circular(18)),
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.paddingSmall),
                  child: Stack(
                    children: [
                      Align(
                        alignment: Alignment.center,
                        child: Column(
                          children: [
                            Image.asset(
                              "assets/applications/${connectionStore.dsmVersion}/control_panel.png",
                              height: 45,
                              width: 45,
                              fit: BoxFit.contain,
                            ),
                            const SizedBox(
                              height: 5,
                            ),
                            const Text("控制面板"),
                          ],
                        ),
                      ),
                      if (appNotify['SYNO.SDS.AdminCenter.Application'] != null)
                        Positioned(
                          right: 30,
                          child: Badge(
                            appNotify['SYNO.SDS.AdminCenter.Application']
                                ['unread'],
                            size: 20,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
          break;
        case "SYNO.SDS.PkgManApp.Instance":
          apps.add(
            GestureDetector(
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(CupertinoPageRoute(
                    builder: (context) {
                      return Packages(system['firmware_ver']);
                    },
                    settings: const RouteSettings(name: "packages")));
              },
              child: Card(
                shape: RoundedRectangleBorder(
                    side: const BorderSide(),
                    borderRadius: BorderRadius.circular(18)),
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.paddingSmall),
                  child: Stack(
                    children: [
                      Align(
                        alignment: Alignment.center,
                        child: Column(
                          children: [
                            Image.asset(
                              "assets/applications/${connectionStore.dsmVersion}/package_center.png",
                              height: 45,
                              width: 45,
                              fit: BoxFit.contain,
                            ),
                            const SizedBox(
                              height: 5,
                            ),
                            const Text("套件中心"),
                          ],
                        ),
                      ),
                      if (appNotify['SYNO.SDS.PkgManApp.Instance'] != null)
                        Positioned(
                          right: 30,
                          child: Badge(
                            appNotify['SYNO.SDS.PkgManApp.Instance']['unread'],
                            size: 20,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
          break;
        case "SYNO.SDS.ResourceMonitor.Instance":
          apps.add(
            GestureDetector(
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(CupertinoPageRoute(
                    builder: (context) {
                      return const ResourceMonitor();
                    },
                    settings: const RouteSettings(name: "resource_monitor")));
              },
              child: Card(
                shape: RoundedRectangleBorder(
                    side: const BorderSide(),
                    borderRadius: BorderRadius.circular(18)),
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.paddingSmall),
                  child: Column(
                    children: [
                      Image.asset(
                        "assets/applications/${connectionStore.dsmVersion}/resource_monitor.png",
                        height: 45,
                        width: 45,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(
                        height: 5,
                      ),
                      const Text("资源监控"),
                    ],
                  ),
                ),
              ),
            ),
          );
          break;
        case "SYNO.SDS.StorageManager.Instance":
          apps.add(
            GestureDetector(
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(CupertinoPageRoute(
                    builder: (context) {
                      return const StorageManager();
                    },
                    settings: const RouteSettings(name: "storage_manager")));
              },
              child: Card(
                shape: RoundedRectangleBorder(
                    side: const BorderSide(),
                    borderRadius: BorderRadius.circular(18)),
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.paddingSmall),
                  child: Column(
                    children: [
                      Image.asset(
                        "assets/applications/${connectionStore.dsmVersion}/storage_manager.png",
                        height: 45,
                        width: 45,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(
                        height: 5,
                      ),
                      const Text("存储空间管理员"),
                    ],
                  ),
                ),
              ),
            ),
          );
          break;
        case "SYNO.SDS.LogCenter.Instance":
          apps.add(
            GestureDetector(
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(CupertinoPageRoute(
                    builder: (context) {
                      return const LogCenter();
                    },
                    settings: const RouteSettings(name: "log_center")));
              },
              child: Card(
                shape: RoundedRectangleBorder(
                    side: const BorderSide(),
                    borderRadius: BorderRadius.circular(18)),
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.paddingSmall),
                  child: Column(
                    children: [
                      Image.asset(
                        "assets/applications/${connectionStore.dsmVersion}/log_center.png",
                        height: 45,
                        width: 45,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(
                        height: 5,
                      ),
                      const Text("日志中心"),
                    ],
                  ),
                ),
              ),
            ),
          );
          break;
        case "SYNO.SDS.SecurityScan.Instance":
          apps.add(
            GestureDetector(
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
              child: Card(
                shape: RoundedRectangleBorder(
                    side: const BorderSide(),
                    borderRadius: BorderRadius.circular(18)),
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.paddingSmall),
                  child: Stack(
                    children: [
                      Align(
                        alignment: Alignment.center,
                        child: Column(
                          children: [
                            Image.asset(
                              "assets/applications/${connectionStore.dsmVersion}/security_scan.png",
                              height: 45,
                              width: 45,
                              fit: BoxFit.contain,
                            ),
                            const SizedBox(
                              height: 5,
                            ),
                            const Text("安全顾问"),
                          ],
                        ),
                      ),
                      if (appNotify['SYNO.SDS.SecurityScan.Instance'] != null)
                        Positioned(
                          right: 30,
                          child: Badge(
                            appNotify['SYNO.SDS.SecurityScan.Instance']
                                ['unread'],
                            size: 20,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
          break;
        case "SYNO.SDS.XLPan.Application":
          apps.add(
            GestureDetector(
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
              child: Card(
                shape: RoundedRectangleBorder(
                    side: const BorderSide(),
                    borderRadius: BorderRadius.circular(18)),
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.paddingSmall),
                  child: Column(
                    children: [
                      Image.asset(
                        "assets/applications/xunlei.png",
                        height: 45,
                        width: 45,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(
                        height: 5,
                      ),
                      const Text("迅雷"),
                    ],
                  ),
                ),
              ),
            ),
          );
          break;
        case "SYNO.SDS.Virtualization.Application":
          apps.add(
            GestureDetector(
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
              child: Card(
                shape: RoundedRectangleBorder(
                    side: const BorderSide(),
                    borderRadius: BorderRadius.circular(18)),
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.paddingSmall),
                  child: Column(
                    children: [
                      Image.asset(
                        "assets/applications/${connectionStore.dsmVersion}/virtual_machine.png",
                        height: 45,
                        width: 45,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(
                        height: 5,
                      ),
                      const Text(
                        "Virtual Machine Manager",
                        maxLines: 1,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
          break;
        case "SYNO.SDS.Docker.Application":
          apps.add(
            GestureDetector(
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(CupertinoPageRoute(
                  builder: (context) {
                    return const Docker();
                  },
                  settings: const RouteSettings(name: "docker"),
                ));
              },
              child: Card(
                shape: RoundedRectangleBorder(
                    side: const BorderSide(),
                    borderRadius: BorderRadius.circular(18)),
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.paddingSmall),
                  child: Column(
                    children: [
                      Image.asset(
                        "assets/applications/docker.png",
                        height: 45,
                        width: 45,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(
                        height: 5,
                      ),
                      const Text(
                        "Docker",
                        maxLines: 1,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
          break;
        case "SYNO.SDS.ContainerManager.Application":
          apps.add(
            GestureDetector(
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(CupertinoPageRoute(
                  builder: (context) {
                    return const Docker(title: "Container Manager");
                  },
                  settings: const RouteSettings(name: "Container Manager"),
                ));
              },
              child: Card(
                shape: RoundedRectangleBorder(
                    side: const BorderSide(),
                    borderRadius: BorderRadius.circular(18)),
                child: Column(
                  children: [
                    Column(
                      children: [
                        Image.asset(
                          "assets/applications/container_manager.png",
                          height: 45,
                          width: 45,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(
                          height: 5,
                        ),
                        const Text(
                          "Container Manager",
                          maxLines: 1,
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
          break;
        case "SYNO.SDS.DownloadStation.Application":
          apps.add(
            GestureDetector(
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(CupertinoPageRoute(
                  builder: (context) {
                    return const DownloadStation();
                  },
                  settings: const RouteSettings(name: "download_station"),
                ));
              },
              child: Card(
                shape: RoundedRectangleBorder(
                    side: const BorderSide(),
                    borderRadius: BorderRadius.circular(18)),
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.paddingSmall),
                  child: Column(
                    children: [
                      Image.asset(
                        "assets/applications/download_station.png",
                        height: 45,
                        width: 45,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(
                        height: 5,
                      ),
                      const Text(
                        "Download Station",
                        maxLines: 1,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
          break;
        case "SYNO.Photo.AppInstance":
          apps.add(
            GestureDetector(
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(CupertinoPageRoute(
                  builder: (context) {
                    return const Moments();
                  },
                  settings: const RouteSettings(name: "moments"),
                ));
              },
              child: Card(
                shape: RoundedRectangleBorder(
                    side: const BorderSide(),
                    borderRadius: BorderRadius.circular(18)),
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.paddingSmall),
                  child: Column(
                    children: [
                      Image.asset(
                        "assets/applications/6/moments.png",
                        height: 45,
                        width: 45,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(
                        height: 5,
                      ),
                      const Text(
                        "Moments",
                        maxLines: 1,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
          break;
        case "SYNO.Foto.AppInstance":
          apps.add(
            GestureDetector(
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(CupertinoPageRoute(
                  builder: (context) {
                    return const Photos();
                  },
                  settings: const RouteSettings(name: "photos"),
                ));
              },
              child: Card(
                shape: RoundedRectangleBorder(
                    side: const BorderSide(),
                    borderRadius: BorderRadius.circular(18)),
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.paddingSmall),
                  child: Column(
                    children: [
                      Image.asset(
                        "assets/applications/7/synology_photos.png",
                        height: 45,
                        width: 45,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(
                        height: 5,
                      ),
                      const Text(
                        "Synology Photos",
                        maxLines: 1,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
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
