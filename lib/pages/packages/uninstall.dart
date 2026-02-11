import 'dart:convert';
import 'package:garden/util/log.dart';
import 'package:garden/util/ui_util.dart';

import 'package:garden/util/http_util.dart';
import 'package:garden/extensions/context.dart';
import 'package:garden/widgets/neu_back_button.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:garden/constants/app_constants.dart';

class UninstallPackage extends StatefulWidget {
  final Map package;
  const UninstallPackage(this.package, {super.key});
  @override
  UninstallPackageState createState() => UninstallPackageState();
}

class UninstallPackageState extends State<UninstallPackage> {
  bool loading = true;
  bool uninstalling = false;
  List pageData = [];
  @override
  void initState() {
    getData();
    super.initState();
  }

  getData() async {
    var res = await DsmApi.uninstallPackageInfo(widget.package['id']);
    if (res['success']) {
      setState(() {
        loading = false;
        pageData = jsonDecode(
            Uri.decodeComponent(res['data']['additional']['uninstall_pages']));
        Log.info(pageData);
      });
    } else {
      UiUtil.toast("获取卸载信息失败，代码${res['error']['code']}");
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
        shape: context.stadiumShapeBorder,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Expanded(
                child: Text(item['desc']),
              ),
              Card(
                shape: RoundedRectangleBorder(
                    side: const BorderSide(),
                    borderRadius: BorderRadius.circular(18)),
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.paddingSmall),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: item['checked']
                        ? Icon(
                            CupertinoIcons.checkmark_alt,
                            color: Theme.of(context).colorScheme.primary,
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
          side: const BorderSide(), borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item['desc']),
            const SizedBox(
              height: 20,
            ),
            ...subItems.map(_buildSubItem),
          ],
        ),
      ),
    );
  }

  Widget _buildData(data) {
    List items = data['items'];
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            data['step_title'],
            style: const TextStyle(fontSize: 24),
          ),
          const SizedBox(
            height: 20,
          ),
          ...items.map(_buildItem),
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
          ? const Center(
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppConstants.paddingLarge),
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
                          await DsmApi.uninstallPackageTask(
                              widget.package['id'],
                              extra: extra);
                          UiUtil.toast("卸载成功");
                          if (context.mounted) {
                            // ignore: use_build_context_synchronously
                            Navigator.of(context).pop();
                            Navigator.of(context).pop();
                          }
                        },
                        // margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        child: const Text(
                          "确认卸载",
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                  ],
                ),
                if (uninstalling)
                  const Center(
                    child: CupertinoActivityIndicator(
                      radius: 14,
                    ),
                  )
              ],
            ),
    );
  }
}
