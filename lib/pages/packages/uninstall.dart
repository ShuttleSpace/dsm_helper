import 'dart:convert';

import 'package:garden/util/function.dart';
import 'package:garden/widgets/neu_back_button.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class UninstallPackage extends StatefulWidget {
  final Map package;
  UninstallPackage(this.package);
  @override
  _UninstallPackageState createState() => _UninstallPackageState();
}

class _UninstallPackageState extends State<UninstallPackage> {
  bool loading = true;
  bool uninstalling = false;
  List pageData = [];
  @override
  void initState() {
    getData();
    super.initState();
  }

  getData() async {
    var res = await Api.uninstallPackageInfo(widget.package['id']);
    if (res['success']) {
      setState(() {
        loading = false;
        pageData = jsonDecode(
            Uri.decodeComponent(res['data']['additional']['uninstall_pages']));
        print(pageData);
      });
    } else {
      Util.instance.toast("获取卸载信息失败，代码${res['error']['code']}");
    }
  }

  Widget _buildSubItem(item) {
    item['checked'] = item['checked'] ?? false;
    return GestureDetector(
      onTap: () {
        setState(() {
          item['checked'] = !item['checked'];
        });
      },
      child: Card(
        shape: RoundedRectangleBorder(
            side: BorderSide(), borderRadius: BorderRadius.circular(18)),
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Row(
            children: [
              Expanded(
                child: Text(item['desc']),
              ),
              Card(
                shape: RoundedRectangleBorder(
                    side: BorderSide(),
                    borderRadius: BorderRadius.circular(18)),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: item['checked']
                        ? Icon(
                            CupertinoIcons.checkmark_alt,
                            color: Color(0xffff9813),
                          )
                        : null,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItem(item) {
    List subItems = item['subitems'];
    return Card(
      shape: RoundedRectangleBorder(
          side: BorderSide(), borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item['desc']),
            SizedBox(
              height: 20,
            ),
            ...subItems.map(_buildSubItem).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildData(data) {
    List items = data['items'];
    return Padding(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            data['step_title'],
            style: TextStyle(fontSize: 24),
          ),
          SizedBox(
            height: 20,
          ),
          ...items.map(_buildItem).toList(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: AppBackButton(context),
        title: Text(
          "卸载${widget.package['dname']}",
        ),
      ),
      body: loading
          ? Center(
              child: CupertinoActivityIndicator(
                radius: 14,
              ),
            )
          : Stack(
              children: [
                Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        itemBuilder: (context, i) {
                          return _buildData(pageData[i]);
                        },
                        itemCount: pageData.length,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: OutlinedButton(
                        onPressed: () async {
                          //获取额外参数
                          Map extra = {};
                          for (int i = 0; i < pageData.length; i++) {
                            for (int j = 0;
                                j < pageData[i]['items'].length;
                                j++) {
                              for (int k = 0;
                                  k <
                                      pageData[i]['items'][j]['subitems']
                                          .length;
                                  k++) {
                                if (pageData[i]['items'][j]['subitems'][k]
                                    ['checked']) {
                                  extra[pageData[i]['items'][j]['subitems'][i]
                                          ['key']] =
                                      pageData[i]['items'][j]['subitems'][i]
                                          ['checked'];
                                }
                              }
                            }
                          }
                          setState(() {
                            uninstalling = true;
                          });
                          await Api.uninstallPackageTask(widget.package['id'],
                              extra: extra);
                          Util.instance.toast("卸载成功");
                          Navigator.of(context).pop();
                          Navigator.of(context).pop();
                        },
                        // margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        child: Text(
                          "确认卸载",
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 20,
                    ),
                  ],
                ),
                if (uninstalling)
                  Center(
                    child: CupertinoActivityIndicator(
                      radius: 14,
                    ),
                  )
              ],
            ),
    );
  }
}
