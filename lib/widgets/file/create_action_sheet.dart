import 'package:flutter/cupertino.dart';
import 'package:garden/api/dsm_api.dart';
import 'package:garden/pages/control_panel/shared_folders/add_shared_folder.dart';
import 'package:garden/pages/file/remote_folder.dart';
import 'package:garden/pages/file/share.dart';
import 'package:garden/pages/file/share_manager.dart';
import 'package:garden/util/ui_util.dart';
import 'package:garden/widgets/bottom_action_sheet.dart';
import 'package:garden/widgets/name_input_dialog.dart';

/// 文件页「选择操作」浮层：共享文件夹/新建/文件请求/链接管理/装载远程。
class FileCreateActionSheet extends StatelessWidget {
  final List paths;
  final Future<List> Function() getVolumes;
  final VoidCallback onRefresh;
  final VoidCallback onReloadRemote;

  const FileCreateActionSheet({
    super.key,
    required this.paths,
    required this.getVolumes,
    required this.onRefresh,
    required this.onReloadRemote,
  });

  @override
  Widget build(BuildContext context) {
    return BottomActionSheet(
      title: "选择操作",
      titleSpacing: 12,
      cancelSpacing: 20,
      actions: [
        if (paths.isEmpty)
          BottomActionItem(
            label: "共享文件夹",
            iconAsset: "assets/icons/new_folder.png",
            onPressed: () async {
              final volumes = await getVolumes();
              if (volumes.isNotEmpty) {
                if (context.mounted) {
                  Navigator.of(context)
                      .push(CupertinoPageRoute(
                    builder: (context) => AddSharedFolders(volumes),
                    settings:
                        const RouteSettings(name: "add_shared_folders"),
                  ))
                      .then((res) {
                    if (res != null && res) {
                      onRefresh();
                    }
                  });
                }
              } else {
                UiUtil.toast("未获取到存储空间");
              }
            },
          ),
        if (paths.isNotEmpty)
          BottomActionItem(
            label: "新建文件夹",
            iconAsset: "assets/icons/new_folder.png",
            onPressed: () {
              showCupertinoDialog(
                context: context,
                builder: (context) => NameInputDialog(
                  title: "新建文件夹",
                  labelText: "文件夹名",
                  hintText: "请输入文件夹名",
                  emptyMessage: "请输入文件夹名",
                  onConfirm: (name) async {
                    final path = "/${paths.join("/")}";
                    try {
                      await dsmFileStationCreateFolderForPage(path, name);
                      UiUtil.toast("文件夹创建成功");
                      onRefresh();
                    } catch (e) {
                      final raw = e is DSMException ? e.rawError : null;
                      final errors = raw?['errors'] as List?;
                      if (errors != null &&
                          errors.isNotEmpty &&
                          errors[0]['code'] == 414) {
                        UiUtil.toast("文件夹创建失败：指定的名称已存在");
                      } else {
                        UiUtil.toast("文件夹创建失败");
                      }
                    }
                  },
                ),
              );
            },
          ),
        if (paths.isNotEmpty)
          BottomActionItem(
            label: "创建文件请求",
            iconAsset: "assets/icons/upload.png",
            widthDivisor: 4,
            onPressed: () {
              Navigator.of(context).push(CupertinoPageRoute(
                builder: (context) => Share(
                  paths: ["/${paths.join("/")}"],
                  fileRequest: true,
                ),
                settings: const RouteSettings(name: "share"),
              ));
            },
          ),
        BottomActionItem(
          label: "共享链接管理",
          iconAsset: "assets/icons/link.png",
          onPressed: () {
            Navigator.of(context).push(CupertinoPageRoute(
              builder: (content) => const ShareManager(),
              settings: const RouteSettings(name: "share_manager"),
            ));
          },
        ),
        BottomActionItem(
          label: "装载远程",
          iconAsset: "assets/icons/remote.png",
          onPressed: () {
            Navigator.of(context)
                .push(CupertinoPageRoute(
              builder: (content) => const RemoteFolder(),
              settings: const RouteSettings(name: "remote_folder"),
            ))
                .then((res) {
              onRefresh();
              onReloadRemote();
            });
          },
        ),
      ],
    );
  }
}
