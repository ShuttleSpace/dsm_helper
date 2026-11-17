import 'dart:async';
import 'dart:convert';
import 'package:garden/api/dsm_api.dart';
import 'package:garden/api/dsm_api.filestation.transfer_url.dart';
import 'package:garden/extensions/datetime.dart';
import 'package:garden/extensions/int.dart';
import 'package:garden/extensions/string.dart';
import 'package:garden/services/office_preview.dart';
import 'package:garden/stores/settings_store.dart';
import 'package:garden/util/file_type_util.dart';
import 'package:garden/util/ui_util.dart';
import 'package:garden/util/storage_util.dart';
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
import 'package:garden/pages/control_panel/shared_folders/add_shared_folder.dart';
import 'package:garden/pages/file/detail.dart';
import 'package:garden/pages/file/favorite.dart';
import 'package:garden/pages/file/remote_folder.dart';
import 'package:garden/pages/file/search.dart';
import 'package:garden/pages/file/select_folder.dart';
import 'package:garden/pages/file/share.dart';
import 'package:garden/pages/file/share_manager.dart';
import 'package:garden/pages/file/upload.dart';
import 'package:garden/theme/app_theme.dart';
import 'package:garden/util/file_types.dart';
import 'package:garden/widgets/animation_progress_bar.dart';
import 'package:garden/hooks/use_file_download.dart';
import 'package:garden/hooks/use_file_click.dart';
import 'package:garden/extensions/context.dart';
import 'package:garden/widgets/file_icon.dart';
import 'package:garden/widgets/transparent_router.dart';
import 'package:extended_text/extended_text.dart';
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
                        padding: const EdgeInsets.all(AppConstants.paddingSmall),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            const Text(
                              "下载确认",
                              style: TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(
                              height: 12,
                            ),
                            const Text(
                              "您当前正在使用数据网络，下载文件可能会产生流量费用，是否继续下载？",
                              style: TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.w400),
                            ),
                            const SizedBox(
                              height: 22,
                            ),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () async {
                                      Navigator.of(context).pop(true);
                                      download(filePaths);
                                    },
                                    child: const Text(
                                      "下载",
                                      style: TextStyle(
                                          fontSize: 18, color: Colors.redAccent),
                                    ),
                                  ),
                                ),
                                const SizedBox(
                                  width: 20,
                                ),
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () async {
                                      Navigator.of(context).pop(false);
                                    },
                                    child: const Text(
                                      "取消",
                                      style: TextStyle(fontSize: 18),
                                    ),
                                  ),
                                ),
                              ],
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
    Widget buildSortMenu(BuildContext context) {
      return Material(
        color: Colors.transparent,
        child: Card(
          shape: context.stadiumShapeBorder,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Card(
                  shape: RoundedRectangleBorder(
                      side: const BorderSide(),
                      borderRadius: BorderRadius.circular(18)),
                  child: SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: () {
                              sortBy.value = "name";
                            },
                            child: Row(
                              children: [
                                const Expanded(
                                  child: Text("名称"),
                                ),
                                Card(
                                  shape: RoundedRectangleBorder(
                                      side: const BorderSide(),
                                      borderRadius: BorderRadius.circular(18)),
                                  child: Padding(
                                    padding: const EdgeInsets.all(
                                        AppConstants.paddingSmall),
                                    child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: sortBy.value == "name"
                                          ? Icon(
                                              CupertinoIcons.checkmark_alt,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primary,
                                            )
                                          : null,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 5),
                          GestureDetector(
                            onTap: () {
                              sortBy.value = "size";
                            },
                            child: Row(
                              children: [
                                const Expanded(
                                  child: Text("大小"),
                                ),
                                Card(
                                  shape: RoundedRectangleBorder(
                                      side: const BorderSide(),
                                      borderRadius: BorderRadius.circular(18)),
                                  child: Padding(
                                    padding: const EdgeInsets.all(
                                        AppConstants.paddingSmall),
                                    child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: sortBy.value == "size"
                                          ? Icon(
                                              CupertinoIcons.checkmark_alt,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primary,
                                            )
                                          : null,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 5),
                          GestureDetector(
                            onTap: () {
                              sortBy.value = "type";
                            },
                            child: Row(
                              children: [
                                const Expanded(
                                  child: Text("文件类型"),
                                ),
                                Card(
                                  shape: RoundedRectangleBorder(
                                      side: const BorderSide(),
                                      borderRadius: BorderRadius.circular(18)),
                                  child: Padding(
                                    padding: const EdgeInsets.all(
                                        AppConstants.paddingSmall),
                                    child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: sortBy.value == "type"
                                          ? Icon(
                                              CupertinoIcons.checkmark_alt,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primary,
                                            )
                                          : null,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 5),
                          GestureDetector(
                            onTap: () {
                              sortBy.value = "mtime";
                            },
                            child: Row(
                              children: [
                                const Expanded(
                                  child: Text("修改日期"),
                                ),
                                Card(
                                  shape: RoundedRectangleBorder(
                                      side: const BorderSide(),
                                      borderRadius: BorderRadius.circular(18)),
                                  child: Padding(
                                    padding: const EdgeInsets.all(
                                        AppConstants.paddingSmall),
                                    child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: sortBy.value == "mtime"
                                          ? Icon(
                                              CupertinoIcons.checkmark_alt,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primary,
                                            )
                                          : null,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 5),
                          GestureDetector(
                            onTap: () {
                              sortBy.value = "crtime";
                            },
                            child: Row(
                              children: [
                                const Expanded(
                                  child: Text("创建日期"),
                                ),
                                Card(
                                  shape: RoundedRectangleBorder(
                                      side: const BorderSide(),
                                      borderRadius: BorderRadius.circular(18)),
                                  child: Padding(
                                    padding: const EdgeInsets.all(
                                        AppConstants.paddingSmall),
                                    child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: sortBy.value == "crtime"
                                          ? Icon(
                                              CupertinoIcons.checkmark_alt,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primary,
                                            )
                                          : null,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 5),
                          GestureDetector(
                            onTap: () {
                              sortBy.value = "atime";
                            },
                            child: Row(
                              children: [
                                const Expanded(
                                  child: Text("最近访问时间"),
                                ),
                                Card(
                                  shape: RoundedRectangleBorder(
                                      side: const BorderSide(),
                                      borderRadius: BorderRadius.circular(18)),
                                  child: Padding(
                                    padding: const EdgeInsets.all(
                                        AppConstants.paddingSmall),
                                    child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: sortBy.value == "atime"
                                          ? Icon(
                                              CupertinoIcons.checkmark_alt,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primary,
                                            )
                                          : null,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 5),
                          GestureDetector(
                            onTap: () {
                              sortBy.value = "posix";
                            },
                            child: Row(
                              children: [
                                const Expanded(
                                  child: Text("权限"),
                                ),
                                Card(
                                  shape: RoundedRectangleBorder(
                                      side: const BorderSide(),
                                      borderRadius: BorderRadius.circular(18)),
                                  child: Padding(
                                    padding: const EdgeInsets.all(
                                        AppConstants.paddingSmall),
                                    child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: sortBy.value == "posix"
                                          ? Icon(
                                              CupertinoIcons.checkmark_alt,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primary,
                                            )
                                          : null,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 5),
                          GestureDetector(
                            onTap: () {
                              sortBy.value = "user";
                            },
                            child: Row(
                              children: [
                                const Expanded(
                                  child: Text("拥有者"),
                                ),
                                Card(
                                  shape: RoundedRectangleBorder(
                                      side: const BorderSide(),
                                      borderRadius: BorderRadius.circular(18)),
                                  child: Padding(
                                    padding: const EdgeInsets.all(
                                        AppConstants.paddingSmall),
                                    child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: sortBy.value == "user"
                                          ? Icon(
                                              CupertinoIcons.checkmark_alt,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primary,
                                            )
                                          : null,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 5),
                          GestureDetector(
                            onTap: () {
                              sortBy.value = "group";
                            },
                            child: Row(
                              children: [
                                const Expanded(
                                  child: Text("群组"),
                                ),
                                Card(
                                  shape: RoundedRectangleBorder(
                                      side: const BorderSide(),
                                      borderRadius: BorderRadius.circular(18)),
                                  child: Padding(
                                    padding: const EdgeInsets.all(
                                        AppConstants.paddingSmall),
                                    child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: sortBy.value == "group"
                                          ? Icon(
                                              CupertinoIcons.checkmark_alt,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primary,
                                            )
                                          : null,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(
                  height: 20,
                ),
                Card(
                  shape: RoundedRectangleBorder(
                      side: const BorderSide(),
                      borderRadius: BorderRadius.circular(18)),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: () {
                            sortDirection.value = "ASC";
                          },
                          child: Row(
                            children: [
                              const Expanded(
                                child: Text("由小至大"),
                              ),
                              Card(
                                shape: RoundedRectangleBorder(
                                    side: const BorderSide(),
                                    borderRadius: BorderRadius.circular(18)),
                                child: Padding(
                                  padding: const EdgeInsets.all(
                                      AppConstants.paddingSmall),
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: sortDirection.value == "ASC"
                                        ? Icon(
                                            CupertinoIcons.checkmark_alt,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary,
                                          )
                                        : null,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 5),
                        GestureDetector(
                          onTap: () {
                            sortDirection.value = "DESC";
                          },
                          child: Row(
                            children: [
                              const Expanded(
                                child: Text("由大至小"),
                              ),
                              Card(
                                shape: RoundedRectangleBorder(
                                    side: const BorderSide(),
                                    borderRadius: BorderRadius.circular(18)),
                                child: Padding(
                                  padding: const EdgeInsets.all(
                                      AppConstants.paddingSmall),
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: sortDirection.value == "DESC"
                                        ? Icon(
                                            CupertinoIcons.checkmark_alt,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary,
                                          )
                                        : null,
                                  ),
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
                  height: 22,
                ),
                OutlinedButton(
                  onPressed: () async {
                    Navigator.of(context).pop();
                  },
                  child: const Text(
                    "确定",
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
      );
    }
    deleteFile(List<String> filePaths) {
      UiUtil.vibrate(FeedbackType.warning);
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
                  padding: const EdgeInsets.all(AppConstants.paddingSmall),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      const Text(
                        "确认删除",
                        style:
                            TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(
                        height: 12,
                      ),
                      const Text(
                        "确认要删除文件？",
                        style:
                            TextStyle(fontSize: 20, fontWeight: FontWeight.w400),
                      ),
                      const SizedBox(
                        height: 22,
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () async {
                                Navigator.of(context).pop();
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
                              child: const Text(
                                "确认删除",
                                style: TextStyle(
                                    fontSize: 18, color: Colors.redAccent),
                              ),
                            ),
                          ),
                          const SizedBox(
                            width: 20,
                          ),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () async {
                                Navigator.of(context).pop();
                              },
                              child: const Text(
                                "取消",
                                style: TextStyle(fontSize: 18),
                              ),
                            ),
                          ),
                        ],
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
          return Material(
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
                        style:
                            TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
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
                                await dsmFileStationCompressStartForPage(file, destPath);
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
          );
        },
      );
    }
    openFile(file,
        {FileTypeEnum fileType = FileTypeEnum.other, bool remote = false}) async {
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
              bool useEmbeedVideoPlayer =
                  await StorageUtil.getBool("use_embeed_video_player") ?? true;
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
              if (useEmbeedVideoPlayer) {
                AndroidIntent intent = AndroidIntent(
                  action: 'action_view',
                  data: url,
                  arguments: {},
                  type: "video/*",
                );
                await intent.launch();
              } else {
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
                if (context.mounted) {
                  // ignore: use_build_context_synchronously
                  Navigator.of(context)
                      .push(CupertinoPageRoute(builder: (context) {
                    return VideoPlayerPage(
                      url: url,
                      name: file['name'],
                      cover: cover,
                      nfo: nfo,
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
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Stack(
                        children: [
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "选择操作",
                                style: TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                          if (!remote)
                            Row(
                              children: [
                                OutlinedButton(
                                  onPressed: () async {
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
                                      const SizedBox(
                                        width: 5,
                                      ),
                                      const Text("多选"),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                      SizedBox(
                        width: double.infinity,
                        child: Wrap(
                          runSpacing: 20,
                          spacing: 20,
                          children: [
                            Container(
                              constraints: const BoxConstraints(maxWidth: 112),
                              width: (MediaQuery.sizeOf(context).width - 100) / 3,
                              child: OutlinedButton(
                                onPressed: () async {
                                  Navigator.of(context).pop();
                                  Navigator.of(context).push(CupertinoPageRoute(
                                      builder: (context) {
                                        return FileDetail(file);
                                      },
                                      settings: const RouteSettings(
                                          name: "file_detail")));
                                },
                                child: Column(
                                  children: [
                                    Image.asset(
                                      "assets/icons/info_liner.png",
                                      width: 30,
                                    ),
                                    const Text(
                                      "详情",
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Container(
                              constraints: const BoxConstraints(maxWidth: 112),
                              width: (MediaQuery.sizeOf(context).width - 100) / 3,
                              child: OutlinedButton(
                                onPressed: () async {
                                  Navigator.of(context).pop();
                                  downloadFiles([file]);
                                },
                                child: Column(
                                  children: [
                                    Image.asset(
                                      "assets/icons/download.png",
                                      width: 30,
                                    ),
                                    const Text(
                                      "下载",
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (FileTypeUtil.toFileTypeEnum(
                                        FileTypeUtil.getFileType(file['name'])) ==
                                    FileTypeEnum.zip &&
                                !remote &&
                                file['path'].startsWith("/"))
                              Container(
                                constraints: const BoxConstraints(maxWidth: 112),
                                width:
                                    (MediaQuery.sizeOf(context).width - 100) / 3,
                                child: OutlinedButton(
                                  onPressed: () async {
                                    Navigator.of(context).pop();
                                    extractFile(file);
                                  },
                                  child: Column(
                                    children: [
                                      Image.asset(
                                        "assets/icons/unzip.png",
                                        width: 30,
                                      ),
                                      const Text(
                                        "解压",
                                        style: TextStyle(fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            if (paths.value.length > 1 &&
                                !remote &&
                                !remote &&
                                file['path'].startsWith("/"))
                              Container(
                                constraints: const BoxConstraints(maxWidth: 112),
                                width:
                                    (MediaQuery.sizeOf(context).width - 100) / 3,
                                child: OutlinedButton(
                                  onPressed: () async {
                                    Navigator.of(context).pop();
                                    compressFile([file['path']]);
                                  },
                                  child: Column(
                                    children: [
                                      Image.asset(
                                        "assets/icons/archive.png",
                                        width: 30,
                                      ),
                                      const Text(
                                        "压缩",
                                        style: TextStyle(fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            if (!remote &&
                                !remote &&
                                file['path'].startsWith("/"))
                              Container(
                                constraints: const BoxConstraints(maxWidth: 112),
                                width:
                                    (MediaQuery.sizeOf(context).width - 100) / 3,
                                child: OutlinedButton(
                                  onPressed: () async {
                                    Navigator.of(context).pop();
                                    Navigator.of(context).push(CupertinoPageRoute(
                                        builder: (context) {
                                          return Share(paths: [file['path']]);
                                        },
                                        settings:
                                            const RouteSettings(name: "share")));
                                  },
                                  child: Column(
                                    children: [
                                      Image.asset(
                                        "assets/icons/share.png",
                                        width: 30,
                                      ),
                                      const Text(
                                        "共享",
                                        style: TextStyle(fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            if (file['isdir'] &&
                                !remote &&
                                !remote &&
                                file['path'].startsWith("/")) ...[
                              Container(
                                constraints: const BoxConstraints(maxWidth: 112),
                                width:
                                    (MediaQuery.sizeOf(context).width - 100) / 3,
                                child: OutlinedButton(
                                  onPressed: () async {
                                    Navigator.of(context).pop();
                                    Navigator.of(context).push(CupertinoPageRoute(
                                        builder: (context) {
                                          return Share(
                                            paths: [file['path']],
                                            fileRequest: true,
                                          );
                                        },
                                        settings:
                                            const RouteSettings(name: "share")));
                                  },
                                  child: Column(
                                    children: [
                                      Image.asset(
                                        "assets/icons/upload.png",
                                        width: 30,
                                      ),
                                      const Text(
                                        "文件请求",
                                        style: TextStyle(fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                            if (paths.value.isNotEmpty)
                              Container(
                                constraints: const BoxConstraints(maxWidth: 112),
                                width:
                                    (MediaQuery.sizeOf(context).width - 100) / 3,
                                child: OutlinedButton(
                                  onPressed: () async {
                                    TextEditingController nameController =
                                        TextEditingController.fromValue(
                                            TextEditingValue(text: file['name']));
                                    Navigator.of(context).pop();
                                    String name = "";
                                    showCupertinoDialog(
                                      context: context,
                                      builder: (context) {
                                        return Material(
                                          color: Colors.transparent,
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Card(
                                                shape: RoundedRectangleBorder(
                                                    side: const BorderSide(),
                                                    borderRadius:
                                                        BorderRadius.circular(5)),
                                                margin:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 50),
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.all(20),
                                                  child: Column(
                                                    children: [
                                                      const Text(
                                                        "重命名",
                                                        style: TextStyle(
                                                            fontSize: 20,
                                                            fontWeight:
                                                                FontWeight.w500),
                                                      ),
                                                      const SizedBox(
                                                        height: 16,
                                                      ),
                                                      Card(
                                                        shape: RoundedRectangleBorder(
                                                            side:
                                                                const BorderSide(),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(5)),
                                                        child: Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                  .all(8.0),
                                                          child: TextField(
                                                            onChanged: (v) =>
                                                                name = v,
                                                            controller:
                                                                nameController,
                                                            decoration:
                                                                const InputDecoration(
                                                              border: InputBorder
                                                                  .none,
                                                              hintText: "请输入新的名称",
                                                              labelText: "文件名",
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(
                                                        height: 16,
                                                      ),
                                                      Row(
                                                        children: [
                                                          Expanded(
                                                            child: OutlinedButton(
                                                              onPressed:
                                                                  () async {
                                                                if (name.trim() ==
                                                                    "") {
                                                                  UiUtil.toast(
                                                                      "请输入新文件名");
                                                                  return;
                                                                }
                                                                Navigator.of(
                                                                        context)
                                                                    .pop();
                                                                try {
                                                                  await dsmFileStationRenameForPage(
                                                                      file['path'], name);
                                                                  UiUtil.toast("重命名成功");
                                                                  refresh();
                                                                } catch (e) {
                                                                  final raw = e is DSMException
                                                                      ? e.rawError
                                                                      : null;
                                                                  final errors =
                                                                      raw?['errors'] as List?;
                                                                  if (errors != null &&
                                                                      errors.isNotEmpty &&
                                                                      errors[0]['code'] == 414) {
                                                                    UiUtil.toast("重命名失败：指定的名称已存在");
                                                                  } else {
                                                                    UiUtil.toast("重命名失败");
                                                                  }
                                                                }
                                                              },
                                                              child: const Text(
                                                                "确定",
                                                                style: TextStyle(
                                                                    fontSize: 18),
                                                              ),
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                            width: 16,
                                                          ),
                                                          Expanded(
                                                            child: OutlinedButton(
                                                              onPressed:
                                                                  () async {
                                                                Navigator.of(
                                                                        context)
                                                                    .pop();
                                                              },
                                                              child: const Text(
                                                                "取消",
                                                                style: TextStyle(
                                                                    fontSize: 18),
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      )
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    );
                                  },
                                  child: Column(
                                    children: [
                                      Image.asset(
                                        "assets/icons/edit.png",
                                        width: 30,
                                      ),
                                      const Text(
                                        "重命名",
                                        style: TextStyle(fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            if (file['isdir'] &&
                                !remote &&
                                !remote &&
                                file['path'].startsWith("/"))
                              Container(
                                constraints: const BoxConstraints(maxWidth: 112),
                                width:
                                    (MediaQuery.sizeOf(context).width - 100) / 3,
                                child: OutlinedButton(
                                  onPressed: () async {
                                    Navigator.of(context).pop();
                                    try {
                                      await dsmFileStationFavoriteAddForPage(
                                          "${file['name']} - ${paths.value[1]}",
                                          file['path']);
                                      UiUtil.toast("收藏成功");
                                    } catch (e) {
                                      UiUtil.toast("收藏失败，代码${_dsmErrorCode(e)}");
                                    }
                                  },
                                  child: Column(
                                    children: [
                                      Image.asset(
                                        "assets/icons/collect.png",
                                        width: 30,
                                      ),
                                      const Text(
                                        "添加收藏",
                                        style: TextStyle(fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            if (file['additional']['mount_point_type'] ==
                                    "remote" &&
                                file['path'].startsWith("/"))
                              Container(
                                constraints: const BoxConstraints(maxWidth: 112),
                                width:
                                    (MediaQuery.sizeOf(context).width - 100) / 3,
                                child: OutlinedButton(
                                  onPressed: () async {
                                    Navigator.of(context).pop();
                                    try {
                                      await dsmFileStationMountUnmountForPage(file['path']);
                                      UiUtil.toast("卸载成功");
                                      refresh();
                                      getSmbFolder();
                                    } catch (e) {
                                      UiUtil.toast("卸载失败，代码${_dsmErrorCode(e)}");
                                    }
                                  },
                                  child: Column(
                                    children: [
                                      Image.asset(
                                        "assets/icons/eject.png",
                                        width: 30,
                                      ),
                                      const Text(
                                        "卸载",
                                        style: TextStyle(fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            if (remote && !file['path'].startsWith("/"))
                              Container(
                                constraints: const BoxConstraints(maxWidth: 112),
                                width:
                                    (MediaQuery.sizeOf(context).width - 100) / 3,
                                child: OutlinedButton(
                                  onPressed: () async {
                                    Navigator.of(context).pop();
                                    try {
                                      await dsmFileStationVFSConnectionDeleteForPage(file['path']);
                                      UiUtil.toast("远程连接已断开");
                                      refresh();
                                      getSmbFolder();
                                    } catch (e) {
                                      UiUtil.toast("断开连接失败，代码${_dsmErrorCode(e)}");
                                    }
                                  },
                                  child: Column(
                                    children: [
                                      Image.asset(
                                        "assets/icons/eject.png",
                                        width: 30,
                                      ),
                                      const Text(
                                        "断开连接",
                                        style: TextStyle(fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            if (paths.value.length > 1)
                              Container(
                                constraints: const BoxConstraints(maxWidth: 112),
                                width:
                                    (MediaQuery.sizeOf(context).width - 100) / 3,
                                child: OutlinedButton(
                                  onPressed: () async {
                                    Navigator.of(context).pop();
                                    deleteFile([file['path']]);
                                  },
                                  child: Column(
                                    children: [
                                      Image.asset(
                                        "assets/icons/delete.png",
                                        width: 30,
                                      ),
                                      const Text(
                                        "删除",
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.redAccent),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
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
    }
    Widget buildFileItem(file, {bool remote = false}) {
      FileTypeEnum fileType =
          FileTypeUtil.toFileTypeEnum(FileTypeUtil.getFileType(file['name']));
      String path = file['path'];
      Widget actionButton = multiSelect.value
          ? Card(
              shape: RoundedRectangleBorder(
                  side: const BorderSide(),
                  borderRadius: BorderRadius.circular(18)),
              child: SizedBox(
                width: 20,
                height: 20,
                child: selectedFiles.value.contains(file)
                    ? Icon(
                        CupertinoIcons.checkmark_alt,
                        color: Theme.of(context).colorScheme.primary,
                      )
                    : null,
              ),
            )
          : GestureDetector(
              onTap: () {
                fileAction(file, remote: remote);
              },
              child: Card(
                shape: RoundedRectangleBorder(
                    side: const BorderSide(),
                    borderRadius: BorderRadius.circular(18)),
                // padding: EdgeInsets.zero,
                child: const Padding(
                  padding: EdgeInsets.all(2.0),
                  child: Icon(
                    CupertinoIcons.right_chevron,
                    size: 14,
                  ),
                ),
              ),
            );
      return Container(
        constraints: listType.value == ListType.icon && !remote
            ? const BoxConstraints(maxWidth: 112)
            : null,
        width: listType.value == ListType.icon && !remote
            ? (MediaQuery.sizeOf(context).width - 80) / 3
            : double.infinity,
        padding: listType.value == ListType.icon && !remote
            ? EdgeInsets.zero
            : const EdgeInsets.only(bottom: 20.0),
        child: OutlinedButton(
          onLongPress: () {
            UiUtil.vibrate(FeedbackType.light);
            fileAction(file, remote: remote);
          },
          onPressed: () {
            openFile(file, fileType: fileType, remote: remote);
          },
          child: listType.value == ListType.list || remote
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 10,
                      ),
                      Hero(
                        tag: thumbUrl(
                          baseUri: connectionStore.baseUri.value,
                          path: path,
                          sid: connectionStore.sid.value,
                        ),
                        child: FileIcon(
                          file['isdir'] ? FileTypeEnum.folder : fileType,
                          thumb: file['path'],
                        ),
                      ),
                      const SizedBox(
                        width: 10,
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ExtendedText(
                              file['name'],
                              style: TextStyle(
                                  fontSize: 14,
                                  color: file['additional']['mount_point_type'] ==
                                          "remotefail"
                                      ? AppTheme.of(context).titleColor
                                      : Theme.brightnessOf(context) ==
                                              Brightness.dark
                                          ? Colors.white
                                          : Colors.black),
                              overflowWidget: const TextOverflowWidget(
                                position: TextOverflowPosition.middle,
                                align: TextOverflowAlign.right,
                                child: Text(
                                  "…",
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ),
                              maxLines: 2,
                            ),
                            const SizedBox(
                              height: 5,
                            ),
                            if (!file['isdir'] && file['additional'] != null ||
                                (file['additional']['time'] != null &&
                                    file['additional']['time']['mtime'] != null))
                              Text.rich(
                                TextSpan(
                                  children: [
                                    if (!file['isdir'])
                                      TextSpan(
                                          text: (int.parse(
                                                  file['additional']['size']
                                                      .toString()))
                                              .formatSize()),
                                    if (file['additional'] != null &&
                                        file['additional']['time'] != null &&
                                        file['additional']['time']['mtime'] !=
                                            null)
                                      TextSpan(
                                        text: (file['isdir'] ? "" : " | ") +
                                            DateTime.fromMillisecondsSinceEpoch(
                                                    file['additional']['time']
                                                            ['mtime'] *
                                                        1000)
                                                .format("Y/m/d H:i:s"),
                                      )
                                  ],
                                  style: TextStyle(
                                      fontSize: 12,
                                      color:
                                          AppTheme.of(context).placeholderColor),
                                ),
                              ),
                            if (remote)
                              Text(
                                file['path'],
                                style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.of(context).placeholderColor),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(
                        width: 10,
                      ),
                      actionButton,
                      const SizedBox(
                        width: 10,
                      ),
                    ],
                  ),
                )
              : Stack(
                  children: [
                    Align(
                      alignment: Alignment.center,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 5,
                        ),
                        child: Column(
                          children: [
                            Hero(
                              tag: thumbUrl(
                                baseUri: connectionStore.baseUri.value,
                                path: path,
                                sid: connectionStore.sid.value,
                              ),
                              child: FileIcon(
                                file['isdir'] ? FileTypeEnum.folder : fileType,
                                thumb: file['path'],
                                width:
                                    (MediaQuery.sizeOf(context).width - 140) / 3,
                                height: 30,
                              ),
                            ),
                            const SizedBox(
                              height: 10,
                            ),
                            Text(
                              file['name'],
                              maxLines: 1,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (multiSelect.value)
                      Align(
                        alignment: Alignment.topRight,
                        child: Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: actionButton,
                        ),
                      ),
                  ],
                ),
        ),
      );
    }
    Widget buildPathItem(BuildContext context, int index) {
      return Container(
        padding:
            const EdgeInsets.symmetric(vertical: AppConstants.paddingSmall + 2),
        child: OutlinedButton(
          onPressed: () {
            String path = "";
            List<String> items = [];
            if (paths.value.length > 1 && paths.value[0].contains("//")) {
              Log.info("远程");
              items = paths.value.getRange(0, index + 1).toList().cast();
              path = items.join("/");
              goPath(path);
            } else {
              Log.info("本地");
              items = paths.value.getRange(0, index + 1).toList().cast();
              path = "/${items.join("/")}";
            }
            goPath(path);
          },
          child: Text(
            paths.value[index],
            style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).textTheme.headlineMedium?.color),
          ),
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
    Widget buildProcessList() {
      List<Widget> children = [];
      Map<String, String> types = {
        "copy": "复制：",
        "move": "移动：",
        "delete": "删除：",
        "extract": "解压：",
        "compress": "压缩：",
      };
      backgroundProcess.value.forEach((key, task) {
        var value = task['data'];
        children.add(
          Card(
            shape: RoundedRectangleBorder(
                side: const BorderSide(),
                borderRadius: BorderRadius.circular(18)),
            margin: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: types["${task['type'] ?? ''}"],
                        ),
                        TextSpan(
                          text: task['path']
                              .map((e) => e.split("/").last)
                              .join(","),
                          style: TextStyle(
                              color: AppTheme.of(context).placeholderColor),
                        ),
                        if (['copy', 'move', 'achieve', 'compress']
                                .contains(task['type']) &&
                            value != null) ...[
                          const TextSpan(
                            text: " 至 ",
                          ),
                          TextSpan(
                            text: value['dest_folder_path'] ?? '',
                            style: TextStyle(
                                color: AppTheme.of(context).placeholderColor),
                          ),
                        ],
                      ],
                    ),
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  if (value != null)
                    FAProgressBar(
                      backgroundColor: Colors.transparent,
                      changeColorValue: 100,
                      changeProgressColor: Colors.green,
                      progressColor: Colors.blue,
                      size: 20,
                      currentValue:
                          (num.parse("${value['progress']}") * 100).toInt(),
                      displayText: '%',
                    ),
                ],
              ),
            ),
          ),
        );
      });
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: children,
      );
    }
    Widget buildTitleAction(BuildContext context) {
      return SizedBox(
        width: MediaQuery.sizeOf(context).width,
        height: 50,
        child: ListView(
          scrollDirection: Axis.horizontal,
          shrinkWrap: true,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 10, top: 8, bottom: 8),
              child: OutlinedButton(
                onPressed: () async {
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
                child: multiSelect.value
                    ? const Icon(Icons.close)
                    : Image.asset(
                        "assets/icons/collect.png",
                        width: 20,
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 10, top: 8, bottom: 8),
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
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  Stack(
                                    children: [
                                      const Align(
                                        alignment: Alignment.center,
                                        child: Text(
                                          "远程文件夹",
                                          style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.w500),
                                        ),
                                      ),
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: SizedBox(
                                          width: 30,
                                          height: 30,
                                          child: OutlinedButton(
                                            onPressed: () async {
                                              UiUtil.toast("重新加载远程连接中");
                                              Navigator.of(context).pop();
                                              getFtpFolder();
                                              getSftpFolder();
                                              getSmbFolder();
                                              getDavFolder();
                                            },
                                            child: const Icon(
                                              Icons.refresh,
                                              size: 20,
                                            ),
                                          ),
                                        ),
                                      )
                                    ],
                                  ),
                                  const SizedBox(
                                    height: 20,
                                  ),
                                  Container(
                                    constraints: BoxConstraints(
                                      minHeight: 50,
                                      maxHeight:
                                          MediaQuery.sizeOf(context).height * 0.8,
                                    ),
                                    child: SingleChildScrollView(
                                      child: Column(
                                        children: [
                                          if ((smbFolders.value +
                                                  ftpFolders.value +
                                                  sftpFolders.value +
                                                  davFolders.value)
                                              .isNotEmpty) ...[
                                            ...(smbFolders.value +
                                                    ftpFolders.value +
                                                    sftpFolders.value +
                                                    davFolders.value)
                                                .map((folder) {
                                              return buildFileItem(folder,
                                                  remote: true);
                                            }),
                                          ] else
                                            Center(
                                              child: Text(
                                                "未挂载远程文件夹",
                                                style: TextStyle(
                                                    color: AppTheme.of(context)
                                                        .placeholderColor),
                                              ),
                                            ),
                                        ],
                                      ),
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
                child: Image.asset(
                  "assets/icons/remote.png",
                  width: 20,
                ),
              ),
            ),
            if (connectionStore.notVisitorAccount.watch(context) &&
                paths.value.isNotEmpty &&
                !multiSelect.value)
              Padding(
                padding: const EdgeInsets.only(left: 10, top: 8, bottom: 8),
                child: OutlinedButton(
                  onPressed: () async {
                    Navigator.of(context)
                        .push(CupertinoPageRoute(
                            builder: (context) {
                              return Upload("/${paths.value.join("/")}");
                            },
                            settings: const RouteSettings(name: "upload")))
                        .then((value) {
                      refresh();
                    });
                  },
                  child: Image.asset(
                    "assets/icons/upload.png",
                    width: 20,
                  ),
                ),
              ),
            if (backgroundProcess.value.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 10, top: 8, bottom: 8),
                child: OutlinedButton(
                  onPressed: () async {
                  
                    showProcessList.value = !showProcessList.value;
                
                  },
                  child: Image.asset(
                    "assets/icons/bgtask.gif",
                    width: 20,
                  ),
                ),
              ),
            const SizedBox(
              width: 24,
            ),
            if (paths.value.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(right: 10, top: 8, bottom: 8),
                child: OutlinedButton(
                  onPressed: () async {
                    Navigator.of(context)
                        .push(CupertinoPageRoute(
                            builder: (content) {
                              return Search("/${paths.value.join("/")}");
                            },
                            settings: const RouteSettings(name: "search")))
                        .then((res) {
                      if (res != null) {
                        search(res['folders'], res['pattern'],
                            res['search_content']);
                      }
                    });
                  },
                  child: Image.asset(
                    "assets/icons/search.png",
                    width: 20,
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(right: 10, top: 8, bottom: 8),
              child: OutlinedButton(
                onPressed: () {
                
                  listType.value =
                      listType.value == ListType.list ? ListType.icon : ListType.list;
              
                  StorageUtil.setString("file_list_type",
                      listType.value == ListType.list ? "list" : "icon");
                },
                child: Image.asset(
                  listType.value == ListType.list
                      ? "assets/icons/list_list.png"
                      : "assets/icons/list_icon.png",
                  width: 20,
                  height: 20,
                ),
              ),
            ),
            if (multiSelect.value)
              Padding(
                padding: const EdgeInsets.only(right: 10, top: 8, bottom: 8),
                child: OutlinedButton(
                  onPressed: () {
                    if (selectedFiles.value.length == files.value.length) {
                      selectedFiles.value = [];
                    } else {
                      selectedFiles.value = [];
                      for (var file in files.value) {
                        selectedFiles.value = [...selectedFiles.value, file];
                      }
                    }

                  
                  },
                  child: Image.asset(
                    "assets/icons/select_all.png",
                    width: 20,
                    height: 20,
                  ),
                ),
              )
            else if (paths.value.length > 1)
              Padding(
                padding: const EdgeInsets.only(right: 10, top: 8, bottom: 8),
                child: OutlinedButton(
                  onPressed: () {
                    showCupertinoModalPopup(
                      context: context,
                      builder: (context) {
                        return Watch((context) => buildSortMenu(context));
                      },
                    ).then((value) {
                      refresh();
                    });
                  },
                  child: Image.asset(
                    "assets/icons/sort.png",
                    width: 20,
                    height: 20,
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(right: 10, top: 8, bottom: 8),
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
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  const Text(
                                    "选择操作",
                                    style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w500),
                                  ),
                                  const SizedBox(
                                    height: 12,
                                  ),
                                  SizedBox(
                                    width: double.infinity,
                                    child: Wrap(
                                      runSpacing: 20,
                                      spacing: 20,
                                      children: [
                                        if (paths.value.isEmpty) ...[
                                          Container(
                                            constraints: const BoxConstraints(
                                                maxWidth: 112),
                                            width: (MediaQuery.of(context)
                                                        .size
                                                        .width -
                                                    100) /
                                                3,
                                            child: OutlinedButton(
                                              onPressed: () async {
                                                Navigator.of(context).pop();
                                                List volumes = await getVolumes();
                                                if (volumes.isNotEmpty) {
                                                  if (context.mounted) {
                                                    Navigator.of(context)
                                                        .push(CupertinoPageRoute(
                                                            builder: (context) {
                                                              return AddSharedFolders(
                                                                  volumes);
                                                            },
                                                            settings:
                                                                const RouteSettings(
                                                                    name:
                                                                        "add_shared_folders")))
                                                        .then((res) {
                                                      if (res != null && res) {
                                                        refresh();
                                                      }
                                                    });
                                                  }
                                                } else {
                                                  UiUtil.toast("未获取到存储空间");
                                                }
                                              },
                                              child: Column(
                                                children: [
                                                  Image.asset(
                                                    "assets/icons/new_folder.png",
                                                    width: 30,
                                                  ),
                                                  const Text(
                                                    "共享文件夹",
                                                    style:
                                                        TextStyle(fontSize: 12),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                        if (paths.value.isNotEmpty) ...[
                                          Container(
                                            constraints: const BoxConstraints(
                                                maxWidth: 112),
                                            width: (MediaQuery.of(context)
                                                        .size
                                                        .width -
                                                    100) /
                                                3,
                                            child: OutlinedButton(
                                              onPressed: () async {
                                                Navigator.of(context).pop();
                                                String name = "";
                                                showCupertinoDialog(
                                                    context: context,
                                                    builder: (context) {
                                                      return Material(
                                                        color: Colors.transparent,
                                                        child: Column(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .center,
                                                          children: [
                                                            Card(
                                                              shape: RoundedRectangleBorder(
                                                                  side:
                                                                      const BorderSide(),
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              5)),
                                                              child: Padding(
                                                                padding:
                                                                    const EdgeInsets
                                                                        .all(20),
                                                                child: Column(
                                                                  children: [
                                                                    const Text(
                                                                      "新建文件夹",
                                                                      style: TextStyle(
                                                                          fontSize:
                                                                              20,
                                                                          fontWeight:
                                                                              FontWeight.w500),
                                                                    ),
                                                                    const SizedBox(
                                                                      height: 16,
                                                                    ),
                                                                    Card(
                                                                      shape: RoundedRectangleBorder(
                                                                          side:
                                                                              const BorderSide(),
                                                                          borderRadius:
                                                                              BorderRadius.circular(5)),
                                                                      child:
                                                                          Padding(
                                                                        padding: const EdgeInsets
                                                                            .all(
                                                                            8.0),
                                                                        child:
                                                                            TextField(
                                                                          onChanged:
                                                                              (v) =>
                                                                                  name = v,
                                                                          decoration:
                                                                              const InputDecoration(
                                                                            border:
                                                                                InputBorder.none,
                                                                            hintText:
                                                                                "请输入文件夹名",
                                                                            labelText:
                                                                                "文件夹名",
                                                                          ),
                                                                        ),
                                                                      ),
                                                                    ),
                                                                    const SizedBox(
                                                                      height: 20,
                                                                    ),
                                                                    Row(
                                                                      children: [
                                                                        Expanded(
                                                                          child:
                                                                              OutlinedButton(
                                                                            onPressed:
                                                                                () async {
                                                                              if (name.trim() ==
                                                                                  "") {
                                                                                UiUtil.toast("请输入文件夹名");
                                                                                return;
                                                                              }
                                                                              Navigator.of(context).pop();
                                                                              String
                                                                                  path =
                                                                                  "/${paths.value.join("/")}";
                                                                              try {
                                                                                await dsmFileStationCreateFolderForPage(path, name);
                                                                                UiUtil.toast("文件夹创建成功");
                                                                                refresh();
                                                                              } catch (e) {
                                                                                final raw = e is DSMException ? e.rawError : null;
                                                                                final errors = raw?['errors'] as List?;
                                                                                if (errors != null && errors.isNotEmpty && errors[0]['code'] == 414) {
                                                                                  UiUtil.toast("文件夹创建失败：指定的名称已存在");
                                                                                } else {
                                                                                  UiUtil.toast("文件夹创建失败");
                                                                                }
                                                                              }
                                                                            },
                                                                            child:
                                                                                const Text(
                                                                              "确定",
                                                                              style:
                                                                                  TextStyle(fontSize: 18),
                                                                            ),
                                                                          ),
                                                                        ),
                                                                        const SizedBox(
                                                                          width:
                                                                              16,
                                                                        ),
                                                                        Expanded(
                                                                          child:
                                                                              OutlinedButton(
                                                                            onPressed:
                                                                                () async {
                                                                              Navigator.of(context).pop();
                                                                            },
                                                                            child:
                                                                                const Text(
                                                                              "取消",
                                                                              style:
                                                                                  TextStyle(fontSize: 18),
                                                                            ),
                                                                          ),
                                                                        ),
                                                                      ],
                                                                    )
                                                                  ],
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      );
                                                    });
                                              },
                                              child: Column(
                                                children: [
                                                  Image.asset(
                                                    "assets/icons/new_folder.png",
                                                    width: 30,
                                                  ),
                                                  const Text(
                                                    "新建文件夹",
                                                    style:
                                                        TextStyle(fontSize: 12),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          SizedBox(
                                            width: (MediaQuery.of(context)
                                                        .size
                                                        .width -
                                                    100) /
                                                4,
                                            child: OutlinedButton(
                                              onPressed: () async {
                                                Navigator.of(context).pop();
                                                Navigator.of(context).push(
                                                    CupertinoPageRoute(
                                                        builder: (context) {
                                                          return Share(
                                                            paths: [
                                                              "/${paths.value.join("/")}"
                                                            ],
                                                            fileRequest: true,
                                                          );
                                                        },
                                                        settings:
                                                            const RouteSettings(
                                                                name: "share")));
                                              },
                                              child: Column(
                                                children: [
                                                  Image.asset(
                                                    "assets/icons/upload.png",
                                                    width: 30,
                                                  ),
                                                  const Text(
                                                    "创建文件请求",
                                                    style:
                                                        TextStyle(fontSize: 12),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                        Container(
                                          constraints:
                                              const BoxConstraints(maxWidth: 112),
                                          width:
                                              (MediaQuery.sizeOf(context).width -
                                                      100) /
                                                  3,
                                          child: OutlinedButton(
                                            onPressed: () async {
                                              Navigator.of(context).pop();
                                              Navigator.of(context).push(
                                                  CupertinoPageRoute(
                                                      builder: (content) {
                                                        return const ShareManager();
                                                      },
                                                      settings: const RouteSettings(
                                                          name:
                                                              "share_manager")));
                                            },
                                            child: Column(
                                              children: [
                                                Image.asset(
                                                  "assets/icons/link.png",
                                                  width: 30,
                                                ),
                                                const Text(
                                                  "共享链接管理",
                                                  style: TextStyle(fontSize: 12),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        Container(
                                          constraints:
                                              const BoxConstraints(maxWidth: 112),
                                          width:
                                              (MediaQuery.sizeOf(context).width -
                                                      100) /
                                                  3,
                                          child: OutlinedButton(
                                            onPressed: () async {
                                              Navigator.of(context).pop();
                                              Navigator.of(context)
                                                  .push(CupertinoPageRoute(
                                                      builder: (content) {
                                                        return const RemoteFolder();
                                                      },
                                                      settings: const RouteSettings(
                                                          name: "remote_folder")))
                                                  .then((res) {
                                                refresh();
                                                getSmbFolder();
                                              });
                                            },
                                            child: Column(
                                              children: [
                                                Image.asset(
                                                  "assets/icons/remote.png",
                                                  width: 30,
                                                ),
                                                const Text(
                                                  "装载远程",
                                                  style: TextStyle(fontSize: 12),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        // if (paths.length > 0)
                                        //   Container(
                                        //     constraints: BoxConstraints(maxWidth: 112),
                                        //     width: (MediaQuery.sizeOf(context).width - 100) / 3,
                                        //     child: NeuButton(
                                        //       onPressed: () async {
                                        //         Navigator.of(context).pop();
                                        //         Navigator.of(context)
                                        //             .push(CupertinoPageRoute(
                                        //                 builder: (content) {
                                        //                   return Search("/" + paths.join("/"));
                                        //                 },
                                        //                 settings: RouteSettings(name: "search")))
                                        //             .then((res) {
                                        //           if (res != null) {
                                        //             search(res['folders'], res['pattern'], res['search_content']);
                                        //           }
                                        //         });
                                        //       },
                                        //       decoration: NeumorphicDecoration(
                                        //         color: Theme.of(context).scaffoldBackgroundColor,
                                        //         borderRadius: BorderRadius.circular(10),
                                        //       ),
                                        //       bevel: 20,
                                        //       padding: EdgeInsets.symmetric(vertical: AppConstants.paddingSmall + 2),
                                        //       child: Column(
                                        //         children: [
                                        //           Image.asset(
                                        //             "assets/icons/search.png",
                                        //             width: 30,
                                        //           ),
                                        //           Text(
                                        //             "搜索",
                                        //             style: TextStyle(fontSize: 12),
                                        //           ),
                                        //         ],
                                        //       ),
                                        //     ),
                                        //   ),
                                      ],
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
                child: Image.asset(
                  "assets/icons/actions.png",
                  width: 20,
                  height: 20,
                ),
              ),
            )
          ],
        ),
      );
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
        title: buildTitleAction(context),
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
                      itemBuilder: buildPathItem,
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
            buildProcessList(),
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
                                    bottom:
                                        selectedFiles.value.isNotEmpty ? 140 : 20),
                                itemBuilder: (context, i) {
                                  return buildFileItem(files.value[i]);
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
                                      children:
                                          files.value.map(buildFileItem).toList(),
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
                                    showCupertinoModalPopup(
                                      context: context,
                                      builder: (context) {
                                        return const SelectFolder(
                                          multi: false,
                                        );
                                      },
                                    ).then((folder) async {
                                      if (folder != null &&
                                          folder.length == 1) {
                                        List<String> movePaths = selectedFiles.value
                                            .map((e) => e['path'] as String)
                                            .toList();
                                        try {
                                          final data = await dsmFileStationCopyMoveStartForPage(
                                              movePaths, folder[0], true);
                                          selectedFiles.value = [];
                                          multiSelect.value = false;
                                          backgroundProcess.value[data['taskid']] = {
                                            "timer": null,
                                            "data": {
                                              "dest_folder_path": folder[0],
                                              "progress": 0,
                                            },
                                            "type": "move",
                                            "path": movePaths,
                                          };
                                          getProcessingTaskResult(data['taskid']);
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
                                    showCupertinoModalPopup(
                                      context: context,
                                      builder: (context) {
                                        return const SelectFolder(
                                          multi: false,
                                        );
                                      },
                                    ).then((folder) async {
                                      if (folder != null &&
                                          folder.length == 1) {
                                        List<String> copyPaths = selectedFiles.value
                                            .map((e) => e['path'] as String)
                                            .toList();
                                        try {
                                          final data = await dsmFileStationCopyMoveStartForPage(
                                              copyPaths, folder[0], false);
                                          selectedFiles.value = [];
                                          multiSelect.value = false;
                                          backgroundProcess.value[data['taskid']] = {
                                            "timer": null,
                                            "data": {
                                              "dest_folder_path": folder[0],
                                              "progress": 0,
                                            },
                                            "type": "copy",
                                            "path": copyPaths,
                                          };
                                          getProcessingTaskResult(data['taskid']);
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
