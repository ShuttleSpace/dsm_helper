import 'package:garden/util/file_type_util.dart';
import 'package:garden/stores/connection_store.dart';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:garden/constants/app_constants.dart';
import 'package:garden/theme/app_theme.dart';
import 'package:garden/util/http_util.dart';
import 'package:garden/widgets/file_icon.dart';

/// 文件列表项组件
///
/// 用于显示文件/文件夹的列表项，支持图标和列表两种视图模式
class FileListItem extends StatelessWidget {
  final Map file;
  final bool multiSelect;
  final bool selected;
  final bool remote;
  final ListType listType;
  final VoidCallback? onTap;
  final ValueChanged? onMulitSelect;

  const FileListItem({
    super.key,
    required this.file,
    this.multiSelect = false,
    this.selected = false,
    this.remote = false,
    this.listType = ListType.list,
    this.onTap,
    this.onMulitSelect,
  });

  @override
  Widget build(BuildContext context) {
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
              child: selected
                  ? Icon(
                      CupertinoIcons.checkmark_alt,
                      color: Theme.of(context).colorScheme.primary,
                    )
                  : null,
            ),
          )
        : GestureDetector(
            onTap: onTap,
            child: Card(
              shape: RoundedRectangleBorder(
                  side: const BorderSide(),
                  borderRadius: BorderRadius.circular(18)),
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
        onPressed: () {
          if (!multiSelect) {
            onMulitSelect?.call((true, file));
          }
        },
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.black,
          backgroundColor: Colors.transparent,
          side: BorderSide(color: Colors.grey.shade300),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: listType == ListType.icon && !remote
            ? Stack(
                children: [
                  Align(
                    alignment: Alignment.center,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Column(
                        children: [
                          Hero(
                            tag:
                                "${connectionStore.baseUri}/webapi/entry.cgi?path=${Uri.encodeComponent(path)}&size=original&api=SYNO.FileStation.Thumb&method=get&version=2&_sid=${connectionStore.sid}&animate=true",
                            child: FileIcon(
                              file['isdir'] ? FileTypeEnum.folder : fileType,
                              thumb: file['path'],
                              width:
                                  (MediaQuery.sizeOf(context).width - 140) / 3,
                              height: 30,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            file['name'],
                            maxLines: 1,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 12),
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
              )
            : Row(
                children: [
                  const SizedBox(
                    width: 10,
                  ),
                  Hero(
                    tag:
                        "${connectionStore.baseUri}/webapi/entry.cgi?path=${Uri.encodeComponent(path)}&size=thumb&api=NEU_FILE_THUMB&method=get&version=1&_sid=${connectionStore.sid}&animate=true",
                    child: FileIcon(
                      file['isdir'] ? FileTypeEnum.folder : fileType,
                      thumb: file['path'],
                      width: 30,
                      height: 30,
                    ),
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          file['name'],
                          maxLines: 2,
                          style: const TextStyle(
                              fontSize: AppConstants.fontSizeMedium),
                          overflow: TextOverflow.ellipsis,
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
      ),
    );
  }
}

/// 文件列表项类型枚举
enum ListType { list, icon }
