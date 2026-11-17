import 'dart:io';
import 'package:garden/util/file_type_util.dart';
import 'package:garden/util/log.dart';
import 'package:garden/util/ui_util.dart';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:garden/pages/common/select_local_folder.dart';
import 'package:garden/pages/file/select_folder.dart';
import 'package:garden/theme/app_theme.dart';
import 'package:garden/services/transfer_upload.dart';
import 'package:garden/stores/transfer_store.dart';
import 'package:garden/extensions/string.dart';
import 'package:garden/util/file_types.dart';
import 'package:garden/widgets/file_icon.dart';
import 'package:garden/widgets/label.dart';
import 'package:garden/widgets/neu_back_button.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:garden/constants/app_constants.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:signals_hooks/signals_hooks.dart';

UploadStatus uploadStatusFromTransfer(TransferState state) {
  switch (state) {
    case TransferState.done:
      return UploadStatus.complete;
    case TransferState.error:
    case TransferState.canceled:
      return UploadStatus.failed;
    case TransferState.queued:
    case TransferState.active:
    case TransferState.paused:
      return UploadStatus.running;
  }
}

class UploadItem {
  String path;
  String subPath;
  String name;
  int fileSize;
  int uploadSize;
  UploadStatus status;
  String? taskId;
  CancelToken? cancelToken;
  UploadItem(this.path, this.name,
      {this.subPath = "",
      this.fileSize = 0,
      this.uploadSize = 0,
      this.status = UploadStatus.wait}) {
    cancelToken = CancelToken();
  }
}

class Upload extends HookWidget {
  final String path;
  final List<String>? selectedFilesPath;
  const Upload(this.path, {super.key, this.selectedFilesPath});

  @override
  Widget build(BuildContext context) {
    final savePath = useSignal(path);
    final uploads = useSignal<List<UploadItem>>(
      selectedFilesPath?.map((filePath) {
        File file = File(filePath);
        return UploadItem(
          filePath,
          filePath.split("/").last,
          fileSize: file.lengthSync(),
        );
      }).toList() ??
          [],
    );

    // Upload items are mutated in place (status, progress); writing a new
    // list notifies the signal so the page rebuilds.
    void notifyUploads() {
      uploads.value = List.of(uploads.value);
    }

    final taskStates = useSignal<Map<String, TransferState>>({});
    useEffect(() {
      final dispose = effect(() {
        taskStates.value = {
          for (final t in transferStore.tasks.value) t.id: t.state,
        };
      });
      return dispose;
    }, const []);

    UploadStatus effectiveStatus(UploadItem upload) {
      final state = upload.taskId == null
          ? null
          : taskStates.watch(context)[upload.taskId];
      return state == null ? upload.status : uploadStatusFromTransfer(state);
    }

  Widget buildUploadStatus(UploadItem upload) {
    final status = effectiveStatus(upload);
    if (status == UploadStatus.complete) {
      return const Label(
        "上传完成",
        Colors.lightGreen,
        fill: true,
        fontSize: 10,
        height: 22,
      );
    } else if (status == UploadStatus.failed) {
      return const Label(
        "上传失败",
        Colors.redAccent,
        fill: true,
        fontSize: 10,
        height: 22,
      );
    } else if (status == UploadStatus.canceled) {
      return const Label(
        "取消上传",
        Colors.redAccent,
        fill: true,
        fontSize: 10,
        height: 22,
      );
    } else if (status == UploadStatus.running) {
      return Label(
        "${(upload.uploadSize / (upload.fileSize == 0 ? 1 : upload.fileSize) * 100).toStringAsFixed(2)}%",
        Colors.lightBlueAccent,
        fill: true,
        fontSize: 10,
        height: 22,
      );
    } else if (status == UploadStatus.wait) {
      return const Label(
        "等待上传",
        Colors.lightBlueAccent,
        fill: true,
        fontSize: 10,
        height: 22,
      );
    } else {
      return Container();
    }
  }

  Widget buildUploadItem(UploadItem upload) {
    FileTypeEnum fileType =
        FileTypeUtil.toFileTypeEnum(FileTypeUtil.getFileType(upload.path));
    // String path = file['path'];
    return Padding(
      padding:
          const EdgeInsets.only(top: 10.0, bottom: 10.0, left: 20, right: 20),
      child: OutlinedButton(
        onPressed: () async {},
        // margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Row(
          children: [
            const SizedBox(
              width: 20,
            ),
            Hero(
              tag: upload.path,
              child: FileIcon(
                fileType,
                thumb: upload.path,
                network: false,
              ),
            ),
            const SizedBox(
              width: 10,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    upload.name,
                    style: const TextStyle(
                      fontSize: 14,
                    ),
                  ),
                  if (upload.subPath.isNotBlank)
                    Text(
                      upload.subPath,
                      style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.of(context).placeholderColor),
                    ),
                  const SizedBox(
                    height: 5,
                  ),
                  buildUploadStatus(upload),
                ],
              ),
            ),
            const SizedBox(
              width: 10,
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: OutlinedButton(
                onPressed: () {
                  showCupertinoModalPopup(
                    context: context,
                    builder: (context) {
                      return Material(
                        color: Colors.transparent,
                        child: Card(
                          shape: RoundedRectangleBorder(
                              side: const BorderSide(),
                              borderRadius: BorderRadius.circular(18)),
                          child: SafeArea(
                            top: false,
                            child: Padding(
                              padding: const EdgeInsets.all(
                                  AppConstants.paddingSmall),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  const Text(
                                    "选择操作",
                                    style: TextStyle(
                                        fontSize: 20,
                                        color: Colors.black,
                                        fontWeight: FontWeight.w500),
                                  ),
                                  if (upload.status == UploadStatus.failed) ...[
                                    const SizedBox(
                                      height: 22,
                                    ),
                                    OutlinedButton(
                                      onPressed: () async {
                                        upload.status = UploadStatus.wait;
                                        notifyUploads();
                                        Navigator.of(context).pop();
                                      },
                                      child: const Text(
                                        "重试",
                                        style: TextStyle(fontSize: 18),
                                      ),
                                    ),
                                  ],
                                  const SizedBox(
                                    height: 22,
                                  ),
                                  OutlinedButton(
                                    onPressed: () async {
                                      uploads.value =
                                          List.of(uploads.value)..remove(upload);
                                      Navigator.of(context).pop();
                                    },
                                    child: const Text(
                                      "取消上传",
                                      style: TextStyle(
                                          fontSize: 18,
                                          color: Colors.redAccent),
                                    ),
                                  ),
                                  const SizedBox(
                                    height: 16,
                                  ),
                                  OutlinedButton(
                                    onPressed: () async {
                                      Navigator.of(context).pop();
                                    },
                                    child: const Text(
                                      "取消",
                                      style: TextStyle(fontSize: 18),
                                    ),
                                  ),
                                  const SizedBox(
                                    height: 8,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
                child: const Icon(
                  CupertinoIcons.right_chevron,
                  size: 18,
                ),
              ),
            ),
            const SizedBox(
              width: 20,
            ),
          ],
        ),
      ),
    );
  }

    return Scaffold(
      appBar: AppBar(
        leading: AppBackButton(context),
        title: const Text(
          "文件上传",
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: OutlinedButton(
              onPressed: () {
                showCupertinoModalPopup(
                  context: context,
                  builder: (context) {
                    return const SelectFolder(
                      multi: false,
                    );
                  },
                ).then((res) {
                  if (res != null && res.length == 1) {
                    savePath.value = res[0];
                  }
                });
              },
              child: SizedBox(
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "上传位置",
                      style: TextStyle(fontSize: 12),
                    ),
                    Text(
                      savePath.value == "" ? "请选择上传位置" : savePath.value,
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: uploads.value.isNotEmpty
                ? ListView.builder(
                    itemBuilder: (context, i) {
                      return buildUploadItem(uploads.value[i]);
                    },
                    itemCount: uploads.value.length,
                  )
                : Center(
                    child: Text(
                      "暂无待上传文件",
                      style: TextStyle(
                          color: AppTheme.of(context).placeholderColor),
                    ),
                  ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        showCupertinoModalPopup(
                          context: context,
                          builder: (context) {
                            return Material(
                              color: Colors.transparent,
                              child: Card(
                                shape: RoundedRectangleBorder(
                                    side: const BorderSide(),
                                    borderRadius: BorderRadius.circular(18)),
                                child: SafeArea(
                                  top: false,
                                  child: Padding(
                                    padding: const EdgeInsets.all(
                                        AppConstants.paddingSmall),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: <Widget>[
                                        const Text(
                                          "选择添加方式",
                                          style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.w500),
                                        ),
                                        const SizedBox(
                                          height: 12,
                                        ),
                                        OutlinedButton(
                                          onPressed: () async {
                                            Navigator.of(context).pop();
                                            final List<AssetEntity>? assets =
                                                await AssetPicker.pickAssets(
                                                    context,
                                                    pickerConfig:
                                                        const AssetPickerConfig(
                                                            maxAssets: 1000));
                                            if (assets != null &&
                                                assets.isNotEmpty) {
                                              for (var asset in assets) {
                                                asset.file.then((file) {
                                                  if (file == null) {
                                                    return;
                                                  }
                                                  uploads.value = [
                                                    ...uploads.value,
                                                    UploadItem(file.path,
                                                        file.path.split("/").last)
                                                  ];
                                                });
                                              }
                                            } else {
                                              Log.debug("未选择文件");
                                            }
                                          },
                                          child: const Text(
                                            "上传图片",
                                            style: TextStyle(fontSize: 18),
                                          ),
                                        ),
                                        const SizedBox(
                                          height: 20,
                                        ),
                                        OutlinedButton(
                                          onPressed: () async {
                                            Navigator.of(context).pop();
                                            DeviceInfoPlugin deviceInfo =
                                                DeviceInfoPlugin();
                                            if (Platform.isAndroid) {
                                              AndroidDeviceInfo androidInfo =
                                                  await deviceInfo.androidInfo;
                                              if (androidInfo.version.sdkInt >=
                                                  30) {
                                                bool permission = false;
                                                permission = await Permission
                                                    .manageExternalStorage
                                                    .request()
                                                    .isGranted;
                                                if (!permission) {
                                                  UiUtil.toast("安卓11需授权文件管理权限");
                                                  return;
                                                }
                                              } else {
                                                bool permission = false;
                                                permission = await Permission
                                                    .storage
                                                    .request()
                                                    .isGranted;
                                                if (!permission) {
                                                  UiUtil.toast("请先授权APP访问存储权限");
                                                  return;
                                                }
                                              }
                                              if (context.mounted) {
                                                showCupertinoModalBottomSheet<
                                                    List<FileSystemEntity>>(
                                                  context: context,
                                                  builder: (context) {
                                                    return const SelectLocalFolder(
                                                      multi: true,
                                                      folder: false,
                                                    );
                                                  },
                                                ).then((res) {
                                                  if (res != null &&
                                                      res.isNotEmpty) {
                                                    for (var entry in res) {
                                                      if (FileSystemEntity
                                                          .isFileSync(
                                                              entry.path)) {
                                                        uploads.value = [
                                                          ...uploads.value,
                                                          UploadItem(entry.path,
                                                              entry.path
                                                                  .split("/")
                                                                  .last)
                                                        ];
                                                      } else {
                                                        Directory directory =
                                                            Directory(
                                                                entry.path);
                                                        directory
                                                            .list(
                                                                recursive: true)
                                                            .forEach((element) {
                                                          if (!element.path
                                                              .split("/")
                                                              .last
                                                              .startsWith(
                                                                  ".")) {
                                                            if (FileSystemEntity
                                                                .isFileSync(
                                                                    element
                                                                        .path)) {
                                                              List<String>
                                                                  slice =
                                                                  element.path
                                                                      .replaceFirst(
                                                                          "${entry.path}/",
                                                                          "")
                                                                      .split(
                                                                          "/");
                                                              uploads.value = [
                                                                ...uploads.value,
                                                                UploadItem(
                                                                    element.path,
                                                                    slice.last,
                                                                    subPath: slice
                                                                        .getRange(0,
                                                                            slice.length -
                                                                                1)
                                                                        .join("/"))
                                                              ];
                                                            }
                                                          }
                                                        });
                                                      }
                                                    }
                                                  }
                                                  // if (res != null && res.length == 1) {
                                                  //   updateState(() {
                                                  //     downloadPath = res[0];
                                                  //     HttpUtil.downloadSavePath = res[0];
                                                  //     HttpUtil.setStorage("download_save_path", res[0]);
                                                  //   });
                                                  // }
                                                });
                                              }
                                            } else {
                                              FilePickerResult? result =
                                                  await FilePicker.platform
                                                      .pickFiles(
                                                          allowMultiple: true);
                                              if (result == null) {
                                                UiUtil.toast('选择文件为空!');
                                                return;
                                              }
                                              uploads.value = [
                                                ...uploads.value,
                                                ...result.files
                                                    .takeWhile((t) =>
                                                        t.path != null)
                                                    .map((file) {
                                                  return UploadItem(file.path!,
                                                      file.name,
                                                      fileSize: file.size);
                                                })
                                              ];
                                            }
                                          },
                                          child: const Text(
                                            "上传文件",
                                            style: TextStyle(fontSize: 18),
                                          ),
                                        ),
                                        const SizedBox(
                                          height: 20,
                                        ),
                                        OutlinedButton(
                                          onPressed: () async {
                                            Navigator.of(context).pop();
                                          },
                                          child: const Text(
                                            "取消",
                                            style: TextStyle(fontSize: 18),
                                          ),
                                        ),
                                        const SizedBox(
                                          height: 8,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                      child: const Text("添加文件"),
                    ),
                  ),
                  const SizedBox(
                    width: 20,
                  ),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        if (savePath.value.isBlank) {
                          UiUtil.vibrate(FeedbackType.warning);
                          UiUtil.toast("请选择上传位置");
                          return;
                        }
                        // return;
                        for (int i = 0; i < uploads.value.length; i++) {
                          UploadItem upload = uploads.value[i];
                          if (upload.status != UploadStatus.wait) {
                            continue;
                          }
                          //上传文件（走 transfer 引擎，后台可续传）
                          upload.status = UploadStatus.running;
                          notifyUploads();
                          final remoteDir =
                              "${savePath.value}${upload.subPath.isNotBlank ? "/${upload.subPath}" : ""}";
                          try {
                            final taskId = await enqueueFileUpload(
                              localPath: upload.path,
                              remoteDir: remoteDir,
                            );
                            transferStore.add(TransferTask(
                              id: taskId,
                              type: TransferType.upload,
                              localPath: upload.path,
                              remotePath: '$remoteDir/${upload.name}',
                              state: TransferState.active,
                            ));
                            upload.taskId = taskId;
                            upload.uploadSize = 0;
                          } catch (e) {
                            Log.error(e);
                            upload.status = UploadStatus.failed;
                          }
                          notifyUploads();
                        }
                      },
                      child: const Text("开始上传"),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
