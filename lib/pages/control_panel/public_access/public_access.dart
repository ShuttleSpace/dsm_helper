import 'dart:async';

import 'package:garden/extensions/color.dart';
import 'package:garden/pages/control_panel/public_access/edit_ddns.dart';
import 'dart:convert';
import 'package:garden/api/dsm_api.dart';
import 'package:garden/widgets/bubble_tab_indicator.dart';
import 'package:garden/widgets/label.dart';
import 'package:garden/widgets/neu_back_button.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:garden/constants/app_constants.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:signals_hooks/signals_hooks.dart';

class PublicAccess extends HookWidget {
  const PublicAccess({super.key});

  @override
  Widget build(BuildContext context) {
    final tickerProvider = useSingleTickerProvider();
    final tabController = useMemoized(
      () => TabController(length: 1, vsync: tickerProvider),
      const [],
    );
    final providers = useSignal<List>([]);
    final records = useSignal<List>([]);
    final ips = useSignal<List>([]);
    final Map statusStr = {
      "service_ddns_normal": "正常",
      "service_ddns_error_unknown": "联机失败",
      "loading": "加载中",
      "disabled": "已停用",
    };

    Future<void> getData() async {
      try {
        final apis = [
          {"api": "SYNO.Core.DDNS.Provider", "version": 1, "method": "list"},
          {"api": "SYNO.Core.DDNS.Record", "version": 1, "method": "list"},
          {
            "api": "SYNO.Core.DDNS.ExtIP",
            "version": 2,
            "method": "list",
            "retry": true
          },
          {
            "api": "SYNO.Core.DDNS.Synology",
            "version": 1,
            "method": "get_myds_account"
          },
        ];
        final data = await dsmControlPanelPost({
          "api": 'SYNO.Entry.Request',
          "method": 'request',
          "mode": '"parallel"',
          "compound": jsonEncode(apis),
          "version": 1,
        });
        for (final item in data['result'] ?? []) {
          if (item is! Map || item['success'] != true) continue;
          final itemData = item['data'];
          if (itemData is! Map) continue;
          switch (item['api']) {
            case "SYNO.Core.DDNS.Provider":
              providers.value = (itemData['providers'] as List? ?? [])
                  .where((e) =>
                      e['provider'].startsWith("USER_") || e['url'] == null)
                  .map((e) {
                e['provider'] = e['provider'].replaceAll("USER_", "*");
                return e;
              }).toList();
              providers.value.sort((a, b) =>
                  a['provider'].compareTo(b['provider']));
              break;
            case "SYNO.Core.DDNS.Record":
              records.value = (itemData['records'] as List? ?? []).map((e) {
                e['provider'] = e['provider'].replaceAll("USER_", "*");
                return e;
              }).toList();
              break;
            case "SYNO.Core.DDNS.ExtIP":
              final rawIps = item['data'];
              ips.value = rawIps is List ? List<dynamic>.from(rawIps) : <dynamic>[];
              break;
          }
        }
      } catch (e) {
        // 旧层失败时保持原状态。
      }
    }

    useEffect(() {
      getData();
      final timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        getData();
      });
      return () {
        timer.cancel();
        tabController.dispose();
      };
    }, const []);

    Widget buildDdnsItem(ddns) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(CupertinoPageRoute(builder: (context) {
          return EditDdns(
            providers.value,
            ddns: ddns,
          );
        })).then((value) async {
          if (value != null && value) {
            try {
              await dsmControlPanelPost({
                "api": 'SYNO.Core.DDNS.Record',
                "method": 'update_ip_address',
                "version": 1,
                "id": '"${ddns['id'].replaceAll("USER_", "*")}"',
              });
              await getData();
            } catch (e) {
              // 旧层忽略失败。
            }
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
                    providers.value,
                    extIp: ips.value,
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
                try {
                  await dsmControlPanelPost({
                    "api": 'SYNO.Core.DDNS.Record',
                    "method": 'update_ip_address',
                    "version": 1,
                    "id": '"null"',
                  });
                  await getData();
                } catch (e) {
                  // 旧层忽略失败。
                }
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
                  child: Text("DDNS"),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 10, horizontal: 5),
                  child: Text("路由器配置"),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 10, horizontal: 5),
                  child: Text("高级设置"),
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: tabController,
              children: [
                ListView.builder(
                  itemBuilder: (context, i) {
                    return buildDdnsItem(records.value[i]);
                  },
                  itemCount: records.value.length,
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
