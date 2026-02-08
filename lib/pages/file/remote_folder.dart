import 'package:garden/extensions/color.dart';
import 'package:garden/pages/file/select_folder.dart';
import 'package:garden/util/ui_util.dart';
import 'package:garden/util/http_util.dart';
import 'package:garden/widgets/bubble_tab_indicator.dart';
import 'package:garden/widgets/neu_back_button.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:garden/constants/app_constants.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';

class RemoteFolder extends StatefulWidget {
  const RemoteFolder({super.key});

  @override
  RemoteFolderState createState() => RemoteFolderState();
}

class RemoteFolderState extends State<RemoteFolder>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String serverIp = "";
  String mountPoint = "";
  bool autoMount = false;
  String account = "";
  String passwd = "";
  @override
  void initState() {
    _tabController = TabController(length: 2, vsync: this);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
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
              controller: _tabController,
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
              controller: _tabController,
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
                          onChanged: (v) => serverIp = v,
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
                          onChanged: (v) => account = v,
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
                          onChanged: (v) => passwd = v,
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
                            setState(() {
                              mountPoint = res[0];
                            });
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
                                    mountPoint == "" ? "选择装载到文件夹" : mountPoint,
                                    style: TextStyle(
                                        fontSize: 16,
                                        color: mountPoint == ""
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
                        setState(() {
                          autoMount = !autoMount;
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
                              const Text("开机时自动装载"),
                              const Spacer(),
                              if (autoMount)
                                Icon(
                                  CupertinoIcons.checkmark_alt,
                                  color: Theme.of(context).colorScheme.primary,
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
                        if (mountPoint == "") {
                          UiUtil.toast("请选择保存位置");
                          UiUtil.vibrate(FeedbackType.impact);
                          return;
                        }
                        if (serverIp.trim() == "") {
                          UiUtil.toast("请输入远程文件夹地址");
                          return;
                        }
                        var res = await DsmApi.mountFolder(
                            serverIp, account, passwd, mountPoint, autoMount);
                        if (res['success']) {
                          UiUtil.toast("装载成功");
                          UiUtil.vibrate(FeedbackType.light);
                        } else {
                          UiUtil.vibrate(FeedbackType.warning);
                          if (res['error']['code'] == 436) {
                            UiUtil.toast("远程文件夹地址有误");
                          } else {
                            UiUtil.toast("装载失败，代码${res['error']['code']}");
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
