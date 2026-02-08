import 'package:garden/pages/control_panel/file_service/log_setting.dart';
import 'package:garden/util/log.dart';
import 'package:garden/util/ui_util.dart';
import 'package:garden/pages/log_center/log_center.dart';
import 'package:garden/util/http_util.dart';
import 'package:garden/widgets/neu_picker.dart';
import 'package:garden/widgets/bubble_tab_indicator.dart';
import 'package:garden/widgets/neu_back_button.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:garden/constants/app_constants.dart';
import 'package:garden/theme/app_colors.dart';
import 'package:flutter/services.dart';

class FileService extends StatefulWidget {
  const FileService({super.key});

  @override
  FileServiceState createState() => FileServiceState();
}

class FileServiceState extends State<FileService>
    with SingleTickerProviderStateMixin {
  final TextEditingController _workgroupController = TextEditingController();
  final TextEditingController _nfsv4Controller = TextEditingController();
  final TextEditingController _timeoutController = TextEditingController();
  final TextEditingController _ftpPortController = TextEditingController();
  final TextEditingController _sftpPortController = TextEditingController();
  List<String> utf8Modes = ['禁用', '自动', '强制'];
  bool loading = true;
  late TabController _tabController;
  Map smb = {};
  Map afp = {};
  Map nfs = {};
  Map ftp = {};
  Map sftp = {};
  Map bandwidth = {};
  Map tftp = {};
  Map backup = {};
  Map serviceDiscovery = {};
  Map bonjourSharing = {};
  Map syslogClient = {};
  bool enableWstransfer = false;
  bool saving = false;
  @override
  void initState() {
    _tabController = TabController(length: 2, vsync: this);
    getData(() {
      Navigator.of(context).pop();
    });
    super.initState();
  }

  getData(Function onFailure) async {
    var res = await DsmApi.fileService();
    Log.log("FileService: $res");
    if (res['success']) {
      setState(() {
        loading = false;
      });
      if (res['data']['has_fail']) {
        UiUtil.toast("加载失败");

        onFailure();
        return;
      }
      List result = res['data']['result'];
      for (var item in result) {
        if (item['success'] == true) {
          switch (item['api']) {
            case "SYNO.Core.FileServ.SMB":
              setState(() {
                smb = item['data'];
                _workgroupController.value =
                    TextEditingValue(text: smb['workgroup'] ?? "");
              });
              break;
            case "SYNO.Core.FileServ.AFP":
              setState(() {
                afp = item['data'];
              });
              break;
            case "SYNO.Core.FileServ.NFS":
              setState(() {
                nfs = item['data'];
              });
              _nfsv4Controller.value =
                  TextEditingValue(text: nfs['nfs_v4_domain'] ?? "");
              break;
            case "SYNO.Core.FileServ.FTP":
              setState(() {
                ftp = item['data'];
                _timeoutController.value =
                    TextEditingValue(text: "${ftp['timeout']}");
                _ftpPortController.value =
                    TextEditingValue(text: "${ftp['portnum']}");
              });
              break;
            case "SYNO.Core.FileServ.FTP.SFTP":
              setState(() {
                sftp = item['data'];
                Log.log("SFTP: $sftp");
                _sftpPortController.value =
                    TextEditingValue(text: "${sftp['portnum']}");
              });
              break;
            case "SYNO.Core.BandwidthControl.Protocol":
              setState(() {
                bandwidth = item['data'];
              });
              break;
            case "SYNO.Core.TFTP":
              setState(() {
                tftp = item['data'];
              });
              break;
            case "SYNO.Backup.Service.NetworkBackup":
              setState(() {
                backup = item['data'];
              });
              break;
            case "SYNO.Core.ExternalDevice.Printer.BonjourSharing":
              setState(() {
                bonjourSharing = item['data'];
              });
              break;
            case "SYNO.Core.FileServ.ServiceDiscovery":
              setState(() {
                serviceDiscovery = item['data'];
              });
              break;
            case "SYNO.Core.SyslogClient.FileTransfer":
              setState(() {
                syslogClient = item['data'];
              });
              break;
            case "SYNO.Core.FileServ.ServiceDiscovery.WSTransfer":
              setState(() {
                enableWstransfer = item['data']['enable_wstransfer'];
              });
              break;
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: AppBackButton(context),
        title: const Text("文件服务"),
      ),
      body: loading
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
                      controller: _tabController,
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
                    controller: _tabController,
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
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        smb['enable_samba'] =
                                            !smb['enable_samba'];
                                      });
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
                                            const Expanded(
                                              child: Text(
                                                "启用SMB服务",
                                              ),
                                            ),
                                            if (smb['enable_samba'])
                                              Icon(
                                                CupertinoIcons.checkmark_alt,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .primary,
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (smb['enable_samba']) ...[
                                    const SizedBox(
                                      height: 20,
                                    ),
                                    Card(
                                      shape: RoundedRectangleBorder(
                                          side: const BorderSide(),
                                          borderRadius:
                                              BorderRadius.circular(5)),
                                      child: Padding(
                                        padding: const EdgeInsets.all(
                                            AppConstants.paddingSmall),
                                        child: TextField(
                                          controller: _workgroupController,
                                          onChanged: (v) =>
                                              smb['workgroup'] = v,
                                          decoration: const InputDecoration(
                                            border: InputBorder.none,
                                            labelText: '工作群组',
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(
                                      height: 20,
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          smb['disable_shadow_copy'] =
                                              !smb['disable_shadow_copy'];
                                        });
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
                                              const Expanded(
                                                child: Text(
                                                  "不可访问以前版本",
                                                ),
                                              ),
                                              if (smb['disable_shadow_copy'])
                                                const Icon(
                                                  CupertinoIcons.checkmark_alt,
                                                  color:
                                                      AppColors.primaryAction,
                                                ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(
                                      height: 20,
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          syslogClient['cifs'] =
                                              !syslogClient['cifs'];
                                        });
                                        if (syslogClient['cifs']) {
                                          Navigator.of(context).push(
                                              CupertinoPageRoute(
                                                  builder: (context) {
                                            return const LogSetting("cifs");
                                          }));
                                        }
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
                                              const Expanded(
                                                child: Text(
                                                  "启动传输日志",
                                                ),
                                              ),
                                              if (syslogClient['cifs'])
                                                const Icon(
                                                  CupertinoIcons.checkmark_alt,
                                                  color:
                                                      AppColors.primaryAction,
                                                ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    if (syslogClient['cifs']) ...[
                                      const SizedBox(
                                        height: 20,
                                      ),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: OutlinedButton(
                                              onPressed: () {
                                                if (syslogClient['cifs']) {
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
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        afp['enable_afp'] = !afp['enable_afp'];
                                      });
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
                                            const Expanded(
                                              child: Text(
                                                "启用AFP服务",
                                              ),
                                            ),
                                            if (afp['enable_afp'])
                                              Icon(
                                                CupertinoIcons.checkmark_alt,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .primary,
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (afp['enable_afp']) ...[
                                    const SizedBox(
                                      height: 20,
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          syslogClient['afp'] =
                                              !syslogClient['afp'];
                                        });
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
                                              const Expanded(
                                                child: Text(
                                                  "启动传输日志",
                                                ),
                                              ),
                                              if (syslogClient['afp'])
                                                const Icon(
                                                  CupertinoIcons.checkmark_alt,
                                                  color:
                                                      AppColors.primaryAction,
                                                ),
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
                                    "NFS",
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(
                                    height: 20,
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        nfs['enable_nfs'] = !nfs['enable_nfs'];
                                      });
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
                                            const Expanded(
                                              child: Text(
                                                "启用NFS服务",
                                              ),
                                            ),
                                            if (nfs['enable_nfs'])
                                              Icon(
                                                CupertinoIcons.checkmark_alt,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .primary,
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (nfs['enable_nfs']) ...[
                                    const SizedBox(
                                      height: 20,
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          nfs['enable_nfs_v4'] =
                                              !nfs['enable_nfs_v4'];
                                        });
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
                                              const Expanded(
                                                child: Text(
                                                  "启用 NFSv4.1 支持",
                                                ),
                                              ),
                                              if (nfs['enable_nfs_v4'])
                                                const Icon(
                                                  CupertinoIcons.checkmark_alt,
                                                  color:
                                                      AppColors.primaryAction,
                                                ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                  if (nfs['enable_nfs'] &&
                                      nfs['enable_nfs_v4']) ...[
                                    const SizedBox(
                                      height: 20,
                                    ),
                                    Card(
                                      shape: RoundedRectangleBorder(
                                          side: const BorderSide(),
                                          borderRadius:
                                              BorderRadius.circular(5)),
                                      child: Padding(
                                        padding: const EdgeInsets.all(
                                            AppConstants.paddingSmall),
                                        child: TextField(
                                          controller: _nfsv4Controller,
                                          onChanged: (v) =>
                                              nfs['nfs_v4_domain'] = v,
                                          decoration: const InputDecoration(
                                            border: InputBorder.none,
                                            labelText: 'NFSv4 域',
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
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        ftp['enable_ftp'] = !ftp['enable_ftp'];
                                      });
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
                                            const Expanded(
                                              child: Text(
                                                "启用FTP服务",
                                              ),
                                            ),
                                            if (ftp['enable_ftp'])
                                              Icon(
                                                CupertinoIcons.checkmark_alt,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .primary,
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(
                                    height: 20,
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        ftp['enable_ftps'] =
                                            !ftp['enable_ftps'];
                                      });
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
                                            const Expanded(
                                              child: Text(
                                                "启用 FTP SSL/TLS 加密服务（FTPS）",
                                              ),
                                            ),
                                            if (ftp['enable_ftps'])
                                              Icon(
                                                CupertinoIcons.checkmark_alt,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .primary,
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (ftp['enable_ftps']) ...[
                                    const SizedBox(
                                      height: 20,
                                    ),
                                    Card(
                                      shape: RoundedRectangleBorder(
                                          side: const BorderSide(),
                                          borderRadius:
                                              BorderRadius.circular(5)),
                                      child: Padding(
                                        padding: const EdgeInsets.all(
                                            AppConstants.paddingSmall),
                                        child: TextField(
                                          controller: _timeoutController,
                                          onChanged: (v) {
                                            try {
                                              ftp['timeout'] = int.parse(v);
                                            } catch (e) {
                                              Log.log(
                                                  "parse ftp timeout error $e");
                                            }
                                          },
                                          keyboardType: TextInputType.number,
                                          inputFormatters: [
                                            FilteringTextInputFormatter
                                                .digitsOnly,
                                          ],
                                          decoration: const InputDecoration(
                                            border: InputBorder.none,
                                            labelText: '超时(1-7200秒)',
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(
                                      height: 20,
                                    ),
                                    Card(
                                      shape: RoundedRectangleBorder(
                                          side: const BorderSide(),
                                          borderRadius:
                                              BorderRadius.circular(5)),
                                      child: Padding(
                                        padding: const EdgeInsets.all(
                                            AppConstants.paddingSmall),
                                        child: TextField(
                                          controller: _ftpPortController,
                                          onChanged: (v) {
                                            try {
                                              ftp['portnum'] = int.parse(v);
                                            } catch (e) {
                                              Log.log(
                                                  "parse ftp portnum error: $e");
                                            }
                                          },
                                          keyboardType: TextInputType.number,
                                          inputFormatters: [
                                            FilteringTextInputFormatter
                                                .digitsOnly,
                                          ],
                                          decoration: const InputDecoration(
                                            border: InputBorder.none,
                                            labelText: 'FTP 服务所使用的端口号',
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(
                                      height: 20,
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          ftp['enable_fxp'] =
                                              !ftp['enable_fxp'];
                                        });
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
                                              const Expanded(
                                                child: Text(
                                                  "启用 FXP",
                                                ),
                                              ),
                                              if (ftp['enable_fxp'])
                                                const Icon(
                                                  CupertinoIcons.checkmark_alt,
                                                  color:
                                                      AppColors.primaryAction,
                                                ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(
                                      height: 20,
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          ftp['enable_fips'] =
                                              !ftp['enable_fips'];
                                        });
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
                                              const Expanded(
                                                child: Text(
                                                  "启用 FIPS 加密模块",
                                                ),
                                              ),
                                              if (ftp['enable_fips'])
                                                const Icon(
                                                  CupertinoIcons.checkmark_alt,
                                                  color:
                                                      AppColors.primaryAction,
                                                ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(
                                      height: 20,
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          ftp['enable_ascii'] =
                                              !ftp['enable_ascii'];
                                        });
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
                                              const Expanded(
                                                child: Text(
                                                  "支持 ASCII 传送模式",
                                                ),
                                              ),
                                              if (ftp['enable_ascii'])
                                                const Icon(
                                                  CupertinoIcons.checkmark_alt,
                                                  color:
                                                      AppColors.primaryAction,
                                                ),
                                            ],
                                          ),
                                        ),
                                      ),
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
                                              value: ftp['utf8_mode'],
                                              onConfirm: (v) {
                                                setState(() {
                                                  ftp['utf8_mode'] = v;
                                                });
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
                                              Text(utf8Modes[ftp['utf8_mode']]),
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
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        sftp['enable'] = !sftp['enable'];
                                      });
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
                                            const Expanded(
                                              child: Text(
                                                "启用SFTP服务",
                                              ),
                                            ),
                                            if (sftp['enable'])
                                              Icon(
                                                CupertinoIcons.checkmark_alt,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .primary,
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(
                                    height: 20,
                                  ),
                                  Card(
                                    shape: RoundedRectangleBorder(
                                        side: const BorderSide(),
                                        borderRadius:
                                            BorderRadius.circular(18)),
                                    child: Padding(
                                      padding: const EdgeInsets.all(
                                          AppConstants.paddingSmall),
                                      child: TextField(
                                        controller: _sftpPortController,
                                        onChanged: (v) {
                                          try {
                                            sftp['portnum'] = int.parse(v);
                                          } catch (e) {
                                            Log.log(
                                                "parse ftp portnum error: $e");
                                          }
                                        },
                                        keyboardType: TextInputType.number,
                                        inputFormatters: [
                                          FilteringTextInputFormatter
                                              .digitsOnly,
                                        ],
                                        decoration: const InputDecoration(
                                          border: InputBorder.none,
                                          labelText: '端口号',
                                        ),
                                      ),
                                    ),
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
                        if (saving) {
                          return;
                        }
                        setState(() {
                          saving = true;
                        });
                        var res = await DsmApi.fileServiceSave(
                            smb, syslogClient, afp, nfs, ftp, sftp);

                        if (res['success']) {
                          setState(() {
                            saving = false;
                          });
                          UiUtil.toast("保存成功");
                          getData(() {
                            Navigator.of(context).pop();
                          });
                        }
                      },
                      child: saving
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
