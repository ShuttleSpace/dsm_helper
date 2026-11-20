import 'package:flutter/material.dart';

/// 文件标题操作栏组件
///
/// 用于显示文件管理页面的顶部操作按钮栏
class FileTitleAction extends StatelessWidget {
  final bool multiSelect;
  final bool favoriteLoading;
  final bool showProcessList;
  final ListType listType;
  final List paths;
  final int selectedFilesCount;
  final int totalFilesCount;
  final bool notReviewAccount;
  final bool hasBackgroundProcess;
  final VoidCallback onCollectPressed;
  final VoidCallback onRemotePressed;
  final VoidCallback onUploadPressed;
  final VoidCallback onProcessListPressed;
  final VoidCallback onSearchPressed;
  final VoidCallback onListTypeChanged;
  final VoidCallback onSelectAllPressed;
  final VoidCallback onSortPressed;
  final VoidCallback onActionsPressed;

  const FileTitleAction({
    super.key,
    required this.multiSelect,
    required this.favoriteLoading,
    required this.showProcessList,
    required this.listType,
    required this.paths,
    required this.selectedFilesCount,
    required this.totalFilesCount,
    required this.notReviewAccount,
    required this.hasBackgroundProcess,
    required this.onCollectPressed,
    required this.onRemotePressed,
    required this.onUploadPressed,
    required this.onProcessListPressed,
    required this.onSearchPressed,
    required this.onListTypeChanged,
    required this.onSelectAllPressed,
    required this.onSortPressed,
    required this.onActionsPressed,
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
          _buildCollectButton(),
          _buildRemoteButton(),
          if (notReviewAccount && paths.isNotEmpty && !multiSelect)
            _buildUploadButton(),
          if (hasBackgroundProcess) _buildProcessListButton(),
          const SizedBox(width: 24),
          if (paths.isNotEmpty) _buildSearchButton(),
          _buildListTypeButton(),
          if (multiSelect)
            _buildSelectAllButton()
          else if (paths.length > 1)
            _buildSortButton(),
          _buildActionsButton(),
        ],
      ),
    );
  }

  Widget _buildCollectButton() {
    return Padding(
      padding: const EdgeInsets.only(left: 10, top: 8, bottom: 8),
      child: OutlinedButton(
        onPressed: onCollectPressed,
        child: multiSelect
            ? const Icon(Icons.close)
            : Image.asset(
                "assets/icons/collect.png",
                width: 20,
              ),
      ),
    );
  }

  Widget _buildRemoteButton() {
    return Padding(
      padding: const EdgeInsets.only(left: 10, top: 8, bottom: 8),
      child: OutlinedButton(
        onPressed: onRemotePressed,
        child: Image.asset(
          "assets/icons/remote.png",
          width: 20,
        ),
      ),
    );
  }

  Widget _buildUploadButton() {
    return Padding(
      padding: const EdgeInsets.only(left: 10, top: 8, bottom: 8),
      child: OutlinedButton(
        onPressed: onUploadPressed,
        child: Image.asset(
          "assets/icons/upload.png",
          width: 20,
        ),
      ),
    );
  }

  Widget _buildProcessListButton() {
    return Padding(
      padding: const EdgeInsets.only(left: 10, top: 8, bottom: 8),
      child: OutlinedButton(
        onPressed: onProcessListPressed,
        child: Image.asset(
          "assets/icons/bgtask.gif",
          width: 20,
        ),
      ),
    );
  }

  Widget _buildSearchButton() {
    return Padding(
      padding: const EdgeInsets.only(right: 10, top: 8, bottom: 8),
      child: OutlinedButton(
        onPressed: onSearchPressed,
        child: Image.asset(
          "assets/icons/search.png",
          width: 20,
        ),
      ),
    );
  }

  Widget _buildListTypeButton() {
    return Padding(
      padding: const EdgeInsets.only(right: 10, top: 8, bottom: 8),
      child: OutlinedButton(
        onPressed: onListTypeChanged,
        child: Image.asset(
          listType == ListType.list
              ? "assets/icons/list_list.png"
              : "assets/icons/list_icon.png",
          width: 20,
          height: 20,
        ),
      ),
    );
  }

  Widget _buildSelectAllButton() {
    return Padding(
      padding: const EdgeInsets.only(right: 10, top: 8, bottom: 8),
      child: OutlinedButton(
        onPressed: onSelectAllPressed,
        child: Image.asset(
          "assets/icons/select_all.png",
          width: 20,
          height: 20,
        ),
      ),
    );
  }

  Widget _buildSortButton() {
    return Padding(
      padding: const EdgeInsets.only(right: 10, top: 8, bottom: 8),
      child: OutlinedButton(
        onPressed: onSortPressed,
        child: Image.asset(
          "assets/icons/sort.png",
          width: 20,
          height: 20,
        ),
      ),
    );
  }

  Widget _buildActionsButton() {
    return Padding(
      padding: const EdgeInsets.only(right: 10, top: 8, bottom: 8),
      child: OutlinedButton(
        onPressed: onActionsPressed,
        child: Image.asset(
          "assets/icons/actions.png",
          width: 20,
          height: 20,
        ),
      ),
    );
  }
}

/// 文件列表类型枚举
enum ListType { list, icon }