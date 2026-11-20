import 'package:extended_text/extended_text.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:garden/api/dsm_api.filestation.transfer_url.dart';
import 'package:garden/extensions/datetime.dart';
import 'package:garden/extensions/int.dart';
import 'package:garden/stores/connection_store.dart';
import 'package:garden/theme/app_theme.dart';
import 'package:garden/util/file_type_util.dart';
import 'package:garden/util/file_types.dart';
import 'package:garden/util/ui_util.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';
import 'package:garden/widgets/file_icon.dart';

/// 文件列表项（列表/图标两种布局）。
///
/// 从 `Files.buildFileItem` 抽出，业务动作由回调传入，
/// 多选状态由 [multiSelect] / [selected] 驱动。
class FileListItem extends StatelessWidget {
  final Map file;
  final bool remote;
  final bool iconMode;
  final bool multiSelect;
  final bool selected;
  final VoidCallback onAction;
  final VoidCallback onTap;

  const FileListItem({
    super.key,
    required this.file,
    required this.remote,
    required this.iconMode,
    required this.multiSelect,
    required this.selected,
    required this.onAction,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fileType =
        FileTypeUtil.toFileTypeEnum(FileTypeUtil.getFileType(file['name']));
    final String path = file['path'];
    Widget actionButton = multiSelect
        ? Card(
            shape: RoundedRectangleBorder(
              side: const BorderSide(),
              borderRadius: BorderRadius.circular(18),
            ),
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
            onTap: onAction,
            child: Card(
              shape: RoundedRectangleBorder(
                side: const BorderSide(),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Padding(
                padding: EdgeInsets.all(2.0),
                child: Icon(CupertinoIcons.right_chevron, size: 14),
              ),
            ),
          );

    return Container(
      constraints: iconMode ? const BoxConstraints(maxWidth: 112) : null,
      width: iconMode ? (MediaQuery.sizeOf(context).width - 80) / 3 : double.infinity,
      padding: iconMode ? EdgeInsets.zero : const EdgeInsets.only(bottom: 20.0),
      child: OutlinedButton(
        onLongPress: () {
          UiUtil.vibrate(FeedbackType.light);
          onAction();
        },
        onPressed: onTap,
        child: !iconMode
            ? Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  children: [
                    const SizedBox(width: 10),
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
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ExtendedText(
                            file['name'],
                            style: TextStyle(
                              fontSize: 14,
                              color: file['additional']?['mount_point_type'] ==
                                          "remotefail"
                                  ? AppTheme.of(context).titleColor
                                  : Theme.brightnessOf(context) ==
                                          Brightness.dark
                                      ? Colors.white
                                      : Colors.black,
                            ),
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
                          const SizedBox(height: 5),
                          if (!file['isdir'] && file['additional'] != null ||
                              (file['additional']?['time'] != null &&
                                  file['additional']['time']['mtime'] != null))
                            Text.rich(
                              TextSpan(
                                children: [
                                  if (!file['isdir'])
                                    TextSpan(
                                      text: (int.parse(file['additional']['size']
                                              .toString()))
                                          .formatSize(),
                                    ),
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
                                    ),
                                ],
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.of(context).placeholderColor,
                                ),
                              ),
                            ),
                          if (remote)
                            Text(
                              file['path'],
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.of(context).placeholderColor,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    actionButton,
                    const SizedBox(width: 10),
                  ],
                ),
              )
            : Stack(
                children: [
                  Align(
                    alignment: Alignment.center,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 5),
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
                              width: (MediaQuery.sizeOf(context).width - 140) / 3,
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
              ),
      ),
    );
  }
}
