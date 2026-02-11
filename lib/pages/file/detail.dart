import 'dart:async';
import 'package:garden/api/dsm_api.dart';
import 'package:garden/util/log.dart';
import 'package:garden/util/ui_util.dart';

import 'package:garden/util/http_util.dart';
import 'package:garden/widgets/neu_back_button.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:garden/constants/app_constants.dart';
import 'package:flutter/services.dart';

class FileDetail extends StatefulWidget {
  final Map file;
  const FileDetail(this.file, {super.key});
  @override
  FileDetailState createState() => FileDetailState();
}

class FileDetailState extends State<FileDetail> {
  Timer? timer;
  bool loadingSize = true;
  int size = 0;
  int folderCount = 0;
  int fileCount = 0;
  @override
  void initState() {
    getDirSize();
    super.initState();
  }

  @override
  dispose() {
    timer?.cancel();
    super.dispose();
  }

  getDirSize() async {
    var task = await dsmFileStationDirSizeStart(widget.file['path']);
    if (task['success']) {
      timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
        var result = await dsmFileStationDirSizeStatus(task['data']['taskid']);
        Log.info(result);
        if (result['success'] && result['data']['finished']) {
          timer.cancel();
          setState(() {
            loadingSize = false;
            size = result['data']['total_size'];
            folderCount = result['data']['num_dir'];
            fileCount = result['data']['num_file'];
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: AppBackButton(context),
        title: Text(
          widget.file['name'],
        ),
      ),
      body: ListView(
        children: [
          const SizedBox(
            height: 30,
          ),
          Card(
            shape: RoundedRectangleBorder(
                side: const BorderSide(),
                borderRadius: BorderRadius.circular(18)),
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.paddingSmall),
              child: Row(
                children: [
                  const Text("名称："),
                  Expanded(
                    child: Text(widget.file['name']),
                  ),
                ],
              ),
            ),
          ),
          Card(
            shape: RoundedRectangleBorder(
                side: const BorderSide(),
                borderRadius: BorderRadius.circular(18)),
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              child: Row(
                children: [
                  const Text("位置："),
                  Expanded(
                    child: Text(
                      widget.file['path'],
                    ),
                  ),
                  OutlinedButton(
                    onPressed: () async {
                      ClipboardData data =
                          ClipboardData(text: widget.file['path']);
                      Clipboard.setData(data);
                      UiUtil.toast("已复制到剪贴板");
                    },
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: Icon(
                        Icons.copy,
                        color: Theme.of(context).colorScheme.primary,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Card(
            shape: RoundedRectangleBorder(
                side: const BorderSide(),
                borderRadius: BorderRadius.circular(18)),
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              child: Row(
                children: [
                  const Text("路径："),
                  Expanded(
                    child: Text(
                      "${widget.file['additional']['real_path']}",
                    ),
                  ),
                  OutlinedButton(
                    onPressed: () async {
                      ClipboardData data = ClipboardData(
                          text: widget.file['additional']['real_path']);
                      Clipboard.setData(data);
                      UiUtil.toast("已复制到剪贴板");
                    },
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: Icon(
                        Icons.copy,
                        color: Theme.of(context).colorScheme.primary,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Card(
            shape: RoundedRectangleBorder(
                side: const BorderSide(),
                borderRadius: BorderRadius.circular(18)),
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.paddingSmall),
              child: Row(
                children: [
                  const Text("大小："),
                  loadingSize
                      ? const CupertinoActivityIndicator()
                      : Text(size.formatSize())
                ],
              ),
            ),
          ),
          if (widget.file['isdir'])
            Card(
              shape: RoundedRectangleBorder(
                  side: const BorderSide(),
                  borderRadius: BorderRadius.circular(18)),
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.paddingSmall),
                child: Row(
                  children: [
                    const Text("包含："),
                    loadingSize
                        ? const CupertinoActivityIndicator()
                        : Text("$folderCount个文件夹，$fileCount个文件")
                  ],
                ),
              ),
            ),
          Card(
            shape: RoundedRectangleBorder(
                side: const BorderSide(),
                borderRadius: BorderRadius.circular(18)),
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.paddingSmall),
              child: Row(
                children: [
                  const Text("创建时间："),
                  Text(DateTime.fromMillisecondsSinceEpoch(
                          widget.file['additional']['time']['ctime'] * 1000)
                      .format("Y-m-d H:i:s"))
                ],
              ),
            ),
          ),
          Card(
            shape: RoundedRectangleBorder(
                side: const BorderSide(),
                borderRadius: BorderRadius.circular(18)),
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.paddingSmall),
              child: Row(
                children: [
                  const Text("修改时间："),
                  Text(DateTime.fromMillisecondsSinceEpoch(
                          widget.file['additional']['time']['mtime'] * 1000)
                      .format("Y-m-d H:i:s"))
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
