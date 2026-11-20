import 'package:flutter/material.dart';
import 'package:garden/theme/app_theme.dart';
import 'package:garden/util/file_type_util.dart';
import 'package:garden/util/file_types.dart';
import 'package:garden/util/ui_util.dart';
import 'package:garden/widgets/file/file_list_item.dart';

/// 文件页顶部的「远程文件夹」浮层。
class RemoteFolderSheet extends StatelessWidget {
  final List folders;
  final VoidCallback onRefresh;
  final void Function(Map folder) onFolderAction;
  final void Function(Map file, FileTypeEnum fileType) onFolderTap;

  const RemoteFolderSheet({
    super.key,
    required this.folders,
    required this.onRefresh,
    required this.onFolderAction,
    required this.onFolderTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: Colors.transparent,
        child: Card(
          shape: RoundedRectangleBorder(
            side: const BorderSide(),
            borderRadius: BorderRadius.circular(18),
          ),
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
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: SizedBox(
                          width: 30,
                          height: 30,
                          child: OutlinedButton(
                            onPressed: () {
                              UiUtil.toast("重新加载远程连接中");
                              Navigator.of(context).pop();
                              onRefresh();
                            },
                            child: const Icon(Icons.refresh, size: 20),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    constraints: BoxConstraints(
                      minHeight: 50,
                      maxHeight: MediaQuery.sizeOf(context).height * 0.8,
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          if (folders.isNotEmpty)
                            ...folders.map((folder) => FileListItem(
                                  file: folder,
                                  remote: true,
                                  iconMode: false,
                                  multiSelect: false,
                                  selected: false,
                                  onAction: () => onFolderAction(folder),
                                  onTap: () => onFolderTap(
                                    folder,
                                    FileTypeUtil.toFileTypeEnum(
                                      FileTypeUtil.getFileType(folder['name']),
                                    ),
                                  ),
                                ))
                          else
                            Center(
                              child: Text(
                                "未挂载远程文件夹",
                                style: TextStyle(
                                  color: AppTheme.of(context).placeholderColor,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text("取消", style: TextStyle(fontSize: 18)),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
