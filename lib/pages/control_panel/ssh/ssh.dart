import 'package:garden/util/http_util.dart';
import 'package:garden/util/ui_util.dart';
import 'package:garden/widgets/bubble_tab_indicator.dart';
import 'package:garden/widgets/neu_back_button.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:garden/constants/app_constants.dart';
import 'package:garden/theme/app_colors.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';

class SshSetting extends StatefulWidget {
  const SshSetting({super.key});

  @override
  SshSettingState createState() => SshSettingState();
}

class SshSettingState extends State<SshSetting>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _portController = TextEditingController();
  bool loading = true;
  bool ssh = false;
  bool telnet = false;

  String sshPort = '';
  @override
  void initState() {
    _tabController = TabController(length: 2, vsync: this);
    getData();
    super.initState();
  }

  getData() async {
    var res = await DsmApi.terminalInfo();
    if (res['success']) {
      setState(() {
        loading = false;
        ssh = res['data']['enable_ssh'];
        telnet = res['data']['enable_telnet'];
        sshPort = res['data']['ssh_port'].toString();
        _portController.value = TextEditingValue(text: sshPort);
      });
    } else {
      UiUtil.toast("获取失败，code：${res['error']['code']}");
      if (context.mounted) {
        // ignore: use_build_context_synchronously
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: AppBackButton(context),
        title: const Text("终端机和SNMP"),
      ),
      body: loading
          ? const Center(
              child: CupertinoActivityIndicator(
                radius: 14,
              ),
            )
          : Column(
              children: [
                Card(
                  shape: RoundedRectangleBorder(
                      side: const BorderSide(),
                      borderRadius: BorderRadius.circular(18)),
                  margin:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                  child: TabBar(
                    dividerHeight: 0,
                    isScrollable: false,
                    controller: _tabController,
                    indicatorSize: TabBarIndicatorSize.label,
                    labelColor: Theme.brightnessOf(context) == Brightness.dark
                        ? Colors.white
                        : Colors.black,
                    unselectedLabelColor: Colors.grey,
                    indicator: const BubbleTabIndicator(),
                    tabs: const [
                      Padding(
                        padding:
                            EdgeInsets.symmetric(vertical: 10, horizontal: 5),
                        child: Text("终端机"),
                      ),
                      Padding(
                        padding:
                            EdgeInsets.symmetric(vertical: 10, horizontal: 5),
                        child: Text("SNMP"),
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
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                telnet = !telnet;
                              });
                            },
                            child: Card(
                              shape: RoundedRectangleBorder(
                                  side: const BorderSide(),
                                  borderRadius: BorderRadius.circular(18)),
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Row(
                                  children: [
                                    const Text(
                                      "启动Telnet功能",
                                      style: TextStyle(fontSize: 16),
                                    ),
                                    const Spacer(),
                                    if (telnet)
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
                              setState(() {
                                ssh = !ssh;
                              });
                            },
                            child: Card(
                              shape: RoundedRectangleBorder(
                                  side: const BorderSide(),
                                  borderRadius: BorderRadius.circular(18)),
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Row(
                                  children: [
                                    const Text(
                                      "启动SSH功能",
                                      style: TextStyle(fontSize: 16),
                                    ),
                                    const Spacer(),
                                    if (ssh)
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
                          Card(
                            shape: RoundedRectangleBorder(
                                side: const BorderSide(),
                                borderRadius: BorderRadius.circular(18)),
                            child: Padding(
                              padding: const EdgeInsets.all(
                                  AppConstants.paddingSmall),
                              child: TextField(
                                controller: _portController,
                                keyboardType: TextInputType.number,
                                onChanged: (v) => sshPort = v,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  labelText: 'SSH端口',
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(
                            height: 20,
                          ),
                          OutlinedButton(
                            onPressed: () async {
                              var res = await DsmApi.setTerminal(
                                  ssh, telnet, sshPort);
                              if (res['success']) {
                                UiUtil.vibrate(FeedbackType.light);
                                UiUtil.toast("应用成功");
                              } else {
                                UiUtil.vibrate(FeedbackType.warning);
                                UiUtil.toast(
                                    "应用失败，code：${res['error']['code']}");
                              }
                            },
                            child: const Text(
                              ' 应用 ',
                              style: TextStyle(fontSize: 18),
                            ),
                          ),
                        ],
                      ),
                      const Center(
                        child: Text("暂未开发"),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
