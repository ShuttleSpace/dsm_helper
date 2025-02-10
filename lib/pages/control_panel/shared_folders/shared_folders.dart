import 'dart:async';

import 'package:dsm_helper/pages/control_panel/shared_folders/add_shared_folder.dart';
import 'package:dsm_helper/util/function.dart';
import 'package:dsm_helper/widgets/file_icon.dart';
import 'package:dsm_helper/widgets/neu_back_button.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class SharedFolders extends StatefulWidget {
  @override
  _SharedFoldersState createState() => _SharedFoldersState();
}

class _SharedFoldersState extends State<SharedFolders> {
  bool loading = true;
  bool success = true;
  String msg = "";
  List folders = [];
  List volumes = [];
  late Timer timer;
  @override
  void initState() {
    getVolumes();
    super.initState();
  }

  getVolumes() async {
    var res = await Api.volumes();
    if (res['success']) {
      setState(() {
        volumes = res['data']['volumes'];
      });
      getData();
    }
  }

  getData() async {
    setState(() {
      loading = true;
    });
    var res = await Api.shareCore(additional: [
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
    ]);
    setState(() {
      loading = false;
      success = res['success'];
    });
    if (res['success']) {
      folders = res['data']['shares'];
      folders.forEach((folder) {
        volumes.forEach((volume) {
          if (volume['volume_path'] == folder['vol_path']) {
            folder['volume_name'] = volume['display_name'];
            folder['volume_desc'] = volume['description'];
          }
        });
      });
      setState(() {});
    } else {
      if (loading) {
        setState(() {
          msg = res['msg'] ?? "加载失败，code:${res['error']['code']}";
        });
      }
    }
  }

  deleteFolder(String folder) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) {
        return Material(
          color: Colors.transparent,
          child: Card(
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    "删除共享文件夹",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                  ),
                  SizedBox(
                    height: 12,
                  ),
                  Text(
                    "我已了解所选共享文件夹及其快照将被永久删除并无法恢复",
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w400,
                        color: Colors.red),
                  ),
                  SizedBox(
                    height: 22,
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            Navigator.of(context).pop();
                            var res = await Api.deleteSharedFolder([folder]);
                            print(res);
                            if (res['success']) {
                              Util.toast("共享文件夹删除成功");
                              getData();
                            } else {
                              Util.toast("共享文件夹删除出错");
                            }
                          },
                          child: Text(
                            "确认删除",
                            style: TextStyle(
                                fontSize: 18, color: Colors.redAccent),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 16,
                      ),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            Navigator.of(context).pop();
                          },
                          child: Text(
                            "取消",
                            style: TextStyle(fontSize: 18),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 8,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFolderItem(folder) {
    return Padding(
      padding: const EdgeInsets.only(top: 20.0, left: 20, right: 20),
      child: Opacity(
        opacity: 1,
        child: OutlinedButton(
          onPressed: () async {},
          // margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            children: [
              SizedBox(
                width: 20,
              ),
              folder['encryption'] == null || folder['encryption'] == 0
                  ? FileIcon(
                      FileTypeEnum.folder,
                    )
                  : Image.asset(
                      "assets/icons/folder_locked.png",
                      width: 40,
                      height: 40,
                    ),
              SizedBox(
                width: 10,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      folder['name'],
                      style: TextStyle(
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(
                      height: 5,
                    ),
                    Text(
                      "${folder['volume_name']}${folder['volume_desc'] != "" ? "(${folder['volume_desc']})" : ""}",
                      style: TextStyle(
                          fontSize: 12,
                          color:
                              Theme.of(context).textTheme.headlineSmall?.color),
                    ),
                    if (folder['unite_permission'] != null) ...[
                      SizedBox(
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
                      SizedBox(
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
                      SizedBox(
                        height: 5,
                      ),
                      Text(
                        "共享文件夹配额：${folder['quota_value'] > 0 ? Util.formatSize(folder['quota_value'] * 1024 * 1024) : "已停用"}",
                        style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.color),
                      ),
                    ],
                    if (folder['share_quota_used'] != null) ...[
                      SizedBox(
                        height: 5,
                      ),
                      Text(
                        "共享文件夹大小：${Util.formatSize(folder['share_quota_used'] * 1024 * 1024)}",
                        style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.color),
                      ),
                    ],
                    if (folder['enable_share_compress'] != null) ...[
                      SizedBox(
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
                      SizedBox(
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
              SizedBox(
                width: 10,
              ),
              folder['is_share_moving']
                  ? Text("移动中")
                  : OutlinedButton(
                      onPressed: () {
                        showCupertinoModalPopup(
                          context: context,
                          builder: (context) {
                            return Material(
                              color: Colors.transparent,
                              child: Card(
                                child: SafeArea(
                                  top: false,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: <Widget>[
                                      Text(
                                        "选择操作",
                                        style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w500),
                                      ),
                                      SizedBox(
                                        height: 12,
                                      ),
                                      if (folder['support_snapshot']) ...[
                                        OutlinedButton(
                                          onPressed: () async {
                                            Navigator.of(context).pop();
                                          },
                                          child: Text(
                                            "克隆",
                                            style: TextStyle(fontSize: 18),
                                          ),
                                        ),
                                        SizedBox(
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
                                                        volumes,
                                                        folder: folder);
                                                  },
                                                  settings: RouteSettings(
                                                      name:
                                                          "add_shared_folders")))
                                              .then((res) {
                                            if (res != null && res) {
                                              getData();
                                            }
                                          });
                                        },
                                        child: Text(
                                          "编辑",
                                          style: TextStyle(fontSize: 18),
                                        ),
                                      ),
                                      SizedBox(
                                        height: 16,
                                      ),
                                      if (folder['enable_recycle_bin']) ...[
                                        OutlinedButton(
                                          onPressed: () async {
                                            Navigator.of(context).pop();
                                            Api.cleanRecycleBin(folder['name'])
                                                .then((res) {
                                              if (res['success']) {
                                                Util.toast("请求已发送");
                                              }
                                            });
                                          },
                                          child: Text(
                                            "清空回收站",
                                            style: TextStyle(fontSize: 18),
                                          ),
                                        ),
                                        SizedBox(
                                          height: 16,
                                        ),
                                      ],
                                      OutlinedButton(
                                        onPressed: () async {
                                          Navigator.of(context).pop();
                                          deleteFolder(folder['name']);
                                        },
                                        child: Text(
                                          "删除",
                                          style: TextStyle(
                                              fontSize: 18,
                                              color: Colors.redAccent),
                                        ),
                                      ),
                                      SizedBox(
                                        height: 8,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                      child: Icon(
                        CupertinoIcons.right_chevron,
                        size: 18,
                      ),
                    ),
              SizedBox(
                width: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: AppBackButton(context),
        title: Text(
          "共享文件夹",
        ),
        actions: volumes.length > 0
            ? [
                Padding(
                  padding: EdgeInsets.only(right: 10, top: 8, bottom: 8),
                  child: OutlinedButton(
                    onPressed: () async {
                      Navigator.of(context)
                          .push(CupertinoPageRoute(
                              builder: (context) {
                                return AddSharedFolders(volumes);
                              },
                              settings:
                                  RouteSettings(name: "add_shared_folders")))
                          .then((res) {
                        if (res != null && res) {
                          getData();
                        }
                      });
                    },
                    child: Icon(Icons.add),
                  ),
                )
              ]
            : null,
      ),
      body: success
          ? Stack(
              children: [
                ListView.builder(
                  padding: EdgeInsets.only(bottom: 20),
                  itemBuilder: (context, i) {
                    return _buildFolderItem(folders[i]);
                  },
                  itemCount: folders.length,
                ),
                // if (selectedFiles.length > 0)
                if (loading)
                  Container(
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.height,
                    color: Theme.of(context)
                        .scaffoldBackgroundColor
                        .withOpacity(0.7),
                    child: Center(
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
                  Text("$msg"),
                  SizedBox(
                    height: 20,
                  ),
                  SizedBox(
                    width: 200,
                    child: OutlinedButton(
                      onPressed: () {
                        getData();
                      },
                      child: Text(
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
