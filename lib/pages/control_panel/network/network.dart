import 'package:garden/api/dsm_api.dart';
import 'package:garden/util/log.dart';
import 'package:garden/widgets/bubble_tab_indicator.dart';
import 'package:garden/widgets/expansion_container.dart';
import 'package:garden/widgets/label.dart';
import 'package:garden/widgets/neu_back_button.dart';
import 'package:flutter/cupertino.dart';
import 'package:garden/widgets/settings/settings_text_field.dart';
import 'package:flutter/material.dart';
import 'package:garden/constants/app_constants.dart';
import 'package:garden/theme/app_colors.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:signals_hooks/signals_hooks.dart';

class Network extends HookWidget {
  const Network({super.key});

  @override
  Widget build(BuildContext context) {
    final tickerProvider = useSingleTickerProvider();
    final tabController = useMemoized(
      () => TabController(length: 5, vsync: tickerProvider),
      const [],
    );
    final serverNameController = useTextEditingController();
    final dnsPrimaryController = useTextEditingController();
    final dnsSecondaryController = useTextEditingController();
    final proxyHttpHostController = useTextEditingController();
    final proxyHttpPortController = useTextEditingController();
    final network = useSignal<Map>({});
    final proxy = useSignal<Map>({});
    final gateway = useSignal<Map>({});
    final dsm = useSignal<Map>({});
    final ethernets = useSignal<List>([]);
    final pppoes = useSignal<List>([]);
    final loading = useSignal(true);

    getData() async {
      late Map<String, dynamic> data;
      try {
        data = await dsmCoreNetworkStatusForPage();
      } catch (e) {
        loading.value = false;
        return;
      }
      {
        loading.value = false;
        List result = data['result'] ?? [];
        for (var item in result) {
          if (item['success'] == true) {
            switch (item['api']) {
              case "SYNO.Core.Network":
                if (item['data'] != null) {
                  network.value = item['data'];
                  serverNameController.value =
                      TextEditingValue(text: network.value['server_name']);
                  dnsPrimaryController.value =
                      TextEditingValue(text: network.value['dns_primary']);
                  dnsSecondaryController.value =
                      TextEditingValue(text: network.value['dns_secondary']);
                }
                break;
              case "SYNO.Core.Network.Ethernet":
                ethernets.value = item['data'];
                break;
              case "SYNO.Core.Network.PPPoE":
                pppoes.value = item['data'];
                break;
              case "SYNO.Core.Network.Proxy":
                proxy.value = item['data'];
                proxyHttpHostController.value =
                    TextEditingValue(text: proxy.value['http_host']);
                proxyHttpPortController.value =
                    TextEditingValue(text: proxy.value['http_port']);
                break;
              case "SYNO.Core.Network.Router.Gateway.List":
                gateway.value = item['data'];
                break;
              case "SYNO.Core.Web.DSM":
                dsm.value = item['data'];
                Log.info("Web.DSM: ${dsm.value}");
                break;
            }
          }
        }
      }
    }

    useEffect(() {
      getData();
      return () {
        tabController.dispose();
      };
    }, const []);

    return Scaffold(
      appBar: AppBar(
        leading: AppBackButton(context),
        title: const Text("网络"),
      ),
      body: loading.value
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
                    isScrollable: true,
                    controller: tabController,
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
                        child: Text("常规"),
                      ),
                      Padding(
                        padding:
                            EdgeInsets.symmetric(vertical: 10, horizontal: 5),
                        child: Text("网络界面"),
                      ),
                      Padding(
                        padding:
                            EdgeInsets.symmetric(vertical: 10, horizontal: 5),
                        child: Text("流量控制"),
                      ),
                      Padding(
                        padding:
                            EdgeInsets.symmetric(vertical: 10, horizontal: 5),
                        child: Text("静态路由"),
                      ),
                      Padding(
                        padding:
                            EdgeInsets.symmetric(vertical: 10, horizontal: 5),
                        child: Text("DSM设置"),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    controller: tabController,
                    children: [
                      ListView(
                        children: [
                          Card(
                            shape: RoundedRectangleBorder(
                                side: const BorderSide(),
                                borderRadius: BorderRadius.circular(18)),
                            margin: const EdgeInsets.only(
                                top: 20, left: 20, right: 20),
                            child: Padding(
                              padding: const EdgeInsets.all(
                                  AppConstants.paddingLarge),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "常规",
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(
                                    height: 20,
                                  ),
                                  const Text("请输入系统名称、域名服务器 (DNS) 及默认网关。"),
                                  const SizedBox(
                                    height: 20,
                                  ),
                                  SettingsTextField(
                                    controller: serverNameController,
                                    label: "系统名称",
                                    onChanged: (v) =>
                                        network.value['server_name'] = v,
                                  ),
                                  const SizedBox(
                                    height: 20,
                                  ),
                                  Text(
                                      "默认网关(gateway): ${network.value['gateway']}"),
                                  const SizedBox(
                                    height: 5,
                                  ),
                                  Text(
                                      "IPv6默认网关: ${network.value['v6gateway'] == "" ? "-" : network.value['v6gateway']}"),
                                  const SizedBox(
                                    height: 20,
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      FocusScope.of(context).unfocus();
                                      network.value['dns_manual'] =
                                          !network.value['dns_manual'];
                                      network.notifyListeners();
                                    },
                                    child: Card(
                                      shape: RoundedRectangleBorder(
                                          side: const BorderSide(),
                                          borderRadius:
                                              BorderRadius.circular(5)),
                                      child: Padding(
                                        padding: const EdgeInsets.all(
                                            AppConstants.paddingSmall),
                                        child: Row(
                                          children: [
                                            const Text("手动配置DNS服务器"),
                                            const Spacer(),
                                            if (network.value['dns_manual'])
                                              const Icon(
                                                CupertinoIcons.checkmark_alt,
                                                color: AppColors.primaryAction,
                                                size: 22,
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(
                                    height: 20,
                                  ),
                                  SettingsTextField(
                                    controller: dnsPrimaryController,
                                    label: "首选DNS服务器",
                                    onChanged: (v) =>
                                        network.value['dns_primary'] = v,
                                    enabled: network.value['dns_manual'],
                                  ),
                                  const SizedBox(
                                    height: 20,
                                  ),
                                  SettingsTextField(
                                    controller: dnsSecondaryController,
                                    label: "备用DNS服务器",
                                    onChanged: (v) =>
                                        network.value['dns_secondary'] = v,
                                    enabled: network.value['dns_manual'],
                                  ),
                                ],
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
                            margin: const EdgeInsets.only(
                                top: 20, left: 20, right: 20),
                            child: Padding(
                              padding: const EdgeInsets.all(
                                  AppConstants.paddingLarge),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "代理服务器",
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(
                                    height: 20,
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      FocusScope.of(context).unfocus();
                                      proxy.value['enable'] =
                                          !proxy.value['enable'];
                                      proxy.notifyListeners();
                                    },
                                    child: Card(
                                      shape: RoundedRectangleBorder(
                                          side: const BorderSide(),
                                          borderRadius:
                                              BorderRadius.circular(5)),
                                      child: Padding(
                                        padding: const EdgeInsets.all(
                                            AppConstants.paddingSmall),
                                        child: Row(
                                          children: [
                                            const Text("手动配置DNS服务器"),
                                            const Spacer(),
                                            if (proxy.value['enable'])
                                              const Icon(
                                                CupertinoIcons.checkmark_alt,
                                                color: AppColors.primaryAction,
                                                size: 22,
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(
                                    height: 20,
                                  ),
                                  SettingsTextField(
                                    controller: proxyHttpHostController,
                                    label: "地址",
                                    onChanged: (v) =>
                                        proxy.value['http_host'] = v,
                                    enabled: proxy.value['enable'],
                                  ),
                                  const SizedBox(
                                    height: 20,
                                  ),
                                  SettingsTextField(
                                    controller: proxyHttpPortController,
                                    label: "端口",
                                    onChanged: (v) =>
                                        proxy.value['http_port'] = v,
                                    enabled: proxy.value['enable'],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(
                            height: 20,
                          ),
                        ],
                      ),
                      ListView(
                        children: [
                          ...ethernets.value.map((ethernet) {
                            return Card(
                              shape: RoundedRectangleBorder(
                                  side: const BorderSide(),
                                  borderRadius: BorderRadius.circular(18)),
                              margin: const EdgeInsets.only(
                                  left: 20, right: 20, top: 20),
                              // padding: EdgeInsets.symmetric(horizontal: AppConstants.paddingLarge),
                              child: ExpansionContainer(
                                title: Column(
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          "局域网${ethernets.value.indexOf(ethernet) + 1}",
                                          style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w600),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(
                                          width: 10,
                                        ),
                                        if (ethernet['status'] == 'connected')
                                          const Label("已联机", Colors.blue)
                                        else if (ethernet['status'] ==
                                            'disconnected')
                                          const Label("尚未联机", Colors.grey)
                                        else
                                          Label(ethernet['status'],
                                              Colors.orangeAccent),
                                      ],
                                    ),
                                    if (ethernet['status'] == 'connected')
                                      Row(
                                        children: [
                                          Text(ethernet['use_dhcp']
                                              ? 'DHCP'
                                              : '静态IP'),
                                          const SizedBox(
                                            width: 20,
                                          ),
                                          Text(ethernet['ip']),
                                        ],
                                      ),
                                  ],
                                ),
                                showFirst: false,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20, vertical: 10),
                                    child: Column(
                                      children: [
                                        Row(
                                          children: [
                                            const Text("子网掩码(mask)："),
                                            Expanded(
                                              child: Text(
                                                ethernet['mask'] == ''
                                                    ? '--'
                                                    : ethernet['mask'],
                                                textAlign: TextAlign.right,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(top: 10),
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const Text("IPv6地址："),
                                              Expanded(
                                                child: ethernet['ipv6'] !=
                                                            null &&
                                                        ethernet['ipv6']
                                                                .length >
                                                            0
                                                    ? Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .end,
                                                        children:
                                                            (ethernet['ipv6']
                                                                    as List)
                                                                .map((ipv6) {
                                                          return Text(ipv6);
                                                        }).toList(),
                                                      )
                                                    : const Text(
                                                        "--",
                                                        textAlign:
                                                            TextAlign.right,
                                                      ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(
                                          height: 10,
                                        ),
                                        Row(
                                          children: [
                                            const Text("网络状态："),
                                            Expanded(
                                              child: Text(
                                                "${ethernet['max_supported_speed']} Mb/s,${ethernet['duplex'] ? '全双工' : '半双工'}, MTU ${ethernet['mtu']}",
                                                textAlign: TextAlign.right,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                          ...pppoes.value.map((pppoe) {
                            return Card(
                              shape: RoundedRectangleBorder(
                                  side: const BorderSide(),
                                  borderRadius: BorderRadius.circular(18)),
                              margin: const EdgeInsets.only(
                                  left: 20, right: 20, top: 20),
                              // padding: EdgeInsets.symmetric(horizontal: AppConstants.paddingLarge),
                              child: ExpansionContainer(
                                title: Column(
                                  children: [
                                    Row(
                                      children: [
                                        const Text(
                                          "PPPoE",
                                          style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w600),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(
                                          width: 10,
                                        ),
                                        if (pppoe['status'] == 'connected')
                                          const Label("已联机", Colors.blue)
                                        else if (pppoe['status'] ==
                                            'disconnected')
                                          const Label("尚未联机", Colors.grey)
                                        else
                                          Label(pppoe['status'],
                                              Colors.orangeAccent),
                                      ],
                                    ),
                                    if (pppoe['status'] == 'connected')
                                      Row(
                                        children: [
                                          Text(pppoe['use_dhcp']
                                              ? 'DHCP'
                                              : '静态IP'),
                                          const SizedBox(
                                            width: 20,
                                          ),
                                          Text(pppoe['ip']),
                                        ],
                                      ),
                                  ],
                                ),
                                showFirst: false,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20, vertical: 10),
                                    child: Column(
                                      children: [
                                        Row(
                                          children: [
                                            const Text("子网掩码(mask)："),
                                            Expanded(
                                              child: Text(
                                                pppoe['mask'] == ''
                                                    ? '--'
                                                    : pppoe['mask'],
                                                textAlign: TextAlign.right,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(top: 10),
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const Text("IPv6地址："),
                                              Expanded(
                                                child: pppoe['ipv6'] != null &&
                                                        pppoe['ipv6'].length > 0
                                                    ? Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .end,
                                                        children: (pppoe['ipv6']
                                                                as List)
                                                            .map((ipv6) {
                                                          return Text(ipv6);
                                                        }).toList(),
                                                      )
                                                    : const Text(
                                                        "--",
                                                        textAlign:
                                                            TextAlign.right,
                                                      ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (pppoe['status'] == 'connected')
                                          Padding(
                                            padding:
                                                const EdgeInsets.only(top: 10),
                                            child: Row(
                                              children: [
                                                const Text("网络状态："),
                                                Expanded(
                                                  child: Text(
                                                    "${pppoe['max_supported_speed']} Mb/s,${pppoe['duplex'] ? '全双工' : '半双工'}, MTU ${pppoe['mtu']}",
                                                    textAlign: TextAlign.right,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                      const Center(
                        child: Text("开发中"),
                      ),
                      const Center(
                        child: Text("开发中"),
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
