import 'package:garden/pages/control_panel/file_service/log_setting.dart';
import 'package:garden/util/log.dart';
import 'package:garden/util/ui_util.dart';
import 'package:garden/pages/log_center/log_center.dart';
import 'package:garden/api/dsm_api.dart';
import 'package:garden/widgets/neu_picker.dart';
import 'package:garden/widgets/settings/settings_toggle_tile.dart';
import 'package:garden/widgets/bubble_tab_indicator.dart';
import 'package:garden/widgets/neu_back_button.dart';
import 'package:flutter/cupertino.dart';
import 'package:garden/widgets/settings/settings_text_field.dart';
import 'package:flutter/material.dart';
import 'package:garden/constants/app_constants.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:signals_hooks/signals_hooks.dart';

class FileService extends HookWidget {
  const FileService({super.key});

  @override
  Widget build(BuildContext context) {
    final tickerProvider = useSingleTickerProvider();
    final tabController = useMemoized(
      () => TabController(length: 2, vsync: tickerProvider),
      const [],
    );
    final workgroupController = useTextEditingController();
    final nfsv4Controller = useTextEditingController();
    final timeoutController = useTextEditingController();
    final ftpPortController = useTextEditingController();
    final sftpPortController = useTextEditingController();
    const utf8Modes = ['禁用', '自动', '强制'];
    final loading = useSignal(true);
    final smb = useSignal<Map>({});
    final afp = useSignal<Map>({});
    final nfs = useSignal<Map>({});
    final ftp = useSignal<Map>({});
    final sftp = useSignal<Map>({});
    final bandwidth = useSignal<Map>({});
    final tftp = useSignal<Map>({});
    final backup = useSignal<Map>({});
    final serviceDiscovery = useSignal<Map>({});
    final bonjourSharing = useSignal<Map>({});
    final syslogClient = useSignal<Map>({});
    final saving = useSignal(false);

    getData(Function onFailure) async {
      late Map<String, dynamic> data;
      try {
        data = await dsmCoreFileServiceForPage();
      } catch (e) {
        loading.value = false;
        onFailure();
        return;
      }
      Log.log("FileService: $data");
      loading.value = false;
      if (data['has_fail'] == true) {
        UiUtil.toast("加载失败");
        onFailure();
        return;
      }
      List result = data['result'] ?? [];
      for (var item in result) {
        if (item['success'] == true) {
          switch (item['api']) {
            case "SYNO.Core.FileServ.SMB":
              smb.value = item['data'];
              workgroupController.value =
                  TextEditingValue(text: smb.value['workgroup'] ?? "");
              break;
            case "SYNO.Core.FileServ.AFP":
              afp.value = item['data'];
              break;
            case "SYNO.Core.FileServ.NFS":
              nfs.value = item['data'];
              nfsv4Controller.value =
                  TextEditingValue(text: nfs.value['nfs_v4_domain'] ?? "");
              break;
            case "SYNO.Core.FileServ.FTP":
              ftp.value = item['data'];
              timeoutController.value =
                  TextEditingValue(text: "${ftp.value['timeout']}");
              ftpPortController.value =
                  TextEditingValue(text: "${ftp.value['portnum']}");
              break;
            case "SYNO.Core.FileServ.FTP.SFTP":
              sftp.value = item['data'];
              Log.log("SFTP: ${sftp.value}");
              sftpPortController.value =
                  TextEditingValue(text: "${sftp.value['portnum']}");
              break;
            case "SYNO.Core.BandwidthControl.Protocol":
              bandwidth.value = item['data'];
              break;
            case "SYNO.Core.TFTP":
              tftp.value = item['data'];
              break;
            case "SYNO.Backup.Service.NetworkBackup":
              backup.value = item['data'];
              break;
            case "SYNO.Core.ExternalDevice.Printer.BonjourSharing":
              bonjourSharing.value = item['data'];
              break;
            case "SYNO.Core.FileServ.ServiceDiscovery":
              serviceDiscovery.value = item['data'];
              break;
            case "SYNO.Core.SyslogClient.FileTransfer":
              syslogClient.value = item['data'];
              break;
            case "SYNO.Core.FileServ.ServiceDiscovery.WSTransfer":
              // enable_wstransfer was assigned but never read (dead state).
              break;
          }
        }
      }
    }

    useEffect(() {
      getData(() {
        Navigator.of(context).pop();
      });
      return () {
        tabController.dispose();
      };
    }, const []);

    return Scaffold(
      appBar: AppBar(
        leading: AppBackButton(context),
        title: const Text("文件服务"),
      ),
      body: loading.value
          ? const Center(
              child: CupertinoActivityIndicator(
                radius: 14,
              ),
            )
          : Column(
              children: [
                Card(
                  shape: RoundedRectangleBorder(
                      side: const BorderSide(),
                      borderRadius: BorderRadius.circular(18)),
                  margin:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                  child: Padding(
                    padding: const EdgeInsets.all(AppConstants.paddingSmall),
                    child: TabBar(
                      dividerHeight: 0,
                      isScrollable: true,
                      controller: tabController,
                      indicatorSize: TabBarIndicatorSize.label,
                      labelColor: Theme.brightnessOf(context) == Brightness.dark
                          ? Colors.white
                          : Colors.black,
                      unselectedLabelColor: Colors.grey,
                      indicator: const BubbleTabIndicator(),
                      tabs: const [
                        Padding(
                          padding:
                              EdgeInsets.symmetric(vertical: 10, horizontal: 5),
                          child: Text("SMB/AFP/NFS"),
                        ),
                        Padding(
                          padding:
                              EdgeInsets.symmetric(vertical: 10, horizontal: 5),
                          child: Text("FTP"),
                        ),
                        // Padding(
                        //   padding: EdgeInsets.symmetric(vertical: 10, horizontal: 5),
                        //   child: Text("TFTP"),
                        // ),
                        // Padding(
                        //   padding: EdgeInsets.symmetric(vertical: 10, horizontal: 5),
                        //   child: Text("rsync"),
                        // ),
                        // Padding(
                        //   padding: EdgeInsets.symmetric(vertical: 10, horizontal: 5),
                        //   child: Text("高级设置"),
                        // ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    controller: tabController,
                    children: [
                      ListView(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        children: [
                          Card(
                            shape: RoundedRectangleBorder(
                                side: const BorderSide(),
                                borderRadius: BorderRadius.circular(18)),
                            margin: const EdgeInsets.only(left: 20, right: 20),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "SMB",
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(
                                    height: 20,
                                  ),
                                  SettingsToggleTile(
                                    label: "启用SMB服务",
                                    value: smb.value['enable_samba'],
                                    onTap: () {
                                      smb.value['enable_samba'] =
                                          !smb.value['enable_samba'];
                                      smb.notifyListeners();
                                    },
                                  ),
                                  if (smb.value['enable_samba']) ...[
                                    const SizedBox(
                                      height: 20,
                                    ),
                                    SettingsTextField(
                                      controller: workgroupController,
                                      label: "工作群组",
                                      onChanged: (v) =>
                                          smb.value['workgroup'] = v,
                                    ),
                                    const SizedBox(
                                      height: 20,
                                    ),
                                    SettingsToggleTile(
                                      label: "不可访问以前版本",
                                      value: smb.value['disable_shadow_copy'],
                                      onTap: () {
                                        smb.value['disable_shadow_copy'] =
                                            !smb.value['disable_shadow_copy'];
                                        smb.notifyListeners();
                                      },
                                    ),
                                    const SizedBox(
                                      height: 20,
                                    ),
                                    SettingsToggleTile(
                                      label: "启动传输日志",
                                      value: syslogClient.value['cifs'],
                                      onTap: () {
                                        syslogClient.value['cifs'] =
                                            !syslogClient.value['cifs'];
                                        syslogClient.notifyListeners();

                                        if (syslogClient.value['cifs']) {
                                          Navigator.of(context).push(
                                              CupertinoPageRoute(
                                                  builder: (context) {
                                            return const LogSetting("cifs");
                                          }));
                                        }
                                      },
                                    ),
                                    if (syslogClient.value['cifs']) ...[
                                      const SizedBox(
                                        height: 20,
                                      ),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: OutlinedButton(
                                              onPressed: () {
                                                if (syslogClient
                                                    .value['cifs']) {
                                                  Navigator.of(context).push(
                                                      CupertinoPageRoute(
                                                          builder: (context) {
                                                    return const LogSetting(
                                                        "cifs");
                                                  }));
                                                }
                                              },
                                              child: const Text("日志设置"),
                                            ),
                                          ),
                                          const SizedBox(
                                            width: 20,
                                          ),
                                          Expanded(
                                            child: OutlinedButton(
                                              onPressed: () {
                                                Navigator.of(context).push(
                                                    CupertinoPageRoute(
                                                        builder: (context) {
                                                  return const LogCenter();
                                                }));
                                              },
                                              child: const Text(
                                                "查看日志",
                                              ),
                                            ),
                                          ),
                                        ],
                                      )
                                    ],
                                  ],
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(
                            height: 20,
                          ),
                          Card(
                            shape: RoundedRectangleBorder(
                                side: const BorderSide(),
                                borderRadius: BorderRadius.circular(18)),
                            margin: const EdgeInsets.only(left: 20, right: 20),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "AFP",
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(
                                    height: 20,
                                  ),
                                  SettingsToggleTile(
                                    label: "启用AFP服务",
                                    value: afp.value['enable_afp'],
                                    onTap: () {
                                      afp.value['enable_afp'] =
                                          !afp.value['enable_afp'];
                                      afp.notifyListeners();
                                    },
                                  ),
                                  if (afp.value['enable_afp']) ...[
                                    const SizedBox(
                                      height: 20,
                                    ),
                                    SettingsToggleTile(
                                      label: "启动传输日志",
                                      value: syslogClient.value['afp'],
                                      onTap: () {
                                        syslogClient.value['afp'] =
                                            !syslogClient.value['afp'];
                                        syslogClient.notifyListeners();
                                      },
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(
                            height: 20,
                          ),
                          Card(
                            shape: RoundedRectangleBorder(
                                side: const BorderSide(),
                                borderRadius: BorderRadius.circular(18)),
                            margin: const EdgeInsets.only(left: 20, right: 20),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "NFS",
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(
                                    height: 20,
                                  ),
                                  SettingsToggleTile(
                                    label: "启用NFS服务",
                                    value: nfs.value['enable_nfs'],
                                    onTap: () {
                                      nfs.value['enable_nfs'] =
                                          !nfs.value['enable_nfs'];
                                      nfs.notifyListeners();
                                    },
                                  ),
                                  if (nfs.value['enable_nfs']) ...[
                                    const SizedBox(
                                      height: 20,
                                    ),
                                    SettingsToggleTile(
                                      label: "启用 NFSv4.1 支持",
                                      value: nfs.value['enable_nfs_v4'],
                                      onTap: () {
                                        nfs.value['enable_nfs_v4'] =
                                            !nfs.value['enable_nfs_v4'];
                                        nfs.notifyListeners();
                                      },
                                    ),
                                  ],
                                  if (nfs.value['enable_nfs'] &&
                                      nfs.value['enable_nfs_v4']) ...[
                                    const SizedBox(
                                      height: 20,
                                    ),
                                    SettingsTextField(
                                      controller: nfsv4Controller,
                                      label: "NFSv4 域",
                                      onChanged: (v) =>
                                          nfs.value['nfs_v4_domain'] = v,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(
                            height: 20,
                          ),
                        ],
                      ),
                      ListView(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        children: [
                          Card(
                            shape: RoundedRectangleBorder(
                                side: const BorderSide(),
                                borderRadius: BorderRadius.circular(18)),
                            margin: const EdgeInsets.only(left: 20, right: 20),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "FTP/FTPS",
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(
                                    height: 20,
                                  ),
                                  SettingsToggleTile(
                                    label: "启用FTP服务",
                                    value: ftp.value['enable_ftp'],
                                    onTap: () {
                                      ftp.value['enable_ftp'] =
                                          !ftp.value['enable_ftp'];
                                      ftp.notifyListeners();
                                    },
                                  ),
                                  const SizedBox(
                                    height: 20,
                                  ),
                                  SettingsToggleTile(
                                    label: "启用 FTP SSL/TLS 加密服务（FTPS）",
                                    value: ftp.value['enable_ftps'],
                                    onTap: () {
                                      ftp.value['enable_ftps'] =
                                          !ftp.value['enable_ftps'];
                                      ftp.notifyListeners();
                                    },
                                  ),
                                  if (ftp.value['enable_ftps']) ...[
                                    const SizedBox(
                                      height: 20,
                                    ),
                                    SettingsTextField(
                                      controller: timeoutController,
                                      label: "超时(1-7200秒)",
                                      onChanged: (v) {
                                        try {
                                          ftp.value['timeout'] = int.parse(v);
                                        } catch (e) {
                                          Log.log("parse ftp timeout error $e");
                                        }
                                      },
                                      keyboardType: TextInputType.number,
                                    ),
                                    const SizedBox(
                                      height: 20,
                                    ),
                                    SettingsTextField(
                                      controller: ftpPortController,
                                      label: "FTP 服务所使用的端口号",
                                      onChanged: (v) {
                                        try {
                                          ftp.value['portnum'] = int.parse(v);
                                        } catch (e) {
                                          Log.log(
                                              "parse ftp portnum error: $e");
                                        }
                                      },
                                      keyboardType: TextInputType.number,
                                    ),
                                    const SizedBox(
                                      height: 20,
                                    ),
                                    SettingsToggleTile(
                                      label: "启用 FXP",
                                      value: ftp.value['enable_fxp'],
                                      onTap: () {
                                        ftp.value['enable_fxp'] =
                                            !ftp.value['enable_fxp'];
                                        ftp.notifyListeners();
                                      },
                                    ),
                                    const SizedBox(
                                      height: 20,
                                    ),
                                    SettingsToggleTile(
                                      label: "启用 FIPS 加密模块",
                                      value: ftp.value['enable_fips'],
                                      onTap: () {
                                        ftp.value['enable_fips'] =
                                            !ftp.value['enable_fips'];
                                        ftp.notifyListeners();
                                      },
                                    ),
                                    const SizedBox(
                                      height: 20,
                                    ),
                                    SettingsToggleTile(
                                      label: "支持 ASCII 传送模式",
                                      value: ftp.value['enable_ascii'],
                                      onTap: () {
                                        ftp.value['enable_ascii'] =
                                            !ftp.value['enable_ascii'];
                                        ftp.notifyListeners();
                                      },
                                    ),
                                    const SizedBox(
                                      height: 20,
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        FocusScope.of(context).unfocus();
                                        showCupertinoModalPopup(
                                          context: context,
                                          builder: (context) {
                                            return NeuPicker(
                                              utf8Modes,
                                              value: ftp.value['utf8_mode'],
                                              onConfirm: (v) {
                                                ftp.value['utf8_mode'] = v;
                                                ftp.notifyListeners();
                                              },
                                            );
                                          },
                                        );
                                      },
                                      child: Card(
                                        shape: RoundedRectangleBorder(
                                            side: const BorderSide(),
                                            borderRadius:
                                                BorderRadius.circular(5)),
                                        child: Padding(
                                          padding: const EdgeInsets.all(
                                              AppConstants.paddingSmall),
                                          child: Row(
                                            children: [
                                              const Text("UTF-8 编码:"),
                                              const Spacer(),
                                              Text(utf8Modes[
                                                  ftp.value['utf8_mode']]),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(
                            height: 20,
                          ),
                          Card(
                            shape: RoundedRectangleBorder(
                                side: const BorderSide(),
                                borderRadius: BorderRadius.circular(18)),
                            margin: const EdgeInsets.only(left: 20, right: 20),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "SFTP",
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(
                                    height: 20,
                                  ),
                                  SettingsToggleTile(
                                    label: "启用SFTP服务",
                                    value: sftp.value['enable'],
                                    onTap: () {
                                      sftp.value['enable'] =
                                          !sftp.value['enable'];
                                      sftp.notifyListeners();
                                    },
                                  ),
                                  const SizedBox(
                                    height: 20,
                                  ),
                                  SettingsTextField(
                                    controller: sftpPortController,
                                    label: "端口号",
                                    onChanged: (v) {
                                      try {
                                        sftp.value['portnum'] = int.parse(v);
                                      } catch (e) {
                                        Log.log("parse ftp portnum error: $e");
                                      }
                                    },
                                    keyboardType: TextInputType.number,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      // Center(),
                      // Center(),
                      // Center(),
                    ],
                  ),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: OutlinedButton(
                      onPressed: () async {
                        if (saving.value) {
                          return;
                        }
                        saving.value = true;
                        try {
                          await dsmCoreFileServiceSaveForPage(
                              smb.value,
                              syslogClient.value,
                              afp.value,
                              nfs.value,
                              ftp.value,
                              sftp.value);
                          UiUtil.toast("保存成功");
                          getData(() {
                            Navigator.of(context).pop();
                          });
                        } catch (e) {
                          UiUtil.toast("保存失败");
                        } finally {
                          saving.value = false;
                        }
                      },
                      child: saving.value
                          ? const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CupertinoActivityIndicator(),
                                SizedBox(
                                  width: 20,
                                ),
                                Text(
                                  ' 保存中 ',
                                  style: TextStyle(fontSize: 18),
                                )
                              ],
                            )
                          : const Text(
                              ' 保存 ',
                              style: TextStyle(fontSize: 18),
                            ),
                    ),
                  ),
                )
              ],
            ),
    );
  }
}
