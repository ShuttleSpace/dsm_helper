import 'dart:math';
import 'package:garden/util/log.dart';
import 'package:garden/widgets/bottom_option_sheet.dart';
import 'package:garden/widgets/settings/settings_toggle_tile.dart';
import 'package:garden/util/ui_util.dart';

import 'package:garden/extensions/int.dart';
import 'package:garden/api/dsm_api.dart';
import 'package:garden/widgets/neu_back_button.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:garden/constants/app_constants.dart';
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
      late Map<String, dynamic> folder;
      try {
        folder = await dsmCoreShareDetailForPage(folderName);
      } catch (e) {
        final code = e is DSMException ? e.code : -1;
        if (code == 402) {
          UiUtil.toast("此共享文件夹不存在");
        } else {
          UiUtil.toast("加载失败，code: $code");
        }
        if (context.mounted) {
          // ignore: use_build_context_synchronously
          Navigator.of(context).pop();
        }
        return;
      } finally {
        loading.value = false;
      }
      nameController.text = name.value = oldName.value = folder['name'] ?? '';
      descController.text = desc.value = folder['desc'] ?? '';
      hidden.value = folder['hidden'] ?? false;
      hideUnreadable.value = folder['hide_unreadable'] ?? false;
      recycleBin.value = folder['enable_recycle_bin'] ?? false;
      recycleBinAdminOnly.value = folder['recycle_bin_admin_only'] ?? false;
      encryption.value = folder['encryption'] == 1;
      if ((folder['quota_value'] ?? 0) > 0) {
        enableShareQuota.value = true;
        final quota = folder['quota_value'] as int;
        if (quota < 1024) {
          selectedUnitIndex.value = 2;
          shareQuota.value = "$quota";
        } else if (quota < 1024 * 1024) {
          selectedUnitIndex.value = 1;
          shareQuota.value = "${quota ~/ 1024}";
        } else {
          selectedUnitIndex.value = 0;
          shareQuota.value = "${quota ~/ (1024 * 1024)}";
        }
        unitController.value =
            TextEditingValue(text: units[selectedUnitIndex.value]);
        shareQuotaController.text = shareQuota.value;
      }
      enableShareCow.value = folder['enable_share_cow'] ?? false;
      enableShareCompress.value = folder['enable_share_compress'] ?? false;
      shareQuotaUsed.value = folder['share_quota_used'] ?? 0;
      for (var i = 0; i < volumes.length; i++) {
        if (volumes[i]['volume_path'] == folder['vol_path']) {
          selectedVolumeIndex.value = i;
          volumeController.value = TextEditingValue(
              text:
                  "${volumes[selectedVolumeIndex.value]['display_name']}(可用容量：${int.parse(volumes[selectedVolumeIndex.value]['size_free_byte']).formatSize()}) - ${volumes[selectedVolumeIndex.value]['fs_type']}");
          break;
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
      try {
        await dsmCoreShareAddForPage(
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
      } catch (e) {
        creating.value = false;
        UiUtil.toast("${folder != null ? '修改' : '新增'}共享文件夹失败");
        return;
      }
      creating.value = false;
      {
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
                        builder: (context) => BottomOptionSheet(
                          title: "选择所在位置",
                          options: [
                            for (final volume in volumes)
                              BottomOption(
                                title:
                                    "${volume['display_name']}(可用容量：${int.parse(volume['size_free_byte']).formatSize()}) - ${volume['fs_type']}",
                                subtitle: "${volume['description']}",
                                onPressed: () {
                                  selectedVolumeIndex.value =
                                      volumes.indexOf(volume);
                                  volumeController.value = TextEditingValue(
                                    text:
                                        "${volumes[selectedVolumeIndex.value]['display_name']}(可用容量：${int.parse(volumes[selectedVolumeIndex.value]['size_free_byte']).formatSize()}) - ${volumes[selectedVolumeIndex.value]['fs_type']}",
                                  );
                                },
                              ),
                          ],
                        ),
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
                  SettingsToggleTile(
                    label: "在“网上邻居”隐藏此共享文件夹",
                    value: hidden.value,
                    shape: RoundedRectangleBorder(
                      side: const BorderSide(),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    onTap: () {
                      FocusScope.of(context).unfocus();
                      hidden.value = !hidden.value;
                    },
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  SettingsToggleTile(
                    label: "对没有权限的用户隐藏子文件夹和文件",
                    value: hideUnreadable.value,
                    shape: RoundedRectangleBorder(
                      side: const BorderSide(),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    onTap: () {
                      FocusScope.of(context).unfocus();
                      hideUnreadable.value = !hideUnreadable.value;
                    },
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: SettingsToggleTile(
                          label: "启用回收站",
                          value: recycleBin.value,
                          shape: RoundedRectangleBorder(
                            side: const BorderSide(),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          onTap: () {
                            FocusScope.of(context).unfocus();
                            recycleBin.value = !recycleBin.value;
                          },
                        ),
                      ),
                      const SizedBox(
                        width: 20,
                      ),
                      Expanded(
                        flex: 4,
                        child: SettingsToggleTile(
                          label: "只允许管理员访问",
                          value: recycleBinAdminOnly.value,
                          shape: RoundedRectangleBorder(
                            side: const BorderSide(),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          onTap: () {
                            FocusScope.of(context).unfocus();
                            if (recycleBin.value) {
                              recycleBinAdminOnly.value =
                                  !recycleBinAdminOnly.value;
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  SettingsToggleTile(
                    label: "加密共享此文件夹",
                    value: encryption.value,
                    shape: RoundedRectangleBorder(
                      side: const BorderSide(),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    onTap: () {
                      FocusScope.of(context).unfocus();
                      encryption.value = !encryption.value;
                    },
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
                  SettingsToggleTile(
                    label: "启用数据总和检查码以实现高级数据完整性",
                    value: enableShareCow.value,
                    shape: RoundedRectangleBorder(
                      side: const BorderSide(),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    onTap: () {
                      FocusScope.of(context).unfocus();
                      if (volumes[selectedVolumeIndex.value]['fs_type'] ==
                          "btrfs") {
                        enableShareCow.value = !enableShareCow.value;
                      }
                    },
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  SettingsToggleTile(
                    label: "启用文件压缩",
                    value: enableShareCompress.value,
                    shape: RoundedRectangleBorder(
                      side: const BorderSide(),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    onTap: () {
                      FocusScope.of(context).unfocus();
                      if (volumes[selectedVolumeIndex.value]['fs_type'] ==
                          "btrfs") {
                        enableShareCompress.value = !enableShareCompress.value;
                      }
                    },
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  SettingsToggleTile(
                    label: "启用共享文件夹配额",
                    value: enableShareQuota.value,
                    shape: RoundedRectangleBorder(
                      side: const BorderSide(),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    onTap: () {
                      FocusScope.of(context).unfocus();
                      if (volumes[selectedVolumeIndex.value]['fs_type'] ==
                          "btrfs") {
                        enableShareQuota.value = !enableShareQuota.value;
                      }
                    },
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
                                builder: (context) => BottomOptionSheet(
                                  title: "选择单位",
                                  borderRadius: 5,
                                  optionTextAlign: TextAlign.center,
                                  options: [
                                    for (final unit in units)
                                      BottomOption(
                                        title: unit,
                                        onPressed: () {
                                          selectedUnitIndex.value =
                                              units.indexOf(unit);
                                          unitController.value =
                                              TextEditingValue(text: unit);
                                        },
                                      ),
                                  ],
                                ),
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
