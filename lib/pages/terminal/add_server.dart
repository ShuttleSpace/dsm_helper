import 'dart:convert';
import 'package:garden/util/log.dart';
import 'package:garden/util/ui_util.dart';
import 'package:garden/util/storage_util.dart';

import 'package:flutter/cupertino.dart';
import 'package:garden/pages/common/device_finder.dart';
import 'package:garden/util/http_util.dart';
import 'package:garden/widgets/neu_back_button.dart';
import 'package:flutter/material.dart';
import 'package:garden/constants/app_constants.dart';

class AddServer extends StatefulWidget {
  final int index;
  const AddServer({super.key, this.index = 0});
  @override
  AddServerState createState() => AddServerState();
}

class AddServerState extends State<AddServer> {
  List servers = [];

  String host = "";
  String account = "";
  String password = "";
  String port = "22";

  final TextEditingController _hostController = TextEditingController();
  final TextEditingController _accountController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _portController =
      TextEditingController(text: "22");

  @override
  void initState() {
    getData();
    super.initState();
  }

  getData() async {
    String str = await StorageUtil.getString("terminal_servers") ?? '';
    setState(() {
      if (str.isNotBlank) {
        servers = json.decode(str);
        host = servers[widget.index]['host'];
        _hostController.text = host;
        account = servers[widget.index]['account'];
        _accountController.text = account;
        password = servers[widget.index]['password'];
        _passwordController.text = password;
        port = servers[widget.index]['port'];
        _portController.text = port;
      } else {
        servers = [];
      }
    });
    // print(servers);
  }

  _save() async {
    Map server = {
      "host": host,
      "port": port,
      "account": account,
      "password": password,
    };
    //添加服务器记录
    servers[widget.index] = server;

    // print(servers);
    StorageUtil.setString("terminal_servers", jsonEncode(servers));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: AppBackButton(context),
        title: const Text("添加服务器"),
        actions: [
          Padding(
            padding:
                const EdgeInsetsGeometry.only(right: 10, top: 8, bottom: 8),
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(36, 36),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: () async {
                FocusScope.of(context).unfocus();
                final result = await Navigator.of(context).push(
                  CupertinoPageRoute(
                    builder: (context) {
                      return const DeviceFinder(
                        url: "https://finds.synology.com",
                        title: "设备发现",
                      );
                    },
                  ),
                );

                if (result != null && result is String) {
                  try {
                    final data = jsonDecode(result) as Map<String, dynamic>;
                    // 用户选择的设备信息
                    setState(() {
                      host = data['host'] ?? '';
                      // port = data['port'] ?? (https ? '5001' : '5000');
                      _hostController.value = TextEditingValue(text: host);
                      _portController.value = TextEditingValue(text: port);
                    });
                    UiUtil.toast("已选择设备: ${data['name'] ?? host}");
                  } catch (e) {
                    Log.debug("Error parsing device info: $e");
                    UiUtil.toast("解析设备信息失败");
                  }
                }
              },
              child: const Icon(
                Icons.open_in_browser,
                size: 20,
              ),
            ),
          )
        ],
      ),
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: <Widget>[
            const SizedBox(
              height: 20,
            ),
            Card(
              shape: RoundedRectangleBorder(
                  side: const BorderSide(),
                  borderRadius: BorderRadius.circular(18)),
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.paddingSmall),
                child: Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: TextField(
                        controller: _hostController,
                        onChanged: (v) => host = v,
                        autocorrect: false,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          labelText: '网址/IP',
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: TextField(
                        onChanged: (v) => port = v,
                        controller: _portController,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          labelText: '端口',
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
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.paddingSmall),
                child: TextField(
                  controller: _accountController,
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
                padding: const EdgeInsets.all(AppConstants.paddingSmall),
                child: TextField(
                  controller: _passwordController,
                  onChanged: (v) => password = v,
                  obscureText: true,
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
            // SizedBox(
            //   height: 20,
            // ),
            OutlinedButton(
              onPressed: _save,
              child: const Text(
                ' 保存 ',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
