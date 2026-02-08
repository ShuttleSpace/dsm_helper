import 'package:garden/util/http_util.dart';
import 'package:garden/util/file_type_util.dart';
import 'package:garden/util/ui_util.dart';
import 'package:garden/widgets/button_style.dart';
import 'package:garden/widgets/file_icon.dart';
import 'package:garden/widgets/neu_back_button.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:garden/constants/app_constants.dart';

class SelectFile extends StatefulWidget {
  final List listId;
  final String destination;
  const SelectFile(this.listId, this.destination, {super.key});
  @override
  SelectFileState createState() => SelectFileState();
}

class SelectFileState extends State<SelectFile> {
  String title = "";
  List files = [];
  List selectedFiles = [];
  int size = 0;
  @override
  void initState() {
    getData();
    super.initState();
  }

  getData() async {
    var res = await DsmApi.downloadFileList(widget.listId[0]);
    if (res['success']) {
      setState(() {
        title = res['data']['title'];
        files = res['data']['files'];
        for (var element in files) {
          selectedFiles.add(element['index']);
        }
        size = res['data']['size'];
      });
    } else {
      UiUtil.toast("获取文件列表失败，代码${res['error']['code']}");
    }
  }

  Widget _buildFileItem(file) {
    FileTypeEnum fileType =
        FileTypeUtil.toFileTypeEnum(FileTypeUtil.getFileType(file['name']));
    return GestureDetector(
      onTap: () {
        if (selectedFiles.contains(file['index'])) {
          setState(() {
            selectedFiles.remove(file['index']);
          });
        } else {
          setState(() {
            selectedFiles.add(file['index']);
          });
        }
      },
      child: Card(
        shape: context.stadiumShapeBorder,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Row(
            children: [
              const SizedBox(
                width: 20,
              ),
              FileIcon(
                fileType, //file['isdir'] ? FileType.folder :
              ),
              const SizedBox(
                width: 10,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      file['name'],
                      style: const TextStyle(
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(
                      height: 5,
                    ),
                    Text(
                      file['size'].formatSize(),
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              const SizedBox(
                width: 10,
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
                    child: selectedFiles.contains(file['index'])
                        ? Icon(
                            CupertinoIcons.checkmark_alt,
                            color: Theme.of(context).colorScheme.primary,
                          )
                        : null,
                  ),
                ),
              ),
              const SizedBox(
                width: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: AppBackButton(context),
        title: const Text("选择下载文件"),
      ),
      body: Column(
        children: [
          const SizedBox(
            height: 20,
          ),
          Card(
            shape: RoundedRectangleBorder(
                side: const BorderSide(),
                borderRadius: BorderRadius.circular(18)),
            margin: const EdgeInsets.symmetric(
                horizontal: AppConstants.paddingLarge),
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.paddingSmall),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title),
                  const SizedBox(
                    height: 10,
                  ),
                  Text(
                    size.formatSize(),
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(
            height: 20,
          ),
          // NeuCard(
          //   curveType: CurveType.flat,
          //   bevel: 20,
          //   margin: EdgeInsets.symmetric(horizontal: AppConstants.paddingLarge),
          //   decoration: NeumorphicDecoration(
          //     color: Theme.of(context).scaffoldBackgroundColor,
          //     borderRadius: BorderRadius.circular(20),
          //   ),
          //   child: Padding(
          //     padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          //     child: Row(
          //       children: [
          //         NeuCard(
          //           curveType: CurveType.flat,
          //           bevel: 5,
          //           margin: EdgeInsets.only(right: 20),
          //           decoration: NeumorphicDecoration(
          //             color: Theme.of(context).scaffoldBackgroundColor,
          //             borderRadius: BorderRadius.circular(10),
          //           ),
          //           padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          //           child: Text("全部"),
          //         ),
          //         NeuCard(
          //           curveType: CurveType.flat,
          //           bevel: 5,
          //           margin: EdgeInsets.only(right: 20),
          //           decoration: NeumorphicDecoration(
          //             color: Theme.of(context).scaffoldBackgroundColor,
          //             borderRadius: BorderRadius.circular(10),
          //           ),
          //           padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          //           child: Text("视频"),
          //         ),
          //         NeuCard(
          //           curveType: CurveType.flat,
          //           bevel: 5,
          //           margin: EdgeInsets.only(right: 20),
          //           decoration: NeumorphicDecoration(
          //             color: Theme.of(context).scaffoldBackgroundColor,
          //             borderRadius: BorderRadius.circular(10),
          //           ),
          //           padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          //           child: Text("图片"),
          //         ),
          //       ],
          //     ),
          //   ),
          // ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.paddingLarge),
              itemBuilder: (context, i) {
                return _buildFileItem(files[i]);
              },
              itemCount: files.length,
              separatorBuilder: (context, i) {
                return const SizedBox(
                  height: 20,
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: OutlinedButton(
              onPressed: () async {
                if (selectedFiles.isNotEmpty) {
                  var res = await DsmApi.downloadCreate(
                      widget.listId[0], widget.destination, selectedFiles);
                  if (res['success']) {
                    UiUtil.toast("下载任务创建成功");
                    if (context.mounted) {
                      // ignore: use_build_context_synchronously
                      Navigator.of(context).pop();
                      Navigator.of(context).pop();
                    }
                  }
                } else {
                  UiUtil.toast("请选择要下载的文件");
                }
              },
              // margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: const Text(
                "开始下载",
                style: TextStyle(fontSize: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
