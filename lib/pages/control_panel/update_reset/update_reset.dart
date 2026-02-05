import 'package:garden/pages/common/browser.dart';
import 'package:garden/util/http_util.dart';
import 'package:garden/util/log.dart';
import 'package:garden/widgets/bubble_tab_indicator.dart';
import 'package:garden/widgets/neu_back_button.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:garden/constants/app_constants.dart';

class UpdateReset extends StatefulWidget {
  const UpdateReset({super.key});

  @override
  UpdateResetState createState() => UpdateResetState();
}

class UpdateResetState extends State<UpdateReset>
    with SingleTickerProviderStateMixin {
  final TapGestureRecognizer _updateNoteRecognizer = TapGestureRecognizer();
  late TabController _tabController;
  String firmwareDate = "";
  String firmwareVer = "";
  String model = "";
  Map? update;
  bool checking = true;
  @override
  void initState() {
    _tabController = TabController(length: 3, vsync: this);
    getData();
    checkUpdate();
    super.initState();
  }

  @override
  void dispose() {
    _updateNoteRecognizer.dispose();
    super.dispose();
  }

  getData() async {
    var res = await Api.firmwareVersion();
    if (res['success']) {
      setState(() {
        firmwareDate = res['data']['firmware_date'];
        firmwareVer = res['data']['firmware_ver'];
        model = res['data']['model'];
      });
    }
  }

  checkUpdate() async {
    var res = await Api.firmwareUpgrade();
    setState(() {
      checking = false;
    });
    Log.info("check update: $res");
    if (res['success']) {
      setState(() {
        update = res['data']['update'];
      });
    } else {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: AppBackButton(context),
        title: const Text("更新和还原"),
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
              isScrollable: true,
              controller: _tabController,
              indicatorSize: TabBarIndicatorSize.label,
              labelColor: Theme.brightnessOf(context) == Brightness.dark
                  ? Colors.white
                  : Colors.black,
              unselectedLabelColor: Colors.grey,
              indicator: const BubbleTabIndicator(),
              tabs: const [
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 10, horizontal: 5),
                  child: Text("系统更新"),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 10, horizontal: 5),
                  child: Text("系统设置备份"),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 10, horizontal: 5),
                  child: Text("重置"),
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
                    const Text(
                      "Synology 会不时发布 DSM 更新。安装更新版本的 DSM 以获得新功能、安全补丁以及改进的系统稳定性。",
                      style: TextStyle(color: Colors.grey),
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
                        child: Text("产品型号: $model"),
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
                        child: Text("DSM 版本: $firmwareVer"),
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
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("状态: "),
                            Expanded(
                              child: checking
                                  ? const CupertinoActivityIndicator()
                                  : update != null &&
                                          (update?['available'] ?? true)
                                      ? Text.rich(TextSpan(
                                          children: [
                                            TextSpan(
                                              text:
                                                  "${update?['version']}版本可下载",
                                              style: const TextStyle(
                                                  color: Colors.green),
                                            ),
                                            TextSpan(
                                                text: " (说明)",
                                                style: const TextStyle(
                                                    color: Colors.blue),
                                                recognizer:
                                                    _updateNoteRecognizer
                                                      ..onTap = () {
                                                        String url =
                                                            "http://update.synology.com/autoupdate/whatsnew.php?model=${Uri.encodeComponent(model)}&update_version=${update?['version_details']['buildnumber']}-0";
                                                        Navigator.of(context).push(
                                                            CupertinoPageRoute(
                                                          builder: (context) {
                                                            return Browser(
                                                              url: url,
                                                              title:
                                                                  "${update?['version']}版本更新说明",
                                                            );
                                                          },
                                                          settings:
                                                              const RouteSettings(
                                                                  name:
                                                                      "browser"),
                                                        ));
                                                      }),
                                          ],
                                        ))
                                      : const Text(
                                          "无更新",
                                        ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    const Text(
                      "为保证系统稳定性，此处仅作展示，请至WEB控制端进行更新",
                      style: TextStyle(color: Colors.red),
                    ),
                  ],
                ),
                const Center(
                  child: Text("待开发"),
                ),
                const Center(
                  child: Text("待开发"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
