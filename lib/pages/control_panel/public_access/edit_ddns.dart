// ignore_for_file: unused_import

import 'package:cool_ui/cool_ui.dart';
import 'package:garden/util/log.dart';
import 'package:garden/util/ui_util.dart';
import 'dart:convert';
import 'package:garden/api/dsm_api.dart';
import 'package:garden/widgets/neu_picker.dart';
import 'package:garden/widgets/label.dart';
import 'package:garden/widgets/neu_back_button.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:garden/constants/app_constants.dart';
import 'package:garden/theme/app_colors.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:signals_hooks/signals_hooks.dart';

class EditDdns extends HookWidget {
  final Map? ddns;
  final List extIp;
  final List providers;
  const EditDdns(this.providers, {super.key, this.extIp = const [], this.ddns});

  @override
  Widget build(BuildContext context) {
    final hostnameController = useTextEditingController();
    final usernameController = useTextEditingController();
    final ddnsInfo = useSignal<Map>({});
    final Map statusStr = {
      "service_ddns_normal": "正常",
      "service_ddns_error_unknown": "联机失败",
      "loading": "加载中",
      "disabled": "已停用",
    };

    // The ddns entry is edited in place; every change writes a new map so the
    // signal notifies and the page rebuilds (the old code used setState).
    void updateDdns(Map changes) {
      ddnsInfo.value = {...ddnsInfo.value, ...changes};
    }

    useEffect(() {
      if (ddns != null) {
        ddnsInfo.value = {...ddns!};
      }
      hostnameController.value =
          TextEditingValue(text: ddnsInfo.value['hostname']);
      usernameController.value =
          TextEditingValue(text: ddnsInfo.value['username']);
      if (ddnsInfo.value['ip'] == "0.0.0.0") {
        ddnsInfo.value["ip"] = "-";
      }
      if (ddnsInfo.value['ipv6'] == "0:0:0:0:0:0:0:0") {
        ddnsInfo.value['ipv6'] = "-";
      }
      return null;
    }, const []);

    deleteDdns() async {
    UiUtil.vibrate(FeedbackType.warning);
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
                padding: const EdgeInsets.all(AppConstants.paddingSmall),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const Text(
                      "确认删除",
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(
                      height: 12,
                    ),
                    const Text(
                      "确认要删除以下DDNS？",
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.w400),
                    ),
                    const SizedBox(
                      height: 22,
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () async {
                              if (ddns == null) {
                                UiUtil.toast('ddns 为空!');
                                return;
                              }
                              Navigator.of(context).pop();
                              try {
                                await dsmControlPanelPost({
                                  "id": jsonEncode([ddns!['id']]),
                                  "api": 'SYNO.Core.DDNS.Record',
                                  "method": 'delete',
                                  "version": 1,
                                });
                                UiUtil.toast("DDNS删除成功");
                                if (context.mounted) {
                                  Navigator.of(context).pop(true);
                                }
                              } catch (e) {
                                final code = e is DSMException ? e.code : -1;
                                UiUtil.toast("删除失败，代码:$code");
                              }
                            },
                            child: const Text(
                              "确认删除",
                              style: TextStyle(
                                  fontSize: 18, color: Colors.redAccent),
                            ),
                          ),
                        ),
                        const SizedBox(
                          width: 20,
                        ),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () async {
                              Navigator.of(context).pop();
                            },
                            child: const Text(
                              "取消",
                              style: TextStyle(fontSize: 18),
                            ),
                          ),
                        ),
                      ],
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
  }

  bool checkForm() {
    if (ddnsInfo.value['provider'] == null ||
        ddnsInfo.value['provider'] == "") {
      UiUtil.toast("请选择服务供应商");
      return false;
    } else if (ddnsInfo.value['hostname'] == null ||
        ddnsInfo.value['hostname'] == "") {
      UiUtil.toast("请输入主机名称");
      return false;
    } else if (ddnsInfo.value['username'] == null ||
        ddnsInfo.value['username'] == "") {
      UiUtil.toast("请输入用户名/电子邮件");
      return false;
    } else if (ddns == null &&
        (ddnsInfo.value['passwd'] == null ||
            ddnsInfo.value['passwd'] == "")) {
      UiUtil.toast("请输入密码/密钥");
      return false;
    }

    return true;
  }

    return Scaffold(
      appBar: AppBar(
        leading: AppBackButton(context),
        title: const Text("DDNS"),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10, top: 8, bottom: 8),
            child: OutlinedButton(
              onPressed: deleteDdns,
              child: Image.asset(
                "assets/icons/delete.png",
                width: 30,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                ...[
                  GestureDetector(
                    onTap: () async {
                      updateDdns({'enable': !ddnsInfo.value['enable']});
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
                            const Text("启用支持DDNS"),
                            const Spacer(),
                            if (ddnsInfo.value['enable'])
                              const Icon(
                                CupertinoIcons.checkmark_alt,
                                color: AppColors.primaryAction,
                                size: 22,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                ],
                GestureDetector(
                  onTap: () {
                    FocusScope.of(context).unfocus();
                    return;
                  },
                  child: Card(
                    shape: RoundedRectangleBorder(
                        side: const BorderSide(),
                        borderRadius: BorderRadius.circular(18)),
                    child: Padding(
                      padding: const EdgeInsets.all(AppConstants.paddingSmall),
                      child: Row(
                        children: [
                          const Text("服务供应商"),
                          const Spacer(),
                          Text(
                              "${ddnsInfo.value['provider'] != null && ddnsInfo.value['provider'] != "" ? providers.where((element) => element['provider'] == ddnsInfo.value['provider']).first['provider'] : "请选择"}"),
                        ],
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
                      controller: hostnameController,
                      onChanged: (v) => updateDdns({'hostname': v}),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        labelText: '主机名称',
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
                      controller: usernameController,
                      onChanged: (v) => updateDdns({'username': v}),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        labelText: '用户名/电子邮件',
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
                      onChanged: (v) => updateDdns({'passwd': v}),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        labelText: '密码/密钥',
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
                    child: Row(
                      children: [
                        const Text("外部地址(ipv4):"),
                        const Spacer(),
                        Text("${ddnsInfo.value['ip']}"),
                      ],
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
                    child: Row(
                      children: [
                        const Text("外部地址(ipv6):"),
                        const Spacer(),
                        Text("${ddnsInfo.value['ipv6']}"),
                      ],
                    ),
                  ),
                ),
                //statusStr[ddns['status']] ?? ddns['status']
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
                          padding:
                              const EdgeInsets.all(AppConstants.paddingSmall),
                          child: Row(
                            children: [
                              const Text("状态:"),
                              const SizedBox(
                                width: 10,
                              ),
                              if (ddnsInfo.value['status'] != null)
                                Label(
                                  statusStr[ddnsInfo.value['status']] ??
                                      ddnsInfo.value['status'],
                                  ddnsInfo.value['status'] ==
                                          "service_ddns_normal"
                                      ? Colors.green
                                      : Colors.red,
                                  fill: true,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(
                      width: 20,
                    ),
                    OutlinedButton(
                      onPressed: () async {
                        if (checkForm()) {
                          var hide = showWeuiLoadingToast(
                              context: context,
                              message: const Text("测试中，请稍后"),
                              backButtonClose: true,
                              alignment: Alignment.center);
                          Map<String, dynamic> data;
                          try {
                            final ddns = ddnsInfo.value;
                            final body = <String, dynamic>{
                              "api": 'SYNO.Core.DDNS.Record',
                              "method": 'test',
                              "version": 1,
                              "heartbeat": ddns['heartbeat'],
                              "enable": true,
                              "provider": '"${ddns['provider'].replaceAll("*", "USER_")}"',
                              "hostname": '"${ddns['hostname']}"',
                              "username": '"${ddns['username']}"',
                              "net": '"${ddns['net']}"',
                              "ip": '"${ddns['ip']}"',
                              "ipv6": '"${ddns['ipv6']}"',
                            };
                            if (ddns['passwd'] != null) {
                              body['passwd'] = '"${ddns['passwd']}"';
                            }
                            data = await dsmControlPanelPost(body);
                            Log.info("ddnsTest:$data");
                            updateDdns({'status': data['status']});
                          } catch (e) {
                            final raw = e is DSMException ? e.rawError : null;
                            final code = e is DSMException ? e.code : -1;
                            UiUtil.toast("测试失败，$raw,code:$code");
                          } finally {
                            hide();
                          }
                        }
                      },
                      child: const Text("测试联机"),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: OutlinedButton(
                onPressed: () async {
                  if (checkForm()) {
                    try {
                      final ddns = ddnsInfo.value;
                      final body = <String, dynamic>{
                        "api": 'SYNO.Core.DDNS.Record',
                        "method": 'set',
                        "version": 1,
                        "id": '"${ddns['id'].replaceAll("USER_", "*")}"',
                        "enable": ddns['enable'],
                        "provider": '"${ddns['provider']}"',
                        "hostname": '"${ddns['hostname']}"',
                        "username": '"${ddns['username']}"',
                        "net": '"${ddns['net']}"',
                        "ip": '"${ddns['ip']}"',
                        "ipv6": '"${ddns['ipv6']}"',
                        "heartbeat": ddns['heartbeat'],
                      };
                      if (ddns['passwd'] != null) {
                        body['passwd'] = '"${ddns['passwd']}"';
                      }
                      await dsmControlPanelPost(body);
                      UiUtil.toast("保存成功");
                      if (context.mounted) {
                        Navigator.of(context).pop(true);
                      }
                    } catch (e) {
                      final code = e is DSMException ? e.code : -1;
                      UiUtil.toast("保存失败,代码$code");
                    }
                  }
                },
                child: const Text(
                  ' 保存 ',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
