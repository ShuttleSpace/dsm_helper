import 'dart:convert';
import 'package:garden/util/log.dart';
import 'package:garden/util/ui_util.dart';

import 'package:garden/api/dsm_api.dart';
import 'package:garden/widgets/neu_back_button.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:garden/constants/app_constants.dart';
import 'package:garden/theme/app_colors.dart';
import 'package:signals_hooks/signals_hooks.dart';

class UninstallPackage extends HookWidget {
  final Map package;
  const UninstallPackage(this.package, {super.key});

  @override
  Widget build(BuildContext context) {
    final loading = useSignal(true);
    final uninstalling = useSignal(false);
    final pageData = useSignal<List>([]);
    final rebuild = useSignal(0);

    getData() async {
      try {
        final data = await dsmControlPanelPost({
          "id": package['id'],
          "additional": jsonEncode(["uninstall_pages"]),
          "api": "SYNO.Core.Package",
          "version": 1,
          "method": "get",
        });
        final additional = (data['additional'] as Map?) ?? const {};
        pageData.value =
            jsonDecode(Uri.decodeComponent(additional['uninstall_pages']));
        Log.info(pageData.value);
      } catch (e) {
        final code = e is DSMException ? e.code : -1;
        UiUtil.toast("获取卸载信息失败，代码$code");
      } finally {
        loading.value = false;
      }
    }

    Widget buildSubItem(item) {
      item['checked'] = item['checked'] ?? false;
      return GestureDetector(
        onTap: () {
          item['checked'] = !item['checked'];
          rebuild.value++;
        },
        child: Card(
          shape: RoundedRectangleBorder(
              side: const BorderSide(),
              borderRadius: BorderRadius.circular(18)),
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
                          ? const Icon(
                              CupertinoIcons.checkmark_alt,
                              color: AppColors.primaryAction,
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

    Widget buildItem(item) {
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
              ...subItems.map(buildSubItem),
            ],
          ),
        ),
      );
    }

    Widget buildData(data) {
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
            ...items.map(buildItem),
          ],
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
        title: Text(
          "卸载${package['dname']}",
        ),
      ),
      body: loading.value
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
                          return buildData(pageData.value[i]);
                        },
                        itemCount: pageData.value.length,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppConstants.paddingLarge),
                      child: OutlinedButton(
                        onPressed: () async {
                          //获取额外参数
                          Map extra = {};
                          for (int i = 0; i < pageData.value.length; i++) {
                            for (int j = 0;
                                j < pageData.value[i]['items'].length;
                                j++) {
                              for (int k = 0;
                                  k <
                                      pageData.value[i]['items'][j]['subitems']
                                          .length;
                                  k++) {
                                if (pageData.value[i]['items'][j]['subitems'][k]
                                    ['checked']) {
                                  extra[pageData.value[i]['items'][j]
                                          ['subitems'][i]['key']] =
                                      pageData.value[i]['items'][j]
                                          ['subitems'][i]['checked'];
                                }
                              }
                            }
                          }
                          uninstalling.value = true;
                          await dsmCorePackageUninstallTaskForPage(
                              package['id'],
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
                if (uninstalling.value)
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
