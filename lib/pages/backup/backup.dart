import 'dart:convert';
import 'package:garden/pages/backup/backup_model.dart';
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
import 'package:garden/util/file_types.dart';
import 'package:garden/widgets/file_icon.dart';
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
      transferStore.addStep(parent.id, TransferStep(
        id: taskId,
        localPath: cachePath,
        remotePath: remoteDir(backupFolder, filename),
        state: TransferState.active,
        modifyTime: asset.modifiedDateTime,
      ));
    } catch (e) {
      transferStore.setError(parent.id, '备份入队未完成: $e');
      throw BackupEnqueueIncomplete('备份入队未完成: $e');
    }
  }
  if (transferStore.tasks.value.firstWhere((t) => t.id == parent.id).steps!.isEmpty) {
    transferStore.setError(parent.id, '没有可备份的文件');
    throw BackupEnqueueIncomplete('没有可备份的文件');
  }
  return transferStore.tasks.value.firstWhere((t) => t.id == parent.id);
}

String remoteDir(String backupFolder, String filename) =>
    backupFolder.endsWith('/') ? '$backupFolder$filename' : '$backupFolder/$filename';

/// 父任务完成时把备份时间推进到所有子步骤中最晚的修改时间。
void Function() syncBackupTimeOnCompletion(ValueChanged<DateTime?> onTime) {
  final subscription = transferStore.tasks.toStream().listen((tasks) {
    for (final t in tasks) {
      if (t.steps == null || t.state != TransferState.done) continue;
      final latest = t.steps!
          .map((s) => s.modifyTime)
          .whereType<DateTime>()
          .fold<DateTime?>(null, (a, b) => a == null || b.isAfter(a) ? b : a);
      if (latest == null) continue;
      StorageUtil.setString(
          'last_backup_time', latest.millisecondsSinceEpoch.toString());
      onTime(latest);
    }
  });
  return subscription.cancel;
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
    final uploading = useSignal<UploadItem?>(null);
    // Only read/written from the backup loop, never during build.
    final cancel = useRef(false);
    final continueBackup = useSignal(true);

getAssetCount() async {
  uploads.value = await collectBackupAssets(albums.value);
}

getData() async {
  String last = await StorageUtil.getString("last_backup_time") ?? '';

  lastBackupTime.value = last.isNotBlank
      ? DateTime.fromMillisecondsSinceEpoch(int.parse(last))
      : null;
  backupFolder.value = await StorageUtil.getString("backup_folder") ?? '';
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
      final dispose = syncBackupTimeOnCompletion((time) {
        lastBackupTime.value = time;
      });
      return dispose;
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
          ...[
            Card(
              shape: RoundedRectangleBorder(
                  side: const BorderSide(),
                  borderRadius: BorderRadius.circular(18)),
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.paddingSmall),
                child: Stack(
                  children: [
                    Container(
                      width: (MediaQuery.sizeOf(context).width - 40) *
                          (uploading.value?.uploadSize ??
                              1 /
                                  (uploading.value?.fileSize == 0
                                      ? 1
                                      : (uploading.value?.fileSize ?? 1))),
                      height: 70,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.amber[100],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 15),
                      child: Row(
                        children: [
                          uploading.value?.type == AssetType.image
                              ? Image.file(
                                  uploading.value!.file!,
                                  height: 40,
                                  width: 40,
                                )
                              : const FileIcon(FileTypeEnum.image),
                          const SizedBox(
                            width: 20,
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  uploading.value?.file?.path.split("/").last ??
                                      '[Idle]',
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 2,
                                  style: const TextStyle(fontSize: 13),
                                ),
                                const SizedBox(
                                  height: 5,
                                ),
                                Text(
                                  uploading.value?.file?.parent.path ?? '[Idle]',
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(
              height: 20,
            ),
          ],
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
              UiUtil.toast("暂不支持自动备份");
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
                    const SizedBox(
                      width: 20,
                      // child: Icon(
                      //   CupertinoIcons.checkmark_alt,
                      //   color: AppColors.primaryAction,
                      // ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(
            height: 20,
          ),
          uploading.value == null
              ? OutlinedButton(
                  onPressed: onStartBackup,
                  child: const Text("开始备份"),
                )
              : OutlinedButton(
                  onPressed: () async {
                    cancel.value = true;
                    UiUtil.toast("当前文件上传完成后将暂停任务");
                  },
                  child: const Text("暂停备份"),
                ),
        ],
      ),
    );
  }
}
