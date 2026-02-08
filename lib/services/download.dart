import 'dart:io';
import 'dart:ui';

import 'package:background_downloader/background_downloader.dart';
import 'package:garden/extensions/string.dart';
import 'package:garden/util/log.dart';
import 'package:permission_handler/permission_handler.dart';

Future<String?> enqueDownloadTask(
  String url,
  String fileName, {
  VoidCallback? onPermissionDenied,
}) async {
  //检查权限
  if (!await Permission.storage.request().isGranted) {
    onPermissionDenied?.call();
    return null;
  }
  String savePath = await downloadTargetDir();
  Log.debug("savePath:$savePath");
  Directory saveDir = Directory(savePath);
  if (!saveDir.existsSync()) {
    Directory dir = await saveDir.create(recursive: true);
    Log.debug("文件夹不存在, 创建文件夹: $dir");
  } else {
    Log.debug("文件夹已存在");
  }

  fileName = fileName.makeUniqueFileName(savePath);
  Log.debug("fileName:$fileName");
  // xross platform
  final task = DownloadTask(
    url: url,
    filename: fileName,
    directory: savePath,
  );
  final enqueState = await FileDownloader().enqueue(task);
  if (!enqueState) {
    return Future.error("队列下载任务失败!");
  }
  return task.taskId;
}
