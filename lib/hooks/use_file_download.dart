import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/widgets.dart';
import 'package:garden/extensions/string.dart';
import 'package:garden/pages/download/download_state.dart';
import 'package:garden/services/transfer_download.dart';
import 'package:garden/stores/transfer_store.dart';
import 'package:garden/util/log.dart';
import 'package:garden/util/ui_util.dart';
import 'package:permission_handler/permission_handler.dart';

typedef DownloadFilesFn = Future<void> Function(List files);

/// 文件下载复用 hook：把 DSM 文件加入 app 自带的后台传输引擎
/// （background_downloader + /fbdownload），并在传输列表登记。
/// 文件列表与文件详情页共用，避免重复实现权限/入队/登记逻辑。
DownloadFilesFn useFileDownload(BuildContext context) {
  return (List files) async {
    if (files.isEmpty) return;
    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      final granted = androidInfo.version.sdkInt >= 30
          ? await Permission.manageExternalStorage.request().isGranted
          : await Permission.storage.request().isGranted;
      if (!granted) {
        UiUtil.toast(androidInfo.version.sdkInt >= 30
            ? "安卓11以上需授权文件管理权限"
            : "请先授权APP访问存储权限");
        return;
      }
    }

    final destDir = await downloadTargetDir();
    var ok = 0;
    for (final file in files) {
      try {
        final taskId = await enqueueFileDownload(
          remotePath: file['path'] as String,
          destDir: destDir,
          destName: file['isdir'] == true
              ? "${file['name']}.zip"
              : file['name'] as String,
        );
        transferStore.add(TransferTask(
          id: taskId,
          type: TransferType.download,
          localPath: destDir,
          remotePath: file['path'] as String,
          state: TransferState.active,
        ));
        ok++;
      } catch (e) {
        Log.error("download failed: $e");
      }
    }
    UiUtil.toast(ok > 0
        ? "已添加${ok > 1 ? "$ok个" : ""}下载任务，请至下载页面查看"
        : "添加下载任务失败");
    if (context.mounted) {
      DownloadStateInherited.of(context)?.notifier.runLoop();
    }
  };
}
