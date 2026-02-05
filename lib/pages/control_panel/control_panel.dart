import 'package:garden/pages/control_panel/external_device/external_device.dart';
import 'package:garden/stores/connection_store.dart';
import 'package:garden/pages/control_panel/file_service/file_service.dart';
import 'package:garden/pages/control_panel/media_index/media_index.dart';
import 'package:garden/pages/control_panel/network/network.dart';
import 'package:garden/pages/control_panel/power/power.dart';
import 'package:garden/pages/control_panel/public_access/public_access.dart';
import 'package:garden/pages/control_panel/ssh/ssh.dart';
import 'package:garden/pages/control_panel/task_scheduler/task_scheduler.dart';
import 'package:garden/pages/control_panel/update_reset/update_reset.dart';
import 'package:garden/pages/control_panel/user_groups/user_group.dart';
import 'package:garden/pages/control_panel/users/users.dart';
import 'package:garden/constants/app_constants.dart';
import 'package:garden/util/badge.dart';
import 'package:garden/widgets/control_panel_item.dart';
import 'package:garden/widgets/neu_back_button.dart';

import 'shared_folders/shared_folders.dart';
import 'package:garden/pages/control_panel/info/info.dart';
import 'package:flutter/material.dart' hide Badge;

class ControlPanel extends StatefulWidget {
  final Map system;
  final List volumes;
  final List disks;
  final Map notify;
  const ControlPanel(this.system, this.volumes, this.disks, this.notify,
      {super.key});
  @override
  ControlPanelState createState() => ControlPanelState();
}

class ControlPanelState extends State<ControlPanel> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: AppBackButton(context),
        title: const Text(
          "控制面板",
        ),
      ),
      body: ListView(
        children: [
          Card(
            shape: RoundedRectangleBorder(
                side: const BorderSide(),
                borderRadius: BorderRadius.circular(18)),
            margin: const EdgeInsets.only(top: 20, left: 20, right: 20),
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.paddingSmall),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 20, left: 20, bottom: 20),
                    child: Text(
                      "文件共享",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppConstants.paddingLarge),
                    child: Wrap(
                      spacing: 20,
                      runSpacing: 20,
                      children: [
                        ControlPanelItem(
                          title: "共享文件夹",
                          iconPath:
                              "assets/control_panel/${connectionStore.version}/shared_folders.png",
                          targetPage: const SharedFolders(),
                          routeName: "share_folders",
                        ),
                        ControlPanelItem(
                          title: "文件服务",
                          iconPath:
                              "assets/control_panel/${connectionStore.version}/file_services.png",
                          targetPage: const FileService(),
                          routeName: "file_service",
                        ),
                        ControlPanelItem(
                          title: connectionStore.version < 7 ? "用户账户" : "用户与群组",
                          iconPath:
                              "assets/control_panel/${connectionStore.version}/users.png",
                          targetPage: const Users(),
                          routeName: "users",
                        ),
                        if (connectionStore.version < 7)
                          ControlPanelItem(
                            title: "用户群组",
                            iconPath:
                                "assets/control_panel/${connectionStore.version}/groups.png",
                            targetPage: const UserGroups(),
                            routeName: "user_groups",
                          ),
                        // NeuCard(
                        //   width: (MediaQuery.sizeOf(context).width - 120) / 3,
                        //   height: (MediaQuery.sizeOf(context).width - 120) / 3,
                        //   curveType: CurveType.flat,
                        //   decoration: NeumorphicDecoration(
                        //     color: Theme.of(context).scaffoldBackgroundColor,
                        //     borderRadius: BorderRadius.circular(20),
                        //   ),
                        //   bevel: 20,
                        //   child: Column(
                        //     mainAxisAlignment: MainAxisAlignment.center,
                        //     children: [
                        //       Image.asset(
                        //         "assets/control_panel/${HttpUtil.version}/ldap.png",
                        //         height: 30,
                        //         width: 30,
                        //         fit: BoxFit.contain,
                        //       ),
                        //       SizedBox(
                        //         height: 5,
                        //       ),
                        //       Text(
                        //         "域/LDAP",
                        //         style: TextStyle(fontSize: 12),
                        //       ),
                        //     ],
                        //   ),
                        // ),
                      ],
                    ),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                ],
              ),
            ),
          ),
          Card(
            shape: RoundedRectangleBorder(
                side: const BorderSide(),
                borderRadius: BorderRadius.circular(18)),
            margin: const EdgeInsets.only(top: 20, left: 20, right: 20),
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.paddingSmall),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 20, left: 20, bottom: 20),
                    child: Text(
                      "连接性",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppConstants.paddingLarge),
                    child: Wrap(
                      spacing: 20,
                      runSpacing: 20,
                      children: [
                        // if (HttpUtil.version < 7)
                        //   NeuCard(
                        //     width: (MediaQuery.sizeOf(context).width - 120) / 3,
                        //     height: (MediaQuery.sizeOf(context).width - 120) / 3,
                        //     curveType: CurveType.convex,
                        //     decoration: NeumorphicDecoration(
                        //       color: Theme.of(context).scaffoldBackgroundColor,
                        //       borderRadius: BorderRadius.circular(20),
                        //     ),
                        //     bevel: 20,
                        //     child: Column(
                        //       mainAxisAlignment: MainAxisAlignment.center,
                        //       children: [
                        //         Image.asset(
                        //           "assets/control_panel/${HttpUtil.version}/quickconnect.png",
                        //           height: 30,
                        //           width: 30,
                        //           fit: BoxFit.contain,
                        //         ),
                        //         SizedBox(
                        //           height: 5,
                        //         ),
                        //         Text(
                        //           "Quick Connect",
                        //           style: TextStyle(fontSize: 12),
                        //         ),
                        //       ],
                        //     ),
                        //   ),
                        ControlPanelItem(
                          title: "外部访问",
                          iconPath:
                              "assets/control_panel/${connectionStore.version}/public_access.png",
                          targetPage: const PublicAccess(),
                          routeName: "public_access",
                        ),
                        ControlPanelItem(
                          title: "网络",
                          iconPath:
                              "assets/control_panel/${connectionStore.version}/network.png",
                          targetPage: const Network(),
                          routeName: "network",
                        ),
                        // if (HttpUtil.version < 7)
                        //   NeuCard(
                        //     width: (MediaQuery.sizeOf(context).width - 120) / 3,
                        //     height: (MediaQuery.sizeOf(context).width - 120) / 3,
                        //     curveType: CurveType.convex,
                        //     decoration: NeumorphicDecoration(
                        //       color: Theme.of(context).scaffoldBackgroundColor,
                        //       borderRadius: BorderRadius.circular(20),
                        //     ),
                        //     bevel: 20,
                        //     child: Column(
                        //       mainAxisAlignment: MainAxisAlignment.center,
                        //       children: [
                        //         Image.asset(
                        //           "assets/control_panel/${HttpUtil.version}/dhcp_server.png",
                        //           height: 30,
                        //           width: 30,
                        //           fit: BoxFit.contain,
                        //         ),
                        //         SizedBox(
                        //           height: 5,
                        //         ),
                        //         Text(
                        //           "DHCP Server",
                        //           style: TextStyle(fontSize: 12),
                        //         ),
                        //       ],
                        //     ),
                        //   ),
                        // if (HttpUtil.version < 7)
                        //   NeuCard(
                        //     width: (MediaQuery.sizeOf(context).width - 120) / 3,
                        //     height: (MediaQuery.sizeOf(context).width - 120) / 3,
                        //     curveType: CurveType.convex,
                        //     decoration: NeumorphicDecoration(
                        //       color: Theme.of(context).scaffoldBackgroundColor,
                        //       borderRadius: BorderRadius.circular(20),
                        //     ),
                        //     bevel: 20,
                        //     child: Column(
                        //       mainAxisAlignment: MainAxisAlignment.center,
                        //       children: [
                        //         Image.asset(
                        //           "assets/control_panel/6/wireless.png",
                        //           height: 30,
                        //           width: 30,
                        //           fit: BoxFit.contain,
                        //         ),
                        //         SizedBox(
                        //           height: 5,
                        //         ),
                        //         Text(
                        //           "无线",
                        //           style: TextStyle(fontSize: 12),
                        //         ),
                        //       ],
                        //     ),
                        //   ),
                        // NeuCard(
                        //   width: (MediaQuery.sizeOf(context).width - 120) / 3,
                        //   height: (MediaQuery.sizeOf(context).width - 120) / 3,
                        //   curveType: CurveType.convex,
                        //   decoration: NeumorphicDecoration(
                        //     color: Theme.of(context).scaffoldBackgroundColor,
                        //     borderRadius: BorderRadius.circular(20),
                        //   ),
                        //   bevel: 20,
                        //   child: Column(
                        //     mainAxisAlignment: MainAxisAlignment.center,
                        //     children: [
                        //       Image.asset(
                        //         "assets/control_panel/${HttpUtil.version}/security.png",
                        //         height: 30,
                        //         width: 30,
                        //         fit: BoxFit.contain,
                        //       ),
                        //       SizedBox(
                        //         height: 5,
                        //       ),
                        //       Text(
                        //         "安全性",
                        //         style: TextStyle(fontSize: 12),
                        //       ),
                        //     ],
                        //   ),
                        // ),
                        if (connectionStore.version >= 7)
                          ControlPanelItem(
                            title: "终端机和SNMP",
                            iconPath:
                                "assets/control_panel/${connectionStore.version}/terminal_and_SNMP.png",
                            targetPage: const SshSetting(),
                            routeName: "ssh_setting",
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                ],
              ),
            ),
          ),
          Card(
            shape: RoundedRectangleBorder(
                side: const BorderSide(),
                borderRadius: BorderRadius.circular(18)),
            margin: const EdgeInsets.only(top: 20, left: 20, right: 20),
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.paddingSmall),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 20, left: 20, bottom: 20),
                    child: Text(
                      "系统",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppConstants.paddingLarge),
                    child: Wrap(
                      spacing: 20,
                      runSpacing: 20,
                      children: [
                        ControlPanelItem(
                          title: "信息中心",
                          iconPath:
                              "assets/control_panel/${connectionStore.version}/info_center.png",
                          targetPage: SystemInfo(
                              0, widget.system, widget.volumes, widget.disks),
                          routeName: "system_info_all",
                        ),
                        // NeuCard(
                        //   width: (MediaQuery.sizeOf(context).width - 120) / 3,
                        //   height: (MediaQuery.sizeOf(context).width - 120) / 3,
                        //   curveType: CurveType.flat,
                        //   decoration: NeumorphicDecoration(
                        //     color: Theme.of(context).scaffoldBackgroundColor,
                        //     borderRadius: BorderRadius.circular(20),
                        //   ),
                        //   bevel: 20,
                        //   child: Column(
                        //     mainAxisAlignment: MainAxisAlignment.center,
                        //     children: [
                        //       Image.asset(
                        //         "assets/control_panel/${HttpUtil.version}/login_style.png",
                        //         height: 30,
                        //         width: 30,
                        //         fit: BoxFit.contain,
                        //       ),
                        //       SizedBox(
                        //         height: 5,
                        //       ),
                        //       Text(
                        //         HttpUtil.version < 7 ? "主题样式" : "登录门户",
                        //         style: TextStyle(fontSize: 12),
                        //       ),
                        //     ],
                        //   ),
                        // ),
                        // NeuCard(
                        //   width: (MediaQuery.sizeOf(context).width - 120) / 3,
                        //   height: (MediaQuery.sizeOf(context).width - 120) / 3,
                        //   curveType: CurveType.flat,
                        //   decoration: NeumorphicDecoration(
                        //     color: Theme.of(context).scaffoldBackgroundColor,
                        //     borderRadius: BorderRadius.circular(20),
                        //   ),
                        //   bevel: 20,
                        //   child: Column(
                        //     mainAxisAlignment: MainAxisAlignment.center,
                        //     children: [
                        //       Image.asset(
                        //         "assets/control_panel/${HttpUtil.version}/region.png",
                        //         height: 30,
                        //         width: 30,
                        //         fit: BoxFit.contain,
                        //       ),
                        //       SizedBox(
                        //         height: 5,
                        //       ),
                        //       Text(
                        //         "区域选项",
                        //         style: TextStyle(fontSize: 12),
                        //       ),
                        //     ],
                        //   ),
                        // ),
                        // NeuCard(
                        //   width: (MediaQuery.sizeOf(context).width - 120) / 3,
                        //   height: (MediaQuery.sizeOf(context).width - 120) / 3,
                        //   curveType: CurveType.flat,
                        //   decoration: NeumorphicDecoration(
                        //     color: Theme.of(context).scaffoldBackgroundColor,
                        //     borderRadius: BorderRadius.circular(20),
                        //   ),
                        //   bevel: 20,
                        //   child: Column(
                        //     mainAxisAlignment: MainAxisAlignment.center,
                        //     children: [
                        //       Image.asset(
                        //         "assets/control_panel/${HttpUtil.version}/notifications.png",
                        //         height: 30,
                        //         width: 30,
                        //         fit: BoxFit.contain,
                        //       ),
                        //       SizedBox(
                        //         height: 5,
                        //       ),
                        //       Text(
                        //         "通知设置",
                        //         style: TextStyle(fontSize: 12),
                        //       ),
                        //     ],
                        //   ),
                        // ),
                        if (connectionStore.version < 7)
                          ControlPanelItem(
                            title: "任务计划",
                            iconPath:
                                "assets/control_panel/${connectionStore.version}/task_scheduler.png",
                            targetPage: const TaskScheduler(),
                            routeName: "task_scheduler",
                          ),
                        ControlPanelItem(
                          title: "硬件和电源",
                          iconPath:
                              "assets/control_panel/${connectionStore.version}/hardware_and_power.png",
                          targetPage: const Power(),
                          routeName: "power",
                        ),
                        ControlPanelItem(
                          title: "外部设备",
                          iconPath:
                              "assets/control_panel/${connectionStore.version}/external_devices.png",
                          targetPage: const ExternalDevice(),
                          routeName: "external_device",
                        ),
                        Stack(
                          children: [
                            ControlPanelItem(
                              title: "更新和还原",
                              iconPath:
                                  "assets/control_panel/${connectionStore.version}/update_and_reset.png",
                              targetPage: const UpdateReset(),
                              routeName: "update_and_reset",
                            ),
                            if (widget.notify[
                                        'SYNO.SDS.AdminCenter.Update_Reset.Main'] !=
                                    null &&
                                widget.notify[
                                            'SYNO.SDS.AdminCenter.Update_Reset.Main']
                                        ['unread'] !=
                                    null)
                              Positioned(
                                top: 8,
                                right: 8,
                                child: Badge(
                                  widget.notify[
                                          'SYNO.SDS.AdminCenter.Update_Reset.Main']
                                      ['unread'],
                                  size: 20,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                ],
              ),
            ),
          ),
          Card(
            shape: RoundedRectangleBorder(
                side: const BorderSide(),
                borderRadius: BorderRadius.circular(18)),
            margin: const EdgeInsets.only(top: 20, left: 20, right: 20),
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.paddingSmall),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 20, left: 20, bottom: 20),
                    child: Text(
                      "应用程序",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppConstants.paddingLarge),
                    child: Wrap(
                      spacing: 20,
                      runSpacing: 20,
                      children: [
                        // if (HttpUtil.version >= 7)
                        //   NeuCard(
                        //     width: (MediaQuery.sizeOf(context).width - 120) / 3,
                        //     height: (MediaQuery.sizeOf(context).width - 120) / 3,
                        //     curveType: CurveType.flat,
                        //     decoration: NeumorphicDecoration(
                        //       color: Theme.of(context).scaffoldBackgroundColor,
                        //       borderRadius: BorderRadius.circular(20),
                        //     ),
                        //     bevel: 20,
                        //     child: Column(
                        //       mainAxisAlignment: MainAxisAlignment.center,
                        //       children: [
                        //         Image.asset(
                        //           "assets/control_panel/${HttpUtil.version}/synology_account.png",
                        //           height: 30,
                        //           width: 30,
                        //           fit: BoxFit.contain,
                        //         ),
                        //         SizedBox(
                        //           height: 5,
                        //         ),
                        //         Text(
                        //           "Synology 账户",
                        //           maxLines: 1,
                        //           overflow: TextOverflow.clip,
                        //           style: TextStyle(fontSize: 12),
                        //         ),
                        //       ],
                        //     ),
                        //   ),
                        // NeuCard(
                        //   width: (MediaQuery.sizeOf(context).width - 120) / 3,
                        //   height: (MediaQuery.sizeOf(context).width - 120) / 3,
                        //   curveType: CurveType.flat,
                        //   decoration: NeumorphicDecoration(
                        //     color: Theme.of(context).scaffoldBackgroundColor,
                        //     borderRadius: BorderRadius.circular(20),
                        //   ),
                        //   bevel: 20,
                        //   child: Column(
                        //     mainAxisAlignment: MainAxisAlignment.center,
                        //     children: [
                        //       Image.asset(
                        //         "assets/control_panel/${HttpUtil.version}/privilege.png",
                        //         height: 30,
                        //         width: 30,
                        //         fit: BoxFit.contain,
                        //       ),
                        //       SizedBox(
                        //         height: 5,
                        //       ),
                        //       Text(
                        //         HttpUtil.version < 7 ? "权限" : "应用程序权限",
                        //         style: TextStyle(fontSize: 12),
                        //       ),
                        //     ],
                        //   ),
                        // ),
                        // if (HttpUtil.version < 7)
                        //   NeuCard(
                        //     width: (MediaQuery.sizeOf(context).width - 120) / 3,
                        //     height: (MediaQuery.sizeOf(context).width - 120) / 3,
                        //     curveType: CurveType.flat,
                        //     decoration: NeumorphicDecoration(
                        //       color: Theme.of(context).scaffoldBackgroundColor,
                        //       borderRadius: BorderRadius.circular(20),
                        //     ),
                        //     bevel: 20,
                        //     child: Column(
                        //       mainAxisAlignment: MainAxisAlignment.center,
                        //       children: [
                        //         Image.asset(
                        //           "assets/control_panel/${HttpUtil.version}/portal.png",
                        //           height: 30,
                        //           width: 30,
                        //           fit: BoxFit.contain,
                        //         ),
                        //         SizedBox(
                        //           height: 5,
                        //         ),
                        //         Text(
                        //           "应用程序门户",
                        //           maxLines: 1,
                        //           overflow: TextOverflow.clip,
                        //           style: TextStyle(fontSize: 12),
                        //         ),
                        //       ],
                        //     ),
                        //   ),
                        ControlPanelItem(
                          title: "索引服务",
                          iconPath:
                              "assets/control_panel/${connectionStore.version}/file_index.png",
                          targetPage: const MediaIndex(),
                          routeName: "media_index",
                        ),
                        if (connectionStore.version < 7)
                          ControlPanelItem(
                            title: "终端机和SNMP",
                            iconPath:
                                "assets/control_panel/${connectionStore.version}/terminal_and_SNMP.png",
                            targetPage: const SshSetting(),
                            routeName: "ssh_setting",
                          ),
                        if (connectionStore.version >= 7)
                          ControlPanelItem(
                            title: "任务计划",
                            iconPath:
                                "assets/control_panel/${connectionStore.version}/task_scheduler.png",
                            targetPage: const TaskScheduler(),
                            routeName: "task_scheduler",
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(
            height: 40,
          ),
        ],
      ),
    );
  }
}
