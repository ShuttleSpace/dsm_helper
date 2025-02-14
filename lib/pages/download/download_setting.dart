import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:humphrey_garden/pages/common/select_local_folder.dart';
import 'package:humphrey_garden/util/function.dart';
import 'package:humphrey_garden/widgets/neu_back_button.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class DownloadSetting extends StatefulWidget {
  @override
  _DownloadSettingState createState() => _DownloadSettingState();
}

class _DownloadSettingState extends State<DownloadSetting> {
  String downloadPath = '';
  @override
  void initState() {
    Util.instance.getDownloadPath().then((value) {
      setState(() {
        downloadPath = value;
      });
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: AppBackButton(context),
        title: Text("下载选项"),
      ),
      body: ListView(
        padding: EdgeInsets.all(20.0),
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
                    Util.instance.toast("安卓11以上需授权文件管理权限");
                    return;
                  }
                } else {
                  bool permission = false;
                  permission = await Permission.storage.request().isGranted;
                  if (!permission) {
                    Util.instance.toast("请先授权APP访问存储权限");
                    return;
                  }
                }

                showCupertinoModalPopup<List<FileSystemEntity>>(
                  context: context,
                  builder: (context) {
                    return SelectLocalFolder(
                      multi: false,
                      folder: true,
                    );
                  },
                ).then((res) {
                  if (res != null && res.length == 1) {
                    setState(() {
                      downloadPath = res[0].path;
                      Util.instance.downloadSavePath = res[0].path;
                      Util.instance
                          .setStorage("download_save_path", res[0].path);
                    });
                  }
                });
              },
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "下载位置",
                          style: TextStyle(fontSize: 12),
                        ),
                        Text(
                          downloadPath,
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 20,
            ),
          ],
        ],
      ),
    );
  }
}
