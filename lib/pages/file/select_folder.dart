import 'package:garden/theme/app_theme.dart';
import 'package:garden/api/dsm_api.dart';
import 'package:garden/util/file_type_util.dart';
import 'package:garden/util/log.dart';
import 'package:garden/util/ui_util.dart';
import 'package:garden/stores/connection_store.dart';
import 'package:garden/util/http_util.dart';
import 'package:garden/widgets/file_icon.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:garden/constants/app_constants.dart';

class SelectFolder extends StatefulWidget {
  final bool multi;
  final bool folder;
  const SelectFolder({super.key, this.multi = false, this.folder = true});
  @override
  SelectFolderState createState() => SelectFolderState();
}

class SelectFolderState extends State<SelectFolder> {
  final ScrollController _scrollController = ScrollController();
  List paths = ["/"];
  List files = [];
  List selectedFiles = [];
  bool loading = true;
  bool success = true;
  String msg = "";
  @override
  void initState() {
    getShareList();
    super.initState();
  }

  getShareList() async {
    setState(() {
      loading = true;
    });
    var res = await DsmApi.shareList();
    setState(() {
      success = res['success'];
    });
    if (res['success']) {
      setState(() {
        loading = false;
        files = res['data']['shares'];
      });
    } else {
      if (loading) {
        setState(() {
          loading = false;
          msg = res['msg'] ?? "加载失败，code:${res['error']['code']}";
        });
      }
    }
  }

  refresh() {
    String path = paths.join("/").substring(1);
    goPath(path);
  }

  getFileList(String path) async {
    setState(() {
      loading = true;
    });
    var res = await dsmFileStationListList(path);
    setState(() {
      success = res['success'];
    });
    if (res['success']) {
      setState(() {
        loading = false;
        files = res['data']['files'];
      });
    } else {
      if (loading) {
        setState(() {
          loading = false;
          msg = res['msg'] ?? "加载失败，code:${res['error']['code']}";
        });
      }
    }
  }

  goPath(String path) async {
    setPaths(path);
    if (path == "/") {
      await getShareList();
    } else {
      await getFileList(path);
    }
    double offset = _scrollController.position.maxScrollExtent;
    _scrollController.animateTo(offset,
        duration: const Duration(milliseconds: 200), curve: Curves.ease);
  }

  setPaths(String path) {
    if (path == "/") {
      setState(() {
        paths = ["/"];
      });
    } else {
      List<String> items = path.split("/");
      items[0] = "/";
      setState(() {
        paths = items;
      });
    }
  }

  Widget _buildPathItem(BuildContext context, int index) {
    return Container(
      margin: index == 0 ? const EdgeInsets.only(left: 20) : null,
      padding:
          const EdgeInsets.symmetric(vertical: AppConstants.paddingSmall + 2),
      child: OutlinedButton(
        onPressed: () {
          String path = "";
          List<String> items = [];
          if (index == 0) {
            path = "/";
          } else {
            items = paths.getRange(1, index + 1).toList().cast();
            path = "/${items.join("/")}";
          }
          goPath(path);
        },
        child: index == 0
            ? const Icon(
                CupertinoIcons.home,
                size: 16,
              )
            : Text(
                paths[index],
                style: const TextStyle(fontSize: 12),
              ),
      ),
    );
  }

  Widget _buildFileItem(file) {
    FileTypeEnum fileType =
        FileTypeUtil.toFileTypeEnum(FileTypeUtil.getFileType(file['name']));
    String path = file['path'];
    return Padding(
      padding: const EdgeInsets.only(top: 20.0, left: 20, right: 20),
      child: Opacity(
        opacity: 1,
        child: OutlinedButton(
          onPressed: () async {
            if (widget.multi) {
            } else {
              if (file['isdir']) {
                goPath(file['path']);
              }
            }
          },
          // margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            children: [
              const SizedBox(
                width: 20,
              ),
              Hero(
                tag:
                    "${connectionStore.baseUri}/webapi/entry.cgi?path=${Uri.encodeComponent(path)}&size=original&api=SYNO.FileStation.Thumb&method=get&version=2&_sid=${connectionStore.sid}&animate=true",
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
                    Text(
                      file['name'],
                      style: const TextStyle(
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(
                      height: 5,
                    ),
                    Text(
                      (file['isdir']
                              ? ""
                              : "${(int.parse(file['additional']['size'])).formatSize()} | ") +
                          DateTime.fromMillisecondsSinceEpoch(
                                  file['additional']['time']['crtime'] * 1000)
                              .format("Y/m/d H:i:s"),
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
              OutlinedButton(
                onPressed: () {
                  setState(() {
                    if (widget.multi) {
                      if (selectedFiles.contains(file['path'])) {
                        selectedFiles.remove(file['path']);
                      } else {
                        selectedFiles.add(file['path']);
                      }
                    } else {
                      selectedFiles = [file['path']];
                    }
                  });
                },
                child: SizedBox(
                  child: selectedFiles.contains(file['path'])
                      ? Icon(
                          CupertinoIcons.checkmark_alt,
                          color: Theme.of(context).colorScheme.primary,
                        )
                      : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> onWillPop(i, r) {
    setState(() {
      selectedFiles = [];
    });
    if (paths.length > 1) {
      paths.removeLast();
      String path = "";

      if (paths.length == 1) {
        path = "/";
      } else {
        path = paths.join("/").substring(1);
      }
      Log.debug(path);
      goPath(path);
      return Future.value(false);
    } else {
      return Future.value(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: onWillPop,
      child: Material(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.8,
            child: Column(
              children: [
                Container(
                  height: 45,
                  color: Theme.of(context).scaffoldBackgroundColor,
                  alignment: Alignment.centerLeft,
                  child: Row(
                    children: [
                      Expanded(
                        child: ListView.separated(
                          controller: _scrollController,
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
                      if (paths.length > 1)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: AppConstants.paddingSmall + 2),
                          child: OutlinedButton(
                            onPressed: () {
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
                                            margin: const EdgeInsets.symmetric(
                                                horizontal: 50),
                                            child: Padding(
                                              padding: const EdgeInsets.all(20),
                                              child: Column(
                                                children: [
                                                  const Text(
                                                    "新建文件夹",
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
                                                          const EdgeInsets.all(
                                                              8.0),
                                                      child: TextField(
                                                        onChanged: (v) =>
                                                            name = v,
                                                        decoration:
                                                            const InputDecoration(
                                                          border:
                                                              InputBorder.none,
                                                          hintText: "请输入文件夹名",
                                                          labelText: "文件夹名",
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
                                                            if (name.trim() ==
                                                                "") {
                                                              UiUtil.toast(
                                                                  "请输入文件夹名");
                                                              return;
                                                            }
                                                            Navigator.of(
                                                                    context)
                                                                .pop();
                                                            String path = paths
                                                                .join("/")
                                                                .substring(1);
                                                            var res = await DsmApi
                                                                .createFolder(
                                                                    path, name);
                                                            if (res[
                                                                'success']) {
                                                              UiUtil.toast(
                                                                  "文件夹创建成功");
                                                              refresh();
                                                            } else {
                                                              if (res['error'][
                                                                          'errors'] !=
                                                                      null &&
                                                                  res['error']['errors']
                                                                          .length >
                                                                      0 &&
                                                                  res['error']['errors']
                                                                              [
                                                                              0]
                                                                          [
                                                                          'code'] ==
                                                                      414) {
                                                                UiUtil.toast(
                                                                    "文件夹创建失败：指定的名称已存在");
                                                              } else {
                                                                UiUtil.toast(
                                                                    "文件夹创建失败");
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
                                                          onPressed: () async {
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
                                  });
                            },
                            child: const Text(
                              "新建",
                              style: TextStyle(fontSize: 14),
                            ),
                          ),
                        ),
                      const SizedBox(
                        width: 10,
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: AppConstants.paddingSmall + 2),
                        child: OutlinedButton(
                          onPressed: () {
                            if (selectedFiles.isNotEmpty) {
                              Navigator.of(context).pop(selectedFiles);
                            } else {
                              if (paths.length > 1) {
                                Navigator.of(context)
                                    .pop([paths.join("/").substring(1)]);
                              } else {
                                UiUtil.toast("无法选择根目录");
                              }
                            }
                          },
                          child: const Text(
                            "选择",
                            style: TextStyle(fontSize: 14),
                          ),
                        ),
                      ),
                      const SizedBox(
                        width: 20,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: loading
                      ? const Center(
                          child: CupertinoActivityIndicator(
                            radius: 14,
                          ),
                        )
                      : success
                          ? ListView(
                              padding: EdgeInsets.only(
                                  bottom: selectedFiles.isNotEmpty ? 140 : 20),
                              children: files
                                  .where((file) => file['isdir'])
                                  .map(_buildFileItem)
                                  .toList(),
                            )
                          : Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(msg),
                                  const SizedBox(
                                    height: 20,
                                  ),
                                  SizedBox(
                                    width: 200,
                                    child: OutlinedButton(
                                      onPressed: () {
                                        String path =
                                            paths.join("/").substring(1);
                                        goPath(path);
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
          ),
        ),
      ),
    );
  }
}
