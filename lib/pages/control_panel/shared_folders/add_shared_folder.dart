import 'dart:math';
import 'package:garden/util/format_util.dart';
import 'package:garden/util/log.dart';
import 'package:garden/util/ui_util.dart';

import 'package:garden/util/http_util.dart';
import 'package:garden/widgets/neu_back_button.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:garden/constants/app_constants.dart';
import 'package:garden/theme/app_colors.dart';
import 'package:flutter/services.dart';

class AddSharedFolders extends StatefulWidget {
  final List volumes;
  final Map? folder;
  const AddSharedFolders(this.volumes, {super.key, this.folder});
  @override
  AddSharedFoldersState createState() => AddSharedFoldersState();
}

class AddSharedFoldersState extends State<AddSharedFolders> {
  TextEditingController volumeController = TextEditingController();
  TextEditingController nameController = TextEditingController();
  TextEditingController descController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController confirmPasswordController = TextEditingController();
  TextEditingController shareQuotaController = TextEditingController();
  List<String> units = ["TB", "GB", "MB"];
  int selectedUnitIndex = 1;
  TextEditingController unitController = TextEditingController();
  bool creating = false;
  String oldName = '';
  String name = "";
  String desc = "";
  int selectedVolumeIndex = 0;
  bool hidden = false;
  bool hideUnreadable = false;
  bool recycleBin = false;
  bool recycleBinAdminOnly = false;
  bool enableShareCow = false;
  bool enableShareCompress = false;
  bool encryption = false;
  String password = "";
  String confirmPassword = "";
  bool enableShareQuota = false;
  num shareQuotaUsed = 0;
  String shareQuota = "";
  bool loading = false;
  @override
  void initState() {
    if (widget.folder != null) {
      getFolderDetail(widget.folder?['name']);
    }

    volumeController.text =
        "${widget.volumes[selectedVolumeIndex]['display_name']}(可用容量：${FormatUtil.formatSize(int.parse(widget.volumes[selectedVolumeIndex]['size_free_byte']))}) - ${widget.volumes[selectedVolumeIndex]['fs_type']}";
    unitController.text = units[selectedUnitIndex];
    super.initState();
  }

  getFolderDetail(String folderName) async {
    setState(() {
      loading = true;
    });
    var res = await Api.shareDetail(folderName);
    if (res['success']) {
      var folder = res['data'];
      nameController.text = name = oldName = folder['name'];
      descController.text = desc = folder['desc'];
      hidden = folder['hidden'];
      hideUnreadable = folder['hide_unreadable'];

      recycleBin = folder['enable_recycle_bin'];
      recycleBinAdminOnly = folder['recycle_bin_admin_only'];
      encryption = folder['encryption'] == 1;
      if (folder['quota_value'] > 0) {
        enableShareQuota = true;
        if (folder['quota_value'] < 1024) {
          selectedUnitIndex = 2;
          shareQuota = "${folder['quota_value']}";
        } else if (folder['quota_value'] < 1024 * 1024) {
          selectedUnitIndex = 1;
          shareQuota = "${folder['quota_value'] ~/ 1024}";
        } else {
          selectedUnitIndex = 0;
          shareQuota = "${folder['quota_value'] ~/ (1024 * 1024)}";
        }
        unitController.text = units[selectedUnitIndex];
        shareQuotaController.text = shareQuota;
      }

      enableShareCow = folder['enable_share_cow'];
      enableShareCompress = folder['enable_share_compress'];

      shareQuotaUsed = folder['share_quota_used'];

      for (var i = 0; i < widget.volumes.length; i++) {
        if (widget.volumes[i]['volume_path'] == folder['vol_path']) {
          selectedVolumeIndex = i;
          volumeController.text =
              "${widget.volumes[selectedVolumeIndex]['display_name']}(可用容量：${FormatUtil.formatSize(int.parse(widget.volumes[selectedVolumeIndex]['size_free_byte']))}) - ${widget.volumes[selectedVolumeIndex]['fs_type']}";
          break;
        }
      }

      setState(() {
        loading = false;
      });
    } else {
      if (res['error']['code'] == 402) {
        UiUtil.toast("此共享文件夹不存在");
      } else {
        UiUtil.toast("加载失败，code: ${res['error']['code']}");
      }

      if (context.mounted) {
        // ignore: use_build_context_synchronously
        Navigator.of(context).pop();
      }
    }
  }

  _save() async {
    FocusScope.of(context).unfocus();
    Log.info(name);
    if (name.trim() == "") {
      UiUtil.toast("请输入共享文件夹名称");
      return;
    }
    if (encryption) {
      if (password.length < 8) {
        UiUtil.toast("加密密钥最短为8位");
        return;
      }
      if (password != confirmPassword) {
        UiUtil.toast("加密密钥和确认密钥不一致");
        return;
      }
    }
    if (enableShareQuota) {
      if (shareQuotaController.text.trim() == "") {
        UiUtil.toast("请输入共享文件夹配额");
        return;
      }
      try {
        shareQuota =
            "${int.parse(shareQuotaController.text) * pow(1024, 2 - selectedUnitIndex)}";
      } catch (e) {
        UiUtil.toast("共享文件夹配额仅支持输入整数");
        return;
      }
    }
    setState(() {
      creating = true;
    });

    var res = await Api.addSharedFolder(
      name,
      widget.volumes[1]['volume_path'],
      desc,
      oldName: oldName,
      encryption: encryption,
      password: password,
      recycleBin: recycleBin,
      recycleBinAdminOnly: recycleBinAdminOnly,
      hidden: hidden,
      hideUnreadable: hideUnreadable,
      enableShareCow: enableShareCow,
      enableShareQuota: enableShareQuota,
      enableShareCompress: enableShareCompress,
      shareQuota: shareQuota,
      method: widget.folder != null ? 'set' : 'create',
    );

    setState(() {
      creating = false;
    });
    Log.info(res);
    if (res['success']) {
      UiUtil.toast("${widget.folder != null ? '修改' : '新增'}共享文件夹成功");
      if (context.mounted) {
        // ignore: use_build_context_synchronously
        Navigator.of(context).pop(true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: AppBackButton(context),
        title: Text(
          "${widget.folder != null ? '修改' : '新增'}共享文件夹",
        ),
      ),
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: <Widget>[
                  const SizedBox(
                    height: 20,
                  ),
                  Card(
                    shape: RoundedRectangleBorder(
                        side: const BorderSide(),
                        borderRadius: BorderRadius.circular(18)),
                    child: Padding(
                      padding: const EdgeInsets.all(AppConstants.paddingSmall),
                      child: TextField(
                        controller: nameController,
                        onChanged: (v) => name = v,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          labelText: '名称',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  Card(
                    shape: RoundedRectangleBorder(
                        side: const BorderSide(),
                        borderRadius: BorderRadius.circular(18)),
                    child: Padding(
                      padding: const EdgeInsets.all(AppConstants.paddingSmall),
                      child: TextField(
                        controller: descController,
                        onChanged: (v) => desc = v,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          labelText: '描述',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  GestureDetector(
                    onTap: () {
                      FocusScope.of(context).unfocus();
                      showCupertinoModalPopup(
                        context: context,
                        builder: (context) {
                          return Material(
                            color: Colors.transparent,
                            child: Card(
                              shape: RoundedRectangleBorder(
                                  side: const BorderSide(),
                                  borderRadius: BorderRadius.circular(18)),
                              child: SafeArea(
                                top: false,
                                child: Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: <Widget>[
                                      const Text(
                                        "选择所在位置",
                                        style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w500),
                                      ),
                                      const SizedBox(
                                        height: 12,
                                      ),
                                      ...widget.volumes.map((volume) {
                                        return Padding(
                                          padding:
                                              const EdgeInsets.only(bottom: 20),
                                          child: OutlinedButton(
                                            onPressed: () {
                                              setState(() {
                                                selectedVolumeIndex = widget
                                                    .volumes
                                                    .indexOf(volume);
                                              });
                                              volumeController.value =
                                                  TextEditingValue(
                                                      text:
                                                          "${widget.volumes[selectedVolumeIndex]['display_name']}(可用容量：${FormatUtil.formatSize(int.parse(widget.volumes[selectedVolumeIndex]['size_free_byte']))}) - ${widget.volumes[selectedVolumeIndex]['fs_type']}");
                                              Navigator.of(context).pop();
                                            },
                                            child: Container(
                                              padding: const EdgeInsets.only(
                                                  left: 20),
                                              width: double.infinity,
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                      "${volume['display_name']}(可用容量：${FormatUtil.formatSize(int.parse(volume['size_free_byte']))}) - ${volume['fs_type']}"),
                                                  const SizedBox(
                                                    height: 5,
                                                  ),
                                                  Text(
                                                    "${volume['description']}",
                                                    style: const TextStyle(
                                                        color: Colors.grey),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        );
                                      }),
                                      OutlinedButton(
                                        onPressed: () async {
                                          Navigator.of(context).pop();
                                        },
                                        child: const Text(
                                          "取消",
                                          style: TextStyle(fontSize: 18),
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
                    child: Card(
                      shape: RoundedRectangleBorder(
                          side: const BorderSide(),
                          borderRadius: BorderRadius.circular(18)),
                      child: Padding(
                        padding:
                            const EdgeInsets.all(AppConstants.paddingSmall),
                        child: TextField(
                          controller: volumeController,
                          decoration: const InputDecoration(
                            enabled: false,
                            border: InputBorder.none,
                            labelText: "所在位置",
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  GestureDetector(
                    onTap: () {
                      FocusScope.of(context).unfocus();
                      setState(() {
                        hidden = !hidden;
                      });
                    },
                    child: Card(
                      shape: RoundedRectangleBorder(
                          side: const BorderSide(),
                          borderRadius: BorderRadius.circular(18)),
                      child: Padding(
                        padding:
                            const EdgeInsets.all(AppConstants.paddingSmall),
                        child: Row(
                          children: [
                            const Text("在“网上邻居”隐藏此共享文件夹"),
                            const Spacer(),
                            if (hidden)
                              const Icon(
                                CupertinoIcons.checkmark_alt,
                                color: AppColors.primaryAction,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  GestureDetector(
                    onTap: () {
                      FocusScope.of(context).unfocus();
                      setState(() {
                        hideUnreadable = !hideUnreadable;
                      });
                    },
                    child: Card(
                      shape: RoundedRectangleBorder(
                          side: const BorderSide(),
                          borderRadius: BorderRadius.circular(18)),
                      child: Padding(
                        padding:
                            const EdgeInsets.all(AppConstants.paddingSmall),
                        child: Row(
                          children: [
                            const Text("对没有权限的用户隐藏子文件夹和文件"),
                            const Spacer(),
                            if (hideUnreadable)
                              const Icon(
                                CupertinoIcons.checkmark_alt,
                                color: AppColors.primaryAction,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: GestureDetector(
                          onTap: () {
                            FocusScope.of(context).unfocus();
                            setState(() {
                              recycleBin = !recycleBin;
                            });
                          },
                          child: Card(
                            shape: RoundedRectangleBorder(
                                side: const BorderSide(),
                                borderRadius: BorderRadius.circular(18)),
                            child: Padding(
                              padding: const EdgeInsets.all(
                                  AppConstants.paddingSmall),
                              child: Row(
                                children: [
                                  const Expanded(
                                    child: Text(
                                      "启用回收站",
                                      overflow: TextOverflow.clip,
                                      maxLines: 1,
                                    ),
                                  ),
                                  if (recycleBin)
                                    const Icon(
                                      CupertinoIcons.checkmark_alt,
                                      color: AppColors.primaryAction,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(
                        width: 20,
                      ),
                      Expanded(
                        flex: 4,
                        child: GestureDetector(
                          onTap: () {
                            FocusScope.of(context).unfocus();
                            if (recycleBin) {
                              setState(() {
                                recycleBinAdminOnly = !recycleBinAdminOnly;
                              });
                            }
                          },
                          child: Card(
                            shape: RoundedRectangleBorder(
                                side: const BorderSide(),
                                borderRadius: BorderRadius.circular(18)),
                            child: Padding(
                              padding: const EdgeInsets.all(
                                  AppConstants.paddingSmall),
                              child: Row(
                                children: [
                                  const Expanded(
                                    child: Text(
                                      "只允许管理员访问",
                                      overflow: TextOverflow.clip,
                                      maxLines: 1,
                                    ),
                                  ),
                                  if (recycleBinAdminOnly)
                                    const Icon(
                                      CupertinoIcons.checkmark_alt,
                                      color: AppColors.primaryAction,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  GestureDetector(
                    onTap: () {
                      FocusScope.of(context).unfocus();
                      setState(() {
                        encryption = !encryption;
                      });
                    },
                    child: Card(
                      shape: RoundedRectangleBorder(
                          side: const BorderSide(),
                          borderRadius: BorderRadius.circular(18)),
                      child: Padding(
                        padding:
                            const EdgeInsets.all(AppConstants.paddingSmall),
                        child: Row(
                          children: [
                            const Text("加密共享此文件夹"),
                            const Spacer(),
                            if (encryption)
                              const Icon(
                                CupertinoIcons.checkmark_alt,
                                color: AppColors.primaryAction,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (encryption) ...[
                    const SizedBox(
                      height: 20,
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Card(
                            shape: RoundedRectangleBorder(
                                side: const BorderSide(),
                                borderRadius: BorderRadius.circular(18)),
                            child: Padding(
                              padding: const EdgeInsets.all(
                                  AppConstants.paddingSmall),
                              child: TextField(
                                onChanged: (v) => password = v,
                                obscureText: true,
                                controller: passwordController,
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  labelText: '加密密钥',
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(
                          width: 20,
                        ),
                        Expanded(
                          child: Card(
                            shape: RoundedRectangleBorder(
                                side: const BorderSide(),
                                borderRadius: BorderRadius.circular(18)),
                            child: Padding(
                              padding: const EdgeInsets.all(
                                  AppConstants.paddingSmall),
                              child: TextField(
                                onChanged: (v) => confirmPassword = v,
                                obscureText: true,
                                controller: confirmPasswordController,
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  labelText: '确认密钥',
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  ],
                  const SizedBox(
                    height: 20,
                  ),
                  GestureDetector(
                    onTap: () {
                      FocusScope.of(context).unfocus();
                      if (widget.volumes[selectedVolumeIndex]['fs_type'] ==
                          "btrfs") {
                        setState(() {
                          enableShareCow = !enableShareCow;
                        });
                      }
                    },
                    child: Card(
                      shape: RoundedRectangleBorder(
                          side: const BorderSide(),
                          borderRadius: BorderRadius.circular(18)),
                      child: Padding(
                        padding:
                            const EdgeInsets.all(AppConstants.paddingSmall),
                        child: Row(
                          children: [
                            const Text("启用数据总和检查码以实现高级数据完整性"),
                            const Spacer(),
                            if (enableShareCow)
                              const Icon(
                                CupertinoIcons.checkmark_alt,
                                color: AppColors.primaryAction,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  GestureDetector(
                    onTap: () {
                      FocusScope.of(context).unfocus();
                      if (widget.volumes[selectedVolumeIndex]['fs_type'] ==
                          "btrfs") {
                        setState(() {
                          enableShareCompress = !enableShareCompress;
                        });
                      }
                    },
                    child: Card(
                      shape: RoundedRectangleBorder(
                          side: const BorderSide(),
                          borderRadius: BorderRadius.circular(18)),
                      child: Padding(
                        padding:
                            const EdgeInsets.all(AppConstants.paddingSmall),
                        child: Row(
                          children: [
                            const Text("启用文件压缩"),
                            const Spacer(),
                            if (enableShareCompress)
                              const Icon(
                                CupertinoIcons.checkmark_alt,
                                color: AppColors.primaryAction,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  GestureDetector(
                    onTap: () {
                      FocusScope.of(context).unfocus();
                      if (widget.volumes[selectedVolumeIndex]['fs_type'] ==
                          "btrfs") {
                        setState(() {
                          enableShareQuota = !enableShareQuota;
                        });
                      }
                    },
                    child: Card(
                      shape: RoundedRectangleBorder(
                          side: const BorderSide(),
                          borderRadius: BorderRadius.circular(18)),
                      child: Padding(
                        padding:
                            const EdgeInsets.all(AppConstants.paddingSmall),
                        child: Row(
                          children: [
                            const Text("启用共享文件夹配额"),
                            Text(
                              "(已使用${FormatUtil.formatSize((shareQuotaUsed * 1024 * 1024).toInt())})",
                              style: const TextStyle(color: Colors.blue),
                            ),
                            const Spacer(),
                            if (enableShareQuota)
                              const Icon(
                                CupertinoIcons.checkmark_alt,
                                color: AppColors.primaryAction,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (enableShareQuota) ...[
                    const SizedBox(
                      height: 20,
                    ),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Card(
                            shape: RoundedRectangleBorder(
                                side: const BorderSide(),
                                borderRadius: BorderRadius.circular(18)),
                            child: Padding(
                              padding: const EdgeInsets.all(
                                  AppConstants.paddingSmall),
                              child: TextField(
                                onChanged: (v) => shareQuota = v,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                controller: shareQuotaController,
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  labelText: '共享文件夹配额',
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(
                          width: 20,
                        ),
                        Expanded(
                          flex: 1,
                          child: GestureDetector(
                            onTap: () {
                              FocusScope.of(context).unfocus();
                              showCupertinoModalPopup(
                                context: context,
                                builder: (context) {
                                  return Material(
                                    color: Colors.transparent,
                                    child: Card(
                                      shape: RoundedRectangleBorder(
                                          side: const BorderSide(),
                                          borderRadius:
                                              BorderRadius.circular(5)),
                                      child: SafeArea(
                                        top: false,
                                        child: Padding(
                                          padding: const EdgeInsets.all(20),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: <Widget>[
                                              const Text(
                                                "选择单位",
                                                style: TextStyle(
                                                    fontSize: 20,
                                                    fontWeight:
                                                        FontWeight.w500),
                                              ),
                                              const SizedBox(
                                                height: 12,
                                              ),
                                              ...units.map((unit) {
                                                return Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          bottom: 20),
                                                  child: OutlinedButton(
                                                    onPressed: () {
                                                      setState(() {
                                                        selectedUnitIndex =
                                                            units.indexOf(unit);
                                                      });
                                                      unitController.value =
                                                          TextEditingValue(
                                                              text: units[
                                                                  selectedUnitIndex]);
                                                      Navigator.of(context)
                                                          .pop();
                                                    },
                                                    child: SizedBox(
                                                      width: double.infinity,
                                                      child: Text(
                                                        unit,
                                                        textAlign:
                                                            TextAlign.center,
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              }),
                                              OutlinedButton(
                                                onPressed: () async {
                                                  Navigator.of(context).pop();
                                                },
                                                child: const Text(
                                                  "取消",
                                                  style:
                                                      TextStyle(fontSize: 18),
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
                            child: Card(
                              shape: RoundedRectangleBorder(
                                  side: const BorderSide(),
                                  borderRadius: BorderRadius.circular(18)),
                              child: Padding(
                                padding: const EdgeInsets.all(
                                    AppConstants.paddingSmall),
                                child: TextField(
                                  controller: unitController,
                                  decoration: const InputDecoration(
                                    enabled: false,
                                    border: InputBorder.none,
                                    labelText: "单位",
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  ],
                ],
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: OutlinedButton(
                  onPressed: _save,
                  child: creating
                      ? const Center(
                          child: CupertinoActivityIndicator(
                            radius: 13,
                          ),
                        )
                      : const Text(
                          ' 保存 ',
                          style: TextStyle(fontSize: 18),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
