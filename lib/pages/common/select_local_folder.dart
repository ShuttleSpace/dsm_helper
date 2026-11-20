import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:garden/constants/app_constants.dart';
import 'package:garden/util/file_types.dart';
import 'package:garden/util/file_type_util.dart';
import 'package:garden/util/http_util.dart';
import 'package:garden/widgets/file_icon.dart';
import 'package:signals_hooks/signals_hooks.dart';

class SelectLocalFolder extends HookWidget {
  final bool multi;
  final bool folder;
  const SelectLocalFolder({super.key, this.multi = false, this.folder = true});

  @override
  Widget build(BuildContext context) {
    final scrollController = useScrollController();
    final paths = useSignal<List<String>>(["/"]);
    final files = useSignal<List<FileSystemEntity>>([]);
    final selectedFiles = useSignal<List<FileSystemEntity>>([]);

    setPaths(String path) {
      if (path == "/") {
        paths.value = ["/"];
      } else {
        List<String> items = path.split("/");
        paths.value = items;
      }
    }

    getData() async {
      Directory directory;
      if (paths.value.length == 1) {
        directory = Directory("/storage/emulated/0/");
      } else {
        directory =
            Directory("/storage/emulated/0/${paths.value.join("/").substring(1)}");
      }
      final newFiles = <FileSystemEntity>[];
      await directory.list().forEach((element) {
        if (!element.path.split("/").last.startsWith(".")) {
          if (folder) {
            if (!FileSystemEntity.isFileSync(element.path)) {
              newFiles.add(element);
            }
          } else {
            newFiles.add(element);
          }
        }
      });
      newFiles.sort((a, b) {
        return a.path.toLowerCase().compareTo(b.path.toLowerCase());
      });
      files.value = newFiles;
    }

    goPath(String path) async {
      path = path.replaceAll("/storage/emulated/0", "");
      setPaths(path);
      await getData();
      double offset = scrollController.position.maxScrollExtent;
      scrollController.animateTo(offset,
          duration: const Duration(milliseconds: 200), curve: Curves.ease);
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
              items = paths.value.getRange(0, index + 1).toList();
              path = items.join("/");
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

    Widget buildFileItem(FileSystemEntity file) {
      FileTypeEnum fileType =
          FileTypeUtil.toFileTypeEnum(FileTypeUtil.getFileType(file.path));
      bool isFile = FileSystemEntity.isFileSync(file.path);
      return Padding(
        padding: const EdgeInsets.only(top: 20.0, left: 20, right: 20),
        child: Opacity(
          opacity: 1,
          child: OutlinedButton(
            onPressed: () async {
              if (isFile) {
                selectedFiles.value = [...selectedFiles.value, file];
              } else {
                goPath(file.path);
              }
            },
            // margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: [
                const SizedBox(
                  width: 20,
                ),
                FileIcon(
                  !isFile ? FileTypeEnum.folder : fileType,
                  thumb: file.path,
                  network: false,
                ),
                const SizedBox(
                  width: 10,
                ),
                Expanded(
                  child: Text(
                    file.path.split("/").last,
                    style: const TextStyle(
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(
                  width: 10,
                ),
                Checkbox(
                  value: selectedFiles.value.contains(file),
                  onChanged: (_) {
                    if (multi) {
                      if (selectedFiles.value.contains(file)) {
                        selectedFiles.value =
                            List.of(selectedFiles.value)..remove(file);
                      } else {
                        selectedFiles.value = [...selectedFiles.value, file];
                      }
                    } else {
                      selectedFiles.value = [file];
                    }
                  },
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
                const SizedBox(
                  width: 20,
                ),
              ],
            ),
          ),
        ),
      );
    }

    Future<bool> onWillPop(i, result) {
      selectedFiles.value = [];
      if (paths.value.length > 1) {
        paths.value = List.of(paths.value)..removeLast();
        String path = "";

        if (paths.value.length == 1) {
          path = "/";
        } else {
          path = paths.value.join("/");
        }
        goPath(path);
        return Future.value(false);
      } else {
        return Future.value(true);
      }
    }

    useEffect(() {
      getData();
      return null;
    }, const []);

    return PopScope(
      onPopInvokedWithResult: onWillPop,
      child: SizedBox(
        width: double.infinity,
        child: Material(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.8,
          child: SafeArea(
            top: false,
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
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              child: const Icon(
                                CupertinoIcons.right_chevron,
                                size: 14,
                              ),
                            );
                          },
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: AppConstants.paddingSmall + 2),
                        child: OutlinedButton(
                          onPressed: () {
                            if (selectedFiles.value.isNotEmpty) {
                              Navigator.of(context).pop(selectedFiles.value);
                            } else {
                              if (paths.value.length > 1) {
                                Navigator.of(context).pop([
                                  Directory(
                                      "/storage/emulated/0${paths.value.join("/")}")
                                ]);
                              }
                              // Navigator.of(context).pop(["/storage/emulated/0" + paths.join("/").substring(1)]);
                            }
                          },
                          child: const Text(
                            "完成",
                            style: TextStyle(fontSize: 12, color: Colors.blue),
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
                  child: ListView(
                    padding: EdgeInsets.only(
                        bottom: selectedFiles.value.isNotEmpty ? 140 : 20),
                    children: files.value.map(buildFileItem).toList(),
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
