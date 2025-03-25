import 'dart:convert';

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
