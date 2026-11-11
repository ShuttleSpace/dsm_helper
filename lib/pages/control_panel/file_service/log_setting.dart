import 'package:garden/util/http_util.dart';
import 'package:garden/util/log.dart';
import 'package:garden/util/ui_util.dart';
import 'package:garden/widgets/neu_back_button.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:garden/constants/app_constants.dart';
import 'package:garden/theme/app_colors.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:signals_hooks/signals_hooks.dart';

class LogSetting extends HookWidget {
  final String protocol;
  const LogSetting(this.protocol, {super.key});

  @override
  Widget build(BuildContext context) {
    final setting = useSignal<Map>({});
    final loading = useSignal(true);

    getData(VoidCallback? callback) async {
      var res = await DsmApi.fileServiceLog(protocol);
      if (res['success']) {
        setting.value = res['data'];
        loading.value = false;
      } else {
        UiUtil.toast("获取失败，code：${res['error']['code']}");
        callback?.call();
      }
    }

    useEffect(() {
      getData(() {
        if (context.mounted) {
          Navigator.of(context).pop();
        }
      });
      return null;
    }, const []);

    return Scaffold(
      appBar: AppBar(
        leading: AppBackButton(context),
        title: const Text("日志设置"),
      ),
      body: loading.value
          ? const Center(
              child: CupertinoActivityIndicator(
                radius: 14,
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      GestureDetector(
                        onTap: () async {
                          setting.value = {
                            ...setting.value,
                            'create': setting.value['create'] == "1" ? "0" : "1"
                          };
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
                                const Text(
                                  '创建',
                                  style: TextStyle(fontSize: 18),
                                ),
                                const Spacer(),
                                if (setting.value['create'] == "1")
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
                        onTap: () async {
                          setting.value = {
                            ...setting.value,
                            'write': setting.value['write'] == "1" ? "0" : "1"
                          };
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
                                const Text(
                                  '写入',
                                  style: TextStyle(fontSize: 18),
                                ),
                                const Spacer(),
                                if (setting.value['write'] == "1")
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
                        onTap: () async {
                          setting.value = {
                            ...setting.value,
                            'move': setting.value['move'] == "1" ? "0" : "1"
                          };
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
                                const Text(
                                  '移动',
                                  style: TextStyle(fontSize: 18),
                                ),
                                const Spacer(),
                                if (setting.value['move'] == "1")
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
                        onTap: () async {
                          setting.value = {
                            ...setting.value,
                            'delete': setting.value['delete'] == "1" ? "0" : "1"
                          };
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
                                const Text(
                                  '删除',
                                  style: TextStyle(fontSize: 18),
                                ),
                                const Spacer(),
                                if (setting.value['delete'] == "1")
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
                        onTap: () async {
                          setting.value = {
                            ...setting.value,
                            'read': setting.value['read'] == "1" ? "0" : "1"
                          };
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
                                const Text(
                                  '读取',
                                  style: TextStyle(fontSize: 18),
                                ),
                                const Spacer(),
                                if (setting.value['read'] == "1")
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
                        onTap: () async {
                          setting.value = {
                            ...setting.value,
                            'rename': setting.value['rename'] == "1" ? "0" : "1"
                          };
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
                                const Text(
                                  '重命名',
                                  style: TextStyle(fontSize: 18),
                                ),
                                const Spacer(),
                                if (setting.value['rename'] == "1")
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
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: OutlinedButton(
                    onPressed: () async {
                      var res = await DsmApi.fileServiceLogSave(
                          protocol, setting.value);
                      Log.info("fileServiceLogSave res: $res");
                      if (res['success']) {
                        UiUtil.vibrate(FeedbackType.light);
                        UiUtil.toast("应用成功");
                        if (context.mounted) {
                          Navigator.of(context).pop();
                        }
                      } else {
                        UiUtil.vibrate(FeedbackType.warning);
                        UiUtil.toast("应用失败，code:${res['error']['code']}");
                      }
                    },
                    child: const Text(
                      ' 应用 ',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
