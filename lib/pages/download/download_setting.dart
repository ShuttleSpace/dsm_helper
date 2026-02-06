import 'dart:io';
import 'package:garden/util/storage_util.dart';
import 'package:garden/util/ui_util.dart';
import 'package:garden/stores/settings_store.dart';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:garden/pages/common/select_local_folder.dart';
import 'package:garden/widgets/neu_back_button.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:garden/constants/app_constants.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:signals/signals_flutter.dart';

class DownloadSetting extends StatefulWidget {
  const DownloadSetting({super.key});

  @override
  DownloadSettingState createState() => DownloadSettingState();
}

class DownloadSettingState extends State<DownloadSetting> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: AppBackButton(context),
        title: const Text("下载选项"),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppConstants.paddingLarge),
        children: [
          if (Platform.isAndroid) ...[
            OutlinedButton(
              onPressed: () async {
                DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
                AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
                if (Platform.isAndroid && androidInfo.version.sdkInt >= 30) {
                  bool permission = false;
                  permission = await Permission.manageExternalStorage
                      .request()
                      .isGranted;
                  if (!permission) {
                    UiUtil.toast("安卓11以上需授权文件管理权限");
                    return;
                  }
                } else {
                  bool permission = false;
                  permission = await Permission.storage.request().isGranted;
                  if (!permission) {
                    UiUtil.toast("请先授权APP访问存储权限");
                    return;
                  }
                }

                if (context.mounted) {
                  showCupertinoModalPopup<List<FileSystemEntity>>(
                    context: context,
                    builder: (context) {
                      return const SelectLocalFolder(
                        multi: false,
                        folder: true,
                      );
                    },
                  ).then((res) {
                    if (res != null && res.length == 1) {
                      setState(() {
                        settingsStore.setDownloadSavePath(res[0].path);
                        StorageUtil.setString(
                            "download_save_path", res[0].path);
                      });
                    }
                  });
                }
              },
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "下载位置",
                          style: TextStyle(fontSize: 12),
                        ),
                        Text(
                          settingsStore.downloadSavePath.watch(context),
                          style:
                              const TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(
              height: 20,
            ),
          ],
        ],
      ),
    );
  }
}
