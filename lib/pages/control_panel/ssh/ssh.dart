import 'package:garden/util/function.dart';
import 'package:garden/widgets/bubble_tab_indicator.dart';
import 'package:garden/widgets/neu_back_button.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';

class SshSetting extends StatefulWidget {
  @override
  _SshSettingState createState() => _SshSettingState();
}

class _SshSettingState extends State<SshSetting>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  TextEditingController _portController = TextEditingController();
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
    var res = await Api.terminalInfo();
    if (res['success']) {
      setState(() {
        loading = false;
        ssh = res['data']['enable_ssh'];
        telnet = res['data']['enable_telnet'];
        sshPort = res['data']['ssh_port'].toString();
        _portController.value = TextEditingValue(text: sshPort);
      });
    } else {
      Util.instance.toast("获取失败，code：${res['error']['code']}");
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: AppBackButton(context),
        title: Text("终端机和SNMP"),
      ),
      body: loading
          ? Center(
              child: CupertinoActivityIndicator(
                radius: 14,
              ),
            )
          : Column(
              children: [
                Card(
                  shape: RoundedRectangleBorder(
                      side: BorderSide(),
                      borderRadius: BorderRadius.circular(18)),
                  margin: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                  child: TabBar(
                    dividerHeight: 0,
                    isScrollable: false,
                    controller: _tabController,
                    indicatorSize: TabBarIndicatorSize.label,
                    labelColor: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black,
                    unselectedLabelColor: Colors.grey,
                    indicator: BubbleTabIndicator(
                      indicatorColor: Theme.of(context).scaffoldBackgroundColor,
                      shadowColor: Util.instance.getAdjustColor(
                          Theme.of(context).scaffoldBackgroundColor, -20),
                    ),
                    tabs: [
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
                        padding: EdgeInsets.all(20),
                        children: [
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                telnet = !telnet;
                              });
                            },
                            child: Card(
                              shape: RoundedRectangleBorder(
                                  side: BorderSide(),
                                  borderRadius: BorderRadius.circular(18)),
                              child: Padding(
                                padding: EdgeInsets.all(20),
                                child: Row(
                                  children: [
                                    Text(
                                      "启动Telnet功能",
                                      style: TextStyle(fontSize: 16),
                                    ),
                                    Spacer(),
                                    if (telnet)
                                      Icon(
                                        CupertinoIcons.checkmark_alt,
                                        color: Color(0xffff9813),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          SizedBox(
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
                                  side: BorderSide(),
                                  borderRadius: BorderRadius.circular(18)),
                              child: Padding(
                                padding: EdgeInsets.all(20),
                                child: Row(
                                  children: [
                                    Text(
                                      "启动SSH功能",
                                      style: TextStyle(fontSize: 16),
                                    ),
                                    Spacer(),
                                    if (ssh)
                                      Icon(
                                        CupertinoIcons.checkmark_alt,
                                        color: Color(0xffff9813),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          SizedBox(
                            height: 20,
                          ),
                          Card(
                            shape: RoundedRectangleBorder(
                                side: BorderSide(),
                                borderRadius: BorderRadius.circular(18)),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: TextField(
                                controller: _portController,
                                keyboardType: TextInputType.number,
                                onChanged: (v) => sshPort = v,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  labelText: 'SSH端口',
                                ),
                              ),
                            ),
                          ),
                          SizedBox(
                            height: 20,
                          ),
                          OutlinedButton(
                            onPressed: () async {
                              var res =
                                  await Api.setTerminal(ssh, telnet, sshPort);
                              if (res['success']) {
                                Util.instance.vibrate(FeedbackType.light);
                                Util.instance.toast("应用成功");
                              } else {
                                Util.instance.vibrate(FeedbackType.warning);
                                Util.instance
                                    .toast("应用失败，code：${res['error']['code']}");
                              }
                            },
                            child: Text(
                              ' 应用 ',
                              style: TextStyle(fontSize: 18),
                            ),
                          ),
                        ],
                      ),
                      Center(
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
