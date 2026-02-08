import 'package:garden/util/http_util.dart';
import 'package:garden/util/log.dart';
import 'package:garden/widgets/bubble_tab_indicator.dart';
import 'package:garden/widgets/expansion_container.dart';
import 'package:garden/widgets/label.dart';
import 'package:garden/widgets/neu_back_button.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:garden/constants/app_constants.dart';

class Network extends StatefulWidget {
  const Network({super.key});

  @override
  NetworkState createState() => NetworkState();
}

class NetworkState extends State<Network> with SingleTickerProviderStateMixin {
  final TextEditingController _serverNameController = TextEditingController();
  final TextEditingController _dnsPrimaryController = TextEditingController();
  final TextEditingController _dnsSecondaryController = TextEditingController();
  final TextEditingController _proxyHttpHostController =
      TextEditingController();
  final TextEditingController _proxyHttpPortController =
      TextEditingController();
  late TabController _tabController;
  Map network = {};
  Map proxy = {};
  Map gateway = {};
  Map dsm = {};
  List ethernets = [];
  List pppoes = [];
  bool loading = true;
  @override
  void initState() {
    _tabController = TabController(length: 5, vsync: this);
    getData();
    super.initState();
  }

  getData() async {
    var res = await DsmApi.networkStatus();
    if (res['success']) {
      setState(() {
        loading = false;
      });
      List result = res['data']['result'];
      for (var item in result) {
        if (item['success'] == true) {
          switch (item['api']) {
            case "SYNO.Core.Network":
              setState(() {
                if (item['data'] != null) {
                  network = item['data'];
                  _serverNameController.value =
                      TextEditingValue(text: network['server_name']);
                  _dnsPrimaryController.value =
                      TextEditingValue(text: network['dns_primary']);
                  _dnsSecondaryController.value =
                      TextEditingValue(text: network['dns_secondary']);
                }
              });
              break;
            case "SYNO.Core.Network.Ethernet":
              setState(() {
                ethernets = item['data'];
              });
              break;
            case "SYNO.Core.Network.PPPoE":
              setState(() {
                pppoes = item['data'];
              });
              break;
            case "SYNO.Core.Network.Proxy":
              setState(() {
                proxy = item['data'];
                _proxyHttpHostController.value =
                    TextEditingValue(text: proxy['http_host']);
                _proxyHttpPortController.value =
                    TextEditingValue(text: proxy['http_port']);
              });
              break;
            case "SYNO.Core.Network.Router.Gateway.List":
              setState(() {
                gateway = item['data'];
              });
              break;
            case "SYNO.Core.Web.DSM":
              setState(() {
                dsm = item['data'];
                Log.info("Web.DSM: $dsm");
              });
              break;
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: AppBackButton(context),
        title: const Text("网络"),
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
                    controller: _tabController,
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
                                  Card(
                                    shape: RoundedRectangleBorder(
                                        side: const BorderSide(),
                                        borderRadius:
                                            BorderRadius.circular(18)),
                                    child: Padding(
                                      padding: const EdgeInsets.all(
                                          AppConstants.paddingSmall),
                                      child: TextField(
                                        controller: _serverNameController,
                                        onChanged: (v) =>
                                            network['server_name'] = v,
                                        decoration: const InputDecoration(
                                          border: InputBorder.none,
                                          labelText: '系统名称',
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(
                                    height: 20,
                                  ),
                                  Text("默认网关(gateway): ${network['gateway']}"),
                                  const SizedBox(
                                    height: 5,
                                  ),
                                  Text(
                                      "IPv6默认网关: ${network['v6gateway'] == "" ? "-" : network['v6gateway']}"),
                                  const SizedBox(
                                    height: 20,
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      FocusScope.of(context).unfocus();
                                      setState(() {
                                        network['dns_manual'] =
                                            !network['dns_manual'];
                                      });
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
                                            if (network['dns_manual'])
                                              Icon(
                                                CupertinoIcons.checkmark_alt,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .primary,
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
                                  Card(
                                    shape: RoundedRectangleBorder(
                                        side: const BorderSide(),
                                        borderRadius:
                                            BorderRadius.circular(18)),
                                    child: Padding(
                                      padding: const EdgeInsets.all(
                                          AppConstants.paddingSmall),
                                      child: TextField(
                                        controller: _dnsPrimaryController,
                                        enabled: network['dns_manual'],
                                        onChanged: (v) =>
                                            network['dns_primary'] = v,
                                        decoration: const InputDecoration(
                                          border: InputBorder.none,
                                          labelText: '首选DNS服务器',
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
                                        borderRadius:
                                            BorderRadius.circular(18)),
                                    child: Padding(
                                      padding: const EdgeInsets.all(
                                          AppConstants.paddingSmall),
                                      child: TextField(
                                        controller: _dnsSecondaryController,
                                        enabled: network['dns_manual'],
                                        onChanged: (v) =>
                                            network['dns_secondary'] = v,
                                        decoration: const InputDecoration(
                                          border: InputBorder.none,
                                          labelText: '备用DNS服务器',
                                        ),
                                      ),
                                    ),
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
                                      setState(() {
                                        proxy['enable'] = !proxy['enable'];
                                      });
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
                                            if (proxy['enable'])
                                              Icon(
                                                CupertinoIcons.checkmark_alt,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .primary,
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
                                  Card(
                                    shape: RoundedRectangleBorder(
                                        side: const BorderSide(),
                                        borderRadius:
                                            BorderRadius.circular(18)),
                                    child: Padding(
                                      padding: const EdgeInsets.all(
                                          AppConstants.paddingSmall),
                                      child: TextField(
                                        controller: _proxyHttpHostController,
                                        enabled: proxy['enable'],
                                        onChanged: (v) =>
                                            proxy['http_host'] = v,
                                        decoration: const InputDecoration(
                                          border: InputBorder.none,
                                          labelText: '地址',
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
                                        borderRadius:
                                            BorderRadius.circular(18)),
                                    child: Padding(
                                      padding: const EdgeInsets.all(
                                          AppConstants.paddingSmall),
                                      child: TextField(
                                        controller: _proxyHttpPortController,
                                        enabled: proxy['enable'],
                                        onChanged: (v) =>
                                            proxy['http_port'] = v,
                                        decoration: const InputDecoration(
                                          border: InputBorder.none,
                                          labelText: '端口',
                                        ),
                                      ),
                                    ),
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
                          ...ethernets.map((ethernet) {
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
                                          "局域网${ethernets.indexOf(ethernet) + 1}",
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
                          ...pppoes.map((pppoe) {
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
