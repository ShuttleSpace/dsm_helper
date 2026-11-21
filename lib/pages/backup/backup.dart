import 'dart:convert';
import 'package:background_downloader/background_downloader.dart';
import 'package:garden/stores/transfer_store.dart';
import 'package:garden/services/transfer_upload.dart';
import 'package:path_provider/path_provider.dart';
import 'package:garden/util/log.dart';
import 'package:garden/util/ui_util.dart';
import 'package:garden/util/storage_util.dart';
import 'package:garden/stores/connection_store.dart';
import 'dart:io';
import 'dart:ui';

import 'package:cool_ui/cool_ui.dart';
import 'package:garden/pages/common/select_ablum.dart';
import 'package:garden/extensions/datetime.dart';
import 'package:garden/extensions/string.dart';
import 'package:garden/widgets/label.dart';
import 'package:garden/widgets/neu_back_button.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:garden/constants/app_constants.dart';
import 'package:garden/theme/app_colors.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:signals_hooks/signals_hooks.dart';

import 'package:garden/widgets/folder_picker_sheet.dart';

/// 把多个相册的资产展平并按 id 去重。
Future<List<AssetEntity>> collectBackupAssets(
  Iterable<AssetPathEntity> albums, {
  Future<List<AssetEntity>> Function(AssetPathEntity) fetch = _defaultAssetFetch,
}) async {
  final result = <AssetEntity>[];
  final ids = <String>{};
  for (final album in albums) {
    for (final asset in await fetch(album)) {
      if (ids.add(asset.id)) result.add(asset);
    }
  }
  return result;
}

Future<List<AssetEntity>> _defaultAssetFetch(AssetPathEntity album) =>
    album.getAssetListRange(start: 0, end: 100000000);

/// iOS 的 asset id 含 "/"，不能直接当目录名。
String backupCacheDirName(String assetId) =>
    assetId.replaceAll(RegExp(r'[^A-Za-z0-9]'), '_');

class BackupEnqueueIncomplete implements Exception {
  BackupEnqueueIncomplete(this.message);
  final String message;

  @override
  String toString() => message;
}

/// 按 modification time 过滤并排序待备份资产。
List<AssetEntity> backupPendingAssets(
  List<AssetEntity> uploads,
  DateTime? lastBackupTime,
  bool continueBackup,
) {
  final since = lastBackupTime?.millisecondsSinceEpoch ?? 0;
  final result = uploads
      .where((a) =>
          !continueBackup || a.modifiedDateTime.millisecondsSinceEpoch > since)
      .toList();
  result.sort((a, b) => a.modifiedDateTime.compareTo(b.modifiedDateTime));
  return result;
}

/// 把每张照片作为一个子步骤入队，整体作为一条父任务。
Future<TransferTask> startBackup({
  required String backupFolder,
  required List<AssetEntity> assets,
  required Future<String> Function(String cachePath, String remoteDir) enqueue,
  required Directory cacheRoot,
  Future<void> Function(String stepId)? cancelEnqueued,
}) async {
  final parent = TransferTask(
    id: 'backup_${DateTime.now().microsecondsSinceEpoch}',
    type: TransferType.upload,
    localPath: '',
    remotePath: backupFolder,
    state: TransferState.queued,
    steps: const [],
  );
  transferStore.add(parent);
  final enqueued = <String>[];
  for (final asset in assets) {
    try {
      final file = await asset.originFile;
      if (file == null) throw const FileSystemException('asset file missing');
      final dir = Directory('${cacheRoot.path}/${backupCacheDirName(asset.id)}')
        ..createSync(recursive: true);
      final filename = file.path.split(Platform.pathSeparator).last;
      final cachePath = '${dir.path}${Platform.pathSeparator}$filename';
      await file.copy(cachePath);
      File(cachePath).setLastModifiedSync(asset.modifiedDateTime);
      final taskId = await enqueue(cachePath, backupFolder);
      enqueued.add(taskId);
      transferStore.addStep(parent.id, TransferStep(
        id: taskId,
        localPath: cachePath,
        remotePath: remoteDir(backupFolder, filename),
        state: TransferState.active,
        modifyTime: asset.modifiedDateTime,
      ));
    } catch (e) {
      for (final stepId in enqueued) {
        await cancelEnqueued?.call(stepId);
        transferStore.setError(stepId, '备份入队未完成: $e');
      }
      transferStore.setError(parent.id, '备份入队未完成: $e', manual: true);
      throw BackupEnqueueIncomplete('备份入队未完成: $e');
    }
  }
  if (transferStore.tasks.value.firstWhere((t) => t.id == parent.id).steps!.isEmpty) {
    transferStore.setError(parent.id, '没有可备份的文件', manual: true);
    throw BackupEnqueueIncomplete('没有可备份的文件');
  }
  return transferStore.tasks.value.firstWhere((t) => t.id == parent.id);
}

String remoteDir(String backupFolder, String filename) =>
    backupFolder.endsWith('/') ? '$backupFolder$filename' : '$backupFolder/$filename';

bool _autoBackupRan = false;

/// 冷启动一次：读配置、解析相册、调用 startAutoBackup。不可用时静默返回 null。
Future<TransferTask?> runAutoBackup() async {
  if (_autoBackupRan) return null;
  _autoBackupRan = true;
  if (!(await StorageUtil.getBool('auto_backup') ?? false)) return null;
  final backupFolder = await StorageUtil.getString('backup_folder') ?? '';
  if (backupFolder.isBlank) return null;
  final albumStr = await StorageUtil.getString('backup_album') ?? '';
  if (albumStr.isBlank) return null;
  final Set<String> ids;
  try {
    ids = (json.decode(albumStr) as List).cast<String>().toSet();
  } catch (e) {
    Log.info('auto backup skipped: bad backup_album $e');
    return null;
  }
  if (await PhotoManager.requestPermissionExtend() !=
      PermissionState.authorized) {
    Log.info('auto backup skipped: photo permission not authorized');
    return null;
  }
  final albums = (await PhotoManager.getAssetPathList())
      .where((a) => ids.contains(a.id))
      .toList();
  if (albums.isEmpty) {
    Log.info('auto backup skipped: saved albums not found');
    return null;
  }
  final uploads = await collectBackupAssets(albums);
  final last = await StorageUtil.getString('last_backup_time') ?? '';
  final docs = await getApplicationDocumentsDirectory();
  final existing =
      transferStore.tasks.value.where((t) => t.steps != null).map((e) => e.id).toSet();
  try {
    return await startAutoBackup(
      enabled: true,
      backupFolder: backupFolder,
      uploads: uploads,
      lastBackupTime: last.isNotBlank
          ? DateTime.fromMillisecondsSinceEpoch(int.tryParse(last) ?? 0)
          : null,
      hasPendingBackup: hasPendingBackupTask(transferStore.tasks.value),
      enqueue: (cachePath, remoteDir) =>
          enqueueFileUpload(localPath: cachePath, remoteDir: remoteDir),
      cancelEnqueued: (stepId) async {
        await FileDownloader().cancelTaskWithId(stepId);
        await FileDownloader().database.deleteRecordWithId(stepId);
      },
      cacheRoot: Directory('${docs.path}/backup_cache'),
    );
  } on BackupEnqueueIncomplete catch (e) {
    // 本次新建的失败父任务不留痕，否则每次启动都会多一条“入队未完成”。
    for (final t in transferStore.tasks.value
        .where((t) => t.steps != null && !existing.contains(t.id))
        .toList()) {
      await transferStore.deleteTask(t);
    }
    Log.info('auto backup skipped: $e');
    return null;
  }
}

/// 已有未完成的备份父任务时不再入队，避免重复上传。
bool hasPendingBackupTask(Iterable<TransferTask> tasks) => tasks.any((t) =>
    t.steps != null &&
    (t.state == TransferState.queued ||
        t.state == TransferState.active ||
        t.state == TransferState.paused));

/// 自动备份的决策层：不可用时返回 null，不抛异常、不提示。
Future<TransferTask?> startAutoBackup({
  required bool enabled,
  required String backupFolder,
  required List<AssetEntity> uploads,
  required DateTime? lastBackupTime,
  required bool hasPendingBackup,
  required Future<String> Function(String cachePath, String remoteDir) enqueue,
  required Directory cacheRoot,
  Future<void> Function(String stepId)? cancelEnqueued,
}) async {
  if (!enabled || backupFolder.isBlank || hasPendingBackup) return null;
  final assets = backupPendingAssets(uploads, lastBackupTime, true);
  if (assets.isEmpty) return null;
  return startBackup(
    backupFolder: backupFolder,
    assets: assets,
    enqueue: enqueue,
    cacheRoot: cacheRoot,
    cancelEnqueued: cancelEnqueued,
  );
}

class Backup extends HookWidget {
  const Backup({super.key});

  @override
  Widget build(BuildContext context) {
    final uploads = useListSignal<AssetEntity>([]);
    final albums = useListSignal<AssetPathEntity>([]);
    final backupFolder = useSignal("");
    final lastBackupTime =
        useSignal<DateTime?>(DateTime.now().add(const Duration(days: -5)));
    final continueBackup = useSignal(true);
    final autoBackup = useSignal(false);

getAssetCount() async {
  uploads.value = await collectBackupAssets(albums.value);
}

getData() async {
  String last = await StorageUtil.getString("last_backup_time") ?? '';

  lastBackupTime.value = last.isNotBlank
      ? DateTime.fromMillisecondsSinceEpoch(int.parse(last))
      : null;
  backupFolder.value = await StorageUtil.getString("backup_folder") ?? '';
  autoBackup.value = await StorageUtil.getBool('auto_backup') ?? false;
  String backupAlbumStr = await StorageUtil.getString("backup_album") ?? '';
  List backupAlbums = [];
  if (await PhotoManager.requestPermissionExtend() ==
      PermissionState.authorized) {
    if (backupAlbumStr.isNotBlank) {
      backupAlbums = json.decode(backupAlbumStr);

      List<AssetPathEntity> list = await PhotoManager.getAssetPathList();
      for (var album in list) {
        if (backupAlbums.contains(album.id)) {
          albums.add(album);
        }
      }
    }
  } else {
    UiUtil.vibrate(FeedbackType.warning);
    UiUtil.toast("请先允许${connectionStore.appName}访问相册");
  }

  getAssetCount();
  // if (Platform.isAndroid) {
  //   String last = await HttpUtil.getStorage("last_backup_time");
  //
  //   lastBackupTime = last.isNotBlank ? DateTime.fromMillisecondsSinceEpoch(int.parse(last)) : null;
  //   backupFolder = await HttpUtil.getStorage("backup_folder") ?? "";
  //   updateState(() {});
  //   Directory directory = Directory(backupSource);
  //   List<FileSystemEntity> list = directory.listSync();
  //   // print(await list.length);
  //
  //   list.forEach((element) {
  //     if (!element.path.split("/").last.startsWith(".")) {
  //       Directory(element.path).list(recursive: true).listen((event) {
  //         if (event is File) {
  //           String ext = event.path.split("/").last.split(".").last;
  //           if (!["back", "tmp"].contains(ext)) {
  //             DateTime lastModify = event.lastModifiedSync();
  //             updateState(() {
  //               if (lastBackupTime != null) {
  //                 if (lastModify.isAfter(lastBackupTime)) {
  //                   uploads.add(UploadItem(event, ext == "mp4" ? UploadFileType.video : UploadFileType.picture, lastModify, fileSize: event.lengthSync()));
  //                 }
  //               } else {
  //                 uploads.add(UploadItem(event, ext == "mp4" ? UploadFileType.video : UploadFileType.picture, lastModify, fileSize: event.lengthSync()));
  //               }
  //             });
  //           }
  //         }
  //       });
  //     }
  //   });
  // } else {
  //
  // }
}

Widget buildAlbumLabel(AssetPathEntity album) {
  return FutureBuilder<int>(
      future: album.assetCountAsync,
      builder: (context, snapshot) {
        return Label(
          "${album.name} (${snapshot.data})",
          Colors.lightBlueAccent,
          fill: true,
        );
      });
  // return Label(
  //   "${album.name} (${album.assetCountAsync})",
  //   Colors.lightBlueAccent,
  //   fill: true,
  // );
}

Future<dynamic> onChooseBackupTargetDialog(BuildContext context) {
  return showFolderPickerSheet(context, filter: ImageFilter.blur());
}

Future<dynamic> onChooseBackupSourceDialog(BuildContext context) {
  return showCupertinoModalPopup(
    context: context,
    builder: (context) {
      return SizedBox(
        width: double.infinity,
        child: Material(
        child: Card(
          shape: RoundedRectangleBorder(
              side: const BorderSide(),
              borderRadius: BorderRadius.circular(18)),
          child: SelectAlbum(
            multi: true,
            selected: albums.value,
          ),
        ),
      ),
      );
    },
  );
}

void onStartBackup() async {
  if (backupFolder.value.isBlank) {
    UiUtil.vibrate(FeedbackType.warning);
    UiUtil.toast("请选择备份目的地");
    return;
  }
  if (albums.value.isEmpty) {
    UiUtil.vibrate(FeedbackType.warning);
    UiUtil.toast("请选择备份源");
    return;
  }
  if (hasPendingBackupTask(transferStore.tasks.value)) {
    UiUtil.vibrate(FeedbackType.warning);
    UiUtil.toast("已有未完成的备份任务");
    return;
  }
  final tasks =
      backupPendingAssets(uploads.value, lastBackupTime.value, continueBackup.value);
  if (tasks.isEmpty) {
    UiUtil.vibrate(FeedbackType.warning);
    UiUtil.toast("没有需要备份的文件");
    return;
  }
  final docs = await getApplicationDocumentsDirectory();
  try {
    final parent = await startBackup(
      backupFolder: backupFolder.value,
      assets: tasks,
      cacheRoot: Directory('${docs.path}/backup_cache'),
      enqueue: (cachePath, remoteDir) =>
          enqueueFileUpload(localPath: cachePath, remoteDir: remoteDir),
      cancelEnqueued: (stepId) async {
        await FileDownloader().cancelTaskWithId(stepId);
        await FileDownloader().database.deleteRecordWithId(stepId);
      },
    );
    UiUtil.vibrate(FeedbackType.light);
    UiUtil.toast("已创建备份任务（${parent.steps!.length} 个文件），请到传输页查看");
  } on BackupEnqueueIncomplete catch (e) {
    UiUtil.vibrate(FeedbackType.warning);
    UiUtil.toast(e.message);
  }
}

    useEffect(() {
      getData();
      return null;
    }, const []);

    return Scaffold(
      appBar: AppBar(
        leading: AppBackButton(context),
        title: const Text("相册备份"),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10, top: 8, bottom: 8),
            child: OutlinedButton(
              onPressed: () async {
                var hide = showWeuiLoadingToast(context: context);
                await PhotoManager.clearFileCache();
                hide();
                UiUtil.toast("缓存清理完成");
              },
              child: Text(
                "清理缓存",
                style: TextStyle(
                    color: Theme.of(context).textTheme.bodyLarge?.color),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          OutlinedButton(
            onPressed: () => onChooseBackupTargetDialog(context).then((res) {
              if (res != null && res.length == 1) {
                backupFolder.value = res[0];
                StorageUtil.setString("backup_folder", backupFolder.value);
              }
            }),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "备份目的地",
                      style: TextStyle(fontSize: 12),
                    ),
                    Text(
                      backupFolder.value == ""
                          ? "请选择目的地"
                          : backupFolder.value,
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(
            height: 20,
          ),
          OutlinedButton(
            onPressed: () {
              onChooseBackupSourceDialog(context).then((res) {
                Log.log("choose backup source dir: $res");
                if (res != null) {
                  albums.value = res;
                  List backupAlbums = albums.value.map((e) => e.id).toList();
                  StorageUtil.setString(
                      "backup_album", json.encode(backupAlbums));

                  getAssetCount();
                }
              });
            },
            child: SizedBox(
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "备份源",
                    style: TextStyle(fontSize: 12),
                  ),
                  const SizedBox(
                    height: 5,
                  ),
                  albums.value.isNotEmpty
                      ? Wrap(
                          runSpacing: 10,
                          spacing: 10,
                          children: albums.value.map(buildAlbumLabel).toList(),
                        )
                      : const Text(
                          "未选择备份源",
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                ],
              ),
            ),
          ),
          const SizedBox(
            height: 20,
          ),
          GestureDetector(
            onTap: () {
              continueBackup.value = true;
            },
            child: Card(
              shape: RoundedRectangleBorder(
                  side: const BorderSide(),
                  borderRadius: BorderRadius.circular(18)),
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.paddingSmall),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "继续备份",
                            style: TextStyle(fontSize: 18),
                          ),
                          Text(
                            lastBackupTime.value != null
                                ? lastBackupTime.value?.format("Y-m-d H:i:s") ?? ''
                                : "从未备份过",
                            style: const TextStyle(
                                fontSize: 16, color: Colors.grey),
                          ),
                          Text(
                            "${uploads.value.where((AssetEntity upload) => (upload.modifiedDateTime.millisecondsSinceEpoch > (lastBackupTime.value?.millisecondsSinceEpoch ?? 0)) && upload.type == AssetType.image).length}张照片 ${uploads.value.where((upload) => (upload.modifiedDateTime.millisecondsSinceEpoch > (lastBackupTime.value?.millisecondsSinceEpoch ?? 0)) && upload.type == AssetType.video).length}个视频",
                            style: const TextStyle(
                                fontSize: 16, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    if (continueBackup.value)
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
              continueBackup.value = false;
            },
            child: Card(
              shape: RoundedRectangleBorder(
                  side: const BorderSide(),
                  borderRadius: BorderRadius.circular(18)),
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.paddingSmall),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "全新备份",
                            style: TextStyle(fontSize: 18),
                          ),
                          Text(
                            "${uploads.where((upload) => upload.type == AssetType.image).length}张照片 ${uploads.where((upload) => upload.type == AssetType.video).length}个视频",
                            style: const TextStyle(
                                fontSize: 16, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    if (!continueBackup.value)
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
              autoBackup.value = !autoBackup.value;
              StorageUtil.setBool('auto_backup', autoBackup.value);
            },
            child: Card(
              shape: RoundedRectangleBorder(
                  side: const BorderSide(),
                  borderRadius: BorderRadius.circular(18)),
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.paddingSmall),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "自动备份",
                            style: TextStyle(fontSize: 18),
                          ),
                          Text(
                            "打开${connectionStore.appName}后自动从上次备份位置继续备份",
                            style: const TextStyle(
                                fontSize: 14, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    if (autoBackup.value)
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
          OutlinedButton(
            onPressed: onStartBackup,
            child: const Text("开始备份"),
          ),
        ],
      ),
    );
  }
}
