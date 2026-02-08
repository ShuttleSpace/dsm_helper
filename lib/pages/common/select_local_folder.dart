import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:garden/constants/app_constants.dart';
import 'package:garden/util/file_types.dart';
import 'package:garden/util/file_type_util.dart';
import 'package:garden/util/http_util.dart';
import 'package:garden/widgets/file_icon.dart';

class SelectLocalFolder extends StatefulWidget {
  final bool multi;
  final bool folder;
  const SelectLocalFolder({super.key, this.multi = false, this.folder = true});
  @override
  SelectLocalFolderState createState() => SelectLocalFolderState();
}

class SelectLocalFolderState extends State<SelectLocalFolder> {
  final ScrollController _scrollController = ScrollController();
  List<String> paths = ["/"];
  List<FileSystemEntity> files = [];
  List<FileSystemEntity> selectedFiles = [];
  String msg = "";
  @override
  void initState() {
    getData();
    super.initState();
  }

  getData() async {
    Directory directory;
    if (paths.length == 1) {
      directory = Directory("/storage/emulated/0/");
    } else {
      directory =
          Directory("/storage/emulated/0/${paths.join("/").substring(1)}");
    }
    files = [];
    await directory.list().forEach((element) {
      if (!element.path.split("/").last.startsWith(".")) {
        if (widget.folder) {
          if (!FileSystemEntity.isFileSync(element.path)) {
            files.add(element);
          }
        } else {
          files.add(element);
        }
      }
    });
    files.sort((a, b) {
      return a.path.toLowerCase().compareTo(b.path.toLowerCase());
    });
    setState(() {});
  }

  goPath(String path) async {
    path = path.replaceAll("/storage/emulated/0", "");
    setPaths(path);
    await getData();
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
            items = paths.getRange(0, index + 1).toList();
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
                paths[index],
                style: const TextStyle(fontSize: 12),
              ),
      ),
    );
  }

  Widget _buildFileItem(FileSystemEntity file) {
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
              selectedFiles.add(file);
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
              OutlinedButton(
                onPressed: () {
                  setState(() {
                    if (widget.multi) {
                      if (selectedFiles.contains(file)) {
                        selectedFiles.remove(file);
                      } else {
                        selectedFiles.add(file);
                      }
                    } else {
                      selectedFiles = [file];
                    }
                  });
                },
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: selectedFiles.contains(file)
                      ? Icon(
                          CupertinoIcons.checkmark_alt,
                          color: Theme.of(context).colorScheme.primary,
                        )
                      : null,
                ),
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
    setState(() {
      selectedFiles = [];
    });
    if (paths.length > 1) {
      paths.removeLast();
      String path = "";

      if (paths.length == 1) {
        path = "/";
      } else {
        path = paths.join("/");
      }
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
                      Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: AppConstants.paddingSmall + 2),
                        child: OutlinedButton(
                          onPressed: () {
                            if (selectedFiles.isNotEmpty) {
                              Navigator.of(context).pop(selectedFiles);
                            } else {
                              if (paths.length > 1) {
                                Navigator.of(context).pop([
                                  Directory(
                                      "/storage/emulated/0${paths.join("/")}")
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
                        bottom: selectedFiles.isNotEmpty ? 140 : 20),
                    children: files.map(_buildFileItem).toList(),
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
