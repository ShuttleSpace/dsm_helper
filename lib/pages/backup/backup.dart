import 'dart:convert';
import 'package:garden/pages/file/upload.dart';
import 'package:garden/util/log.dart';
import 'package:garden/util/ui_util.dart';
import 'package:garden/util/storage_util.dart';
import 'package:garden/stores/connection_store.dart';
import 'dart:io';
import 'dart:ui';

import 'package:cool_ui/cool_ui.dart';
import 'package:dio/dio.dart';
import 'package:garden/pages/common/select_ablum.dart';
import 'package:garden/util/http_util.dart';
import 'package:garden/widgets/file_icon.dart';
import 'package:garden/widgets/label.dart';
import 'package:garden/widgets/neu_back_button.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:garden/constants/app_constants.dart';
import 'package:garden/theme/app_colors.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

import '../file/select_folder.dart';

class Backup extends StatefulWidget {
  const Backup({super.key});

  @override
  BackupState createState() => BackupState();
}


class BackupState extends State<Backup> {
  List<AssetEntity> uploads = [];
  List<AssetPathEntity> albums = [];
  String backupFolder = "";
  DateTime? lastBackupTime = DateTime.now().add(const Duration(days: -5));
  UploadItem? uploading;
  bool cancel = false;
  bool continueBackup = true;
  @override
  void initState() {
    getData();
    super.initState();
  }

  getData() async {
    String last = await StorageUtil.getString("last_backup_time") ?? '';

    lastBackupTime = last.isNotBlank
        ? DateTime.fromMillisecondsSinceEpoch(int.parse(last))
        : null;
    backupFolder = await StorageUtil.getString("backup_folder") ?? '';
    setState(() {});
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
        setState(() {});
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
    //   setState(() {});
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
    //             setState(() {
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

  getAssetCount() async {
    uploads = [];
    var futs = albums
        .map((item) => item.getAssetListRange(start: 0, end: 100000000))
        .toList();
    var value = await Future.wait(futs);
    var values = value.fold([], (prev, el) {
      prev.addAll(el);
      return prev;
    });
    setState(() {
      uploads.addAll(values as List<AssetEntity>);
    });
  }

  Widget _buildAlbumLabel(AssetPathEntity album) {
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

  @override
  Widget build(BuildContext context) {
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
                          (uploading?.uploadSize ??
                              1 /
                                  (uploading?.fileSize == 0
                                      ? 1
                                      : (uploading?.fileSize ?? 1))),
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
                          uploading?.type == AssetType.image
                              ? Image.file(
                                  uploading!.file!,
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
                                  uploading?.file?.path.split("/").last ??
                                      '[Idle]',
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 2,
                                  style: const TextStyle(fontSize: 13),
                                ),
                                const SizedBox(
                                  height: 5,
                                ),
                                Text(
                                  uploading?.file?.parent.path ?? '[Idle]',
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
            onPressed: () => _onChooseBackupTargetDialog(context).then((res) {
              if (res != null && res.length == 1) {
                setState(() {
                  backupFolder = res[0];
                  StorageUtil.setString("backup_folder", backupFolder);
                });
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
                      backupFolder == "" ? "请选择目的地" : backupFolder,
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
              _onChooseBackupSourceDialog(context).then((res) {
                Log.log("choose backup source dir: $res");
                if (res != null) {
                  setState(() {
                    albums = res;
                  });
                  List backupAlbums = albums.map((e) => e.id).toList();
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
                  albums.isNotEmpty
                      ? Wrap(
                          runSpacing: 10,
                          spacing: 10,
                          children: albums.map(_buildAlbumLabel).toList(),
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
              setState(() {
                continueBackup = true;
              });
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
                            lastBackupTime != null
                                ? lastBackupTime?.format("Y-m-d H:i:s") ?? ''
                                : "从未备份过",
                            style: const TextStyle(
                                fontSize: 16, color: Colors.grey),
                          ),
                          Text(
                            "${uploads.where((AssetEntity upload) => (upload.modifiedDateTime.millisecondsSinceEpoch > (lastBackupTime?.millisecondsSinceEpoch ?? 0)) && upload.type == AssetType.image).length}张照片 ${uploads.where((upload) => (upload.modifiedDateTime.millisecondsSinceEpoch > (lastBackupTime?.millisecondsSinceEpoch ?? 0)) && upload.type == AssetType.video).length}个视频",
                            style: const TextStyle(
                                fontSize: 16, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    if (continueBackup)
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
              setState(() {
                continueBackup = false;
              });
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
                    if (!continueBackup)
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
          uploading == null
              ? OutlinedButton(
                  onPressed: _onStartBackup,
                  child: const Text("开始备份"),
                )
              : OutlinedButton(
                  onPressed: () async {
                    cancel = true;
                    UiUtil.toast("当前文件上传完成后将暂停任务");
                  },
                  child: const Text("暂停备份"),
                ),
        ],
      ),
    );
  }

  Future<dynamic> _onChooseBackupTargetDialog(BuildContext context) {
    return showCupertinoModalPopup(
      filter: ImageFilter.blur(),
      context: context,
      builder: (context) {
        return Material(
          child: Card(
            shape: RoundedRectangleBorder(
                side: const BorderSide(),
                borderRadius: BorderRadius.circular(18)),
            child: const SelectFolder(
              multi: false,
            ),
          ),
        );
      },
    );
  }

  Future<dynamic> _onChooseBackupSourceDialog(BuildContext context) {
    return showCupertinoModalPopup(
      context: context,
      builder: (context) {
        return Material(
          child: Card(
            shape: RoundedRectangleBorder(
                side: const BorderSide(),
                borderRadius: BorderRadius.circular(18)),
            child: SelectAlbum(
              multi: true,
              selected: albums,
            ),
          ),
        );
      },
    );
  }

  void _onStartBackup() async {
    if (backupFolder.isBlank) {
      UiUtil.vibrate(FeedbackType.warning);
      UiUtil.toast("请选择备份目的地");
      return;
    }
    if (albums.isEmpty) {
      UiUtil.vibrate(FeedbackType.warning);
      UiUtil.toast("请选择备份源");
      return;
    }
    List<AssetEntity> tasks;
    if (continueBackup) {
      tasks = uploads
          .where((element) =>
              element.modifiedDateTime.millisecondsSinceEpoch >
              (lastBackupTime?.millisecondsSinceEpoch ?? 0))
          .toList();
    } else {
      tasks = uploads;
    }
    //对待备份文件进行排序
    tasks.sort((a, b) {
      return a.modifiedDateTime.isAtSameMomentAs(b.modifiedDateTime)
          ? 0
          : a.modifiedDateTime.isBefore(b.modifiedDateTime)
              ? -1
              : 1;
    });
    for (int i = 0; i < tasks.length; i++) {
      if (cancel) {
        cancel = false;
        setState(() {
          uploading = null;
        });
        UiUtil.toast("备份任务已暂停");
        break;
      }
      uploading = UploadItem(
          await tasks[i].originFile, tasks[i].modifiedDateTime, tasks[i].type);

      if (uploading!.status != UploadStatus.wait) {
        continue;
      }
      //上传文件
      setState(() {
        uploading?.status = UploadStatus.running;
      });
      var res = await DsmApi.upload(
          backupFolder, uploading!.file!.path, uploading!.cancelToken,
          (progress, total) {
        // print("$progress,$total");
        setState(() {
          uploading!.uploadSize = progress;
          uploading!.fileSize = total;
        });
      });
      if (res['success']) {
        if (Platform.isIOS) {
          // 仅在iOS删除源文件（iOS非真实源文件）
          uploading!.file!.deleteSync();
        }

        StorageUtil.setString("last_backup_time",
            uploading!.modifyTime!.millisecondsSinceEpoch.toString());
        setState(() {
          lastBackupTime = uploading!.modifyTime;
          uploading!.status = UploadStatus.complete;
        });
      } else {
        setState(() {
          uploading!.status = UploadStatus.failed;
        });
      }
      if (i == tasks.length - 1) {
        UiUtil.toast("备份已完成");
        UiUtil.vibrate(FeedbackType.light);
        setState(() {
          uploading = null;
          lastBackupTime = DateTime.now();
        });
      }
    }
  }
}
