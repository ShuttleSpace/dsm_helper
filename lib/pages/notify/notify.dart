import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:garden/api/dsm_api.dart';
import 'package:garden/util/log.dart';
import 'package:garden/util/ui_util.dart';
import 'package:garden/stores/connection_store.dart';

import 'package:garden/theme/app_theme.dart';
import 'package:garden/util/http_util.dart';
import 'package:garden/util/strings.dart';
import 'package:garden/widgets/expansion_container.dart';
import 'package:garden/widgets/neu_back_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:garden/constants/app_constants.dart';
import 'package:html/parser.dart';
import 'package:signals_hooks/signals_hooks.dart';

class Notify extends HookWidget {
  final List notifies;
  const Notify(this.notifies, {super.key});

  @override
  Widget build(BuildContext context) {
    final notifyGroups = useSignal<Map<String, List>>({});

    buildNotifyGroups() {
      final groups = <String, List>{};
      final dsmVersion = connectionStore.dsmVersion.value;
      final notifyStrings = connectionStore.notifyStrings.value;
      final stringsMap = connectionStore.strings.value;
      for (var notify in notifies) {
        List msgs = notify['msg'];
        List msgContent = [];
        String title = "";
        List<String> titles = notify['title'].split(":");
        if (dsmVersion == 7) {
          if (notify['title'] != null &&
              notifyStrings.containsKey(notify['title'])) {
            // Log.info(HttpUtil.notifyStrings[notify['title']]);
            title = notifyStrings[notify['title']]['title'];

            for (String content in msgs) {
              Map msgMap = json.decode(content);
              String replaceContent = notifyStrings[notify['title']]['msg'];

              replaceContent = replaceContent
                  .replaceAll("%LINK_BEGIN%", "")
                  .replaceAll("%LINK_END%", "")
                  .replaceAll("%PRE_APP_LINK%", "")
                  .replaceAll("%POST_APP_LINK%", "");

              if (replaceContent.contains("<a")) {
                var document = parse(replaceContent);

                replaceContent =
                    parse(document.body?.text).documentElement?.text ?? '';
              }

              msgMap.forEach((key, value) {
                replaceContent = replaceContent.replaceAll(key, value);
              });
              msgContent.add(replaceContent);
            }
          } else {
            Log.info("未找到");
            title =
                notify['className'] == "" ? notify['title'] : notify['className'];
            msgContent = msgs;
          }
        } else {
          //判断是否在string内
          if (webManagerStrings[titles[0]] != null &&
              webManagerStrings[titles[0]][titles[1]] != null) {
            if (webManagerStrings[titles[0]][titles[1]] != null) {
              title = webManagerStrings[titles[0]][titles[1]];
            }
            msgContent = msgs;
          } else if (stringsMap[notify['className']] != null) {
            if (stringsMap[notify['className']][titles[0]] != null &&
                stringsMap[notify['className']][titles[0]][titles[1]] != null) {
              title = stringsMap[notify['className']][titles[0]][titles[1]];
            } else if (stringsMap[notify['className']] != null &&
                stringsMap[notify['className']]['common'] != null &&
                stringsMap[notify['className']]['common']['displayname'] !=
                    null) {
              title =
                  stringsMap[notify['className']]['common']['displayname'];
            }
            msgContent = msgs;
          } else {
            Log.info("未找到");
            title =
                notify['className'] == "" ? notify['title'] : notify['className'];
            msgContent = msgs;
          }
        }
        notify['contents'] = msgContent;
        if (groups[title] == null) {
          groups[title] = [notify];
        } else {
          groups[title]?.add(notify);
        }
      }
      notifyGroups.value = groups;
    }

    useEffect(() {
      buildNotifyGroups();
      return null;
    }, const []);

    Widget buildNotifyItem(notify) {
      return Card(
        shape: RoundedRectangleBorder(
            side: const BorderSide(), borderRadius: BorderRadius.circular(18)),
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.paddingSmall),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DateTime.fromMillisecondsSinceEpoch(notify['time'] * 1000)
                    .timeAgo,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
              Column(
                children: (notify['contents'] as List).map((msg) {
                  return Text(msg);
                }).toList(),
              ),
            ],
          ),
        ),
      );
    }

    Widget buildNotifyGroup(groupName, List group) {
      return Card(
        shape: RoundedRectangleBorder(
            side: const BorderSide(), borderRadius: BorderRadius.circular(18)),
        margin: const EdgeInsets.only(left: 20, right: 20, top: 20),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.paddingSmall),
          child: ExpansionContainer(
            title: Text(
              "$groupName （${group.length}）",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
            showFirst: true,
            first: buildNotifyItem(group.first),
            trailing: const Icon(Icons.unfold_less),
            children: group.map((buildNotifyItem)).toList(),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: AppBackButton(context),
        title: const Text(
          "消息",
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: notifies.isNotEmpty
                ? ListView(
                    children: notifyGroups.value.keys.map((key) {
                      return buildNotifyGroup(
                          key, notifyGroups.value[key] ?? []);
                    }).toList(),
                  )
                : Center(
                    child: Text(
                      "暂无消息",
                      style: TextStyle(
                          color: AppTheme.of(context).placeholderColor),
                    ),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      try {
                        await dsmCoreDSMNotify('apply');
                        UiUtil.toast("清除成功");
                        // ignore: use_build_context_synchronously
                        if (context.mounted) Navigator.of(context).pop();
                      } on DSMException catch (e) {
                        UiUtil.toast("清除失败：${e.message}");
                      } on DioException catch (e) {
                        UiUtil.toast("网络错误：${e.message}");
                      }
                    },
                    child: const Text("全部清除"),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
