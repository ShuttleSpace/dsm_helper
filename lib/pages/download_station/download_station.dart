import 'dart:async';
import 'package:garden/util/file_type_util.dart';

import 'package:garden/pages/download_station/add_task.dart';
import 'package:garden/pages/download_station/detail.dart';
import 'package:garden/theme/app_colors.dart';
import 'package:garden/theme/app_theme.dart';
import 'package:garden/util/http_util.dart';
import 'package:garden/widgets/file_icon.dart';
import 'package:garden/widgets/animation_progress_bar.dart';
import 'package:garden/widgets/neu_back_button.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class DownloadStation extends StatefulWidget {
  const DownloadStation({super.key});

  @override
  DownloadStationState createState() => DownloadStationState();
}

class DownloadStationState extends State<DownloadStation> {
  bool loading = true;
  late Timer timer;
  List tasks = [];
  int downloadRate = 0;
  int uploadRate = 0;
  Map<String, bool> pauseLoading = {};
  @override
  void initState() {
    timer = Timer.periodic(const Duration(seconds: 10), (timer) {
      getData();
    });
    getData();
    super.initState();
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }

  getData() async {
    var res = await DsmApi.downloadStationInfo();
    if (!mounted) {
      return;
    }
    setState(() {
      loading = false;
    });
    if (res['success']) {
      List result = res['data']['result'];
      for (var item in result) {
        if (item['success'] == true) {
          switch (item['api']) {
            case "SYNO.DownloadStation2.Task":
              setState(() {
                tasks = item['data']['task'];
              });
              break;
            case "SYNO.DownloadStation2.Task.Statistic":
              setState(() {
                downloadRate = item['data']['download_rate'];
                uploadRate = item['data']['upload_rate'];
              });
              break;
          }
        }
      }
    }
  }

  Widget _buildDownloadItem(download) {
    pauseLoading[download['id']] = pauseLoading[download['id']] ?? false;
    FileTypeEnum fileType = FileTypeUtil.toFileTypeEnum(
        FileTypeUtil.getFileType(download['title']));
    return GestureDetector(
      onTap: () {
        Navigator.of(context)
            .push(
          CupertinoPageRoute(
            builder: (context) {
              return DownloadDetail(download['id']);
            },
            settings: const RouteSettings(name: "download_detail"),
          ),
        )
            .then((res) {
          if (res != null && res) {
            getData();
          }
        });
      },
      child: Card(
        shape: RoundedRectangleBorder(
            side: const BorderSide(), borderRadius: BorderRadius.circular(18)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                children: [
                  FileIcon(fileType),
                  const SizedBox(
                    width: 10,
                  ),
                  Expanded(
                    child: Text(
                      "${download['title']}",
                      style: const TextStyle(fontSize: 16),
                      maxLines: 3,
                    ),
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  SizedBox(
                    width: 35,
                    child: download['status'] == 2 ||
                            download['status'] == 3 ||
                            download['status'] > 100
                        ? GestureDetector(
                            onTap: () async {
                              setState(() {
                                pauseLoading[download['id']] = true;
                              });
                              var res = await DsmApi.downloadTaskAction(
                                  [download['id']],
                                  download['status'] == 2 ? "pause" : "resume");
                              setState(() {
                                pauseLoading[download['id']] = false;
                              });
                              if (res['success']) {
                                getData();
                              }
                            },
                            child: pauseLoading[download['id']] == true
                                ? const CupertinoActivityIndicator()
                                : Icon(
                                    download['status'] == 2
                                        ? Icons.pause_circle_outline_sharp
                                        : Icons.play_circle_outline_sharp,
                                    color: download['status'] == 2
                                        ? Colors.red
                                        : Colors.green,
                                  ),
                          )
                        : Container(
                            // child: Text("${download['status']}"),
                            ),
                  ),
                ],
              ),
              const SizedBox(
                height: 5,
              ),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text.rich(
                      TextSpan(
                        children: [
                          if (download['status'] != 5)
                            TextSpan(
                              text:
                                  "${download['additional']['transfer']['size_downloaded'].formatSize()} / ",
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.lightBlueAccent),
                            ),
                          TextSpan(
                            text: download['size'].formatSize(),
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (download['status'] == 2)
                    Expanded(
                      child: Text(
                        download['additional']['transfer']['speed_download'] > 0
                            ? (int.parse(((download['size'] -
                                            download['additional']['transfer']
                                                ['size_downloaded']) /
                                        download['additional']['transfer']
                                            ['speed_download'])
                                    .ceil()))
                                .timeRemaining()
                            : "--:--:--",
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey),
                        textAlign: TextAlign.start,
                      ),
                    ),
                  Expanded(
                    child: download['status'] == 1
                        ? const Text(
                            "等待中",
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                            textAlign: TextAlign.right,
                          )
                        : download['status'] == 2
                            ? Text(
                                "${download['additional']['transfer']['speed_download'].formatSize()}/s",
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.lightBlueAccent),
                                textAlign: TextAlign.right,
                              )
                            : download['status'] == 3
                                ? const Text(
                                    "已暂停",
                                    style: TextStyle(
                                        fontSize: 12, color: Colors.grey),
                                    textAlign: TextAlign.right,
                                  )
                                : download['status'] == 5
                                    ? const Text(
                                        "已完成",
                                        style: TextStyle(
                                            fontSize: 12, color: Colors.green),
                                        textAlign: TextAlign.right,
                                      )
                                    : download['status'] == 6
                                        ? const Text(
                                            "检查中",
                                            style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey),
                                            textAlign: TextAlign.right,
                                          )
                                        : download['status'] == 8
                                            ? const Text(
                                                "做种中",
                                                style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.greenAccent),
                                                textAlign: TextAlign.right,
                                              )
                                            : download['status'] == 11
                                                ? const Text(
                                                    "等待中",
                                                    style: TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.blue),
                                                    textAlign: TextAlign.right,
                                                  )
                                                : download['status'] == 12
                                                    ? const Text(
                                                        "下载中",
                                                        style: TextStyle(
                                                            fontSize: 12,
                                                            color: Colors.blue),
                                                        textAlign:
                                                            TextAlign.right,
                                                      )
                                                    : download['status'] == 101
                                                        ? const Text(
                                                            "错误",
                                                            style: TextStyle(
                                                                fontSize: 12,
                                                                color:
                                                                    Colors.red),
                                                            textAlign:
                                                                TextAlign.right,
                                                          )
                                                        : download['status'] ==
                                                                105
                                                            ? const Text(
                                                                "空间不足",
                                                                style: TextStyle(
                                                                    fontSize:
                                                                        12,
                                                                    color: Colors
                                                                        .red),
                                                                textAlign:
                                                                    TextAlign
                                                                        .right,
                                                              )
                                                            : download['status'] ==
                                                                    113
                                                                ? const Text(
                                                                    "重复的任务",
                                                                    style: TextStyle(
                                                                        fontSize:
                                                                            12,
                                                                        color: Colors
                                                                            .red),
                                                                    textAlign:
                                                                        TextAlign
                                                                            .right,
                                                                  )
                                                                : Text(
                                                                    "代码：${download['status']}",
                                                                    style: const TextStyle(
                                                                        fontSize:
                                                                            12,
                                                                        color: Colors
                                                                            .red),
                                                                    textAlign:
                                                                        TextAlign
                                                                            .right,
                                                                  ),
                  ),
                ],
              ),
              const SizedBox(
                height: 2,
              ),
              FAProgressBar(
                backgroundColor: AppColors.greyLight,
                progressColor: Colors.blue,
                size: 6,
                currentValue: download['size'] == 0
                    ? 0
                    : (download['additional']['transfer']['size_downloaded'] /
                            download['size'] *
                            100)
                        .ceil(),
              )
              // download['status'] == 5
              //     ? Label("完成", Colors.green)
              //     : download['status'] == 2
              //         ? Label(download['size'] == 0 ? "下载中" : "${(download['additional']['transfer']['size_downloaded'] / download['size'] * 100).toStringAsFixed(2)}%", Colors.lightBlueAccent)
              //         : download['status'] == 3
              //             ? Label("暂停", Colors.orange)
              //             : Label("${download['status']}", Colors.red),
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
        title: downloadRate > 0 || uploadRate > 0
            ? Row(
                // mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.download_sharp,
                    size: 20,
                    color: Colors.lightBlueAccent,
                  ),
                  Text(
                    downloadRate.formatSize(),
                    style: const TextStyle(
                      color: Colors.lightBlueAccent,
                    ),
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  const Icon(
                    Icons.upload_sharp,
                    size: 20,
                    color: Colors.orange,
                  ),
                  Text(
                    uploadRate.formatSize(),
                    style: const TextStyle(
                      color: Colors.orange,
                    ),
                  ),
                ],
              )
            : const Text("Download Station"),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10, top: 8, bottom: 8),
            child: OutlinedButton(
              onPressed: () {
                Navigator.of(context)
                    .push(
                  CupertinoPageRoute(
                    builder: (context) {
                      return const AddDownloadTask();
                    },
                    settings: const RouteSettings(name: "add_download_task"),
                  ),
                )
                    .then((value) {
                  getData();
                });
              },
              child: const Icon(Icons.add),
            ),
          ),
        ],
      ),
      body: loading
          ? const Center(
              child: CupertinoActivityIndicator(
                radius: 14,
              ),
            )
          : tasks.isNotEmpty
              ? Column(
                  children: [
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.all(20),
                        itemBuilder: (context, i) {
                          return _buildDownloadItem(tasks[i]);
                        },
                        itemCount: tasks.length,
                        separatorBuilder: (context, i) {
                          return const SizedBox(
                            height: 20,
                          );
                        },
                      ),
                    ),
                  ],
                )
              : Center(
                  child: Text(
                    "暂无下载任务",
                    style:
                        TextStyle(color: AppTheme.of(context).placeholderColor),
                  ),
                ),
    );
  }
}
