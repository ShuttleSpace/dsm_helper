import 'dart:async';

import 'package:garden/pages/control_panel/public_access/edit_ddns.dart';
import 'package:garden/util/http_util.dart';
import 'package:garden/widgets/bubble_tab_indicator.dart';
import 'package:garden/widgets/label.dart';
import 'package:garden/widgets/neu_back_button.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:garden/constants/app_constants.dart';

class PublicAccess extends StatefulWidget {
  const PublicAccess({super.key});

  @override
  PublicAccessState createState() => PublicAccessState();
}

class PublicAccessState extends State<PublicAccess>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List providers = [];
  List records = [];
  String nextUpdateTime = "";
  List ips = [];
  late Timer timer;
  Map statusStr = {
    "service_ddns_normal": "正常",
    "service_ddns_error_unknown": "联机失败",
    "loading": "加载中",
    "disabled": "已停用",
  };
  @override
  void initState() {
    _tabController = TabController(length: 1, vsync: this);
    getData();
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      getData();
    });
    super.initState();
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }

  getData() async {
    var res = await Api.publicAccessInfo();
    if (res['success']) {
      List result = res['data']['result'];
      for (var item in result) {
        if (item['success'] == true) {
          switch (item['api']) {
            case "SYNO.Core.DDNS.Provider":
              setState(() {
                providers = item['data']['providers']
                    .where((e) =>
                        e['provider'].startsWith("USER_") || e['url'] == null)
                    .map((e) {
                  e['provider'] = e['provider'].replaceAll("USER_", "*");
                  return e;
                }).toList();
                providers.sort((a, b) {
                  return a['provider'].compareTo(b['provider']);
                });
              });
              break;
            case "SYNO.Core.DDNS.Record":
              setState(() {
                records = item['data']['records'].map((e) {
                  e['provider'] = e['provider'].replaceAll("USER_", "*");
                  return e;
                }).toList();
                nextUpdateTime = item['data']['next_update_time'];
              });
              break;
            case "SYNO.Core.DDNS.ExtIP":
              ips = item['data'];

              break;
          }
        }
      }
    }
  }

  Widget _buildDdnsItem(ddns) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(CupertinoPageRoute(builder: (context) {
          return EditDdns(
            providers,
            ddns: ddns,
          );
        })).then((value) async {
          if (value != null && value) {
            await Api.ddnsUpdate(id: ddns['id'].replaceAll("USER_", "*"));
            getData();
          }
        });
      },
      child: Card(
        shape: RoundedRectangleBorder(
            side: const BorderSide(), borderRadius: BorderRadius.circular(18)),
        margin: const EdgeInsets.only(top: 20, left: 20, right: 20),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.paddingSmall),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    "${ddns['provider']}",
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(
                    width: 5,
                  ),
                  Label(
                    statusStr[ddns['status']] ?? ddns['status'],
                    ddns['status'] == "service_ddns_normal"
                        ? Colors.green
                        : Colors.red,
                    fill: true,
                  ),
                ],
              ),
              const SizedBox(
                height: 5,
              ),
              Row(
                children: [
                  Text("${ddns['hostname']}"),
                  const SizedBox(
                    width: 10,
                  ),
                  Text("${ddns['ip']}"),
                ],
              ),
              const SizedBox(
                height: 5,
              ),
              Row(
                children: [
                  Text(
                      "上次：${ddns['lastupdated'] == "disabled" ? "已停用" : ddns['lastupdated']}"),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: AppBackButton(context),
        title: const Text("外部访问"),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10, top: 8, bottom: 8),
            child: OutlinedButton(
              onPressed: () async {
                Navigator.of(context)
                    .push(CupertinoPageRoute(builder: (context) {
                  return EditDdns(
                    providers,
                    extIp: ips,
                  );
                }));
              },
              child: const Icon(Icons.add),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 10, top: 8, bottom: 8),
            child: OutlinedButton(
              onPressed: () async {
                await Api.ddnsUpdate();
                getData();
              },
              child: const Icon(Icons.refresh),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(20),
            ),
            margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
            child: TabBar(
              isScrollable: false,
              controller: _tabController,
              indicatorSize: TabBarIndicatorSize.label,
              labelColor: Theme.brightnessOf(context) == Brightness.dark
                  ? Colors.white
                  : Colors.black,
              unselectedLabelColor: Colors.grey,
              indicator: BubbleTabIndicator(
                indicatorColor: Theme.of(context).scaffoldBackgroundColor,
                shadowColor: HttpUtil.getAdjustColor(
                    Theme.of(context).scaffoldBackgroundColor, -20),
              ),
              tabs: const [
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 10, horizontal: 5),
                  child: Text("DDNS"),
                ),
                // Padding(
                //   padding: EdgeInsets.symmetric(vertical: 10, horizontal: 5),
                //   child: Text("路由器配置"),
                // ),
                // Padding(
                //   padding: EdgeInsets.symmetric(vertical: 10, horizontal: 5),
                //   child: Text("高级设置"),
                // ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                ListView.builder(
                  itemBuilder: (context, i) {
                    return _buildDdnsItem(records[i]);
                  },
                  itemCount: records.length,
                ),
                // Center(
                //   child: Text("开发中"),
                // ),
                // Center(
                //   child: Text("开发中"),
                // ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
