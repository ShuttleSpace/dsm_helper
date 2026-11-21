import 'package:garden/extensions/color.dart';
import 'package:garden/pages/file/select_folder.dart';
import 'package:garden/util/ui_util.dart';
import 'dart:convert';
import 'package:garden/api/dsm_api.dart';
import 'package:garden/widgets/bubble_tab_indicator.dart';
import 'package:garden/widgets/neu_back_button.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:garden/constants/app_constants.dart';
import 'package:garden/theme/app_colors.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:signals_hooks/signals_hooks.dart';

class RemoteFolder extends HookWidget {
  const RemoteFolder({super.key});

  @override
  Widget build(BuildContext context) {
    final tickerProvider = useSingleTickerProvider();
    final tabController = useMemoized(
      () => TabController(length: 2, vsync: tickerProvider),
      const [],
    );
    final serverIp = useSignal("");
    final mountPoint = useSignal("");
    final autoMount = useSignal(false);
    final account = useSignal("");
    final passwd = useSignal("");

    useEffect(() => tabController.dispose, const []);

    return Scaffold(
      appBar: AppBar(
        leading: AppBackButton(context),
        title: const Text("装载远程文件夹"),
      ),
      body: Column(
        children: [
          Card(
            shape: RoundedRectangleBorder(
                side: const BorderSide(),
                borderRadius: BorderRadius.circular(18)),
            margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
            child: TabBar(
              dividerHeight: 0,
              controller: tabController,
              indicatorSize: TabBarIndicatorSize.label,
              labelColor: Theme.brightnessOf(context) == Brightness.dark
                  ? Colors.white
                  : Colors.black,
              unselectedLabelColor: Colors.grey,
              indicator: BubbleTabIndicator(
                indicatorColor: Theme.of(context).scaffoldBackgroundColor,
                shadowColor:
                    Theme.of(context).scaffoldBackgroundColor.adjust(-20),
              ),
              tabs: const [
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 10, horizontal: 5),
                  child: Text("CIFS"),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 10, horizontal: 5),
                  child: Text("NFS"),
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: tabController,
              children: [
                ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Card(
                      shape: RoundedRectangleBorder(
                          side: const BorderSide(),
                          borderRadius: BorderRadius.circular(18)),
                      child: Padding(
                        padding:
                            const EdgeInsets.all(AppConstants.paddingSmall),
                        child: TextField(
                          onChanged: (v) => serverIp.value = v,
                          decoration: const InputDecoration(
                              border: InputBorder.none,
                              labelText: '远程文件夹',
                              hintText: r"示例:\\192.168.1.1\share"),
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
                        padding:
                            const EdgeInsets.all(AppConstants.paddingSmall),
                        child: TextField(
                          onChanged: (v) => account.value = v,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            labelText: '账号',
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
                        padding:
                            const EdgeInsets.all(AppConstants.paddingSmall),
                        child: TextField(
                          onChanged: (v) => passwd.value = v,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            labelText: '密码',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    OutlinedButton(
                      onPressed: () {
                        FocusScope.of(context).unfocus();
                        showCupertinoModalPopup(
                          context: context,
                          builder: (context) {
                            return const SelectFolder(
                              multi: false,
                            );
                          },
                        ).then((res) {
                          if (res != null && res.length == 1) {
                            mountPoint.value = res[0];
                          }
                        });
                      },
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "装载到",
                                  style: TextStyle(fontSize: 12),
                                ),
                                SizedBox(
                                  height: 20,
                                  child: Text(
                                    mountPoint.value == ""
                                        ? "选择装载到文件夹"
                                        : mountPoint.value,
                                    style: TextStyle(
                                        fontSize: 16,
                                        color: mountPoint.value == ""
                                            ? Colors.grey
                                            : null),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    GestureDetector(
                      onTap: () {
                        autoMount.value = !autoMount.value;
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
                              const Text("开机时自动装载"),
                              const Spacer(),
                              if (autoMount.value)
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
                    OutlinedButton(
                      onPressed: () async {
                        if (mountPoint.value == "") {
                          UiUtil.toast("请选择保存位置");
                          UiUtil.vibrate(FeedbackType.impact);
                          return;
                        }
                        if (serverIp.value.trim() == "") {
                          UiUtil.toast("请输入远程文件夹地址");
                          return;
                        }
                        try {
                          await dsmControlPanelPost({
                            "mount_type": '"CIFS"',
                            "server_ip": jsonEncode(serverIp.value),
                            "mount_point": '"${mountPoint.value}"',
                            "user_set": false,
                            "auto_mount": autoMount.value,
                            "adv_opt": '""',
                            "account": '"${account.value}"',
                            "passwd": '"${passwd.value}"',
                            "api": "SYNO.FileStation.Mount",
                            "method": "mount_remote",
                            "version": 1,
                          });
                          UiUtil.toast("装载成功");
                          UiUtil.vibrate(FeedbackType.light);
                        } catch (e) {
                          UiUtil.vibrate(FeedbackType.warning);
                          final code = e is DSMException ? e.code : -1;
                          if (code == 436) {
                            UiUtil.toast("远程文件夹地址有误");
                          } else {
                            UiUtil.toast("装载失败，代码$code");
                          }
                        }
                      },
                      child: const Text(
                        ' 装载 ',
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                  ],
                ),
                const Center(
                  child: Text("开发中"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
