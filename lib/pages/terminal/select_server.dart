import 'dart:convert';
import 'package:garden/util/log.dart';
import 'package:garden/util/ui_util.dart';
import 'package:garden/util/storage_util.dart';

import 'package:garden/util/http_util.dart';
import 'package:garden/widgets/neu_back_button.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'add_server.dart';
import 'ssh.dart';

class SelectServer extends StatefulWidget {
  const SelectServer({super.key});

  @override
  SelectServerState createState() => SelectServerState();
}

class SelectServerState extends State<SelectServer> {
  bool loading = true;
  List servers = [];
  @override
  void initState() {
    getData();
    super.initState();
  }

  getData() async {
    String str = await StorageUtil.getString("terminal_servers") ?? '';
    setState(() {
      loading = false;
      if (str.isNotBlank) {
        servers = json.decode(str);
      } else {
        servers = [];
      }
    });
    Log.info(servers);
  }

  Widget _buildServerItem(int index) {
    var server = servers[index];
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: OutlinedButton(
        onPressed: () async {
          Navigator.of(context).push(CupertinoPageRoute(
              builder: (context) {
                return Ssh(server['host'], server['port'], server['account'],
                    server['password']);
              },
              settings: const RouteSettings(name: "ssh_client")));
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${server['account']}",
                      style: const TextStyle(fontSize: 18),
                    ),
                    const SizedBox(
                      height: 5,
                    ),
                    Text(
                      "${server['host']}:${server['port']}",
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              OutlinedButton(
                onPressed: () {
                  Navigator.of(context)
                      .push(CupertinoPageRoute(
                          builder: (context) {
                            return AddServer(index: index);
                          },
                          settings:
                              const RouteSettings(name: "add_ssh_server")))
                      .then((value) {
                    getData();
                  });
                },
                child: Image.asset(
                  "assets/icons/edit.png",
                  width: 20,
                ),
              ),
              const SizedBox(
                width: 10,
              ),
              OutlinedButton(
                onPressed: () {
                  setState(() {
                    servers.remove(server);
                  });

                  StorageUtil.setString(
                      "terminal_servers", jsonEncode(servers));
                  UiUtil.toast("删除成功");
                },
                child: Image.asset(
                  "assets/icons/delete.png",
                  width: 20,
                ),
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
        title: const Text("选择服务器"),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10, top: 8, bottom: 8),
            child: OutlinedButton(
              onPressed: () {
                Navigator.of(context)
                    .push(CupertinoPageRoute(
                        builder: (context) {
                          return const AddServer();
                        },
                        settings: const RouteSettings(name: "add_ssh_server")))
                    .then((value) {
                  getData();
                });
              },
              child: const Icon(Icons.add),
            ),
          )
        ],
      ),
      body: loading
          ? const Center(
              child: CupertinoActivityIndicator(
                radius: 14,
              ),
            )
          : servers.isNotEmpty
              ? ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemBuilder: (context, i) {
                    return _buildServerItem(i);
                  },
                  itemCount: servers.length,
                )
              : Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "未添加服务器",
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                      SizedBox(
                        width: 200,
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.of(context)
                                .push(CupertinoPageRoute(
                                    builder: (context) {
                                      return const AddServer();
                                    },
                                    settings: const RouteSettings(
                                        name: "add_ssh_server")))
                                .then((value) {
                              getData();
                            });
                          },
                          child: const Text(
                            ' 添加 ',
                            style: TextStyle(fontSize: 18),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
