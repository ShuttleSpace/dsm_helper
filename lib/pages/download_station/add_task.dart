import 'package:garden/extensions/map.dart';
import 'package:garden/pages/download_station/select_file.dart';
import 'package:garden/util/ui_util.dart';
import 'package:garden/pages/file/select_folder.dart';
import 'package:garden/util/http_util.dart';
import 'package:garden/widgets/neu_back_button.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:garden/constants/app_constants.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';

class AddDownloadTask extends StatefulWidget {
  final String? torrentPath;
  const AddDownloadTask({super.key, this.torrentPath});
  @override
  AddDownloadTaskState createState() => AddDownloadTaskState();
}

class AddDownloadTaskState extends State<AddDownloadTask> {
  String saveFolder = "";
  String torrentPath = "";
  String url = "";
  @override
  void initState() {
    setState(() {
      torrentPath = widget.torrentPath ?? '';
    });
    getData();
    super.initState();
  }

  getData() async {
    var res = await DsmApi.downloadLocation();
    if (res['success']) {
      setState(() {
        saveFolder = res['data']['default_destination'];
      });
    } else {
      UiUtil.vibrate(FeedbackType.warning);
      UiUtil.toast("获取默认保存位置失败");
    }
  }

  @override
  Widget build(BuildContext context) {
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
                  setState(() {
                    saveFolder = res[0].substring(1);
                  });
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
                          saveFolder == "" ? "选择保存位置" : saveFolder,
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
                onChanged: (v) => url = v,
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
                  setState(() {
                    torrentPath = path;
                  });
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
                        torrentPath == "" ? "选择种子文件" : torrentPath,
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
              if (saveFolder == "") {
                UiUtil.toast("请选择保存位置");
                UiUtil.vibrate(FeedbackType.impact);
                return;
              }
              if (url.trim() == "" && torrentPath == "") {
                UiUtil.toast("请输入下载链接或选择种子文件");
                return;
              }
              Map<dynamic, dynamic>? res;
              if (torrentPath != "") {
                res = await DsmApi.downloadTaskCreate(saveFolder, "file",
                    filePath: torrentPath);
                if (res == null || res.containsKey("success") == false) {
                  UiUtil.toast(
                      "创建任务失败，code：${res?.getMap("error")?.getOrNull("code")}");
                } else {
                  if (context.mounted) {
                    Navigator.of(context)
                        .push(CupertinoPageRoute(builder: (context) {
                      return SelectFile(res!['data']['list_id'], saveFolder);
                    }));
                  }
                }
              } else {
                if (url.trim() == "") {
                  UiUtil.toast("请输入下载链接");
                  UiUtil.vibrate(FeedbackType.light);
                  return;
                }
                res = await DsmApi.downloadTaskCreate(saveFolder, "url",
                    url: url);
                if (res == null || res.containsKey("success") == false) {
                  UiUtil.toast(
                      "创建任务失败，code：${res?.getMap("error")?.getOrNull("code")}");
                } else {
                  UiUtil.toast("创建任务成功");
                  if (context.mounted) {
                    // ignore: use_build_context_synchronously
                    Navigator.of(context).pop();
                  }
                }
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
