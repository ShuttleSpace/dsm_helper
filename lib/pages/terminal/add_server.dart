import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:garden/pages/common/device_finder.dart';
import 'package:garden/util/function.dart';
import 'package:garden/widgets/neu_back_button.dart';
import 'package:flutter/material.dart';

class AddServer extends StatefulWidget {
  final int index;
  AddServer({this.index = 0});
  @override
  _AddServerState createState() => _AddServerState();
}

class _AddServerState extends State<AddServer> {
  List servers = [];

  String host = "";
  String account = "";
  String password = "";
  String port = "22";

  TextEditingController _hostController = TextEditingController();
  TextEditingController _accountController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();
  TextEditingController _portController = TextEditingController(text: "22");

  @override
  void initState() {
    getData();
    super.initState();
  }

  getData() async {
    String str = await Util.instance.getStorage("terminal_servers") ?? '';
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
    Util.instance.setStorage("terminal_servers", jsonEncode(servers));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: AppBackButton(context),
        title: Text("添加服务器"),
        actions: [
          Padding(
            padding: EdgeInsetsGeometry.only(right: 10, top: 8, bottom: 8),
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                minimumSize: Size(36, 36),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: () async {
                FocusScope.of(context).unfocus();
                final result = await Navigator.of(context).push(
                  CupertinoPageRoute(
                    builder: (context) {
                      return DeviceFinder(
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
                    Util.instance.toast("已选择设备: ${data['name'] ?? host}");
                  } catch (e) {
                    debugPrint("Error parsing device info: $e");
                    Util.instance.toast("解析设备信息失败");
                  }
                }
              },
              child: Icon(
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
          padding: EdgeInsets.all(20),
          children: <Widget>[
            SizedBox(
              height: 20,
            ),
            Card(
              shape: RoundedRectangleBorder(
                  side: BorderSide(), borderRadius: BorderRadius.circular(18)),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: TextField(
                        controller: _hostController,
                        onChanged: (v) => host = v,
                        autocorrect: false,
                        decoration: InputDecoration(
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
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          labelText: '端口',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(
              height: 20,
            ),
            Card(
              shape: RoundedRectangleBorder(
                  side: BorderSide(), borderRadius: BorderRadius.circular(18)),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  controller: _accountController,
                  onChanged: (v) => account = v,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    labelText: '账号',
                  ),
                ),
              ),
            ),
            SizedBox(
              height: 20,
            ),
            Card(
              shape: RoundedRectangleBorder(
                  side: BorderSide(), borderRadius: BorderRadius.circular(18)),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  controller: _passwordController,
                  onChanged: (v) => password = v,
                  obscureText: true,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    labelText: '密码',
                  ),
                ),
              ),
            ),
            SizedBox(
              height: 20,
            ),
            // SizedBox(
            //   height: 20,
            // ),
            OutlinedButton(
              onPressed: _save,
              child: Text(
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
