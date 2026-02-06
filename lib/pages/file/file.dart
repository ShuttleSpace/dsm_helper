import 'dart:async';
import 'package:garden/stores/settings_store.dart';
import 'package:garden/util/file_type_util.dart';
import 'package:garden/util/ui_util.dart';
import 'package:garden/util/storage_util.dart';
import 'package:garden/stores/connection_store.dart';
import 'dart:io';
import 'package:android_intent_plus/android_intent.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:draggable_scrollbar/draggable_scrollbar.dart';
import 'package:garden/pages/download/download_state.dart';
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
import 'package:garden/util/http_util.dart';
import 'package:garden/widgets/animation_progress_bar.dart';
import 'package:garden/widgets/file_icon.dart';
import 'package:garden/widgets/transparent_router.dart';
import 'package:extended_text/extended_text.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:garden/constants/app_constants.dart';
import 'package:garden/theme/app_colors.dart';
import 'package:flutter_floating/floating/floating.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:signals_flutter/signals_flutter.dart';

enum ListType { list, icon }

class Files extends StatefulWidget {
  const Files({super.key});
  @override
  FilesState createState({key}) => FilesState();
}

class FilesState extends State<Files> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  List paths = [];
  List files = [];
  List smbFolders = [];
  List ftpFolders = [];
  List sftpFolders = [];
  List davFolders = [];
  bool loading = true;
  bool favoriteLoading = true;
  List favorites = [];
  bool success = true;
  String msg = "";
  bool multiSelect = false;
  List selectedFiles = [];
  final ScrollController _pathScrollController = ScrollController();
  final ScrollController _fileScrollController = ScrollController();
  Map backgroundProcess = {};
  bool showProcessList = false;
  String sortBy = "name";
  String sortDirection = "ASC";
  bool searchResult = false;
  bool searching = false;
  Timer? searchTimer;
  Timer? processingTimer;
  ListType listType = ListType.list;
  Map scrollPosition = {};
  Floating? audioPlayerFloating;
  @override
  void dispose() {
    searchTimer?.cancel();
    processingTimer?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    getShareList();
    getSmbFolder();
    getFtpFolder();
    getSftpFolder();
    getDavFolder();
    processingTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      getBackgroundTask();
    });

    _fileScrollController.addListener(() {
      String path = "";
      if (paths.isNotEmpty) {
        path = "/${paths.join("/")}";
      } else {
        path = "/";
      }
      scrollPosition[path] = _fileScrollController.offset;
    });
    super.initState();
  }

  getBackgroundTask() async {
    var res = await DsmApi.backgroundTask();
    if (res['success']) {
      if (res['data']['tasks'] != null && res['data']['tasks'].length > 0) {
        for (var task in res['data']['tasks']) {
          if (backgroundProcess[task['taskid']] == null) {
            String type = "";
            switch (task['api']) {
              case 'SYNO.FileStation.CopyMove':
                if (task['params']['remove_src']) {
                  type = "move";
                } else {
                  type = "copy";
                }
                break;
              case 'SYNO.FileStation.Delete':
                type = "delete";
                break;
              case 'SYNO.FileStation.Compress':
                type = "compress";
                break;
              case 'SYNO.FileStation.Extract':
                type = 'extract';
                break;
            }
            if (type.isNotBlank) {
              backgroundProcess[task['taskid']] = {
                "timer": null,
                "data": task,
                'type': type,
                'path': task['params']['path'],
              };
              getProcessingTaskResult(task['taskid']);
            }
          }
        }
      }
    }
  }

  getCopyMoveTaskResult(String taskId) async {
    //获取复制/移动进度
    var result = await DsmApi.copyMoveResult(taskId);
    Log.info(result);
    if (result['success'] != null && result['success']) {
      setState(() {
        backgroundProcess[taskId]['data'] = result['data'];
      });
      if (result['data']['finished']) {
        if (showProcessList = true) {
          UiUtil.toast(
              "${result['data']['path']} ${backgroundProcess[taskId]['type'] == 'copy' ? '复制' : '移动'}到 ${result['data']['dest_folder_path']} 完成");
        }

        backgroundProcess[taskId]['timer']?.cancel();
        backgroundProcess[taskId]['timer'] = null;
        backgroundProcess.remove(taskId);
        refresh();
      }
    }
  }

  getDeleteTaskResult(String taskId) async {
    //获取删除进度
    try {
      var result = await DsmApi.deleteResult(taskId);
      if (result['success'] != null && result['success']) {
        if (result['data']['finished']) {
          if (showProcessList = true) {
            UiUtil.toast("文件删除完成");
          }
          backgroundProcess[taskId]['timer']?.cancel();
          backgroundProcess[taskId]['timer'] = null;
          backgroundProcess.remove(taskId);
          refresh();
        }
      }
    } catch (e) {
      UiUtil.toast("文件删除出错");
      backgroundProcess[taskId]['timer']?.cancel();
      backgroundProcess[taskId]['timer'] = null;
      backgroundProcess.remove(taskId);
    }
  }

  getExtractTaskResult(String taskId) async {
    var result = await DsmApi.extractResult(taskId);
    if (result['success'] != null && result['success']) {
      if (result['data']['finished']) {
        if (result['data']['errors'] != null &&
            result['data']['errors'].length > 0) {
          if (result['data']['errors'][0]['code'] == 1403) {
            String password = "";
            if (context.mounted) {
              showCupertinoDialog(
                  // ignore: use_build_context_synchronously
                  context: context,
                  builder: (context) {
                    return Material(
                      color: Colors.transparent,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Card(
                            shape: RoundedRectangleBorder(
                                side: const BorderSide(),
                                borderRadius: BorderRadius.circular(18)),
                            margin: const EdgeInsets.symmetric(horizontal: 50),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                children: [
                                  const Text(
                                    "解压密码",
                                    style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w500),
                                  ),
                                  const SizedBox(
                                    height: 16,
                                  ),
                                  Card(
                                    shape: RoundedRectangleBorder(
                                        side: const BorderSide(),
                                        borderRadius:
                                            BorderRadius.circular(18)),
                                    child: Padding(
                                      padding: const EdgeInsets.all(
                                          AppConstants.paddingSmall),
                                      child: TextField(
                                        onChanged: (v) => password = v,
                                        decoration: const InputDecoration(
                                          border: InputBorder.none,
                                          hintText: "请输入解压密码",
                                          labelText: "解压密码",
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
                                        child: OutlinedButton(
                                          onPressed: () async {
                                            if (password == "") {
                                              UiUtil.toast("请输入解压密码");
                                              return;
                                            }
                                            Navigator.of(context).pop();
                                            extractFile(result['data']['path'],
                                                password: password);
                                          },
                                          child: const Text(
                                            "确定",
                                            style: TextStyle(fontSize: 18),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(
                                        width: 16,
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
                                  )
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  });
            }
          }
        } else {
          if (showProcessList = true) {
            UiUtil.toast("文件解压完成");
          }
        }
        backgroundProcess[taskId]['timer']?.cancel();
        backgroundProcess[taskId]['timer'] = null;
        backgroundProcess.remove(taskId);
        refresh();
      } else {
        setState(() {
          backgroundProcess[taskId]['data'] = result['data'];
        });
      }
    }
  }

  getCompressTaskResult(String taskId) async {
    //获取压缩进度
    try {
      var result = await DsmApi.compressResult(taskId);
      if (result['success'] != null && result['success']) {
        if (result['data']['finished']) {
          if (showProcessList = true) {
            UiUtil.toast("文件压缩完成");
          }

          backgroundProcess[taskId]['timer']?.cancel();
          backgroundProcess[taskId]['timer'] = null;
          backgroundProcess.remove(taskId);
          refresh();
        }
      }
    } catch (e) {
      UiUtil.toast("文件压缩出错");
      backgroundProcess[taskId]['timer']?.cancel();
      backgroundProcess[taskId]['timer'] = null;
      backgroundProcess.remove(taskId);
    }
  }

  getProcessingTaskResult(String taskId) {
    if (backgroundProcess[taskId] == null) {
      return;
    }
    backgroundProcess[taskId]['timer'] =
        Timer.periodic(const Duration(seconds: 1), (_) async {
      switch (backgroundProcess[taskId]['type']) {
        case 'copy':
        case 'move':
          getCopyMoveTaskResult(taskId);
          break;
        case 'extract':
          getExtractTaskResult(taskId);
          break;
        case 'delete':
          getDeleteTaskResult(taskId);
          break;
        case 'compress':
          getCompressTaskResult(taskId);
          break;
      }
    });
  }

  initFloating() {}

  Future<List> getVolumes() async {
    var res = await DsmApi.volumes();
    if (res['success']) {
      return res['data']['volumes'];
    } else {
      return [];
    }
  }

  refresh() {
    String path = "";
    if (paths.isNotEmpty && paths[0].contains("//")) {
      Log.info("远程");
      path = paths.join("/");
    } else {
      Log.info("本地");
      path = (paths.isNotEmpty ? "/" : '') + paths.join("/");
    }
    goPath(path);
  }

  bool get isDrawerOpen {
    return _scaffoldKey.currentState?.isDrawerOpen == true;
  }

  closeDrawer() {
    if (_scaffoldKey.currentState?.isDrawerOpen == true) {
      Navigator.of(context).pop();
    }
  }

  setPaths(String path) {
    setState(() {
      searchResult = false;
      searching = false;
    });
    if (path == "") {
      setState(() {
        paths = [];
      });
    } else {
      if (path.startsWith("/")) {
        List<String> items = path.split("/").sublist(1);
        setState(() {
          paths = items;
        });
      } else {
        List<String> parts = path.split("://");
        String scheme = parts[0];
        String first = "$scheme://${parts[1].split("/").first}";
        // String first = "${uri.scheme}://${uri.userInfo}@${uri.host}";
        List<String> items = path.replaceAll(first, "").split("/");
        items[0] = first;
        setState(() {
          paths = items;
        });
      }
    }
  }

  search(List<String> folders, String pattern, bool searchContent) async {
    setState(() {
      searchResult = true;
      searching = true;
      loading = true;
    });
    var res =
        await DsmApi.searchTask(folders, pattern, searchContent: searchContent);
    if (res['success']) {
      bool? r = await result(res['data']['taskid']);
      if (r == null) {
        UiUtil.toast('Wrong State!');
        return;
      }
      if (r == false) {
        //搜索未结束
        searchTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
          result(res['data']['taskid']);
        });
      }
    } else {
      Log.info("搜索出错");
      UiUtil.toast('搜索出错!');
    }
  }

  downloadFiles(List files) async {
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
                                    download(files);
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
        download(files);
      }
    });
  }

  download(files) async {
    // 检查权限
    if (Platform.isAndroid) {
      DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      if (androidInfo.version.sdkInt >= 30) {
        bool permission = false;
        permission = await Permission.manageExternalStorage.request().isGranted;
        if (!permission) {
          UiUtil.toast("安卓11以上需授权文件管理权限");
          return;
        }
      } else {
        bool permission = false;
        permission = await Permission.storage.request().isGranted;
        if (!permission) {
          UiUtil.toast("请先授权APP访问存储权限");
          return;
        }
      }
    }

    for (var file in files) {
      String url =
          "${connectionStore.baseUrl}/webapi/entry.cgi?api=SYNO.FileStation.Download&version=2&method=download&path=${Uri.encodeComponent(file['path'])}&mode=download&_sid=${connectionStore.sid}";
      String filename = "";
      if (file['isdir']) {
        filename = file['name'] + ".zip";
      } else {
        filename = file['name'];
      }
      await HttpUtil.instance.download(filename, url);
    }
    UiUtil.toast(
        "已添加${files.length > 1 ? "${files.length}个" : ""}下载任务，请至下载页面查看");
    if (context.mounted) {
      // ignore: use_build_context_synchronously
      DownloadStateInherited.of(context)?.notifier.runLoop();
    }
  }

  Future<bool?> result(String taskId) async {
    var res = await DsmApi.searchResult(taskId);
    if (res['success']) {
      if (res['data']['finished']) {
        searchTimer?.cancel();
      }
      setState(() {
        loading = false;
        searching = !res['data']['finished'];

        if (res['data']['files'] != null) {
          files = res['data']['files'];
        } else {
          files = [];
        }
      });

      return res['data']['finished'];
    } else {
      return null;
    }
  }

  getSmbFolder() async {
    var res = await DsmApi.smbFolder();
    if (res['success']) {
      setState(() {
        smbFolders = res['data']['folders'];
      });
    }
  }

  getFtpFolder() async {
    var res = await DsmApi.remoteLink("ftp");
    if (res['success']) {
      setState(() {
        ftpFolders = res['data']['folders'];
      });
    }
  }

  getSftpFolder() async {
    var res = await DsmApi.remoteLink("sftp");
    if (res['success']) {
      setState(() {
        sftpFolders = res['data']['folders'];
      });
    }
  }

  getDavFolder() async {
    var res = await DsmApi.remoteLink("davs");
    if (res['success']) {
      setState(() {
        davFolders = res['data']['folders'];
      });
    }
  }

  getShareList() async {
    String listTypeStr = await StorageUtil.getString("file_list_type") ?? '';

    setState(() {
      if (listTypeStr.isNotBlank) {
        if (listTypeStr == "list") {
          listType = ListType.list;
        } else {
          listType = ListType.icon;
        }
      } else {
        listType = ListType.list;
      }
      loading = true;
    });
    var res = await DsmApi.shareList();
    setState(() {
      loading = false;
      success = res['success'];
    });
    if (res['success']) {
      setState(() {
        files = res['data']['shares'];
      });
    } else {
      if (loading) {
        setState(() {
          msg = res['msg'] ?? "加载失败，code:${res['error']['code']}";
        });
      }
    }
  }

  getFileList(String path) async {
    setState(() {
      loading = true;
    });
    var res = await DsmApi.fileList(path,
        sortBy: sortBy, sortDirection: sortDirection);
    setState(() {
      loading = false;
      success = res['success'];
    });
    if (res['success']) {
      setState(() {
        files = res['data']['files'];
        Log.info(files);
      });
    } else {
      setState(() {
        msg = res['msg'] ?? connectionStore.notReviewAccount
            ? '暂无文件'
            : "加载失败，code:${res['error']['code']}";
      });
    }
  }

  goPath(String path) async {
    Log.info("path:$path");
    UiUtil.vibrate(FeedbackType.light);
    setState(() {
      success = true;
    });
    setPaths(path);
    if (path == "/" || path == "") {
      await getShareList();
    } else {
      await getFileList(path);
    }
    double offset = _pathScrollController.position.maxScrollExtent;
    _pathScrollController.animateTo(offset,
        duration: const Duration(milliseconds: 200), curve: Curves.ease);
    _fileScrollController.jumpTo(scrollPosition[path] ?? 0);
  }

  openPlainFile(file) async {
    setState(() {
      loading = true;
    });
    var res = await HttpUtil.instance.get(
        "${connectionStore.baseUrl}/webapi/entry.cgi?api=SYNO.FileStation.Download&version=1&method=download&path=${Uri.encodeComponent(file['path'])}&mode=open&_sid=${connectionStore.sid}",
        decode: false);
    setState(() {
      loading = false;
    });
    if (context.mounted) {
      // ignore: use_build_context_synchronously
      Navigator.of(context).push(CupertinoPageRoute(builder: (context) {
        return TextEditor(
          fileName: file['name'],
          content: res,
        );
      }));
    }
  }

  Widget _buildSortMenu(BuildContext context, StateSetter setState) {
    return Material(
      color: Colors.transparent,
      child: Card(
        shape: RoundedRectangleBorder(
            side: const BorderSide(), borderRadius: BorderRadius.circular(18)),
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
                            setState(() {
                              sortBy = "name";
                            });
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
                                    child: sortBy == "name"
                                        ? const Icon(
                                            CupertinoIcons.checkmark_alt,
                                            color: AppColors.primaryAction,
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
                            setState(() {
                              sortBy = "size";
                            });
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
                                    child: sortBy == "size"
                                        ? const Icon(
                                            CupertinoIcons.checkmark_alt,
                                            color: AppColors.primaryAction,
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
                            setState(() {
                              sortBy = "type";
                            });
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
                                    child: sortBy == "type"
                                        ? const Icon(
                                            CupertinoIcons.checkmark_alt,
                                            color: AppColors.primaryAction,
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
                            setState(() {
                              sortBy = "mtime";
                            });
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
                                    child: sortBy == "mtime"
                                        ? const Icon(
                                            CupertinoIcons.checkmark_alt,
                                            color: AppColors.primaryAction,
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
                            setState(() {
                              sortBy = "crtime";
                            });
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
                                    child: sortBy == "crtime"
                                        ? const Icon(
                                            CupertinoIcons.checkmark_alt,
                                            color: AppColors.primaryAction,
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
                            setState(() {
                              sortBy = "atime";
                            });
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
                                    child: sortBy == "atime"
                                        ? const Icon(
                                            CupertinoIcons.checkmark_alt,
                                            color: AppColors.primaryAction,
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
                            setState(() {
                              sortBy = "posix";
                            });
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
                                    child: sortBy == "posix"
                                        ? const Icon(
                                            CupertinoIcons.checkmark_alt,
                                            color: AppColors.primaryAction,
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
                            setState(() {
                              sortBy = "user";
                            });
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
                                    child: sortBy == "user"
                                        ? const Icon(
                                            CupertinoIcons.checkmark_alt,
                                            color: AppColors.primaryAction,
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
                            setState(() {
                              sortBy = "group";
                            });
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
                                    child: sortBy == "group"
                                        ? const Icon(
                                            CupertinoIcons.checkmark_alt,
                                            color: AppColors.primaryAction,
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
                          setState(() {
                            sortDirection = "ASC";
                          });
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
                                  child: sortDirection == "ASC"
                                      ? const Icon(
                                          CupertinoIcons.checkmark_alt,
                                          color: AppColors.primaryAction,
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
                          setState(() {
                            sortDirection = "DESC";
                          });
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
                                  child: sortDirection == "DESC"
                                      ? const Icon(
                                          CupertinoIcons.checkmark_alt,
                                          color: AppColors.primaryAction,
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

  deleteFile(List<String> files) {
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
                              var res = await DsmApi.deleteTask(files);
                              backgroundProcess[res['data']['taskid']] = {
                                "timer": null,
                                "data": {
                                  "progress": 0,
                                },
                                "type": 'delete',
                                "path": files,
                              };
                              if (res['success']) {
                                setState(() {
                                  selectedFiles = [];
                                  multiSelect = false;
                                });
                                getProcessingTaskResult(res['data']['taskid']);
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

  extractFile(file, {String password = ''}) async {
    var res = await DsmApi.extractTask(file['path'], "/${paths.join("/")}",
        password: password);
    if (res['success']) {
      backgroundProcess[res['data']['taskid']] = {
        "timer": null,
        "data": null,
        "type": 'extract',
        "path": [file['path']],
      };
      getProcessingTaskResult(res['data']['taskid']);
    }
  }

  compressFile(List<String> file) {
    String zipName = "";
    String destPath = "";
    if (file.length == 1) {
      zipName = "${file[0].split("/").last}.zip";
    } else {
      zipName = paths.last + ".zip";
    }
    destPath = "/${paths.join("/")}/$zipName";
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
                        var res = await DsmApi.compressTask(file, destPath);
                        if (res['success']) {
                          backgroundProcess[res['data']['taskid']] = {
                            "timer": null,
                            "data": {
                              "dest_folder_path": destPath,
                              "progress": 0,
                            },
                            "path": [file],
                            "type": 'compress',
                          };
                          setState(() {
                            multiSelect = false;
                            selectedFiles = [];
                          });
                          getProcessingTaskResult(res['data']['taskid']);
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
    if (multiSelect) {
      setState(() {
        if (selectedFiles.contains(file)) {
          selectedFiles.remove(file);
        } else {
          selectedFiles.add(file);
        }
      });
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
            List<String> paths = [];
            int index = 0;
            for (int i = 0; i < files.length; i++) {
              if (FileTypeUtil.toFileTypeEnum(
                      FileTypeUtil.getFileType(files[i]['name'])) ==
                  FileTypeEnum.image) {
                images.add(
                    "${connectionStore.baseUrl}/webapi/entry.cgi?path=${Uri.encodeComponent(files[i]['path'])}&size=original&api=SYNO.FileStation.Thumb&method=get&version=2&_sid=${connectionStore.sid}&animate=true");
                thumbs.add(
                    "${connectionStore.baseUrl}/webapi/entry.cgi?path=${Uri.encodeComponent(files[i]['path'])}&size=small&api=SYNO.FileStation.Thumb&method=get&version=2&_sid=${connectionStore.sid}&animate=true");
                names.add(files[i]['name']);
                paths.add(files[i]['path']);
                if (files[i]['name'] == file['name']) {
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
                  paths: paths,
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
            String url =
                "${connectionStore.baseUrl}/fbdownload/${Uri.encodeComponent(file['name'])}?dlink=%22${(file['path'] as String).utf8()}%22&_sid=%22${connectionStore.sid}%22&mode=open";
            // String url = HttpUtil.baseUrl + "/fbdownload/${file['name']}?dlink=%22${HttpUtil.utf8Encode(file['path'])}%22&_sid=%22${HttpUtil.sid}%22&mode=open";
            // Log.info(url);
            // 调用nplayer
            // launchUrlString("nplayer-http://${Uri.encodeComponent(url)}");
            // 调用vlc player
            // launchUrlString("vlc://$url");
            // return;
            if (useEmbeedVideoPlayer == '1') {
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
                cover = files.firstWhere((element) =>
                    element['name'].startsWith("$name-fanart") ||
                    element['name'].startsWith("fanart"))['path'];
              } catch (e) {
                try {
                  cover = files.firstWhere((element) =>
                      element['name'].startsWith("$name-thumb") ||
                      element['name'].startsWith("thumb"))['path'];
                } catch (e) {
                  try {
                    cover = files.firstWhere((element) =>
                        element['name'].startsWith("$name-poster") ||
                        element['name'].startsWith("poster"))['path'];
                  } catch (e) {
                    try {
                      cover = files.firstWhere((element) =>
                          element['name'].startsWith("$name-cover") ||
                          element['name'].startsWith("cover"))['path'];
                    } catch (e) {
                      Log.info("无封面图");
                    }
                  }
                }
              }
              try {
                nfo = files.firstWhere(
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
            if (audioPlayerFloating?.isShowing == true) {
              audioPlayerFloating?.close();
            }
            String url =
                "${connectionStore.baseUrl}/fbdownload/${file['name']}?dlink=%22${(file['path'] as String).utf8()}%22&_sid=%22${connectionStore.sid}%22&mode=open";
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
                  audioPlayerFloating?.open(context);
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
                  "${connectionStore.baseUrl}/fbdownload/${file['name']}?dlink=%22${(file['path'] as String).utf8()}%22&_sid=%22${connectionStore.sid}%22&mode=open",
                  file['name']);
            }));
            break;
          default:
            AndroidIntent intent = AndroidIntent(
              action: 'action_view',
              data:
                  "${connectionStore.baseUrl}/fbdownload/${file['name']}?dlink=%22${(file['path'] as String).utf8()}%22&_sid=%22${connectionStore.sid}%22&mode=open",
              arguments: {},
              // type: "application/vnd.ms-powerpoint|application/vnd.openxmlformats-officedocument.presentationml.presentation",
            );
            await intent.launch();
          // HttpUtil.toast("暂不支持打开此类型文件");
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
                                  setState(() {
                                    selectedFiles.add(file);
                                    multiSelect = true;
                                  });
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
                          if (paths.length > 1 &&
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
                          if (paths.isNotEmpty)
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
                                                              var res = await DsmApi
                                                                  .rename(
                                                                      file[
                                                                          'path'],
                                                                      name);
                                                              if (res[
                                                                  'success']) {
                                                                UiUtil.toast(
                                                                    "重命名成功");
                                                                refresh();
                                                              } else {
                                                                if (res['error']
                                                                            [
                                                                            'errors'] !=
                                                                        null &&
                                                                    res['error']['errors']
                                                                            .length >
                                                                        0 &&
                                                                    res['error']['errors'][0]
                                                                            [
                                                                            'code'] ==
                                                                        414) {
                                                                  UiUtil.toast(
                                                                      "重命名失败：指定的名称已存在");
                                                                } else {
                                                                  UiUtil.toast(
                                                                      "重命名失败");
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
                                  var res = await DsmApi.favoriteAdd(
                                      "${file['name']} - ${paths[1]}",
                                      file['path']);
                                  if (res['success']) {
                                    UiUtil.toast("收藏成功");
                                  } else {
                                    UiUtil.toast(
                                        "收藏失败，代码${res['error']['code']}");
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
                                  var res =
                                      await DsmApi.unMountFolder(file['path']);
                                  if (res['success']) {
                                    UiUtil.toast("卸载成功");
                                    refresh();
                                    getSmbFolder();
                                  } else {
                                    UiUtil.toast(
                                        "卸载失败，代码${res['error']['code']}");
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
                                  var res = await DsmApi.remoteUnConnect(
                                      file['path']);
                                  if (res['success']) {
                                    UiUtil.toast("远程连接已断开");
                                    refresh();
                                    getSmbFolder();
                                  } else {
                                    UiUtil.toast(
                                        "断开连接失败，代码${res['error']['code']}");
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
                          if (paths.length > 1)
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

  Widget _buildFileItem(file, {bool remote = false}) {
    FileTypeEnum fileType =
        FileTypeUtil.toFileTypeEnum(FileTypeUtil.getFileType(file['name']));
    String path = file['path'];
    Widget actionButton = multiSelect
        ? Card(
            shape: RoundedRectangleBorder(
                side: const BorderSide(),
                borderRadius: BorderRadius.circular(18)),
            child: SizedBox(
              width: 20,
              height: 20,
              child: selectedFiles.contains(file)
                  ? const Icon(
                      CupertinoIcons.checkmark_alt,
                      color: AppColors.primaryAction,
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
      constraints: listType == ListType.icon && !remote
          ? const BoxConstraints(maxWidth: 112)
          : null,
      width: listType == ListType.icon && !remote
          ? (MediaQuery.sizeOf(context).width - 80) / 3
          : double.infinity,
      padding: listType == ListType.icon && !remote
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
        child: listType == ListType.list || remote
            ? Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 10,
                    ),
                    Hero(
                      tag:
                          "${connectionStore.baseUrl}/webapi/entry.cgi?path=${Uri.encodeComponent(path)}&size=original&api=SYNO.FileStation.Thumb&method=get&version=2&_sid=${connectionStore.sid}&animate=true",
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
                                                file['additional']['size']))
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
                            tag:
                                "${connectionStore.baseUrl}/webapi/entry.cgi?path=${Uri.encodeComponent(path)}&size=original&api=SYNO.FileStation.Thumb&method=get&version=2&_sid=${connectionStore.sid}&animate=true",
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
                  if (multiSelect)
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

  Widget _buildPathItem(BuildContext context, int index) {
    return Container(
      padding:
          const EdgeInsets.symmetric(vertical: AppConstants.paddingSmall + 2),
      child: OutlinedButton(
        onPressed: () {
          String path = "";
          List<String> items = [];
          if (paths.length > 1 && paths[0].contains("//")) {
            Log.info("远程");
            items = paths.getRange(0, index + 1).toList().cast();
            path = items.join("/");
            goPath(path);
          } else {
            Log.info("本地");
            items = paths.getRange(0, index + 1).toList().cast();
            path = "/${items.join("/")}";
          }
          goPath(path);
        },
        child: Text(
          paths[index],
          style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).textTheme.headlineMedium?.color),
        ),
      ),
    );
  }

  Future<bool> onWillPop() {
    if (multiSelect) {
      setState(() {
        multiSelect = false;
        selectedFiles = [];
      });
    } else if (searchResult) {
      setState(() {
        refresh();
      });
    } else {
      if (paths.isNotEmpty) {
        paths.removeLast();
        String path = "";
        Log.info(paths);
        if (paths.isNotEmpty && paths[0].contains("//")) {
          Log.info("远程");
          path = paths.join("/");
        } else {
          Log.info("本地");
          path = (paths.isNotEmpty ? "/" : '') + paths.join("/");
        }
        goPath(path);
      } else {
        return Future.value(true);
      }
    }

    return Future.value(false);
  }

  Widget _buildProcessList() {
    List<Widget> children = [];
    Map<String, String> types = {
      "copy": "复制：",
      "move": "移动：",
      "delete": "删除：",
      "extract": "解压：",
      "compress": "压缩：",
    };
    backgroundProcess.forEach((key, task) {
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

  Widget _buildTitlteAction(BuildContext context) {
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
                if (multiSelect) {
                  setState(() {
                    multiSelect = false;
                    selectedFiles = [];
                  });
                } else {
                  _scaffoldKey.currentState?.openDrawer();
                  setState(() {
                    favoriteLoading = true;
                  });
                  var res = await DsmApi.favoriteList();
                  setState(() {
                    favoriteLoading = false;
                  });
                  if (res['success']) {
                    setState(() {
                      favorites = res['data']['favorites'];
                    });
                  }
                }
              },
              child: multiSelect
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
                                        if ((smbFolders +
                                                ftpFolders +
                                                sftpFolders +
                                                davFolders)
                                            .isNotEmpty) ...[
                                          ...(smbFolders +
                                                  ftpFolders +
                                                  sftpFolders +
                                                  davFolders)
                                              .map((folder) {
                                            return _buildFileItem(folder,
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
          if (connectionStore.notReviewAccount.watch(context) &&
              paths.isNotEmpty &&
              !multiSelect)
            Padding(
              padding: const EdgeInsets.only(left: 10, top: 8, bottom: 8),
              child: OutlinedButton(
                onPressed: () async {
                  Navigator.of(context)
                      .push(CupertinoPageRoute(
                          builder: (context) {
                            return Upload("/${paths.join("/")}");
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
          if (backgroundProcess.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 10, top: 8, bottom: 8),
              child: OutlinedButton(
                onPressed: () async {
                  setState(() {
                    showProcessList = !showProcessList;
                  });
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
          if (paths.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 10, top: 8, bottom: 8),
              child: OutlinedButton(
                onPressed: () async {
                  Navigator.of(context)
                      .push(CupertinoPageRoute(
                          builder: (content) {
                            return Search("/${paths.join("/")}");
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
                setState(() {
                  listType =
                      listType == ListType.list ? ListType.icon : ListType.list;
                });
                StorageUtil.setString("file_list_type",
                    listType == ListType.list ? "list" : "icon");
              },
              child: Image.asset(
                listType == ListType.list
                    ? "assets/icons/list_list.png"
                    : "assets/icons/list_icon.png",
                width: 20,
                height: 20,
              ),
            ),
          ),
          if (multiSelect)
            Padding(
              padding: const EdgeInsets.only(right: 10, top: 8, bottom: 8),
              child: OutlinedButton(
                onPressed: () {
                  if (selectedFiles.length == files.length) {
                    selectedFiles = [];
                  } else {
                    selectedFiles = [];
                    for (var file in files) {
                      selectedFiles.add(file);
                    }
                  }

                  setState(() {});
                },
                child: Image.asset(
                  "assets/icons/select_all.png",
                  width: 20,
                  height: 20,
                ),
              ),
            )
          else if (paths.length > 1)
            Padding(
              padding: const EdgeInsets.only(right: 10, top: 8, bottom: 8),
              child: OutlinedButton(
                onPressed: () {
                  showCupertinoModalPopup(
                    context: context,
                    builder: (context) {
                      return StatefulBuilder(
                        builder: _buildSortMenu,
                      );
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
                                      if (paths.isEmpty) ...[
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
                                      if (paths.isNotEmpty) ...[
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
                                                                                "/${paths.join("/")}";
                                                                            var res =
                                                                                await DsmApi.createFolder(path, name);
                                                                            if (res['success']) {
                                                                              UiUtil.toast("文件夹创建成功");
                                                                              refresh();
                                                                            } else {
                                                                              if (res['error']['errors'] != null && res['error']['errors'].length > 0 && res['error']['errors'][0]['code'] == 414) {
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
                                                            "/${paths.join("/")}"
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        title: _buildTitlteAction(context),
      ),
      body: Column(
        children: [
          const Divider(
            indent: 12,
            endIndent: 12,
          ),
          if (searchResult)
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
                      searchTimer?.cancel();
                      setState(() {
                        searching = false;
                        searchResult = false;
                        refresh();
                      });
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
                          child: searching
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
                  if (paths.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: const Icon(
                        CupertinoIcons.right_chevron,
                        size: 14,
                      ),
                    ),
                  Expanded(
                    child: ListView.separated(
                      controller: _pathScrollController,
                      itemBuilder: _buildPathItem,
                      itemCount: paths.length,
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
          if (backgroundProcess.isNotEmpty && showProcessList)
            _buildProcessList(),
          Expanded(
            child: success
                ? Stack(
                    children: [
                      listType == ListType.list
                          ? DraggableScrollbar.semicircle(
                              backgroundColor:
                                  Theme.of(context).scaffoldBackgroundColor,
                              scrollbarTimeToFade: const Duration(seconds: 1),
                              controller: _fileScrollController,
                              child: ListView.builder(
                                controller: _fileScrollController,
                                padding: EdgeInsets.only(
                                    left: 20,
                                    right: 20,
                                    top: 20,
                                    bottom:
                                        selectedFiles.isNotEmpty ? 140 : 20),
                                itemBuilder: (context, i) {
                                  return _buildFileItem(files[i]);
                                },
                                itemCount: files.length,
                              ),
                            )
                          : SizedBox(
                              width: double.infinity,
                              child: DraggableScrollbar.semicircle(
                                backgroundColor:
                                    Theme.of(context).scaffoldBackgroundColor,
                                scrollbarTimeToFade: const Duration(seconds: 1),
                                controller: _fileScrollController,
                                child: ListView(
                                  controller: _fileScrollController,
                                  padding: const EdgeInsets.all(20),
                                  children: [
                                    Wrap(
                                      runSpacing: 20,
                                      spacing: 20,
                                      children:
                                          files.map(_buildFileItem).toList(),
                                    )
                                  ],
                                ),
                              ),
                            ),
                      // if (selectedFiles.length > 0)
                      AnimatedPositioned(
                        width: MediaQuery.sizeOf(context).width,
                        bottom: selectedFiles.isNotEmpty ? 0 : -100,
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
                                        List<String> files = selectedFiles
                                            .map((e) => e['path'] as String)
                                            .toList();
                                        var res = await DsmApi.copyMoveTask(
                                            files, folder[0], true);
                                        if (res['success']) {
                                          setState(() {
                                            selectedFiles = [];
                                            multiSelect = false;
                                            backgroundProcess[res['data']
                                                ['taskid']] = {
                                              "timer": null,
                                              "data": {
                                                "dest_folder_path": folder[0],
                                                "progress": 0,
                                              },
                                              "type": 'move',
                                              "path": files,
                                            };
                                          });
                                          //获取移动进度
                                          getProcessingTaskResult(
                                              res['data']['taskid']);
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
                                        List<String> files = selectedFiles
                                            .map((e) => e['path'] as String)
                                            .toList();
                                        var res = await DsmApi.copyMoveTask(
                                            files, folder[0], false);
                                        if (res['success']) {
                                          setState(() {
                                            selectedFiles = [];
                                            multiSelect = false;
                                            backgroundProcess[res['data']
                                                ['taskid']] = {
                                              "timer": null,
                                              "data": {
                                                "dest_folder_path": folder[0],
                                                "progress": 0,
                                              },
                                              "type": "copy",
                                              "path": files,
                                            };
                                          });
                                          getProcessingTaskResult(
                                              res['data']['taskid']);
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
                                    compressFile(selectedFiles
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
                                    downloadFiles(selectedFiles);
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
                                    deleteFile(selectedFiles
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
                      if (loading)
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
                          msg,
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
