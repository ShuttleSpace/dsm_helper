import 'dart:convert';
import 'package:garden/util/log.dart';
import 'package:garden/util/ui_util.dart';
import 'package:garden/util/storage_util.dart';

import 'package:flutter/cupertino.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:garden/pages/common/device_finder.dart';
import 'package:garden/util/http_util.dart';
import 'package:garden/widgets/neu_back_button.dart';
import 'package:flutter/material.dart';
import 'package:garden/constants/app_constants.dart';
import 'package:signals_hooks/signals_hooks.dart';

class AddServer extends HookWidget {
  final int index;
  const AddServer({super.key, this.index = 0});

  @override
  Widget build(BuildContext context) {
    final servers = useSignal<List>([]);
    final host = useSignal("");
    final account = useSignal("");
    final password = useSignal("");
    final port = useSignal("22");
    final hostController = useTextEditingController();
    final accountController = useTextEditingController();
    final passwordController = useTextEditingController();
    final portController = useTextEditingController(text: "22");

    getData() async {
      String str = await StorageUtil.getString("terminal_servers") ?? '';
      if (str.isNotBlank) {
        servers.value = json.decode(str);
        host.value = servers.value[index]['host'];
        hostController.text = host.value;
        account.value = servers.value[index]['account'];
        accountController.text = account.value;
        password.value = servers.value[index]['password'];
        passwordController.text = password.value;
        port.value = servers.value[index]['port'];
        portController.text = port.value;
      } else {
        servers.value = [];
      }
    }

    save() async {
      Map server = {
        "host": host.value,
        "port": port.value,
        "account": account.value,
        "password": password.value,
      };
      //添加服务器记录
      servers.value[index] = server;

      StorageUtil.setString("terminal_servers", jsonEncode(servers.value));
      Navigator.of(context).pop();
    }

    useEffect(() {
      getData();
      return null;
    }, const []);

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
                      return const DeviceFinder(title: "设备发现");
                    },
                  ),
                );

                if (result != null && result is String) {
                  try {
                    final data = jsonDecode(result) as Map<String, dynamic>;
                    // 用户选择的设备信息
                    host.value = data['host'] ?? '';
                    // port = data['port'] ?? (https ? '5001' : '5000');
                    hostController.value = TextEditingValue(text: host.value);
                    portController.value =
                        TextEditingValue(text: port.value);
                    UiUtil.toast("已选择设备: ${data['name'] ?? host.value}");
                  } catch (e) {
                    Log.debug("Error parsing device info: $e");
                    UiUtil.toast("解析设备信息失败");
                  }
                }
              },
              child: const Icon(
                Icons.radar,
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
                        controller: hostController,
                        onChanged: (v) => host.value = v,
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
                        onChanged: (v) => port.value = v,
                        controller: portController,
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
                  controller: accountController,
                  onChanged: (v) => account.value = v,
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
                  controller: passwordController,
                  onChanged: (v) => password.value = v,
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
              onPressed: save,
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
