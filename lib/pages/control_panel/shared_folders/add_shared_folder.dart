import 'dart:math';
import 'package:garden/util/log.dart';
import 'package:garden/util/ui_util.dart';

import 'package:garden/util/http_util.dart';
import 'package:garden/widgets/neu_back_button.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:garden/constants/app_constants.dart';
import 'package:garden/theme/app_colors.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:signals_hooks/signals_hooks.dart';

class AddSharedFolders extends HookWidget {
  final List volumes;
  final Map? folder;
  const AddSharedFolders(this.volumes, {super.key, this.folder});

  @override
  Widget build(BuildContext context) {
    final volumeController = useTextEditingController(
      text:
          "${volumes[0]['display_name']}(可用容量：${int.parse(volumes[0]['size_free_byte']).formatSize()}) - ${volumes[0]['fs_type']}",
    );
    final nameController = useTextEditingController();
    final descController = useTextEditingController();
    final passwordController = useTextEditingController();
    final confirmPasswordController = useTextEditingController();
    final shareQuotaController = useTextEditingController();
    const units = ['TB', 'GB', 'MB'];
    final selectedUnitIndex = useSignal(1);
    final unitController = useTextEditingController(text: units[1]);
    final creating = useSignal(false);
    final oldName = useSignal('');
    final name = useSignal('');
    final desc = useSignal('');
    final selectedVolumeIndex = useSignal(0);
    final hidden = useSignal(false);
    final hideUnreadable = useSignal(false);
    final recycleBin = useSignal(false);
    final recycleBinAdminOnly = useSignal(false);
    final enableShareCow = useSignal(false);
    final enableShareCompress = useSignal(false);
    final encryption = useSignal(false);
    final password = useSignal('');
    final confirmPassword = useSignal('');
    final enableShareQuota = useSignal(false);
    final shareQuotaUsed = useSignal<num>(0);
    final shareQuota = useSignal('');
    final loading = useSignal(false);

    getFolderDetail(String folderName) async {
      loading.value = true;
      var res = await DsmApi.shareDetail(folderName);
      if (res['success']) {
        var folder = res['data'];
        nameController.text = name.value = oldName.value = folder['name'];
        descController.text = desc.value = folder['desc'];
        hidden.value = folder['hidden'];
        hideUnreadable.value = folder['hide_unreadable'];
        recycleBin.value = folder['enable_recycle_bin'];
        recycleBinAdminOnly.value = folder['recycle_bin_admin_only'];
        encryption.value = folder['encryption'] == 1;
        if (folder['quota_value'] > 0) {
          enableShareQuota.value = true;
          if (folder['quota_value'] < 1024) {
            selectedUnitIndex.value = 2;
            shareQuota.value = "${folder['quota_value']}";
          } else if (folder['quota_value'] < 1024 * 1024) {
            selectedUnitIndex.value = 1;
            shareQuota.value = "${folder['quota_value'] ~/ 1024}";
          } else {
            selectedUnitIndex.value = 0;
            shareQuota.value = "${folder['quota_value'] ~/ (1024 * 1024)}";
          }
          unitController.value =
              TextEditingValue(text: units[selectedUnitIndex.value]);
          shareQuotaController.text = shareQuota.value;
        }
        enableShareCow.value = folder['enable_share_cow'];
        enableShareCompress.value = folder['enable_share_compress'];
        shareQuotaUsed.value = folder['share_quota_used'];
        for (var i = 0; i < volumes.length; i++) {
          if (volumes[i]['volume_path'] == folder['vol_path']) {
            selectedVolumeIndex.value = i;
            volumeController.value = TextEditingValue(
                text:
                    "${volumes[selectedVolumeIndex.value]['display_name']}(可用容量：${int.parse(volumes[selectedVolumeIndex.value]['size_free_byte']).formatSize()}) - ${volumes[selectedVolumeIndex.value]['fs_type']}");
            break;
          }
        }
        loading.value = false;
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

    save() async {
      FocusScope.of(context).unfocus();
      Log.info(name.value);
      if (name.value.trim() == "") {
        UiUtil.toast("请输入共享文件夹名称");
        return;
      }
      if (encryption.value) {
        if (password.value.length < 8) {
          UiUtil.toast("加密密钥最短为8位");
          return;
        }
        if (password.value != confirmPassword.value) {
          UiUtil.toast("加密密钥和确认密钥不一致");
          return;
        }
      }
      if (enableShareQuota.value) {
        if (shareQuotaController.text.trim() == "") {
          UiUtil.toast("请输入共享文件夹配额");
          return;
        }
        try {
          shareQuota.value =
              "${int.parse(shareQuotaController.text) * pow(1024, 2 - selectedUnitIndex.value)}";
        } catch (e) {
          UiUtil.toast("共享文件夹配额仅支持输入整数");
          return;
        }
      }
      creating.value = true;
      var res = await DsmApi.addSharedFolder(
        name.value,
        volumes[1]['volume_path'],
        desc.value,
        oldName: oldName.value,
        encryption: encryption.value,
        password: password.value,
        recycleBin: recycleBin.value,
        recycleBinAdminOnly: recycleBinAdminOnly.value,
        hidden: hidden.value,
        hideUnreadable: hideUnreadable.value,
        enableShareCow: enableShareCow.value,
        enableShareQuota: enableShareQuota.value,
        enableShareCompress: enableShareCompress.value,
        shareQuota: shareQuota.value,
        method: folder != null ? 'set' : 'create',
      );
      creating.value = false;
      Log.info(res);
      if (res['success']) {
        UiUtil.toast("${folder != null ? '修改' : '新增'}共享文件夹成功");
        if (context.mounted) {
          // ignore: use_build_context_synchronously
          Navigator.of(context).pop(true);
        }
      }
    }

    useEffect(() {
      if (folder != null) {
        getFolderDetail(folder?['name']);
      }
      return null;
    }, const []);

    return Scaffold(
      appBar: AppBar(
        leading: AppBackButton(context),
        title: Text(
          "${folder != null ? '修改' : '新增'}共享文件夹",
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
                        onChanged: (v) => name.value = v,
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
                        onChanged: (v) => desc.value = v,
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
                                      ...volumes.map((volume) {
                                        return Padding(
                                          padding:
                                              const EdgeInsets.only(bottom: 20),
                                          child: OutlinedButton(
                                            onPressed: () {
                                              selectedVolumeIndex.value = volumes
                                                  .indexOf(volume);
                                              volumeController.value =
                                                  TextEditingValue(
                                                      text:
                                                          "${volumes[selectedVolumeIndex.value]['display_name']}(可用容量：${int.parse(volumes[selectedVolumeIndex.value]['size_free_byte']).formatSize()}) - ${volumes[selectedVolumeIndex.value]['fs_type']}");
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
                                                      "${volume['display_name']}(可用容量：${int.parse(volume['size_free_byte']).formatSize()}) - ${volume['fs_type']}"),
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
                      hidden.value = !hidden.value;
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
                            if (hidden.value)
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
                      hideUnreadable.value = !hideUnreadable.value;
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
                            if (hideUnreadable.value)
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
                            recycleBin.value = !recycleBin.value;
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
                                  if (recycleBin.value)
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
                            if (recycleBin.value) {
                              recycleBinAdminOnly.value = !recycleBinAdminOnly.value;
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
                                  if (recycleBinAdminOnly.value)
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
                      encryption.value = !encryption.value;
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
                            if (encryption.value)
                              const Icon(
                                CupertinoIcons.checkmark_alt,
                                color: AppColors.primaryAction,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (encryption.value) ...[
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
                                onChanged: (v) => password.value = v,
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
                                onChanged: (v) => confirmPassword.value = v,
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
                      if (volumes[selectedVolumeIndex.value]['fs_type'] ==
                          "btrfs") {
                        enableShareCow.value = !enableShareCow.value;
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
                            if (enableShareCow.value)
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
                      if (volumes[selectedVolumeIndex.value]['fs_type'] ==
                          "btrfs") {
                        enableShareCompress.value = !enableShareCompress.value;
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
                            if (enableShareCompress.value)
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
                      if (volumes[selectedVolumeIndex.value]['fs_type'] ==
                          "btrfs") {
                        enableShareQuota.value = !enableShareQuota.value;
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
                              "(已使用${(shareQuotaUsed.value * 1024 * 1024).toInt().formatSize()})",
                              style: const TextStyle(color: Colors.blue),
                            ),
                            const Spacer(),
                            if (enableShareQuota.value)
                              const Icon(
                                CupertinoIcons.checkmark_alt,
                                color: AppColors.primaryAction,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (enableShareQuota.value) ...[
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
                                onChanged: (v) => shareQuota.value = v,
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
                                                      selectedUnitIndex.value =
                                                          units.indexOf(unit);
                                                      unitController.value =
                                                          TextEditingValue(
                                                              text: units[
                                                                  selectedUnitIndex.value]);
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
                  onPressed: save,
                  child: creating.value
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
