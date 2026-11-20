import 'dart:convert';
import 'package:garden/api/dsm_api.dart';
import 'package:garden/util/ui_util.dart';
import 'package:garden/widgets/neu_back_button.dart';
import 'package:flutter/cupertino.dart';
import 'package:garden/widgets/bottom_confirm_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:signals_hooks/signals_hooks.dart';

class Users extends HookWidget {
  const Users({super.key});

  @override
  Widget build(BuildContext context) {
    final loading = useSignal(true);
    final users = useSignal<List>([]);

    getData() async {
      try {
        final data = await dsmCoreCurrentConnectionGet('enum',
            offset: 0,
            limit: 50,
            start: 0,
            sortBy: 'time',
            sortDirection: 'DESC');
        users.value = data['items'] ?? [];
        loading.value = false;
      } catch (e) {
        final code = e is DSMException ? e.code : -1;
        UiUtil.toast("获取目前连接用户失败，代码$code");
        if (context.mounted) {
          // ignore: use_build_context_synchronously
          Navigator.of(context).pop();
        }
      }
    }

    useEffect(() {
      getData();
      return null;
    }, const []);

    Widget buildUserItem(user) {
      user['running'] = user['running'] ?? false;
      return Card(
        shape: RoundedRectangleBorder(
            side: const BorderSide(), borderRadius: BorderRadius.circular(18)),
        margin: const EdgeInsets.only(top: 20, left: 20, right: 20),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            "${user['who']}",
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 18),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            "${user['time']}",
                            textAlign: TextAlign.right,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    Row(
                      children: [
                        //from
                        Expanded(
                          flex: 2,
                          child: Text(
                            "${user['type']}",
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            "${user['from']}",
                            textAlign: TextAlign.right,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            "${user['descr']}",
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(
                width: 10,
              ),
              OutlinedButton(
                onPressed: () async {
                  if (user['running']) {
                    return;
                  }
                  showCupertinoModalPopup(
                    context: context,
                    builder: (context) => BottomConfirmSheet(
                      title: "终止连接",
                      content: "确认要终止此连接？",
                      confirmText: "终止连接",
                      textColor: Colors.black,
                      padding: 20,
                      buttonSpacing: 16,
                      onConfirm: () async {
                        user['running'] = true;
                        users.value = List.of(users.value);
                        try {
                          await dsmControlPanelPost({
                            "api": '"SYNO.Core.CurrentConnection"',
                            "method": '"kick_connection"',
                            "version": 1,
                            "http_conn": jsonEncode(
                                {"who": user['who'], "from": user['from']}),
                            "service_conn": "[]",
                          });
                          UiUtil.toast("连接已终止");
                        } catch (e) {
                          // 旧层失败时静默。
                        } finally {
                          user['running'] = false;
                          users.value = List.of(users.value);
                        }
                      },
                    ),
                  );
                },
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: user['running']
                      ? const CupertinoActivityIndicator()
                      : const Icon(
                          Icons.remove_circle_outline,
                          color: Colors.red,
                          size: 18,
                        ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: AppBackButton(context),
        title: const Text("目前连接用户"),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10, top: 8, bottom: 8),
            child: OutlinedButton(
              onPressed: () {
                getData();
              },
              child: const Icon(Icons.refresh),
            ),
          ),
        ],
      ),
      body: loading.value
          ? const Center(
              child: CupertinoActivityIndicator(
                radius: 14,
              ),
            )
          : ListView.separated(
              itemBuilder: (context, i) {
                return buildUserItem(users.value[i]);
              },
              itemCount: users.value.length,
              separatorBuilder: (context, i) {
                return const SizedBox(
                  height: 20,
                );
              },
            ),
    );
  }
}
