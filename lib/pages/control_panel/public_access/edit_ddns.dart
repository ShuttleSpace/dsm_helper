import 'package:cool_ui/cool_ui.dart';
import 'package:humphrey_garden/util/function.dart';
import 'package:humphrey_garden/util/neu_picker.dart';
import 'package:humphrey_garden/widgets/label.dart';
import 'package:humphrey_garden/widgets/neu_back_button.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';

class EditDdns extends StatefulWidget {
  final Map? ddns;
  final List extIp;
  final List providers;
  EditDdns(this.providers, {this.extIp = const [], this.ddns});

  @override
  _EditDdnsState createState() => _EditDdnsState();
}

class _EditDdnsState extends State<EditDdns> {
  TextEditingController _hostnameController = TextEditingController();
  TextEditingController _usernameController = TextEditingController();
  Map ddns = {};
  Map statusStr = {
    "service_ddns_normal": "正常",
    "service_ddns_error_unknown": "联机失败",
    "loading": "加载中",
    "disabled": "已停用",
  };
  @override
  void initState() {
    setState(() {
      if (widget.ddns != null) {
        ddns.addAll(widget.ddns!);
      }
    });
    _hostnameController.value = TextEditingValue(text: ddns['hostname']);
    _usernameController.value = TextEditingValue(text: ddns['username']);
    if (ddns['ip'] == "0.0.0.0") {
      ddns["ip"] = "-";
    }
    if (ddns['ipv6'] == "0:0:0:0:0:0:0:0") {
      ddns['ipv6'] = "-";
    }
    super.initState();
  }

  deleteDdns() async {
    Util.instance.vibrate(FeedbackType.warning);
    showCupertinoModalPopup(
      context: context,
      builder: (context) {
        return Material(
          color: Colors.transparent,
          child: Card(
            shape: RoundedRectangleBorder(
                side: BorderSide(), borderRadius: BorderRadius.circular(36)),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      "确认删除",
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                    ),
                    SizedBox(
                      height: 12,
                    ),
                    Text(
                      "确认要删除以下DDNS？",
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.w400),
                    ),
                    SizedBox(
                      height: 22,
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () async {
                              if (widget.ddns == null) {
                                Util.instance.toast('ddns 为空!');
                                return;
                              }
                              Navigator.of(context).pop();
                              var res =
                                  await Api.ddnsDelete(widget.ddns!['id']);
                              print(res);
                              if (res['success']) {
                                Util.instance.toast("DDNS删除成功");
                                Navigator.of(context).pop(true);
                              } else {
                                Util.instance
                                    .toast("删除失败，代码:${res['error']['code']}");
                              }
                            },
                            child: Text(
                              "确认删除",
                              style: TextStyle(
                                  fontSize: 18, color: Colors.redAccent),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 20,
                        ),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () async {
                              Navigator.of(context).pop();
                            },
                            child: Text(
                              "取消",
                              style: TextStyle(fontSize: 18),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(
                      height: 8,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  bool checkForm() {
    if (ddns['provider'] == null || ddns['provider'] == "") {
      Util.instance.toast("请选择服务供应商");
      return false;
    } else if (ddns['hostname'] == null || ddns['hostname'] == "") {
      Util.instance.toast("请输入主机名称");
      return false;
    } else if (ddns['username'] == null || ddns['username'] == "") {
      Util.instance.toast("请输入用户名/电子邮件");
      return false;
    } else if (widget.ddns == null &&
        (ddns['passwd'] == null || ddns['passwd'] == "")) {
      Util.instance.toast("请输入密码/密钥");
      return false;
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: AppBackButton(context),
        title: Text("DDNS"),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 10, top: 8, bottom: 8),
            child: OutlinedButton(
              onPressed: deleteDdns,
              child: Image.asset(
                "assets/icons/delete.png",
                width: 30,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.all(20),
              children: [
                ...[
                  GestureDetector(
                    onTap: () async {
                      setState(() {
                        ddns['enable'] = !ddns['enable'];
                      });
                    },
                    child: Card(
                      shape: RoundedRectangleBorder(
                          side: BorderSide(),
                          borderRadius: BorderRadius.circular(36)),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            Text("启用支持DDNS"),
                            Spacer(),
                            if (ddns['enable'])
                              Icon(
                                CupertinoIcons.checkmark_alt,
                                color: Color(0xffff9813),
                                size: 22,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 20,
                  ),
                ],
                GestureDetector(
                  onTap: () {
                    FocusScope.of(context).unfocus();
                    return;
                    showCupertinoModalPopup(
                      context: context,
                      builder: (context) {
                        return NeuPicker(
                          widget.providers
                              .map((e) => e['provider'] as String)
                              .toList(),
                          value: widget.providers.indexWhere((element) =>
                              element['provider'] == ddns['provider']),
                          onConfirm: (v) {
                            setState(() {
                              ddns['provider'] =
                                  widget.providers[v]['provider'];
                              print(ddns['provider']);
                            });
                          },
                        );
                      },
                    );
                  },
                  child: Card(
                    shape: RoundedRectangleBorder(
                        side: BorderSide(),
                        borderRadius: BorderRadius.circular(36)),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          Text("服务供应商"),
                          Spacer(),
                          Text(
                              "${ddns['provider'] != null && ddns['provider'] != "" ? widget.providers.where((element) => element['provider'] == ddns['provider']).first['provider'] : "请选择"}"),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  height: 20,
                ),
                Card(
                  shape: RoundedRectangleBorder(
                      side: BorderSide(),
                      borderRadius: BorderRadius.circular(36)),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextField(
                      controller: _hostnameController,
                      onChanged: (v) => ddns['hostname'] = v,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        labelText: '主机名称',
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  height: 20,
                ),
                Card(
                  shape: RoundedRectangleBorder(
                      side: BorderSide(),
                      borderRadius: BorderRadius.circular(36)),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextField(
                      controller: _usernameController,
                      onChanged: (v) => ddns['username'] = v,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        labelText: '用户名/电子邮件',
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  height: 20,
                ),
                Card(
                  shape: RoundedRectangleBorder(
                      side: BorderSide(),
                      borderRadius: BorderRadius.circular(36)),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextField(
                      onChanged: (v) => ddns['passwd'] = v,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        labelText: '密码/密钥',
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  height: 20,
                ),
                Card(
                  shape: RoundedRectangleBorder(
                      side: BorderSide(),
                      borderRadius: BorderRadius.circular(36)),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        Text("外部地址(ipv4):"),
                        Spacer(),
                        Text("${ddns['ip']}"),
                      ],
                    ),
                  ),
                ),
                SizedBox(
                  height: 20,
                ),
                Card(
                  shape: RoundedRectangleBorder(
                      side: BorderSide(),
                      borderRadius: BorderRadius.circular(36)),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        Text("外部地址(ipv6):"),
                        Spacer(),
                        Text("${ddns['ipv6']}"),
                      ],
                    ),
                  ),
                ),
                //statusStr[ddns['status']] ?? ddns['status']
                SizedBox(
                  height: 20,
                ),
                Row(
                  children: [
                    Expanded(
                      child: Card(
                        shape: RoundedRectangleBorder(
                            side: BorderSide(),
                            borderRadius: BorderRadius.circular(36)),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            children: [
                              Text("状态:"),
                              SizedBox(
                                width: 10,
                              ),
                              if (ddns['status'] != null)
                                Label(
                                  statusStr[ddns['status']] ?? ddns['status'],
                                  ddns['status'] == "service_ddns_normal"
                                      ? Colors.green
                                      : Colors.red,
                                  fill: true,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 20,
                    ),
                    OutlinedButton(
                      onPressed: () async {
                        if (checkForm()) {
                          var hide = showWeuiLoadingToast(
                              context: context,
                              message: Text("测试中，请稍后"),
                              backButtonClose: true,
                              alignment: Alignment.center);
                          var res = await Api.ddnsTest(ddns);
                          hide();
                          print(res);
                          if (res['success']) {
                            setState(() {
                              ddns['status'] = res['data']['status'];
                            });
                          } else {
                            Util.instance.toast(
                                "测试失败，${res['error']['errors']},code:${res['error']['code']}");
                          }
                        }
                      },
                      child: Text("测试联机"),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SafeArea(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: OutlinedButton(
                onPressed: () async {
                  if (checkForm()) {
                    var res = await Api.ddnsSave(ddns);
                    if (res['success']) {
                      Util.instance.toast("保存成功");
                      Navigator.of(context).pop(true);
                    } else {
                      Util.instance.toast("保存失败,代码${res['error']['code']}");
                    }
                  }
                },
                child: Text(
                  ' 保存 ',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
