import 'package:garden/theme/app_theme.dart';
import 'package:garden/util/file_type_util.dart';
import 'package:garden/util/log.dart';
import 'package:garden/util/ui_util.dart';
import 'package:garden/widgets/name_input_dialog.dart';
import 'package:garden/stores/connection_store.dart';
import 'package:garden/api/dsm_api.dart';
import 'package:garden/extensions/datetime.dart';
import 'package:garden/extensions/int.dart';
import 'package:garden/util/file_types.dart';
import 'package:garden/widgets/file_icon.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:garden/constants/app_constants.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:signals_hooks/signals_hooks.dart';

class SelectFolder extends HookWidget {
  final bool multi;
  final bool folder;

  /// 非空时额外列出这些扩展名的文件（单选模式下点文件直接返回它），
  /// 字幕、下载种子这类「挑一个文件」的入口复用它，不必另写一个浏览页。
  final List<String> fileExtensions;
  const SelectFolder(
      {super.key,
      this.multi = false,
      this.folder = true,
      this.fileExtensions = const []});

  @override
  Widget build(BuildContext context) {
    final scrollController = useScrollController();
    final paths = useListSignal<String>(["/"]);
    final files = useSignal<List>([]);
    final selectedFiles = useListSignal([]);
    final loading = useSignal(true);
    final success = useSignal(true);
    final msg = useSignal("");

    setPaths(String path) {
      if (path == "/") {
        paths.value = ["/"];
      } else {
        List<String> items = path.split("/");
        items[0] = "/";
        paths.value = items;
      }
    }

    Future<void> getShareList() async {
      loading.value = true;
      try {
        final data = await dsmFileStationListShareForPage();
        files.value = data['shares'] ?? [];
        success.value = true;
      } catch (e) {
        success.value = false;
        msg.value = e is DSMException
            ? '加载失败，code:${e.code}${e.message.toString().isNotEmpty ? '：${e.message}' : ''}'
            : '加载失败：$e';
      } finally {
        loading.value = false;
      }
    }

    Future<void> getFileList(String path) async {
      loading.value = true;
      try {
        final data = await dsmFileStationListForPage(path);
        files.value = data['files'] ?? [];
        success.value = true;
      } catch (e) {
        success.value = false;
        msg.value = e is DSMException
            ? '加载失败，code:${e.code}${e.message.toString().isNotEmpty ? '：${e.message}' : ''}'
            : '加载失败：$e';
      } finally {
        loading.value = false;
      }
    }

    goPath(String path) async {
      setPaths(path);
      if (path == "/") {
        await getShareList();
      } else {
        await getFileList(path);
      }
      double offset = scrollController.position.maxScrollExtent;
      scrollController.animateTo(offset,
          duration: const Duration(milliseconds: 200), curve: Curves.ease);
    }

    refresh() {
      String path = paths.value.join("/").substring(1);
      goPath(path);
    }

    Widget buildPathItem(BuildContext context, int index) {
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
              items = paths.value.getRange(1, index + 1).toList().cast();
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
                  paths.value[index],
                  style: const TextStyle(fontSize: 12),
                ),
        ),
      );
    }

    Widget buildFileItem(file) {
      FileTypeEnum fileType =
          FileTypeUtil.toFileTypeEnum(FileTypeUtil.getFileType(file['name']));
      String path = file['path'];
      return Padding(
        padding: const EdgeInsets.only(top: 20.0, left: 20, right: 20),
        child: Opacity(
          opacity: 1,
          child: OutlinedButton(
            // 多选时点一行仍是进目录，选目录靠右侧勾选框
            onPressed: () async {
              if (file['isdir']) {
                goPath(file['path']);
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
                Checkbox(
                  value: selectedFiles.contains(file['path']),
                  onChanged: (_) {
                    if (multi) {
                      if (selectedFiles.contains(file['path'])) {
                        selectedFiles.remove(file['path']);
                      } else {
                        selectedFiles.add(file['path']);
                      }
                    } else {
                      selectedFiles.value = [file['path']];
                    }
                  },
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
        ),
      );
    }

    Future<bool> onWillPop(i, r) {
      selectedFiles.clear();
      if (paths.value.length > 1) {
        paths.value.removeLast();
        String path = "";

        if (paths.value.length == 1) {
          path = "/";
        } else {
          path = paths.value.join("/").substring(1);
        }
        Log.debug(path);
        goPath(path);
        return Future.value(false);
      } else {
        return Future.value(true);
      }
    }

    useEffect(() {
      getShareList();
      return null;
    }, const []);

    return PopScope(
      onPopInvokedWithResult: onWillPop,
      child: SizedBox(
        width: double.infinity,
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
                            controller: scrollController,
                            itemBuilder: buildPathItem,
                            itemCount: paths.value.length,
                            scrollDirection: Axis.horizontal,
                            separatorBuilder: (context, i) {
                              return Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                child: const Icon(
                                  CupertinoIcons.right_chevron,
                                  size: 14,
                                ),
                              );
                            },
                          ),
                        ),
                        if (paths.value.length > 1)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: AppConstants.paddingSmall + 2),
                            child: OutlinedButton(
                              onPressed: () {
                                showCupertinoDialog(
                                    context: context,
                                    builder: (context) => NameInputDialog(
                                          title: "新建文件夹",
                                          labelText: "文件夹名",
                                          hintText: "请输入文件夹名",
                                          emptyMessage: "请输入文件夹名",
                                          onConfirm: (name) async {
                                            String path = paths.value
                                                .join("/")
                                                .substring(1);
                                            try {
                                              await dsmFileStationCreateFolderForPage(
                                                  path, name);
                                              UiUtil.toast("文件夹创建成功");
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
                                                UiUtil.toast(
                                                    "文件夹创建失败：指定的名称已存在");
                                              } else {
                                                UiUtil.toast("文件夹创建失败");
                                              }
                                            }
                                          },
                                        ));
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
                                // 必须给副本：pop 之后 PopScope 会 clear 掉原列表
                                Navigator.of(context).pop(
                                    List<String>.from(selectedFiles.value));
                              } else {
                                if (paths.value.length > 1) {
                                  Navigator.of(context).pop(
                                      [paths.value.join("/").substring(1)]);
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
                    child: loading.value
                        ? const Center(
                            child: CupertinoActivityIndicator(
                              radius: 14,
                            ),
                          )
                        : success.value
                            ? ListView(
                                padding: EdgeInsets.only(
                                    bottom: selectedFiles.value.isNotEmpty
                                        ? 140
                                        : 20),
                                children: files.value
                                    .where((file) =>
                                        file['isdir'] ||
                                        fileExtensions.contains(
                                            '${file['name']}'
                                                .split('.')
                                                .last
                                                .toLowerCase()))
                                    .map(buildFileItem)
                                    .toList(),
                              )
                            : Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(msg.value),
                                    const SizedBox(
                                      height: 20,
                                    ),
                                    SizedBox(
                                      width: 200,
                                      child: OutlinedButton(
                                        onPressed: () {
                                          String path = paths.value
                                              .join("/")
                                              .substring(1);
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
      ),
    );
  }
}
