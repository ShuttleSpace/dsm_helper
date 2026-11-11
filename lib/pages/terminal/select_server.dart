import 'dart:convert';
import 'package:garden/util/log.dart';
import 'package:garden/util/ui_util.dart';
import 'package:garden/util/storage_util.dart';

import 'package:garden/util/http_util.dart';
import 'package:garden/widgets/neu_back_button.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:signals_hooks/signals_hooks.dart';
import 'add_server.dart';
import 'ssh.dart';

class SelectServer extends HookWidget {
  const SelectServer({super.key});

  @override
  Widget build(BuildContext context) {
    final loading = useSignal(true);
    final servers = useSignal<List>([]);

    getData() async {
      String str = await StorageUtil.getString("terminal_servers") ?? '';
      loading.value = false;
      if (str.isNotBlank) {
        servers.value = json.decode(str);
      } else {
        servers.value = [];
      }
      Log.info(servers.value);
    }

    Widget buildServerItem(int index) {
      var server = servers.value[index];
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
                        style: const TextStyle(
                            fontSize: 16, color: Colors.grey),
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
                    servers.value = List.of(servers.value)..remove(server);

                    StorageUtil.setString(
                        "terminal_servers", jsonEncode(servers.value));
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

    useEffect(() {
      getData();
      return null;
    }, const []);

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
      body: loading.value
          ? const Center(
              child: CupertinoActivityIndicator(
                radius: 14,
              ),
            )
          : servers.value.isNotEmpty
              ? ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemBuilder: (context, i) {
                    return buildServerItem(i);
                  },
                  itemCount: servers.value.length,
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
