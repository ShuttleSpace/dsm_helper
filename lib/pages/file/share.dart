import 'package:garden/util/ui_util.dart';
import 'package:garden/util/storage_util.dart';

import 'dart:convert';
import 'package:garden/api/dsm_api.dart';
import 'package:garden/extensions/datetime.dart';
import 'package:garden/widgets/neu_back_button.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:garden/constants/app_constants.dart';
import 'package:garden/theme/app_colors.dart';
import 'package:flutter/services.dart';
import 'package:flutter_datetime_picker/flutter_datetime_picker.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:signals_hooks/signals_hooks.dart';

class Share extends HookWidget {
  final List<String>? paths;
  final Map? link;
  final bool? fileRequest;
  const Share({super.key, this.paths, this.link, this.fileRequest = false});

  @override
  Widget build(BuildContext context) {
    final loading = useSignal(true);
    // Creating a new share starts with an empty link, editing starts from
    // the link that was passed in.
    final initialLink = paths != null ? <String, dynamic>{} : (link ?? {});
    final initialEndTime = initialLink['date_expired'] != ""
        ? DateTime.parse(initialLink['date_expired'])
        : null;
    final initialStartTime = initialLink['date_available'] != ""
        ? DateTime.parse(initialLink['date_available'])
        : null;
    final initialTimes = initialLink['expire_times'] == 0
        ? ""
        : initialLink['expire_times'].toString();
    // Dynamic value: keep the original truthiness test.
    final hasUpload = initialLink['enable_upload'];

    final linkInfo = useSignal<Map>(initialLink);
    final startTime = useSignal<DateTime?>(initialStartTime);
    final endTime = useSignal<DateTime?>(initialEndTime);
    final times = useSignal(initialTimes);
    // In edit mode the request fields come from the existing link; in create
    // mode they are filled in by getData() before the share is created.
    final requestName =
        useSignal(hasUpload ? (initialLink['request_name'] ?? "") : "");
    final requestInfo =
        useSignal(hasUpload ? (initialLink['request_info'] ?? "") : "");

    final timesController = useTextEditingController(text: initialTimes);
    final endTimeController = useTextEditingController(
        text: initialEndTime?.format("Y-m-d H:i") ?? "");
    final startTimeController = useTextEditingController(
        text: initialStartTime?.format("Y-m-d H:i") ?? "");
    final requestNameController = useTextEditingController(
        text: hasUpload ? (initialLink['request_name'] ?? "") : "");
    final requestInfoController = useTextEditingController(
        text: hasUpload ? (initialLink['request_info'] ?? "") : "");

  deleteShare() async {
    try {
      await dsmControlPanelPost({
        "id": jsonEncode([linkInfo.value['id']]),
        "api": '"SYNO.FileStation.Sharing"',
        "method": '"delete"',
        "version": 3,
      });
      UiUtil.toast("取消共享成功");
      if (context.mounted) {
        // ignore: use_build_context_synchronously
        Navigator.of(context).pop();
      }
    } catch (e) {
      // 旧层失败时静默。
    }
  }

  getData() async {
    if (fileRequest == true) {
      requestName.value = await StorageUtil.getString("account") ?? '';
      requestInfo.value = "嗨，我的朋友！请将文件上传到此处。";
    }
    if (paths == null || paths!.isEmpty) {
      return;
    }
    late Map<String, dynamic> data;
    try {
      final body = <String, dynamic>{
        "api": '"SYNO.FileStation.Sharing"',
        "method": '"create"',
        "version": 3,
        "path": jsonEncode(paths!),
      };
      if (fileRequest ?? false) {
        body['file_request'] = true;
        body['request_name'] = requestName.value;
        body['request_info'] = requestInfo.value;
      }
      data = await dsmControlPanelPost(body);
    } catch (e) {
      loading.value = false;
      return;
    }
    {
      loading.value = false;
      final links = data['links'] as List? ?? [];
      if (links.isEmpty) return;
      linkInfo.value = links[0];
      times.value = linkInfo.value['expire_times'] == 0
          ? ""
          : linkInfo.value['expire_times'].toString();
      if (linkInfo.value['date_expired'] != "") {
        endTime.value = DateTime.parse(linkInfo.value['date_expired']);
      }
      if (linkInfo.value['date_available'] != "") {
        startTime.value = DateTime.parse(linkInfo.value['date_available']);
      }
      String endTimeStr = endTime.value?.format("Y-m-d H:i") ?? "";
      String startTimeStr = startTime.value?.format("Y-m-d H:i") ?? "";
      timesController.value = TextEditingValue(text: times.value);
      endTimeController.value = TextEditingValue(text: endTimeStr);
      startTimeController.value = TextEditingValue(text: startTimeStr);
      if (linkInfo.value['enable_upload']) {
        requestName.value = linkInfo.value['request_name'];
        requestNameController.value =
            TextEditingValue(text: requestName.value);
        requestInfo.value = linkInfo.value['request_info'];
        requestInfoController.value =
            TextEditingValue(text: requestInfo.value);
      }
    }
  }

  Widget buildLinkItem(link) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(
            height: 20,
          ),
          Card(
            shape: RoundedRectangleBorder(
                side: const BorderSide(),
                borderRadius: BorderRadius.circular(18)),
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.paddingSmall),
              child: Image.memory(
                const Base64Decoder().convert(link['qrcode'].split(",")[1]),
                height: 150,
              ),
            ),
          ),
          const SizedBox(
            height: 20,
          ),
          Text(
            link['name'],
            style: const TextStyle(fontSize: 26),
          ),
          Text(
            link['path'],
          ),
          const SizedBox(
            height: 20,
          ),
          Card(
            shape: RoundedRectangleBorder(
                side: const BorderSide(),
                borderRadius: BorderRadius.circular(18)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      "${link['url']}",
                    ),
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  OutlinedButton(
                    onPressed: () async {
                      ClipboardData data = ClipboardData(text: link['url']);
                      Clipboard.setData(data);
                      UiUtil.toast("已复制到剪贴板");
                    },
                    child: const SizedBox(
                      width: 20,
                      height: 20,
                      child: Icon(
                        Icons.copy,
                        color: AppColors.primaryAction,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(
            height: 20,
          ),
          GestureDetector(
            onTap: () {
              FocusScope.of(context).unfocus();
              DatePicker.showDateTimePicker(
                context,
                showTitleActions: true,
                onConfirm: (date) {
                  endTime.value = date;
                  endTimeController.text =
                      endTime.value?.format("Y-m-d H:i") ?? '';
                },
                currentTime: endTime.value ?? DateTime.now(),
                locale: LocaleType.zh,
              );
            },
            child: Card(
              shape: RoundedRectangleBorder(
                  side: const BorderSide(),
                  borderRadius: BorderRadius.circular(18)),
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.paddingSmall),
                child: TextField(
                  controller: endTimeController,
                  decoration: const InputDecoration(
                    enabled: false,
                    border: InputBorder.none,
                    labelText: "设置停止时间",
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
              DatePicker.showDateTimePicker(
                context,
                showTitleActions: true,
                onConfirm: (date) {
                  startTime.value = date;
                  startTimeController.text =
                      startTime.value?.format("Y-m-d H:i") ?? '';
                },
                currentTime: startTime.value ?? DateTime.now(),
                locale: LocaleType.zh,
              );
            },
            child: Card(
              shape: RoundedRectangleBorder(
                  side: const BorderSide(),
                  borderRadius: BorderRadius.circular(18)),
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.paddingSmall),
                child: TextField(
                  controller: startTimeController,
                  decoration: const InputDecoration(
                    enabled: false,
                    border: InputBorder.none,
                    labelText: "设置开始时间",
                  ),
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
                controller: timesController,
                keyboardType: TextInputType.number,
                onChanged: (v) => times.value = v,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  labelText: '允许访问的数量',
                ),
              ),
            ),
          ),
          if (link['enable_upload']) ...[
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
                  controller: requestNameController,
                  onChanged: (v) => requestName.value = v,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    labelText: '您的姓名',
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
                  controller: requestInfoController,
                  onChanged: (v) => requestInfo.value = v,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    labelText: '信息',
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  useEffect(() {
    if (paths != null) {
      getData();
    } else {
      loading.value = false;
    }
    return null;
  }, const []);

    return Scaffold(
      appBar: AppBar(
        leading: AppBackButton(context),
        title: const Text(
          "共享文件",
        ),
      ),
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: loading.value
            ? const Center(
                child: CupertinoActivityIndicator(
                  radius: 14,
                ),
              )
            : Column(
                children: [
                  Expanded(
                    child: ListView(
                      children: [
                        buildLinkItem(linkInfo.value),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () async {
                              List<String> id = [];
                              List<String> url = [];
                              id.add(linkInfo.value['id']);
                              url.add(linkInfo.value['url']);
                              try {
                                final body = <String, dynamic>{
                                  "path": linkInfo.value['path'],
                                  "url": jsonEncode(url),
                                  "protect_type_enable": '"false"',
                                  "date_expired": endTime.value == null
                                      ? ""
                                      : '"${endTime.value!.format("Y-m-d H:i:s")}"',
                                  "expire_times": times.value,
                                  "protect_type": "none",
                                  "redirect_uri": null,
                                  "id": jsonEncode(id),
                                  "date_available": startTime.value == null
                                      ? ""
                                      : '"${startTime.value!.format("Y-m-d H:i:s")}"',
                                  "api": '"SYNO.FileStation.Sharing"',
                                  "method": '"edit"',
                                  "version": 3,
                                };
                                if (linkInfo.value['enable_upload'] == true) {
                                  body['file_request'] = true;
                                  body['request_name'] = requestName.value;
                                  body['request_info'] = requestInfo.value;
                                }
                                await dsmControlPanelPost(body);
                                UiUtil.toast("保存成功");
                              } catch (e) {
                                // 旧层失败时静默。
                              }
                            },
                            child: const Text("保存修改"),
                          ),
                        ),
                        const SizedBox(
                          width: 20,
                        ),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () async {
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
                                              BorderRadius.circular(5)),
                                      child: SafeArea(
                                        top: false,
                                        child: Padding(
                                          padding: const EdgeInsets.all(
                                              AppConstants.paddingSmall),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: <Widget>[
                                              const Text(
                                                "确认取消",
                                                style: TextStyle(
                                                    fontSize: 20,
                                                    fontWeight:
                                                        FontWeight.w500),
                                              ),
                                              const SizedBox(
                                                height: 12,
                                              ),
                                              const Text(
                                                "确认要取消此共享链接？",
                                                style: TextStyle(
                                                    fontSize: 20,
                                                    fontWeight:
                                                        FontWeight.w400),
                                              ),
                                              const SizedBox(
                                                height: 22,
                                              ),
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: OutlinedButton(
                                                      onPressed: () async {
                                                        Navigator.of(context)
                                                            .pop();
                                                        deleteShare();
                                                      },
                                                      child: const Text(
                                                        "取消共享",
                                                        style: TextStyle(
                                                            fontSize: 18,
                                                            color: Colors
                                                                .redAccent),
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(
                                                    width: 16,
                                                  ),
                                                  Expanded(
                                                    child: OutlinedButton(
                                                      onPressed: () async {
                                                        Navigator.of(context)
                                                            .pop();
                                                      },
                                                      child: const Text(
                                                        "取消",
                                                        style: TextStyle(
                                                            fontSize: 18),
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
                                  ),
                                  );
                                },
                              );
                            },
                            child: const Text("取消共享"),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
