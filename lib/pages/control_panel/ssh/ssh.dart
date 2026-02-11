import 'package:dio/dio.dart';
import 'package:garden/api/dsm_api.dart';
import 'package:garden/util/ui_util.dart';
import 'package:garden/widgets/bubble_tab_indicator.dart';
import 'package:garden/widgets/neu_back_button.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:garden/constants/app_constants.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';
import 'package:signals/signals_flutter.dart';

class SshSetting extends StatefulWidget {
  const SshSetting({super.key});

  @override
  SshSettingState createState() => SshSettingState();
}

class SshSettingState extends State<SshSetting>
    with SingleTickerProviderStateMixin, SignalsMixin {
  late TabController _tabController;
  final TextEditingController _portController = TextEditingController();
  late final loading = createSignal(true);
  late final ssh = createSignal(false);
  late final telnet = createSignal(false);
  late final sshPort = createSignal('');

  @override
  void initState() {
    _tabController = TabController(length: 2, vsync: this);
    getData();
    super.initState();
  }

  getData() async {
    try {
      var data = await dsmCoreTerminalGet();
      loading.value = false;
      ssh.value = data['enable_ssh'];
      telnet.value = data['enable_telnet'];
      sshPort.value = data['ssh_port'].toString();
      _portController.value = TextEditingValue(text: sshPort.value);
    } on DSMException catch (e) {
      UiUtil.toast("获取失败，code：${e.code}");
      if (mounted) Navigator.of(context).pop();
    } on DioException catch (e) {
      UiUtil.toast("网络错误：${e.message}");
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: AppBackButton(context),
        title: const Text("终端机和SNMP"),
      ),
      body: Watch((context) => loading.value
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
                            onTap: () => telnet.value = !telnet.value,
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
                                    if (telnet.value)
                                      Icon(
                                        CupertinoIcons.checkmark_alt,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          GestureDetector(
                            onTap: () => ssh.value = !ssh.value,
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
                                    if (ssh.value)
                                      Icon(
                                        CupertinoIcons.checkmark_alt,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
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
                                onChanged: (v) => sshPort.value = v,
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
                          const SizedBox(height: 20),
                          OutlinedButton(
                            onPressed: () async {
                              try {
                                await dsmCoreTerminalSet(
                                  enableSsh: ssh.value,
                                  enableTelnet: telnet.value,
                                  sshPort: sshPort.value,
                                );
                                UiUtil.vibrate(FeedbackType.light);
                                UiUtil.toast("应用成功");
                              } on DSMException catch (e) {
                                UiUtil.vibrate(FeedbackType.warning);
                                UiUtil.toast("应用失败：${e.message}");
                              } on DioException catch (e) {
                                UiUtil.vibrate(FeedbackType.warning);
                                UiUtil.toast("网络错误：${e.message}");
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
            )),
    );
  }
}
