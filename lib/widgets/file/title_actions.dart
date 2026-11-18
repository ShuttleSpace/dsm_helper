import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:garden/util/file_types.dart';
import 'package:garden/widgets/file/create_action_sheet.dart';
import 'package:garden/widgets/file/remote_folder_sheet.dart';
import 'package:garden/widgets/file/sort_menu.dart';
import 'package:signals_hooks/signals_hooks.dart';

/// 文件页标题栏的一排操作按钮。
class FileTitleActions extends StatelessWidget {
  final Signal<bool> multiSelect;
  final Signal<bool> showProcessList;
  final Signal<List> selectedFiles;
  final Signal<List> files;
  final Signal<List> paths;
  final Signal<String> sortBy;
  final Signal<String> sortDirection;
  final bool notVisitor;
  final bool iconMode;
  final bool hasBackgroundProcess;
  final List remoteFolders;

  final VoidCallback onToggleFavorite;
  final VoidCallback onToggleProcessList;
  final VoidCallback onUpload;
  final VoidCallback onSearch;
  final VoidCallback onToggleListType;
  final VoidCallback onSelectAll;
  final VoidCallback onRefresh;
  final VoidCallback onRefreshRemote;
  final Future<List> Function() getVolumes;
  final void Function(Map folder) onFolderAction;
  final void Function(Map file, FileTypeEnum fileType) onFolderTap;

  const FileTitleActions({
    super.key,
    required this.multiSelect,
    required this.showProcessList,
    required this.selectedFiles,
    required this.files,
    required this.paths,
    required this.sortBy,
    required this.sortDirection,
    required this.notVisitor,
    required this.iconMode,
    required this.hasBackgroundProcess,
    required this.remoteFolders,
    required this.onToggleFavorite,
    required this.onToggleProcessList,
    required this.onUpload,
    required this.onSearch,
    required this.onToggleListType,
    required this.onSelectAll,
    required this.onRefresh,
    required this.onRefreshRemote,
    required this.getVolumes,
    required this.onFolderAction,
    required this.onFolderTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.sizeOf(context).width,
      height: 50,
      child: ListView(
        scrollDirection: Axis.horizontal,
        shrinkWrap: true,
        children: [
          _button(
            left: true,
            onTap: onToggleFavorite,
            child: multiSelect.value
                ? const Icon(Icons.close)
                : Image.asset("assets/icons/collect.png", width: 20),
          ),
          _button(
            left: true,
            onTap: () {
              showCupertinoModalPopup(
                context: context,
                builder: (context) => RemoteFolderSheet(
                  folders: remoteFolders,
                  onRefresh: onRefreshRemote,
                  onFolderAction: onFolderAction,
                  onFolderTap: onFolderTap,
                ),
              );
            },
            child: Image.asset("assets/icons/remote.png", width: 20),
          ),
          if (notVisitor && paths.value.isNotEmpty && !multiSelect.value)
            _button(
              left: true,
              onTap: onUpload,
              child: Image.asset("assets/icons/upload.png", width: 20),
            ),
          if (hasBackgroundProcess)
            _button(
              left: true,
              onTap: onToggleProcessList,
              child: Image.asset("assets/icons/bgtask.gif", width: 20),
            ),
          const SizedBox(width: 24),
          if (paths.value.isNotEmpty)
            _button(
              left: false,
              onTap: onSearch,
              child: Image.asset("assets/icons/search.png", width: 20),
            ),
          _button(
            left: false,
            onTap: onToggleListType,
            child: Image.asset(
              iconMode
                  ? "assets/icons/list_icon.png"
                  : "assets/icons/list_list.png",
              width: 20,
              height: 20,
            ),
          ),
          if (multiSelect.value)
            _button(
              left: false,
              onTap: onSelectAll,
              child: Image.asset("assets/icons/select_all.png", width: 20),
            )
          else if (paths.value.length > 1)
            _button(
              left: false,
              onTap: () {
                showCupertinoModalPopup(
                  context: context,
                  builder: (context) => FileSortMenu(
                    sortBy: sortBy,
                    sortDirection: sortDirection,
                  ),
                ).then((value) => onRefresh());
              },
              child: Image.asset("assets/icons/sort.png", width: 20),
            ),
          _button(
            left: false,
            onTap: () {
              showCupertinoModalPopup(
                context: context,
                builder: (context) => FileCreateActionSheet(
                  paths: paths.value,
                  getVolumes: getVolumes,
                  onRefresh: onRefresh,
                  onReloadRemote: onRefreshRemote,
                ),
              );
            },
            child: Image.asset("assets/icons/actions.png", width: 20),
          ),
        ],
      ),
    );
  }

  Widget _button({
    required bool left,
    required VoidCallback onTap,
    required Widget child,
  }) {
    return Padding(
      padding: EdgeInsets.only(
        left: left ? 10 : 0,
        right: left ? 0 : 10,
        top: 8,
        bottom: 8,
      ),
      child: OutlinedButton(onPressed: onTap, child: child),
    );
  }
}
