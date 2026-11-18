import 'dart:convert';
import 'package:garden/extensions/int.dart';
import 'package:garden/util/file_types.dart';
import 'package:garden/util/log.dart';
import 'package:garden/util/ui_util.dart';

import 'package:garden/pages/control_panel/shared_folders/add_shared_folder.dart';
import 'package:garden/api/dsm_api.dart';
import 'package:garden/widgets/file_icon.dart';
import 'package:garden/widgets/neu_back_button.dart';
import 'package:flutter/cupertino.dart';
import 'package:garden/widgets/bottom_confirm_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:signals_hooks/signals_hooks.dart';

class SharedFolders extends HookWidget {
  const SharedFolders({super.key});

  @override
  Widget build(BuildContext context) {
    final loading = useSignal(true);
    final success = useSignal(true);
    final msg = useSignal("");
    final folders = useSignal<List>([]);
    final volumes = useSignal<List>([]);

    Future<void> getData() async {
      loading.value = true;
      try {
        final data = await dsmControlPanelPost({
          "api": '"SYNO.Core.Share"',
          "method": '"list"',
          "version": 1,
          "shareType": '"all"',
          "additional": jsonEncode([
            "hidden",
            "encryption",
            "is_aclmode",
            "unite_permission",
            "is_support_acl",
            "is_sync_share",
            "is_force_readonly",
            "force_readonly_reason",
            "recyclebin",
            "is_share_moving",
            "is_cluster_share",
            "is_exfat_share",
            "support_snapshot",
            "share_quota",
            "enable_share_compress",
            "enable_share_cow",
          ]),
        });
        folders.value = data['shares'] ?? [];
        for (final folder in folders.value) {
          for (final volume in volumes.value) {
            if (volume['volume_path'] == folder['vol_path']) {
              folder['volume_name'] = volume['display_name'];
              folder['volume_desc'] = volume['description'];
            }
          }
        }
        folders.value = List.of(folders.value);
        success.value = true;
      } catch (e) {
        success.value = false;
        msg.value = '加载失败，code:${e is DSMException ? e.code : -1}';
      } finally {
        loading.value = false;
      }
    }

    Future<void> getVolumes() async {
      try {
        final data = await dsmCoreStorageVolumeListForPage();
        volumes.value = data['volumes'] ?? [];
        await getData();
      } catch (e) {
        Log.warn('volumes: $e');
      }
    }

    useEffect(() {
      getVolumes();
      return null;
    }, const []);

    deleteFolder(String folder) {
      showCupertinoModalPopup(
        context: context,
        builder: (context) => BottomConfirmSheet(
          title: "删除共享文件夹",
          content: "我已了解所选共享文件夹及其快照将被永久删除并无法恢复",
          confirmText: "确认删除",
          buttonSpacing: 16,
          onConfirm: () async {
            try {
              await dsmControlPanelPost({
                "api": '"SYNO.Core.Share"',
                "method": '"delete"',
                "version": 1,
                "name": jsonEncode([folder]),
              });
              UiUtil.toast("共享文件夹删除成功");
              getData();
            } catch (e) {
              UiUtil.toast("共享文件夹删除出错");
            }
          },
        ),
      );
    }

    Widget buildFolderItem(folder) {
      return Padding(
        padding: const EdgeInsets.only(top: 20.0, left: 20, right: 20),
        child: Opacity(
          opacity: 1,
          child: OutlinedButton(
            onPressed: () async {},
            // margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: [
                const SizedBox(
                  width: 20,
                ),
                folder['encryption'] == null || folder['encryption'] == 0
                    ? const FileIcon(
                        FileTypeEnum.folder,
                      )
                    : Image.asset(
                        "assets/icons/folder_locked.png",
                        width: 40,
                        height: 40,
                      ),
                const SizedBox(
                  width: 10,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        folder['name'],
                        style: const TextStyle(
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(
                        height: 5,
                      ),
                      Text(
                        "${folder['volume_name']}${folder['volume_desc'] != "" ? "(${folder['volume_desc']})" : ""}",
                        style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.color),
                      ),
                      if (folder['unite_permission'] != null) ...[
                        const SizedBox(
                          height: 5,
                        ),
                        Text(
                          "高级权限：${folder['unite_permission'] ? "已启动" : "已停用"}",
                          style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.color),
                        ),
                      ],
                      if (folder['enable_recycle_bin'] != null) ...[
                        const SizedBox(
                          height: 5,
                        ),
                        Text(
                          "回收站：${folder['enable_recycle_bin'] ? "已启动" : "已停用"}",
                          style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.color),
                        ),
                      ],
                      if (folder['quota_value'] != null) ...[
                        const SizedBox(
                          height: 5,
                        ),
                        Text(
                          "共享文件夹配额：${folder['quota_value'] > 0 ? ((folder['quota_value'] as num) * 1024 * 1024).formatSize() : "已停用"}",
                          style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.color),
                        ),
                      ],
                      if (folder['share_quota_used'] != null) ...[
                        const SizedBox(
                          height: 5,
                        ),
                        Text(
                          "共享文件夹大小：${((folder['share_quota_used'] as num) * 1024 * 1024).formatSize()}",
                          style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.color),
                        ),
                      ],
                      if (folder['enable_share_compress'] != null) ...[
                        const SizedBox(
                          height: 5,
                        ),
                        Text(
                          "文件压缩：${folder['enable_share_compress'] ? "已启动" : "已禁用"}",
                          style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.color),
                        ),
                      ],
                      if (folder['enable_share_cow'] != null) ...[
                        const SizedBox(
                          height: 5,
                        ),
                        Text(
                          "数据完整性保护：${folder['enable_share_cow'] ? "已启动" : "已禁用"}",
                          style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.color),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(
                  width: 10,
                ),
                folder['is_share_moving']
                    ? const Text("移动中")
                    : OutlinedButton(
                        onPressed: () {
                          showCupertinoModalPopup(
                            context: context,
                            builder: (context) {
                              return SizedBox(
                                width: double.infinity,
                                child: Material(
                                  color: Colors.transparent,
                                  child: Card(
                                    shape: RoundedRectangleBorder(
                                        side: const BorderSide(),
                                        borderRadius:
                                            BorderRadius.circular(18)),
                                    child: SafeArea(
                                      top: false,
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: <Widget>[
                                          const Text(
                                            "选择操作",
                                            style: TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.w500),
                                          ),
                                          const SizedBox(
                                            height: 12,
                                          ),
                                          if (folder['support_snapshot']) ...[
                                            OutlinedButton(
                                              onPressed: () async {
                                                Navigator.of(context).pop();
                                              },
                                              child: const Text(
                                                "克隆",
                                                style: TextStyle(fontSize: 18),
                                              ),
                                            ),
                                            const SizedBox(
                                              height: 16,
                                            ),
                                          ],
                                          OutlinedButton(
                                            onPressed: () async {
                                              Navigator.of(context).pop();
                                              Navigator.of(context)
                                                  .push(CupertinoPageRoute(
                                                      builder: (context) {
                                                        return AddSharedFolders(
                                                            volumes.value,
                                                            folder: folder);
                                                      },
                                                      settings: const RouteSettings(
                                                          name:
                                                              "add_shared_folders")))
                                                  .then((res) {
                                                if (res != null && res) {
                                                  getData();
                                                }
                                              });
                                            },
                                            child: const Text(
                                              "编辑",
                                              style: TextStyle(fontSize: 18),
                                            ),
                                          ),
                                          const SizedBox(
                                            height: 16,
                                          ),
                                          if (folder['enable_recycle_bin']) ...[
                                            OutlinedButton(
                                              onPressed: () async {
                                                Navigator.of(context).pop();
                                                dsmControlPanelPost({
                                                  folder['name']:
                                                      '"${folder['name']}"',
                                                  "api":
                                                      '"SYNO.Core.RecycleBin"',
                                                  "method": 'start',
                                                  "version": 1,
                                                }).then((_) {
                                                  UiUtil.toast("请求已发送");
                                                }).catchError((_) {});
                                              },
                                              child: const Text(
                                                "清空回收站",
                                                style: TextStyle(fontSize: 18),
                                              ),
                                            ),
                                            const SizedBox(
                                              height: 16,
                                            ),
                                          ],
                                          OutlinedButton(
                                            onPressed: () async {
                                              Navigator.of(context).pop();
                                              deleteFolder(folder['name']);
                                            },
                                            child: const Text(
                                              "删除",
                                              style: TextStyle(
                                                  fontSize: 18,
                                                  color: Colors.redAccent),
                                            ),
                                          ),
                                          const SizedBox(
                                            height: 8,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                        child: const Icon(
                          CupertinoIcons.right_chevron,
                          size: 18,
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

    return Scaffold(
      appBar: AppBar(
        leading: AppBackButton(context),
        title: const Text(
          "共享文件夹",
        ),
        actions: volumes.value.isNotEmpty
            ? [
                Padding(
                  padding: const EdgeInsets.only(right: 10, top: 8, bottom: 8),
                  child: OutlinedButton(
                    onPressed: () async {
                      Navigator.of(context)
                          .push(CupertinoPageRoute(
                              builder: (context) {
                                return AddSharedFolders(volumes.value);
                              },
                              settings: const RouteSettings(
                                  name: "add_shared_folders")))
                          .then((res) {
                        if (res != null && res) {
                          getData();
                        }
                      });
                    },
                    child: const Icon(Icons.add),
                  ),
                )
              ]
            : null,
      ),
      body: success.value
          ? Stack(
              children: [
                ListView.builder(
                  padding: const EdgeInsets.only(bottom: 20),
                  itemBuilder: (context, i) {
                    return buildFolderItem(folders.value[i]);
                  },
                  itemCount: folders.value.length,
                ),
                // if (selectedFiles.length > 0)
                if (loading.value)
                  Container(
                    width: MediaQuery.sizeOf(context).width,
                    height: MediaQuery.sizeOf(context).height,
                    color: Theme.of(context)
                        .scaffoldBackgroundColor
                        .withValues(alpha: .7),
                    child: const Center(
                      child: CupertinoActivityIndicator(
                        radius: 14,
                      ),
                    ),
                  ),
              ],
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
                        getData();
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
    );
  }
}
