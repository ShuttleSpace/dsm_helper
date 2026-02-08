import 'package:garden/util/http_util.dart';
import 'package:garden/util/log.dart';
import 'package:garden/util/ui_util.dart';
import 'package:garden/widgets/neu_back_button.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:garden/constants/app_constants.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';

class LogSetting extends StatefulWidget {
  final String protocol;
  const LogSetting(this.protocol, {super.key});
  @override
  LogSettingState createState() => LogSettingState();
}

class LogSettingState extends State<LogSetting> {
  Map setting = {};
  bool loading = true;
  @override
  void initState() {
    getData(() {
      if (context.mounted) {
        Navigator.of(context).pop();
      }
    });
    super.initState();
  }

  getData(VoidCallback? callback) async {
    var res = await DsmApi.fileServiceLog(widget.protocol);
    if (res['success']) {
      setState(() {
        setting = res['data'];
        loading = false;
      });
    } else {
      UiUtil.toast("获取失败，code：${res['error']['code']}");
      callback?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: AppBackButton(context),
        title: const Text("日志设置"),
      ),
      body: loading
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
                          setState(() {
                            setting['create'] =
                                setting['create'] == "1" ? "0" : "1";
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
                                const Text(
                                  '创建',
                                  style: TextStyle(fontSize: 18),
                                ),
                                const Spacer(),
                                if (setting['create'] == "1")
                                  Icon(
                                    CupertinoIcons.checkmark_alt,
                                    color:
                                        Theme.of(context).colorScheme.primary,
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
                          setState(() {
                            setting['write'] =
                                setting['write'] == "1" ? "0" : "1";
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
                                const Text(
                                  '写入',
                                  style: TextStyle(fontSize: 18),
                                ),
                                const Spacer(),
                                if (setting['write'] == "1")
                                  Icon(
                                    CupertinoIcons.checkmark_alt,
                                    color:
                                        Theme.of(context).colorScheme.primary,
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
                          setState(() {
                            setting['move'] =
                                setting['move'] == "1" ? "0" : "1";
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
                                const Text(
                                  '移动',
                                  style: TextStyle(fontSize: 18),
                                ),
                                const Spacer(),
                                if (setting['move'] == "1")
                                  Icon(
                                    CupertinoIcons.checkmark_alt,
                                    color:
                                        Theme.of(context).colorScheme.primary,
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
                          setState(() {
                            setting['delete'] =
                                setting['delete'] == "1" ? "0" : "1";
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
                                const Text(
                                  '删除',
                                  style: TextStyle(fontSize: 18),
                                ),
                                const Spacer(),
                                if (setting['delete'] == "1")
                                  Icon(
                                    CupertinoIcons.checkmark_alt,
                                    color:
                                        Theme.of(context).colorScheme.primary,
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
                          setState(() {
                            setting['read'] =
                                setting['read'] == "1" ? "0" : "1";
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
                                const Text(
                                  '读取',
                                  style: TextStyle(fontSize: 18),
                                ),
                                const Spacer(),
                                if (setting['read'] == "1")
                                  Icon(
                                    CupertinoIcons.checkmark_alt,
                                    color:
                                        Theme.of(context).colorScheme.primary,
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
                          setState(() {
                            setting['rename'] =
                                setting['rename'] == "1" ? "0" : "1";
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
                                const Text(
                                  '重命名',
                                  style: TextStyle(fontSize: 18),
                                ),
                                const Spacer(),
                                if (setting['rename'] == "1")
                                  Icon(
                                    CupertinoIcons.checkmark_alt,
                                    color:
                                        Theme.of(context).colorScheme.primary,
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
                          widget.protocol, setting);
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
