import 'dart:async';
import 'package:garden/util/log.dart';
import 'package:garden/util/ui_util.dart';

import 'package:garden/api/dsm_api.dart';
import 'package:garden/extensions/datetime.dart';
import 'package:garden/extensions/int.dart';
import 'package:garden/widgets/neu_back_button.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:garden/constants/app_constants.dart';
import 'package:garden/theme/app_colors.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:signals_hooks/signals_hooks.dart';
import 'package:garden/hooks/use_file_download.dart';

class FileDetail extends HookWidget {
  final Map file;
  const FileDetail(this.file, {super.key});

  @override
  Widget build(BuildContext context) {
    final timer = useRef<Timer?>(null);
    final loadingSize = useSignal(true);
    final size = useSignal(0);
    final folderCount = useSignal(0);
    final fileCount = useSignal(0);
    final appDownload = useFileDownload(context);

    getDirSize() async {
      try {
        final task = await dsmControlPanelPost({
          "api": '"SYNO.FileStation.DirSize"',
          "method": '"start"',
          "version": 1,
          "path": file['path'],
        });
        final taskId = task['taskid'];
        timer.value = Timer.periodic(const Duration(seconds: 1), (timer) async {
          try {
            final result = await dsmControlPanelPost({
              "api": '"SYNO.FileStation.DirSize"',
              "method": '"status"',
              "version": 1,
              "taskid": taskId,
            });
            Log.info(result);
            if (result['finished'] == true) {
              timer.cancel();
              loadingSize.value = false;
              size.value = result['total_size'] ?? 0;
              folderCount.value = result['num_dir'] ?? 0;
              fileCount.value = result['num_file'] ?? 0;
            }
          } catch (e) {
            timer.cancel();
          }
        });
      } catch (e) {
        loadingSize.value = false;
      }
    }

    useEffect(() {
      getDirSize();
      return () => timer.value?.cancel();
    }, const []);

    return Scaffold(
      appBar: AppBar(
        leading: AppBackButton(context),
        title: Text(
          file['name'],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: '下载',
            onPressed: () => appDownload([file]),
          ),
        ],
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
                    child: Text(file['name']),
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
                      file['path'],
                    ),
                  ),
                  OutlinedButton(
                    onPressed: () async {
                      ClipboardData data =
                          ClipboardData(text: file['path']);
                      Clipboard.setData(data);
                      UiUtil.toast("已复制到剪贴板");
                    },
                    child: const SizedBox(
                      width: 20,
                      height: 20,
                      child: Icon(
                        Icons.copy,
                        color: AppColors.primaryAction,
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
                      "${file['additional']['real_path']}",
                    ),
                  ),
                  OutlinedButton(
                    onPressed: () async {
                      ClipboardData data = ClipboardData(
                          text: file['additional']['real_path']);
                      Clipboard.setData(data);
                      UiUtil.toast("已复制到剪贴板");
                    },
                    child: const SizedBox(
                      width: 20,
                      height: 20,
                      child: Icon(
                        Icons.copy,
                        color: AppColors.primaryAction,
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
                  loadingSize.value
                      ? const CupertinoActivityIndicator()
                      : Text(size.value.formatSize())
                ],
              ),
            ),
          ),
          if (file['isdir'])
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
                    loadingSize.value
                        ? const CupertinoActivityIndicator()
                        : Text(
                            "${folderCount.value}个文件夹，${fileCount.value}个文件")
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
                          file['additional']['time']['ctime'] * 1000)
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
                          file['additional']['time']['mtime'] * 1000)
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
