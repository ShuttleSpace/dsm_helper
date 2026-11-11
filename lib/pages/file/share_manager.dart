import 'package:garden/pages/file/share.dart';
import 'package:garden/util/file_type_util.dart';
import 'package:garden/util/http_util.dart';
import 'package:garden/util/log.dart';
import 'package:garden/widgets/file_icon.dart';
import 'package:garden/widgets/label.dart';
import 'package:garden/widgets/neu_back_button.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:garden/constants/app_constants.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:signals_hooks/signals_hooks.dart';

class ShareManager extends HookWidget {
  const ShareManager({super.key});

  @override
  Widget build(BuildContext context) {
    final links = useSignal<List>([]);
    final loading = useSignal(true);

    getData() async {
      var res = await DsmApi.listShare();
      Log.info(res);
      if (res['success']) {
        loading.value = false;
        links.value = res['data']['links'];
      }
    }

    useEffect(() {
      getData();
      return null;
    }, const []);

  Widget buildLinkItem(link) {
    FileTypeEnum fileType =
        FileTypeUtil.toFileTypeEnum(FileTypeUtil.getFileType(link['path']));
    return Padding(
      padding:
          const EdgeInsets.symmetric(vertical: AppConstants.paddingSmall + 2),
      child: OutlinedButton(
        onPressed: () {
          Navigator.of(context)
              .push(CupertinoPageRoute(
                  builder: (context) {
                    return Share(
                      link: link,
                    );
                  },
                  settings: const RouteSettings(name: "share")))
              .then((res) {
            loading.value = true;
            getData();
          });
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                link['isFolder']
                    ? Image.asset(
                        "assets/icons/folder.png",
                        width: 20,
                      )
                    : FileIcon(
                        fileType,
                        thumb: link['path'],
                      ),
                const SizedBox(
                  width: 5,
                ),
                Text(
                  link['name'],
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
            const SizedBox(
              height: 10,
            ),
            Row(
              children: [
                Label(
                    link['status'] == "valid"
                        ? "有效"
                        : link['status'] == "expired"
                            ? "过期"
                            : link['status'] == "inactive"
                                ? "未生效"
                                : link['status'],
                    link['status'] == "valid" ? Colors.green : Colors.red),
                const SizedBox(
                  width: 5,
                ),
                link['enable_upload']
                    ? const Label(
                        "文件请求",
                        Colors.lightBlueAccent,
                        fill: true,
                      )
                    : const Label(
                        "共享链接",
                        Colors.greenAccent,
                        fill: true,
                      ),
              ],
            ),
          ],
        ),
      ),
    );
  }

    return Scaffold(
      appBar: AppBar(
        leading: AppBackButton(context),
        title: const Text(
          "共享链接管理",
        ),
      ),
      body: loading.value
          ? const Center(
              child: CupertinoActivityIndicator(
                radius: 14,
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              itemBuilder: (context, i) {
                return buildLinkItem(links.value[i]);
              },
              itemCount: links.value.length,
            ),
    );
  }
}
