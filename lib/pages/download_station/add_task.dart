import 'package:garden/pages/download_station/select_file.dart';
import 'package:garden/util/ui_util.dart';
import 'package:garden/pages/file/select_folder.dart';
import 'package:garden/api/dsm_api.dart';
import 'package:garden/widgets/neu_back_button.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:garden/constants/app_constants.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:signals_hooks/signals_hooks.dart';

String _errorCode(Object e) => e is DSMException ? '${e.code}' : '-1';

class AddDownloadTask extends HookWidget {
  final String? torrentPath;
  const AddDownloadTask({super.key, this.torrentPath});

  @override
  Widget build(BuildContext context) {
    final saveFolder = useSignal("");
    final torrentPathValue = useSignal(torrentPath ?? '');
    final url = useSignal("");

    Future<void> getData() async {
      try {
        final data = await dsmDownloadStation2SettingsLocationGet();
        saveFolder.value = data['default_destination'] ?? '';
      } catch (e) {
        UiUtil.vibrate(FeedbackType.warning);
        UiUtil.toast("获取默认保存位置失败");
      }
    }

    useEffect(() {
      getData();
      return null;
    }, const []);

    return Scaffold(
      appBar: AppBar(
        leading: AppBackButton(context),
        title: const Text("创建下载任务"),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          OutlinedButton(
            onPressed: () {
              FocusScope.of(context).unfocus();
              showCupertinoModalPopup(
                context: context,
                builder: (context) {
                  return const SelectFolder(
                    multi: false,
                  );
                },
              ).then((res) {
                if (res != null && res.length == 1) {
                  saveFolder.value = res[0].substring(1);
                }
              });
            },
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "保存位置",
                        style: TextStyle(fontSize: 12),
                      ),
                      SizedBox(
                        height: 20,
                        child: Text(
                          saveFolder.value == ""
                              ? "选择保存位置"
                              : saveFolder.value,
                          style:
                              const TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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
                onChanged: (v) => url.value = v,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  labelText: '下载链接',
                ),
              ),
            ),
          ),
          const SizedBox(
            height: 20,
          ),
          OutlinedButton(
            onPressed: () async {
              FocusScope.of(context).unfocus();
              FilePickerResult? pickedFile =
                  await FilePicker.platform.pickFiles();
              if (pickedFile != null && pickedFile.count > 0) {
                String? path = pickedFile.paths[0];
                if (path == null) {
                  UiUtil.toast('文件路径为空!');
                  return;
                }
                String ext = path.split(".").last;
                if (["torrent", "nbz", "txt"].contains(ext)) {
                  torrentPathValue.value = path;
                } else {
                  UiUtil.toast("无效的种子文件");
                }
              }
            },
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "种子文件",
                        style: TextStyle(fontSize: 12),
                      ),
                      Text(
                        torrentPathValue.value == ""
                            ? "选择种子文件"
                            : torrentPathValue.value,
                        maxLines: null,
                        style:
                            const TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(
            height: 20,
          ),
          OutlinedButton(
            onPressed: () async {
              if (saveFolder.value == "") {
                UiUtil.toast("请选择保存位置");
                UiUtil.vibrate(FeedbackType.impact);
                return;
              }
              if (url.value.trim() == "" && torrentPathValue.value == "") {
                UiUtil.toast("请输入下载链接或选择种子文件");
                return;
              }
              try {
                final Map? res;
                if (torrentPathValue.value != "") {
                  res = await dsmDownloadStation2TaskCreate(
                      saveFolder.value, "file",
                      filePath: torrentPathValue.value);
                  if (res == null) {
                    UiUtil.toast("创建任务失败，code：-1");
                    return;
                  }
                  final listId = res['data']?['list_id'];
                  if (context.mounted) {
                    Navigator.of(context)
                        .push(CupertinoPageRoute(builder: (context) {
                      return SelectFile(listId, saveFolder.value);
                    }));
                  }
                } else {
                  if (url.value.trim() == "") {
                    UiUtil.toast("请输入下载链接");
                    UiUtil.vibrate(FeedbackType.light);
                    return;
                  }
                  await dsmDownloadStation2TaskCreate(
                      saveFolder.value, "url",
                      url: url.value);
                  UiUtil.toast("创建任务成功");
                  if (context.mounted) {
                    // ignore: use_build_context_synchronously
                    Navigator.of(context).pop();
                  }
                }
              } catch (e) {
                UiUtil.toast("创建任务失败，code：${_errorCode(e)}");
              }
            },
            child: const Text(
              ' 创建 ',
              style: TextStyle(fontSize: 18),
            ),
          ),
        ],
      ),
    );
  }
}
