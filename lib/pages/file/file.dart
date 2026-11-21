import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:garden/api/dsm_api.dart';
import 'package:garden/api/dsm_api.filestation.transfer_url.dart';
import 'package:garden/extensions/string.dart';
import 'package:garden/services/office_preview.dart';
import 'package:garden/stores/settings_store.dart';
import 'package:garden/util/file_type_util.dart';
import 'package:garden/util/ui_util.dart';
import 'package:garden/util/storage_util.dart';
import 'package:flutter/foundation.dart';
import 'package:garden/stores/connection_store.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:garden/util/log.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';
import 'package:garden/pages/common/audio_player.dart';
import 'package:garden/pages/common/image_preview.dart';
import 'package:garden/pages/common/pdf_viewer.dart';
import 'package:garden/pages/common/text_editor.dart';
import 'package:garden/pages/common/video_player.dart';
import 'package:garden/pages/file/detail.dart';
import 'package:garden/pages/file/favorite.dart';
import 'package:garden/pages/file/search.dart';
import 'package:garden/pages/file/share.dart';
import 'package:garden/pages/file/upload.dart';
import 'package:garden/theme/app_theme.dart';
import 'package:garden/util/file_types.dart';
import 'package:garden/widgets/bottom_action_sheet.dart';
import 'package:garden/widgets/bottom_confirm_sheet.dart';
import 'package:garden/hooks/use_file_download.dart';
import 'package:garden/hooks/use_file_click.dart';
import 'package:garden/widgets/file/create_action_sheet.dart';
import 'package:garden/widgets/file/file_list_item.dart';
import 'package:garden/widgets/file/path_item.dart';
import 'package:garden/widgets/file/process_list.dart';
import 'package:garden/widgets/file/remote_folder_sheet.dart';
import 'package:garden/widgets/file/sort_menu.dart';
import 'package:garden/widgets/file/title_actions.dart';
import 'package:garden/widgets/folder_picker_sheet.dart';
import 'package:garden/widgets/name_input_dialog.dart';
import 'package:garden/widgets/transparent_router.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:garden/constants/app_constants.dart';
import 'package:flutter_floating/floating/floating.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:signals_hooks/signals_hooks.dart';

String _dsmErrorCode(Object e) => e is DSMException ? '${e.code}' : '-1';

enum ListType { list, icon }

class Files extends HookWidget {
  final Signal<bool> filesDrawerOpen;
  final Signal<Future<bool> Function()?> filesOnWillPop;
  const Files(
      {super.key, required this.filesDrawerOpen, required this.filesOnWillPop});

  @override
  Widget build(BuildContext context) {
    final openExternally = useOpenExternally(context);
    final loading = useSignal(true);
    final favoriteLoading = useSignal(true);
    final success = useSignal(true);
    final multiSelect = useSignal(false);
    final showProcessList = useSignal(false);
    final searchResult = useSignal(false);
    final searching = useSignal(false);
    final msg = useSignal('');
    final sortBy = useSignal('name');
    final sortDirection = useSignal('ASC');
    final listType = useSignal(ListType.list);
    // 根目录用空列表表示（与迁移前 `List paths = []` 语义一致）。
    final paths = useSignal<List>([]);
    final files = useSignal<List>([]);
    final smbFolders = useSignal<List>([]);
    final ftpFolders = useSignal<List>([]);
    final sftpFolders = useSignal<List>([]);
    final davFolders = useSignal<List>([]);
    final favorites = useSignal<List>([]);
    final selectedFiles = useSignal<List>([]);
    final backgroundProcess = useSignal<Map>({});
    final scrollPosition = useSignal<Map>({});
    final scaffoldKey = useMemoized(() => GlobalKey<ScaffoldState>(), const []);
    final pathScrollController = useScrollController();
    final fileScrollController = useScrollController();
    final searchTimer = useRef<Timer?>(null);
    final processingTimer = useRef<Timer?>(null);
    final audioPlayerFloating = useRef<Floating?>(null);

    getProcessingTaskResult(String taskId) {
      if (backgroundProcess.value[taskId] == null) {
        return;
      }
      backgroundProcess.value[taskId]['timer'] =
          Timer.periodic(const Duration(seconds: 1), (_) async {
        // switch (backgroundProcess[taskId]['type']) {
        //   case 'copy':
        //   case 'move':
        //     getCopyMoveTaskResult(taskId);
        //     break;
        //   case 'extract':
        //     getExtractTaskResult(taskId);
        //     break;
        //   case 'delete':
        //     getDeleteTaskResult(taskId);
        //     break;
        //   case 'compress':
        //     getCompressTaskResult(taskId);
        //     break;
        // }
      });
    }

    Future<void> getFileList(String path) async {
      loading.value = true;
      try {
        final data = await dsmFileStationListForPage(path,
            sortBy: sortBy.value, sortDirection: sortDirection.value);
        files.value = data['files'] ?? [];
        success.value = true;
        Log.info(files.value);
      } catch (e) {
        success.value = false;
        msg.value = connectionStore.notVisitorAccount.value
            ? '暂无文件'
            : '加载失败，code:${_dsmErrorCode(e)}';
      } finally {
        loading.value = false;
      }
    }

    getShareList() async {
      String listTypeStr = await StorageUtil.getString("file_list_type") ?? '';

      if (listTypeStr.isNotBlank) {
        if (listTypeStr == "list") {
          listType.value = ListType.list;
        } else {
          listType.value = ListType.icon;
        }
      } else {
        listType.value = ListType.list;
      }
      loading.value = true;
      try {
        final data = await dsmFileStationListShareForPage();
        files.value = data['shares'] ?? [];
        success.value = true;
      } catch (e) {
        success.value = false;
        msg.value = '加载失败，code:${_dsmErrorCode(e)}';
      } finally {
        loading.value = false;
      }
    }

    setPaths(String path) {
      searchResult.value = false;
      searching.value = false;

      if (path == "") {
        paths.value = [];
      } else {
        if (path.startsWith("/")) {
          List<String> items = path.split("/").sublist(1);

          paths.value = items;
        } else {
          List<String> parts = path.split("://");
          String scheme = parts[0];
          String first = "$scheme://${parts[1].split("/").first}";
          // String first = "${uri.scheme}://${uri.userInfo}@${uri.host}";
          List<String> items = path.replaceAll(first, "").split("/");
          items[0] = first;

          paths.value = items;
        }
      }
    }

    goPath(String path) async {
      Log.info("path:$path");
      UiUtil.vibrate(FeedbackType.light);

      success.value = true;

      setPaths(path);
      if (path == "/" || path == "") {
        await getShareList();
      } else {
        await getFileList(path);
      }
      double offset = pathScrollController.position.maxScrollExtent;
      pathScrollController.animateTo(offset,
          duration: const Duration(milliseconds: 200), curve: Curves.ease);
      fileScrollController.jumpTo(scrollPosition.value[path] ?? 0);
    }

    refresh() {
      String path = "";
      if (paths.value.isNotEmpty && paths.value[0].contains("//")) {
        Log.info("远程");
        path = paths.value.join("/");
      } else {
        Log.info("本地");
        path = (paths.value.isNotEmpty ? "/" : '') + paths.value.join("/");
      }
      goPath(path);
    }

    extractFile(file, {String password = ''}) async {
      try {
        final data = await dsmFileStationExtractStartForPage(
            file['path'], "/${paths.value.join("/")}",
            password: password);
        backgroundProcess.value[data['taskid']] = {
          "timer": null,
          "data": null,
          "type": 'extract',
          "path": [file['path']],
        };
        getProcessingTaskResult(data['taskid']);
      } catch (e) {
        Log.warn('extract failed: $e');
      }
    }

    initFloating() {}
    Future<List> getVolumes() async {
      try {
        final data = await dsmCoreStorageVolumeListForPage();
        return data['volumes'] ?? [];
      } catch (e) {
        return [];
      }
    }

    closeDrawer() {
      if (scaffoldKey.currentState?.isDrawerOpen == true) {
        Navigator.of(context).pop();
      }
    }

    Future<bool?> result(String taskId) async {
      try {
        final data = await dsmFileStationSearchListForPage(taskId);
        final finished = data['finished'] == true;
        if (finished) {
          searchTimer.value?.cancel();
        }
        loading.value = false;
        searching.value = !finished;
        files.value = data['files'] ?? [];
        return finished;
      } catch (e) {
        return null;
      }
    }

    search(List<String> folders, String pattern, bool searchContent) async {
      searchResult.value = true;
      searching.value = true;
      loading.value = true;

      late Map<String, dynamic> data;
      try {
        data = await dsmFileStationSearchStartForPage(folders, pattern,
            searchContent: searchContent);
      } catch (e) {
        Log.info("搜索出错: $e");
        searching.value = false;
        loading.value = false;
        return;
      }
      bool? r = await result(data['taskid']);
      if (r == null) {
        UiUtil.toast('Wrong State!');
        return;
      }
      if (r == false) {
        //搜索未结束
        searchTimer.value = Timer.periodic(const Duration(seconds: 2), (timer) {
          // result(res['data']['taskid']);
        });
      }
    }

    final appDownload = useFileDownload(context);
    download(List filePaths) async {
      await appDownload(filePaths);
    }

    downloadFiles(List filePaths) async {
      Connectivity().onConnectivityChanged.listen((result) {
        if (result.contains(ConnectivityResult.mobile)) {
          UiUtil.vibrate(FeedbackType.warning);
          if (context.mounted) {
            showCupertinoModalPopup(
              // ignore: use_build_context_synchronously
              context: context,
              builder: (context) => BottomConfirmSheet(
                title: "下载确认",
                content: "您当前正在使用数据网络，下载文件可能会产生流量费用，是否继续下载？",
                confirmText: "下载",
                confirmResult: true,
                cancelResult: false,
                showTrailingSpace: true,
                onConfirm: () => download(filePaths),
              ),
            ).then((value) {
              if (value == null || value == false) {
                return;
              }
            });
          }
        } else {
          download(filePaths);
        }
      });
    }

    Future<void> getSmbFolder() async {
      try {
        final data = await dsmFileStationVirtualFolderSmbForPage();
        smbFolders.value = data['folders'] ?? [];
      } catch (e) {
        Log.warn('smb folders: $e');
      }
    }

    Future<void> getFtpFolder() async {
      try {
        final data = await dsmFileStationVirtualFolderForPage('ftp');
        ftpFolders.value = data['folders'] ?? [];
      } catch (e) {
        Log.warn('ftp folders: $e');
      }
    }

    Future<void> getSftpFolder() async {
      try {
        final data = await dsmFileStationVirtualFolderForPage('sftp');
        sftpFolders.value = data['folders'] ?? [];
      } catch (e) {
        Log.warn('sftp folders: $e');
      }
    }

    Future<void> getDavFolder() async {
      try {
        final data = await dsmFileStationVirtualFolderForPage('davs');
        davFolders.value = data['folders'] ?? [];
      } catch (e) {
        Log.warn('dav folders: $e');
      }
    }

    openPlainFile(file) async {
      loading.value = true;
      try {
        final url = fbDownloadUrl(
          baseUri: connectionStore.baseUri.value,
          path: file['path'],
          sid: connectionStore.sid.value,
          mode: 'open',
        );
        final content = utf8.decode(await fetchFileBytes(url));
        loading.value = false;
        if (context.mounted) {
          // ignore: use_build_context_synchronously
          Navigator.of(context).push(CupertinoPageRoute(builder: (context) {
            return TextEditor(
              fileName: file['name'],
              content: content,
            );
          }));
        }
      } catch (e) {
        loading.value = false;
        Log.error("文本预览失败: $e");
        UiUtil.toast("预览失败：$e");
      }
    }

    deleteFile(List<String> filePaths) {
      UiUtil.vibrate(FeedbackType.warning);
      showCupertinoModalPopup(
        context: context,
        builder: (context) => BottomConfirmSheet(
          title: "确认删除",
          content: "确认要删除文件？",
          confirmText: "确认删除",
          showTrailingSpace: true,
          onConfirm: () async {
            try {
              final data = await dsmFileStationDeleteStartForPage(filePaths);
              backgroundProcess.value[data['taskid']] = {
                "timer": null,
                "data": {
                  "progress": 0,
                },
                "type": 'delete',
                "path": filePaths,
              };
              selectedFiles.value = [];
              multiSelect.value = false;
              getProcessingTaskResult(data['taskid']);
            } catch (e) {
              UiUtil.toast("删除失败，代码：${_dsmErrorCode(e)}");
            }
          },
        ),
      );
    }

    compressFile(List<String> file) {
      String zipName = "";
      String destPath = "";
      if (file.length == 1) {
        zipName = "${file[0].split("/").last}.zip";
      } else {
        zipName = paths.value.last + ".zip";
      }
      destPath = "/${paths.value.join("/")}/$zipName";
      showCupertinoModalPopup(
        context: context,
        builder: (context) {
          return SizedBox(
            width: double.infinity,
            child: Material(
              color: Colors.transparent,
              child: Card(
                shape: RoundedRectangleBorder(
                    side: const BorderSide(),
                    borderRadius: BorderRadius.circular(18)),
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.all(AppConstants.paddingSmall),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        const Text(
                          "压缩文件",
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(
                          height: 12,
                        ),
                        Text(
                          "确认要压缩到$zipName？",
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.w400),
                        ),
                        const SizedBox(
                          height: 22,
                        ),
                        OutlinedButton(
                          onPressed: () async {
                            Navigator.of(context).pop();
                            try {
                              final data =
                                  await dsmFileStationCompressStartForPage(
                                      file, destPath);
                              backgroundProcess.value[data['taskid']] = {
                                "timer": null,
                                "data": {
                                  "dest_folder_path": destPath,
                                  "progress": 0,
                                },
                                "path": [file],
                                "type": 'compress',
                              };
                              multiSelect.value = false;
                              selectedFiles.value = [];
                              getProcessingTaskResult(data['taskid']);
                            } catch (e) {
                              UiUtil.toast("压缩失败，代码：${_dsmErrorCode(e)}");
                            }
                          },
                          child: const Text(
                            "开始压缩",
                            style: TextStyle(fontSize: 18),
                          ),
                        ),
                        const SizedBox(
                          height: 16,
                        ),
                        OutlinedButton(
                          onPressed: () async {
                            // Navigator.of(context).pop();
                            UiUtil.toast("敬请期待");
                          },
                          child: const Text(
                            "更多选项",
                            style: TextStyle(fontSize: 18),
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
            ),
          );
        },
      );
    }

    openFile(file,
        {FileTypeEnum fileType = FileTypeEnum.other,
        bool remote = false}) async {
      if (multiSelect.value) {
        if (selectedFiles.value.contains(file)) {
          selectedFiles.value = List.of(selectedFiles.value)..remove(file);
        } else {
          selectedFiles.value = [...selectedFiles.value, file];
        }
      } else {
        if (file['isdir']) {
          goPath(file['path']);
          if (remote) {
            Navigator.of(context).pop();
          }
        } else {
          switch (fileType) {
            case FileTypeEnum.image:
              //获取当前目录全部图片文件
              List<String> images = [];
              List<String> thumbs = [];
              List<String> names = [];
              List<String> imagePaths = [];
              int index = 0;
              for (int i = 0; i < files.value.length; i++) {
                if (FileTypeUtil.toFileTypeEnum(
                        FileTypeUtil.getFileType(files.value[i]['name'])) ==
                    FileTypeEnum.image) {
                  images.add(thumbUrl(
                      baseUri: connectionStore.baseUri.value,
                      path: files.value[i]['path'],
                      sid: connectionStore.sid.value));
                  thumbs.add(thumbUrl(
                      baseUri: connectionStore.baseUri.value,
                      path: files.value[i]['path'],
                      sid: connectionStore.sid.value,
                      size: 'small'));
                  names.add(files.value[i]['name']);
                  imagePaths.add(files.value[i]['path']);
                  if (files.value[i]['name'] == file['name']) {
                    index = images.length - 1;
                  }
                }
              }
              Navigator.of(context).push(TransparentPageRoute(
                pageBuilder: (context, _, __) {
                  return ImagePreview(
                    images,
                    index,
                    thumbs: thumbs,
                    names: names,
                    paths: imagePaths,
                    onDelete: () {
                      refresh();
                    },
                  );
                },
              ));
              break;
            case FileTypeEnum.movie:
              // android_intent 只有 Android 有实现，其它平台调用会抛异常、点了没反应。
              final preferExternalPlayer = !kIsWeb &&
                  Platform.isAndroid &&
                  (await StorageUtil.getBool("use_embeed_video_player") ??
                      false);
              String url = fbDownloadUrl(
                  baseUri: connectionStore.baseUri.value,
                  path: file['path'],
                  sid: connectionStore.sid.value,
                  mode: 'open');
              // String url = HttpUtil.baseUrl + "/fbdownload/${file['name']}?dlink=%22${HttpUtil.utf8Encode(file['path'])}%22&_sid=%22${HttpUtil.sid}%22&mode=open";
              // Log.info(url);
              // 调用nplayer
              // launchUrlString("nplayer-http://${Uri.encodeComponent(url)}");
              // 调用vlc player
              // launchUrlString("vlc://$url");
              // return;
              var openedExternally = false;
              if (preferExternalPlayer) {
                try {
                  await AndroidIntent(
                    action: 'action_view',
                    data: url,
                    arguments: {},
                    type: "video/*",
                  ).launch();
                  openedExternally = true;
                } catch (e) {
                  // 常见于没有能播视频的 App：退回内置播放器，别让点击没反应。
                  Log.error("外部播放器调用失败，改用内置播放器: $e");
                }
              }
              if (!openedExternally) {
                // 获取封面
                String name = file['name'];
                name = name.substring(0, name.lastIndexOf('.'));
                String cover = '';
                String nfo = '';
                try {
                  cover = files.value.firstWhere((element) =>
                      element['name'].startsWith("$name-fanart") ||
                      element['name'].startsWith("fanart"))['path'];
                } catch (e) {
                  try {
                    cover = files.value.firstWhere((element) =>
                        element['name'].startsWith("$name-thumb") ||
                        element['name'].startsWith("thumb"))['path'];
                  } catch (e) {
                    try {
                      cover = files.value.firstWhere((element) =>
                          element['name'].startsWith("$name-poster") ||
                          element['name'].startsWith("poster"))['path'];
                    } catch (e) {
                      try {
                        cover = files.value.firstWhere((element) =>
                            element['name'].startsWith("$name-cover") ||
                            element['name'].startsWith("cover"))['path'];
                      } catch (e) {
                        Log.info("无封面图");
                      }
                    }
                  }
                }
                try {
                  nfo = files.value.firstWhere(
                      (element) => element['name'] == "$name.nfo")['path'];
                } catch (e) {
                  Log.info("无NFO文件");
                }
                final subtitles =
                    FileTypeUtil.findSiblingSubtitles(files.value, name);
                if (context.mounted) {
                  // ignore: use_build_context_synchronously
                  Navigator.of(context)
                      .push(CupertinoPageRoute(builder: (context) {
                    return VideoPlayerPage(
                      url: url,
                      name: file['name'],
                      cover: cover,
                      nfo: nfo,
                      subtitles: subtitles,
                    );
                  }));
                }
              }

              break;
            case FileTypeEnum.music:
              initFloating();
              if (audioPlayerFloating.value?.isShowing == true) {
                audioPlayerFloating.value?.close();
              }
              String url = fbDownloadUrl(
                  baseUri: connectionStore.baseUri.value,
                  path: file['path'],
                  sid: connectionStore.sid.value,
                  mode: 'open');
              Navigator.of(context).push(CupertinoPageRoute(builder: (context) {
                return AudioPlayer(
                  url: url,
                  name: file['name'],
                );
              })).then((_) {
                // FIXME:
                // TODO:
                if (settingsStore.player.value?.state.playing == true &&
                    settingsStore.player.value?.state.completed == false) {
                  if (context.mounted) {
                    // ignore: use_build_context_synchronously
                    audioPlayerFloating.value?.open(context);
                  }
                }
              });
              break;
            // case FileType.music:
            //   AndroidIntent intent = AndroidIntent(
            //     action: 'action_view',
            //     data: HttpUtil.baseUrl + "/webapi/entry.cgi?api=SYNO.FileStation.Download&version=1&method=download&path=${Uri.encodeComponent(file['path'])}&mode=open&_sid=${HttpUtil.sid}",
            //     arguments: {},
            //     type: "audio/*",
            //   );
            //   await intent.launch();
            //   break;
            // case FileType.word:
            //   AndroidIntent intent = AndroidIntent(
            //     action: 'action_view',
            //     data: HttpUtil.baseUrl + "/webapi/entry.cgi?api=SYNO.FileStation.Download&version=1&method=download&path=${Uri.encodeComponent(file['path'])}&mode=open&_sid=${HttpUtil.sid}",
            //     arguments: {},
            //     type: "application/msword|application/vnd.openxmlformats-officedocument.wordprocessingml.document",
            //   );
            //   await intent.launch();
            //   break;
            // case FileType.excel:
            //   AndroidIntent intent = AndroidIntent(
            //     action: 'action_view',
            //     data: HttpUtil.baseUrl + "/webapi/entry.cgi?api=SYNO.FileStation.Download&version=1&method=download&path=${Uri.encodeComponent(file['path'])}&mode=open&_sid=${HttpUtil.sid}",
            //     arguments: {},
            //     type: "application/vnd.ms-excel|application/x-excel|application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
            //   );
            //   await intent.launch();
            //   break;
            // case FileType.ppt:
            //   AndroidIntent intent = AndroidIntent(
            //     action: 'action_view',
            //     data: HttpUtil.baseUrl + "/webapi/entry.cgi?api=SYNO.FileStation.Download&version=1&method=download&path=${Uri.encodeComponent(file['path'])}&mode=open&_sid=${HttpUtil.sid}",
            //     arguments: {},
            //     type: "application/vnd.ms-powerpoint|application/vnd.openxmlformats-officedocument.presentationml.presentation",
            //   );
            //   await intent.launch();
            //   break;
            case FileTypeEnum.code:
              openPlainFile(file);
              break;
            case FileTypeEnum.text:
              openPlainFile(file);
              break;
            case FileTypeEnum.pdf:
              Navigator.of(context).push(CupertinoPageRoute(builder: (context) {
                return PdfViewer(
                    fbDownloadUrl(
                        baseUri: connectionStore.baseUri.value,
                        path: file['path'],
                        sid: connectionStore.sid.value,
                        mode: 'open'),
                    file['name']);
              }));
              break;
            default:
              // 能嵌的走 WebView JS 预览，其余弹系统"打开方式"选择器
              await openExternally(file);
          }
        }
      }
    }

    fileAction(file, {bool remote = false}) async {
      UiUtil.vibrate(FeedbackType.light);
      showCupertinoModalPopup(
        context: context,
        builder: (context) => BottomActionSheet(
          title: "选择操作",
          leading: !remote
              ? Row(
                  children: [
                    OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        selectedFiles.value = [...selectedFiles.value, file];
                        multiSelect.value = true;
                      },
                      child: Row(
                        children: [
                          Image.asset(
                            "assets/icons/select_all.png",
                            width: 20,
                            height: 20,
                          ),
                          const SizedBox(width: 5),
                          const Text("多选"),
                        ],
                      ),
                    ),
                  ],
                )
              : null,
          actions: [
            BottomActionItem(
              label: "详情",
              iconAsset: "assets/icons/info_liner.png",
              onPressed: () {
                Navigator.of(context).push(CupertinoPageRoute(
                  builder: (context) => FileDetail(file),
                  settings: const RouteSettings(name: "file_detail"),
                ));
              },
            ),
            BottomActionItem(
              label: "下载",
              iconAsset: "assets/icons/download.png",
              onPressed: () => downloadFiles([file]),
            ),
            if (FileTypeUtil.toFileTypeEnum(
                        FileTypeUtil.getFileType(file['name'])) ==
                    FileTypeEnum.zip &&
                !remote &&
                file['path'].startsWith("/"))
              BottomActionItem(
                label: "解压",
                iconAsset: "assets/icons/unzip.png",
                onPressed: () => extractFile(file),
              ),
            if (paths.value.length > 1 &&
                !remote &&
                file['path'].startsWith("/"))
              BottomActionItem(
                label: "压缩",
                iconAsset: "assets/icons/archive.png",
                onPressed: () => compressFile([file['path']]),
              ),
            if (!remote && file['path'].startsWith("/"))
              BottomActionItem(
                label: "共享",
                iconAsset: "assets/icons/share.png",
                onPressed: () {
                  Navigator.of(context).push(CupertinoPageRoute(
                    builder: (context) => Share(paths: [file['path']]),
                    settings: const RouteSettings(name: "share"),
                  ));
                },
              ),
            if (file['isdir'] && !remote && file['path'].startsWith("/"))
              BottomActionItem(
                label: "文件请求",
                iconAsset: "assets/icons/upload.png",
                onPressed: () {
                  Navigator.of(context).push(CupertinoPageRoute(
                    builder: (context) => Share(
                      paths: [file['path']],
                      fileRequest: true,
                    ),
                    settings: const RouteSettings(name: "share"),
                  ));
                },
              ),
            if (paths.value.isNotEmpty)
              BottomActionItem(
                label: "重命名",
                iconAsset: "assets/icons/edit.png",
                onPressed: () {
                  showCupertinoDialog(
                    context: context,
                    builder: (context) => NameInputDialog(
                      title: "重命名",
                      onConfirm: (name) async {
                        try {
                          await dsmFileStationRenameForPage(file['path'], name);
                          UiUtil.toast("重命名成功");
                          refresh();
                        } catch (e) {
                          final raw = e is DSMException ? e.rawError : null;
                          final errors = raw?['errors'] as List?;
                          if (errors != null &&
                              errors.isNotEmpty &&
                              errors[0]['code'] == 414) {
                            UiUtil.toast("重命名失败：指定的名称已存在");
                          } else {
                            UiUtil.toast("重命名失败");
                          }
                        }
                      },
                    ),
                  );
                },
              ),
            if (file['isdir'] && !remote && file['path'].startsWith("/"))
              BottomActionItem(
                label: "添加收藏",
                iconAsset: "assets/icons/collect.png",
                onPressed: () async {
                  try {
                    await dsmFileStationFavoriteAddForPage(
                      "${file['name']} - ${paths.value[1]}",
                      file['path'],
                    );
                    UiUtil.toast("收藏成功");
                  } catch (e) {
                    UiUtil.toast("收藏失败，代码${_dsmErrorCode(e)}");
                  }
                },
              ),
            if (file['additional']['mount_point_type'] == "remote" &&
                file['path'].startsWith("/"))
              BottomActionItem(
                label: "卸载",
                iconAsset: "assets/icons/eject.png",
                onPressed: () async {
                  try {
                    await dsmFileStationMountUnmountForPage(file['path']);
                    UiUtil.toast("卸载成功");
                    refresh();
                    getSmbFolder();
                  } catch (e) {
                    UiUtil.toast("卸载失败，代码${_dsmErrorCode(e)}");
                  }
                },
              ),
            if (remote && !file['path'].startsWith("/"))
              BottomActionItem(
                label: "断开连接",
                iconAsset: "assets/icons/eject.png",
                onPressed: () async {
                  try {
                    await dsmFileStationVFSConnectionDeleteForPage(
                        file['path']);
                    UiUtil.toast("远程连接已断开");
                    refresh();
                    getSmbFolder();
                  } catch (e) {
                    UiUtil.toast("断开连接失败，代码${_dsmErrorCode(e)}");
                  }
                },
              ),
            if (paths.value.length > 1)
              BottomActionItem(
                label: "删除",
                iconAsset: "assets/icons/delete.png",
                labelColor: Colors.redAccent,
                onPressed: () => deleteFile([file['path']]),
              ),
          ],
        ),
      );
    }

    Future<bool> onWillPop() {
      if (multiSelect.value) {
        multiSelect.value = false;
        selectedFiles.value = [];
      } else if (searchResult.value) {
        refresh();
      } else {
        if (paths.value.isNotEmpty) {
          paths.value = List.of(paths.value)..removeLast();
          String path = "";
          Log.info(paths.value);
          if (paths.value.isNotEmpty && paths.value[0].contains("//")) {
            Log.info("远程");
            path = paths.value.join("/");
          } else {
            Log.info("本地");
            path = (paths.value.isNotEmpty ? "/" : '') + paths.value.join("/");
          }
          goPath(path);
        } else {
          return Future.value(true);
        }
      }

      return Future.value(false);
    }

    useEffect(() {
      filesOnWillPop.value = onWillPop;
      final subscription = filesDrawerOpen.subscribe((open) {
        if (!open) closeDrawer();
      });
      getShareList();
      getSmbFolder();
      getFtpFolder();
      getSftpFolder();
      getDavFolder();
      processingTimer.value =
          Timer.periodic(const Duration(seconds: 10), (timer) {
        // getBackgroundTask();
      });
      void listener() {
        String path = "";
        if (paths.value.isNotEmpty) {
          path = "/${paths.value.join("/")}";
        } else {
          path = "/";
        }
        scrollPosition.value[path] = fileScrollController.offset;
      }

      fileScrollController.addListener(listener);
      return () {
        subscription();
        searchTimer.value?.cancel();
        processingTimer.value?.cancel();
        fileScrollController.removeListener(listener);
      };
    }, const []);

    return Scaffold(
      key: scaffoldKey,
      onDrawerChanged: (isOpened) => filesDrawerOpen.value = isOpened,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        title: FileTitleActions(
          multiSelect: multiSelect,
          showProcessList: showProcessList,
          selectedFiles: selectedFiles,
          files: files,
          paths: paths,
          sortBy: sortBy,
          sortDirection: sortDirection,
          notVisitor: connectionStore.notVisitorAccount.watch(context),
          iconMode: listType.value == ListType.icon,
          hasBackgroundProcess: backgroundProcess.value.isNotEmpty,
          remoteFolders: smbFolders.value +
              ftpFolders.value +
              sftpFolders.value +
              davFolders.value,
          onToggleFavorite: () async {
            if (multiSelect.value) {
              multiSelect.value = false;
              selectedFiles.value = [];
            } else {
              scaffoldKey.currentState?.openDrawer();
              favoriteLoading.value = true;
              try {
                final data = await dsmFileStationFavoriteListForPage();
                favorites.value = data['favorites'] ?? [];
              } catch (e) {
                Log.warn('favorites: $e');
              } finally {
                favoriteLoading.value = false;
              }
            }
          },
          onToggleProcessList: () =>
              showProcessList.value = !showProcessList.value,
          onUpload: () {
            Navigator.of(context)
                .push(CupertinoPageRoute(
                  builder: (context) => Upload("/${paths.value.join("/")}"),
                  settings: const RouteSettings(name: "upload"),
                ))
                .then((value) => refresh());
          },
          onSearch: () {
            Navigator.of(context)
                .push(CupertinoPageRoute(
              builder: (content) => Search("/${paths.value.join("/")}"),
              settings: const RouteSettings(name: "search"),
            ))
                .then((res) {
              if (res != null) {
                search(res['folders'], res['pattern'], res['search_content']);
              }
            });
          },
          onToggleListType: () {
            listType.value =
                listType.value == ListType.list ? ListType.icon : ListType.list;
            StorageUtil.setString(
              "file_list_type",
              listType.value == ListType.list ? "list" : "icon",
            );
          },
          onSelectAll: () {
            if (selectedFiles.value.length == files.value.length) {
              selectedFiles.value = [];
            } else {
              selectedFiles.value = [];
              for (var file in files.value) {
                selectedFiles.value = [...selectedFiles.value, file];
              }
            }
          },
          onRefresh: refresh,
          onRefreshRemote: () {
            getFtpFolder();
            getSftpFolder();
            getSmbFolder();
            getDavFolder();
          },
          getVolumes: getVolumes,
          onFolderAction: (folder) => fileAction(folder, remote: true),
          onFolderTap: (folder, fileType) =>
              openFile(folder, fileType: fileType, remote: true),
        ),
      ),
      body: Column(
        children: [
          const Divider(
            indent: 12,
            endIndent: 12,
          ),
          if (searchResult.value)
            Container(
              height: 45,
              color: Theme.of(context).scaffoldBackgroundColor,
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  Container(
                    margin: const EdgeInsets.only(left: 20),
                    child: Card(
                      shape: RoundedRectangleBorder(
                          side: const BorderSide(),
                          borderRadius: BorderRadius.circular(18)),
                      child: const Padding(
                        padding:
                            EdgeInsets.symmetric(vertical: 3, horizontal: 5),
                        child: Text(
                          "搜索结果",
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      searchTimer.value?.cancel();

                      searching.value = false;
                      searchResult.value = false;
                      refresh();
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 20),
                      child: Card(
                        shape: RoundedRectangleBorder(
                            side: const BorderSide(),
                            borderRadius: BorderRadius.circular(18)),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 3, horizontal: 5),
                          child: searching.value
                              ? const Row(
                                  children: [
                                    Text(
                                      "搜索中",
                                      style: TextStyle(fontSize: 12),
                                    ),
                                    SizedBox(
                                      width: 5,
                                    ),
                                    CupertinoActivityIndicator(
                                      radius: 6,
                                    ),
                                  ],
                                )
                              : const Text(
                                  "退出搜索",
                                  style: TextStyle(fontSize: 12),
                                ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              height: 45,
              color: Theme.of(context).scaffoldBackgroundColor,
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.only(left: 20, top: 10, bottom: 10),
                    child: OutlinedButton(
                      onPressed: () {
                        goPath("");
                      },
                      child: const Icon(
                        CupertinoIcons.home,
                        size: 16,
                      ),
                    ),
                  ),
                  if (paths.value.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: const Icon(
                        CupertinoIcons.right_chevron,
                        size: 14,
                      ),
                    ),
                  Expanded(
                    child: ListView.separated(
                      controller: pathScrollController,
                      itemBuilder: (context, index) {
                        final label = paths.value[index];
                        return FilePathItem(
                          label: label,
                          onTap: () {
                            String path = "";
                            List<String> items = [];
                            if (paths.value.length > 1 &&
                                paths.value[0].contains("//")) {
                              Log.info("远程");
                              items = paths.value
                                  .getRange(0, index + 1)
                                  .toList()
                                  .cast();
                              path = items.join("/");
                              goPath(path);
                            } else {
                              Log.info("本地");
                              items = paths.value
                                  .getRange(0, index + 1)
                                  .toList()
                                  .cast();
                              path = "/${items.join("/")}";
                            }
                            goPath(path);
                          },
                        );
                      },
                      itemCount: paths.value.length,
                      scrollDirection: Axis.horizontal,
                      separatorBuilder: (context, i) {
                        return Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          child: const Icon(
                            CupertinoIcons.right_chevron,
                            size: 14,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          if (backgroundProcess.value.isNotEmpty && showProcessList.value)
            FileProcessList(backgroundProcess.value),
          Expanded(
            child: success.value
                ? Stack(
                    children: [
                      listType.value == ListType.list
                          ? Scrollbar(
                              controller: fileScrollController,
                              child: ListView.builder(
                                controller: fileScrollController,
                                padding: EdgeInsets.only(
                                    left: 20,
                                    right: 20,
                                    top: 20,
                                    bottom: selectedFiles.value.isNotEmpty
                                        ? 140
                                        : 20),
                                itemBuilder: (context, i) {
                                  final file = files.value[i];
                                  return FileListItem(
                                    file: file,
                                    remote: false,
                                    iconMode: listType.value == ListType.icon,
                                    multiSelect: multiSelect.value,
                                    selected:
                                        selectedFiles.value.contains(file),
                                    onAction: () => fileAction(file),
                                    onTap: () => openFile(file,
                                        fileType: FileTypeUtil.toFileTypeEnum(
                                            FileTypeUtil.getFileType(
                                                file['name']))),
                                  );
                                },
                                itemCount: files.value.length,
                              ),
                            )
                          : SizedBox(
                              width: double.infinity,
                              child: Scrollbar(
                                controller: fileScrollController,
                                child: ListView(
                                  controller: fileScrollController,
                                  padding: const EdgeInsets.all(20),
                                  children: [
                                    Wrap(
                                      runSpacing: 20,
                                      spacing: 20,
                                      children: files.value.map((file) {
                                        return FileListItem(
                                          file: file,
                                          remote: false,
                                          iconMode:
                                              listType.value == ListType.icon,
                                          multiSelect: multiSelect.value,
                                          selected: selectedFiles.value
                                              .contains(file),
                                          onAction: () => fileAction(file),
                                          onTap: () => openFile(file,
                                              fileType:
                                                  FileTypeUtil.toFileTypeEnum(
                                                      FileTypeUtil.getFileType(
                                                          file['name']))),
                                        );
                                      }).toList(),
                                    )
                                  ],
                                ),
                              ),
                            ),
                      // if (selectedFiles.length > 0)
                      AnimatedPositioned(
                        width: MediaQuery.sizeOf(context).width,
                        bottom: selectedFiles.value.isNotEmpty ? 0 : -100,
                        duration: const Duration(milliseconds: 200),
                        child: Card(
                          color: Colors.transparent.withAlpha(120),
                          shape: RoundedRectangleBorder(
                              side: BorderSide(
                                color: Theme.brightnessOf(context) ==
                                        Brightness.dark
                                    ? Colors.white
                                    : Colors.black,
                              ),
                              borderRadius: BorderRadius.circular(3)),
                          margin: const EdgeInsets.all(20),
                          child: Padding(
                            padding:
                                const EdgeInsets.all(AppConstants.paddingSmall),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    showFolderPickerSheet(context)
                                        .then((folder) async {
                                      if (folder != null &&
                                          folder.length == 1) {
                                        List<String> movePaths = selectedFiles
                                            .value
                                            .map((e) => e['path'] as String)
                                            .toList();
                                        try {
                                          final data =
                                              await dsmFileStationCopyMoveStartForPage(
                                                  movePaths, folder[0], true);
                                          selectedFiles.value = [];
                                          multiSelect.value = false;
                                          backgroundProcess
                                              .value[data['taskid']] = {
                                            "timer": null,
                                            "data": {
                                              "dest_folder_path": folder[0],
                                              "progress": 0,
                                            },
                                            "type": "move",
                                            "path": movePaths,
                                          };
                                          getProcessingTaskResult(
                                              data['taskid']);
                                        } catch (e) {
                                          Log.warn('copy/move failed: $e');
                                        }
                                      }
                                    });
                                  },
                                  child: Column(
                                    children: [
                                      Image.asset(
                                        "assets/icons/move.png",
                                        width: 25,
                                      ),
                                      const Text(
                                        "移动到",
                                        style: TextStyle(fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    showFolderPickerSheet(context)
                                        .then((folder) async {
                                      if (folder != null &&
                                          folder.length == 1) {
                                        List<String> copyPaths = selectedFiles
                                            .value
                                            .map((e) => e['path'] as String)
                                            .toList();
                                        try {
                                          final data =
                                              await dsmFileStationCopyMoveStartForPage(
                                                  copyPaths, folder[0], false);
                                          selectedFiles.value = [];
                                          multiSelect.value = false;
                                          backgroundProcess
                                              .value[data['taskid']] = {
                                            "timer": null,
                                            "data": {
                                              "dest_folder_path": folder[0],
                                              "progress": 0,
                                            },
                                            "type": "copy",
                                            "path": copyPaths,
                                          };
                                          getProcessingTaskResult(
                                              data['taskid']);
                                        } catch (e) {
                                          Log.warn('copy/move failed: $e');
                                        }
                                      }
                                    });
                                  },
                                  child: Column(
                                    children: [
                                      Image.asset(
                                        "assets/icons/copy.png",
                                        width: 25,
                                      ),
                                      const Text(
                                        "复制到",
                                        style: TextStyle(fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    compressFile(selectedFiles.value
                                        .map((e) => e['path'] as String)
                                        .toList());
                                  },
                                  child: Column(
                                    children: [
                                      Image.asset(
                                        "assets/icons/archive.png",
                                        width: 25,
                                      ),
                                      const Text(
                                        "压缩",
                                        style: TextStyle(fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    downloadFiles(selectedFiles.value);
                                  },
                                  child: Column(
                                    children: [
                                      Image.asset(
                                        "assets/icons/download.png",
                                        width: 25,
                                      ),
                                      const Text(
                                        "下载",
                                        style: TextStyle(fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    deleteFile(selectedFiles.value
                                        .map((e) => e['path'] as String)
                                        .toList());
                                  },
                                  child: Column(
                                    children: [
                                      Image.asset(
                                        "assets/icons/delete.png",
                                        width: 25,
                                      ),
                                      const Text(
                                        "删除",
                                        style: TextStyle(fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (loading.value)
                        Container(
                          width: MediaQuery.sizeOf(context).width,
                          height: MediaQuery.sizeOf(context).height,
                          color: Theme.of(context)
                              .scaffoldBackgroundColor
                              .withValues(alpha: .7),
                          child: const Center(
                            child: CupertinoActivityIndicator(
                              radius: 14,
                            ),
                          ),
                        ),
                    ],
                  )
                : Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          msg.value,
                          style: TextStyle(
                              color: AppTheme.of(context).placeholderColor),
                        ),
                        const SizedBox(
                          height: 20,
                        ),
                        SizedBox(
                          width: 200,
                          child: OutlinedButton(
                            onPressed: () {
                              refresh();
                            },
                            child: const Text(
                              ' 刷新 ',
                              style: TextStyle(fontSize: 18),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
      drawer: Favorite(goPath),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      // floatingActionButton: FloatingActionButton(
      //   child: Icon(Icons.refresh),
      //   onPressed: getBackgroundTask,
      // ),
    );
  }
}
