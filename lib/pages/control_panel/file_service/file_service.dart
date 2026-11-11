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
      var res = await DsmApi.fileService();
      Log.log("FileService: $res");
      if (res['success']) {
        loading.value = false;
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
                                  GestureDetector(
                                    onTap: () {
                                      smb.value['enable_samba'] =
                                          !smb.value['enable_samba'];
                                      smb.notifyListeners();

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
                                            if (smb.value['enable_samba'])
                                              const Icon(
                                                CupertinoIcons.checkmark_alt,
                                                color: AppColors.primaryAction,
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (smb.value['enable_samba']) ...[
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
                                          controller: workgroupController,
                                          onChanged: (v) =>
                                              smb.value['workgroup'] = v,
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
                                        smb.value['disable_shadow_copy'] =
                                            !smb.value['disable_shadow_copy'];
                                        smb.notifyListeners();

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
                                              if (smb.value['disable_shadow_copy'])
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
                                              if (syslogClient.value['cifs'])
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
                                    if (syslogClient.value['cifs']) ...[
                                      const SizedBox(
                                        height: 20,
                                      ),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: OutlinedButton(
                                              onPressed: () {
                                                if (syslogClient.value['cifs']) {
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
                                      afp.value['enable_afp'] = !afp.value['enable_afp'];
                                      afp.notifyListeners();

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
                                            if (afp.value['enable_afp'])
                                              const Icon(
                                                CupertinoIcons.checkmark_alt,
                                                color: AppColors.primaryAction,
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (afp.value['enable_afp']) ...[
                                    const SizedBox(
                                      height: 20,
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        syslogClient.value['afp'] =
                                            !syslogClient.value['afp'];
                                        syslogClient.notifyListeners();

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
                                              if (syslogClient.value['afp'])
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
                                      nfs.value['enable_nfs'] = !nfs.value['enable_nfs'];
                                      nfs.notifyListeners();

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
                                            if (nfs.value['enable_nfs'])
                                              const Icon(
                                                CupertinoIcons.checkmark_alt,
                                                color: AppColors.primaryAction,
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (nfs.value['enable_nfs']) ...[
                                    const SizedBox(
                                      height: 20,
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        nfs.value['enable_nfs_v4'] =
                                            !nfs.value['enable_nfs_v4'];
                                        nfs.notifyListeners();

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
                                              if (nfs.value['enable_nfs_v4'])
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
                                  if (nfs.value['enable_nfs'] &&
                                      nfs.value['enable_nfs_v4']) ...[
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
                                          controller: nfsv4Controller,
                                          onChanged: (v) =>
                                              nfs.value['nfs_v4_domain'] = v,
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
                                      ftp.value['enable_ftp'] = !ftp.value['enable_ftp'];
                                      ftp.notifyListeners();

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
                                            if (ftp.value['enable_ftp'])
                                              const Icon(
                                                CupertinoIcons.checkmark_alt,
                                                color: AppColors.primaryAction,
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
                                      ftp.value['enable_ftps'] =
                                          !ftp.value['enable_ftps'];
                                      ftp.notifyListeners();

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
                                            if (ftp.value['enable_ftps'])
                                              const Icon(
                                                CupertinoIcons.checkmark_alt,
                                                color: AppColors.primaryAction,
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (ftp.value['enable_ftps']) ...[
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
                                          controller: timeoutController,
                                          onChanged: (v) {
                                            try {
                                              ftp.value['timeout'] = int.parse(v);
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
                                          controller: ftpPortController,
                                          onChanged: (v) {
                                            try {
                                              ftp.value['portnum'] = int.parse(v);
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
                                        ftp.value['enable_fxp'] =
                                            !ftp.value['enable_fxp'];
                                        ftp.notifyListeners();

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
                                              if (ftp.value['enable_fxp'])
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
                                        ftp.value['enable_fips'] =
                                            !ftp.value['enable_fips'];
                                        ftp.notifyListeners();

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
                                              if (ftp.value['enable_fips'])
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
                                        ftp.value['enable_ascii'] =
                                            !ftp.value['enable_ascii'];
                                        ftp.notifyListeners();

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
                                              if (ftp.value['enable_ascii'])
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
                                              Text(utf8Modes[ftp.value['utf8_mode']]),
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
                                      sftp.value['enable'] = !sftp.value['enable'];
                                      sftp.notifyListeners();

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
                                            if (sftp.value['enable'])
                                              const Icon(
                                                CupertinoIcons.checkmark_alt,
                                                color: AppColors.primaryAction,
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
                                        controller: sftpPortController,
                                        onChanged: (v) {
                                          try {
                                            sftp.value['portnum'] = int.parse(v);
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
                        if (saving.value) {
                          return;
                        }
                        saving.value = true;

                        var res = await DsmApi.fileServiceSave(smb.value,
                            syslogClient.value, afp.value, nfs.value,
                            ftp.value, sftp.value);

                        if (res['success']) {
                          saving.value = false;

                          UiUtil.toast("保存成功");
                          getData(() {
                            Navigator.of(context).pop();
                          });
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
