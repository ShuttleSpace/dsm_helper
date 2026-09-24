import 'package:garden/extensions/context.dart';
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
import 'package:garden/stores/settings_store.dart';
import 'package:garden/widgets/badge.dart';
import 'package:garden/widgets/control_panel_item.dart';
import 'package:garden/widgets/neu_back_button.dart';
import 'package:signals_flutter/signals_flutter.dart';

import 'shared_folders/shared_folders.dart';
import 'package:garden/pages/control_panel/info/info.dart';
import 'package:flutter/material.dart' hide Badge;

class ControlPanel extends StatefulWidget {
  const ControlPanel(
      this.systemData, this.storageVolumes, this.storageDisks, this.appNotify,
      {super.key});
  final ReadonlySignal<Map<dynamic, dynamic>> systemData;
  final ReadonlySignal<List<dynamic>> storageVolumes;
  final ReadonlySignal<List<dynamic>> storageDisks;
  final ReadonlySignal<Map<dynamic, dynamic>> appNotify;
  @override
  ControlPanelState createState() => ControlPanelState();
}

class ControlPanelState extends State<ControlPanel> with SignalsMixin {
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
            shape: context.roundRectShapeBorder,
            margin: const EdgeInsets.only(top: 20, left: 20, right: 20),
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.paddingSmall),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(20),
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
                              "assets/control_panel/${connectionStore.dsmVersion}/shared_folders.png",
                          targetPage: const SharedFolders(),
                          routeName: "share_folders",
                        ),
                        ControlPanelItem(
                          title: "文件服务",
                          iconPath:
                              "assets/control_panel/${connectionStore.dsmVersion}/file_services.png",
                          targetPage: const FileService(),
                          routeName: "file_service",
                        ),
                        ControlPanelItem(
                          title: connectionStore.dsmVersion.watch(context) < 7
                              ? "用户账户"
                              : "用户与群组",
                          iconPath:
                              "assets/control_panel/${connectionStore.dsmVersion}/users.png",
                          targetPage: const Users(),
                          routeName: "users",
                        ),
                        if (connectionStore.dsmVersion < 7)
                          ControlPanelItem(
                            title: "用户群组",
                            iconPath:
                                "assets/control_panel/${connectionStore.dsmVersion}/groups.png",
                            targetPage: const UserGroups(),
                            routeName: "user_groups",
                          ),
                        ControlPanelItem(
                            title: "域/LDAP",
                            iconPath:
                                "assets/control_panel/${settingsStore.dsmApiVersion}/ldap.png",
                            targetPage: const UserGroups())
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
            shape: context.roundRectShapeBorder,
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
                        if (settingsStore.dsmApiVersion < 7)
                          ControlPanelItem(
                              title: "Quick Connect",
                              iconPath:
                                  "assets/control_panel/${settingsStore.dsmApiVersion}/quickconnect.png",
                              targetPage: const UserGroups()),
                        ControlPanelItem(
                          title: "外部访问",
                          iconPath:
                              "assets/control_panel/${connectionStore.dsmVersion}/public_access.png",
                          targetPage: const PublicAccess(),
                          routeName: "public_access",
                        ),
                        ControlPanelItem(
                          title: "网络",
                          iconPath:
                              "assets/control_panel/${connectionStore.dsmVersion}/network.png",
                          targetPage: const Network(),
                          routeName: "network",
                        ),
                        if (settingsStore.dsmApiVersion < 7)
                          ControlPanelItem(
                              title: "DHCP Server",
                              iconPath:
                                  "assets/control_panel/${settingsStore.dsmApiVersion}/dhcp_server.png",
                              targetPage: const UserGroups()),
                        if (settingsStore.dsmApiVersion < 7)
                          const ControlPanelItem(
                              title: "无线",
                              iconPath: "assets/control_panel/6/wireless.png",
                              targetPage: UserGroups()),
                        ControlPanelItem(
                            title: "安全性",
                            iconPath:
                                "assets/control_panel/${settingsStore.dsmApiVersion}/security.png",
                            targetPage: const UserGroups()),
                        if (connectionStore.dsmVersion >= 7)
                          ControlPanelItem(
                            title: "终端机和SNMP",
                            iconPath:
                                "assets/control_panel/${connectionStore.dsmVersion}/terminal_and_SNMP.png",
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
                              "assets/control_panel/${connectionStore.dsmVersion}/info_center.png",
                          targetPage: SystemInfo(0, widget.systemData,
                              widget.storageDisks, widget.storageVolumes),
                          routeName: "system_info_all",
                        ),
                        ControlPanelItem(
                            title: settingsStore.dsmApiVersion < 7
                                ? "主题样式"
                                : "登录门户",
                            iconPath:
                                "assets/control_panel/${settingsStore.dsmApiVersion}/login_style.png",
                            targetPage: const UserGroups()),
                        ControlPanelItem(
                            title: "区域选项",
                            iconPath:
                                "assets/control_panel/${settingsStore.dsmApiVersion}/region.png",
                            targetPage: const UserGroups()),
                        ControlPanelItem(
                            title: "通知设置",
                            iconPath:
                                "assets/control_panel/${settingsStore.dsmApiVersion}/notifications.png",
                            targetPage: const UserGroups()),
                        if (connectionStore.dsmVersion < 7)
                          ControlPanelItem(
                            title: "任务计划",
                            iconPath:
                                "assets/control_panel/${connectionStore.dsmVersion}/task_scheduler.png",
                            targetPage: const TaskScheduler(),
                            routeName: "task_scheduler",
                          ),
                        ControlPanelItem(
                          title: "硬件和电源",
                          iconPath:
                              "assets/control_panel/${connectionStore.dsmVersion}/hardware_and_power.png",
                          targetPage: const Power(),
                          routeName: "power",
                        ),
                        ControlPanelItem(
                          title: "外部设备",
                          iconPath:
                              "assets/control_panel/${connectionStore.dsmVersion}/external_devices.png",
                          targetPage: const ExternalDevice(),
                          routeName: "external_device",
                        ),
                        Stack(
                          children: [
                            ControlPanelItem(
                              title: "更新和还原",
                              iconPath:
                                  "assets/control_panel/${connectionStore.dsmVersion}/update_and_reset.png",
                              targetPage: const UpdateReset(),
                              routeName: "update_and_reset",
                            ),
                            if (widget.appNotify[
                                        'SYNO.SDS.AdminCenter.Update_Reset.Main'] !=
                                    null &&
                                widget.appNotify[
                                            'SYNO.SDS.AdminCenter.Update_Reset.Main']
                                        ['unread'] !=
                                    null)
                              Positioned(
                                top: 8,
                                right: 8,
                                child: Badge(
                                  widget.appNotify[
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
                        if (settingsStore.dsmApiVersion >= 7)
                          ControlPanelItem(
                              title: "Synology 账户",
                              iconPath:
                                  "assets/control_panel/${settingsStore.dsmApiVersion}/synology_account.png",
                              targetPage: const UserGroups()),
                        ControlPanelItem(
                            title: settingsStore.dsmApiVersion < 7
                                ? "权限"
                                : "应用程序权限",
                            iconPath:
                                "assets/control_panel/${settingsStore.dsmApiVersion}/privilege.png",
                            targetPage: const UserGroups()),
                        if (settingsStore.dsmApiVersion < 7)
                          ControlPanelItem(
                              title: settingsStore.dsmApiVersion < 7
                                  ? "权限"
                                  : "应用程序权限",
                              iconPath:
                                  "assets/control_panel/${settingsStore.dsmApiVersion}/privilege.png",
                              targetPage: const UserGroups()),
                        ControlPanelItem(
                            title: "应用程序门户",
                            iconPath:
                                "assets/control_panel/${settingsStore.dsmApiVersion}/portal.png",
                            targetPage: const UserGroups()),
                        ControlPanelItem(
                          title: "索引服务",
                          iconPath:
                              "assets/control_panel/${connectionStore.dsmVersion}/file_index.png",
                          targetPage: const MediaIndex(),
                          routeName: "media_index",
                        ),
                        if (connectionStore.dsmVersion < 7)
                          ControlPanelItem(
                            title: "终端机和SNMP",
                            iconPath:
                                "assets/control_panel/${connectionStore.dsmVersion}/terminal_and_SNMP.png",
                            targetPage: const SshSetting(),
                            routeName: "ssh_setting",
                          ),
                        if (connectionStore.dsmVersion >= 7)
                          ControlPanelItem(
                            title: "任务计划",
                            iconPath:
                                "assets/control_panel/${connectionStore.dsmVersion}/task_scheduler.png",
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
