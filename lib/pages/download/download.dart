import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:ui';
import 'package:android_intent_plus/android_intent.dart';
import 'package:humphrey_garden/pages/common/video_player.dart';
import 'package:humphrey_garden/pages/download/download_setting.dart';
import 'package:humphrey_garden/pages/download/download_state.dart';
import 'package:humphrey_garden/themes/app_theme.dart';
import 'package:humphrey_garden/widgets/transparent_router.dart';
import 'package:humphrey_garden/pages/common/image_preview.dart';
import 'package:humphrey_garden/util/function.dart';
import 'package:humphrey_garden/widgets/file_icon.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';

class DownloadInfo {
  String taskId;
  DownloadTaskStatus status;
  int progress;
  String url;
  String filename;
  String savedDir;
  int timeCreated;

  DownloadInfo(
      {required this.taskId,
      required this.status,
      required this.progress,
      required this.url,
      required this.filename,
      required this.savedDir,
      required this.timeCreated});
  factory DownloadInfo.formTask(DownloadTask task) {
    return DownloadInfo(
        taskId: task.taskId,
        status: task.status,
        progress: task.progress,
        url: task.url,
        filename: task.filename ?? '',
        savedDir: task.savedDir,
        timeCreated: task.timeCreated);
  }
  @override
  String toString() =>
      "DownloadInfo(taskId: $taskId, status: $status, progress: $progress, url: $url, filename: $filename, savedDir: $savedDir, timeCreated: $timeCreated)";
}

class Download extends StatefulWidget {
  Download({key}) : super(key: key);
  @override
  DownloadState createState() => DownloadState();
}

class DownloadState extends State<Download> {
  DownloadStateNotifier? _downloadStateNotifier;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _downloadStateNotifier = DownloadStateInherited.of(context)?.notifier;
  }

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _downloadStateNotifier?.init();
    });
    super.initState();
  }

  @override
  void dispose() {
    _downloadStateNotifier?.unbindBackgroundIsolate();
    super.dispose();
  }

  Widget _buildDownloadStatus(DownloadTaskStatus status, int progress) {
    if (status == DownloadTaskStatus.complete) {
      return Card(
        shape: RoundedRectangleBorder(
            side: BorderSide(), borderRadius: BorderRadius.circular(36)),
        margin: EdgeInsets.only(bottom: 3),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            "下载完成",
            style: TextStyle(fontSize: 10, color: Colors.white),
          ),
        ),
      );
    } else if (status == DownloadTaskStatus.failed) {
      return Card(
        shape: RoundedRectangleBorder(
            side: BorderSide(), borderRadius: BorderRadius.circular(36)),
        margin: EdgeInsets.only(bottom: 3),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            "下载失败",
            style: TextStyle(fontSize: 10, color: Colors.white),
          ),
        ),
      );
    } else if (status == DownloadTaskStatus.canceled) {
      return Card(
        shape: RoundedRectangleBorder(
            side: BorderSide(), borderRadius: BorderRadius.circular(36)),
        margin: EdgeInsets.only(bottom: 3),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            "取消下载",
            style: TextStyle(fontSize: 10, color: Colors.white),
          ),
        ),
      );
    } else if (status == DownloadTaskStatus.paused) {
      return Card(
        shape: RoundedRectangleBorder(
            side: BorderSide(), borderRadius: BorderRadius.circular(36)),
        margin: EdgeInsets.only(bottom: 3),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            "暂停下载",
            style: TextStyle(fontSize: 10, color: Colors.white),
          ),
        ),
      );
    } else if (status == DownloadTaskStatus.running) {
      return Card(
        shape: RoundedRectangleBorder(
            side: BorderSide(), borderRadius: BorderRadius.circular(36)),
        margin: EdgeInsets.only(bottom: 3),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            "$progress%",
            style: TextStyle(fontSize: 10, color: Colors.white),
          ),
        ),
      );
    } else if (status == DownloadTaskStatus.enqueued) {
      return Card(
        shape: RoundedRectangleBorder(
            side: BorderSide(), borderRadius: BorderRadius.circular(36)),
        margin: EdgeInsets.only(bottom: 3),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            "等待下载",
            style: TextStyle(fontSize: 10, color: Colors.white),
          ),
        ),
      );
    } else {
      return Container();
    }
  }

  Widget _buildTaskItem(DownloadInfo task) {
    FileTypeEnum fileType = Util.instance.fileType(task.filename);
    // String path = file['path'];
    return Padding(
      padding:
          const EdgeInsets.only(top: 10.0, bottom: 10.0, left: 20, right: 20),
      child: ValueListenableBuilder(
        valueListenable: _downloadStateNotifier!.multiSelect,
        builder: (context, value, child) => OutlinedButton(
          onLongPress: () {
            Util.instance.vibrate(FeedbackType.light);
            _downloadStateNotifier!
              ..multiSelect.value = true
              ..addSelectedTask(task);
          },
          onPressed: () async {
            // print(task.savedDir + "/" + task.filename);
            // return;
            if (value) {
              if (_downloadStateNotifier!.selectedTasks.value.contains(task)) {
                _downloadStateNotifier!.removeSelectedTask(task);
              } else {
                _downloadStateNotifier!.addSelectedTask(task);
              }
            } else {
              if (fileType == FileTypeEnum.image) {
                //获取当前目录全部图片文件
                List<String> images = [];
                int index = 0;
                for (int i = 0;
                    i < _downloadStateNotifier!.tasks.value.length;
                    i++) {
                  if (task.status == DownloadTaskStatus.complete &&
                      Util.instance.fileType(task.filename) ==
                          FileTypeEnum.image) {
                    images.add(_downloadStateNotifier!.tasks.value[i].savedDir +
                        "/" +
                        _downloadStateNotifier!.tasks.value[i].filename);
                    if (_downloadStateNotifier!.tasks.value[i] == task) {
                      index = images.length - 1;
                    }
                  }
                }
                Navigator.of(context).push(TransparentPageRoute(
                    pageBuilder: (context, _, __) {
                      return ImagePreview(
                        images,
                        index,
                        network: false,
                      );
                    },
                    settings: RouteSettings(name: "preview_image")));
              } else if (fileType == FileTypeEnum.movie) {
                String videoPlayer =
                    await Util.instance.getStorage("video_player") ?? '';
                debugPrint(videoPlayer);
                if (videoPlayer == '1') {
                  AndroidIntent intent = AndroidIntent(
                    action: 'action_view',
                    data: task.savedDir + "/" + task.filename,
                    arguments: {},
                    type: "video/*",
                  );
                  await intent.launch();
                } else {
                  Navigator.of(context).push(
                    CupertinoPageRoute(
                        builder: (context) {
                          return VideoPlayer(
                            url: task.savedDir + "/" + task.filename,
                            name: task.filename,
                          );
                        },
                        settings: RouteSettings(name: "preview_image")),
                  );
                }
              } else {
                var result = await FlutterDownloader.open(taskId: task.taskId);
                if (!result) {
                  Util.instance.toast("不支持打开此文件");
                }
              }
            }
          },
          // margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            children: [
              SizedBox(
                width: 20,
              ),
              Hero(
                tag: task.savedDir + "/" + task.filename,
                child: FileIcon(
                  fileType,
                  thumb: fileType == FileTypeEnum.image &&
                          task.status == DownloadTaskStatus.complete
                      ? task.savedDir + "/" + task.filename
                      : '',
                  network: false,
                ),
              ),
              SizedBox(
                width: 10,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.filename,
                      style: TextStyle(
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(
                      height: 5,
                    ),
                    Text(
                      DateTime.fromMillisecondsSinceEpoch(task.timeCreated)
                          .format("Y/m/d H:i:s"),
                      style: TextStyle(
                          fontSize: 12,
                          color:
                              Theme.of(context).textTheme.headlineSmall?.color),
                    ),
                    SizedBox(
                      height: 5,
                    ),
                    _buildDownloadStatus(task.status, task.progress),
                  ],
                ),
              ),
              SizedBox(
                width: 10,
              ),
              ValueListenableBuilder(
                  valueListenable: _downloadStateNotifier!.multiSelect,
                  builder: (context, v, child) => v
                      ? Card(
                          shape: RoundedRectangleBorder(
                              side: BorderSide(),
                              borderRadius: BorderRadius.circular(36)),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: ValueListenableBuilder(
                                valueListenable:
                                    _downloadStateNotifier!.selectedTasks,
                                builder: (context, selectedTasks, chidl) =>
                                    selectedTasks.contains(task)
                                        ? Icon(
                                            CupertinoIcons.checkmark_alt,
                                            color: Color(0xffff9813),
                                          )
                                        : Container()),
                          ),
                        )
                      : OutlinedButton(
                          onPressed: () {
                            showCupertinoModalPopup(
                              context: context,
                              builder: (context) {
                                return Material(
                                  color: Colors.transparent,
                                  child: Card(
                                    shape: RoundedRectangleBorder(
                                        side: BorderSide(),
                                        borderRadius:
                                            BorderRadius.circular(36)),
                                    child: SafeArea(
                                      top: false,
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: <Widget>[
                                            Text(
                                              "选择操作",
                                              style: TextStyle(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.w500),
                                            ),
                                            SizedBox(
                                              height: 22,
                                            ),
                                            if (task.status ==
                                                DownloadTaskStatus.failed)
                                              OutlinedButton(
                                                onPressed: () async {
                                                  Navigator.of(context).pop();
                                                  await FlutterDownloader.retry(
                                                      taskId: task.taskId);
                                                  await _downloadStateNotifier!
                                                      .runLoop();
                                                },
                                                child: Text(
                                                  "重试",
                                                  style:
                                                      TextStyle(fontSize: 18),
                                                ),
                                              ),
                                            if (task.status ==
                                                DownloadTaskStatus.running)
                                              OutlinedButton(
                                                onPressed: () async {
                                                  Navigator.of(context).pop();
                                                  await FlutterDownloader.pause(
                                                      taskId: task.taskId);
                                                  await _downloadStateNotifier!
                                                      .runLoop();
                                                },
                                                child: Text(
                                                  "暂停",
                                                  style:
                                                      TextStyle(fontSize: 18),
                                                ),
                                              ),
                                            if (task.status ==
                                                DownloadTaskStatus.paused)
                                              OutlinedButton(
                                                onPressed: () async {
                                                  Navigator.of(context).pop();
                                                  debugPrint(task.taskId);
                                                  var res =
                                                      await FlutterDownloader
                                                          .resume(
                                                              taskId:
                                                                  task.taskId);
                                                  debugPrint(res);
                                                  await _downloadStateNotifier!
                                                      .runLoop();
                                                },
                                                child: Text(
                                                  "继续下载",
                                                  style:
                                                      TextStyle(fontSize: 18),
                                                ),
                                              ),
                                            if ([
                                              DownloadTaskStatus.paused,
                                              DownloadTaskStatus.running,
                                              DownloadTaskStatus.failed
                                            ].contains(task.status))
                                              SizedBox(
                                                height: 16,
                                              ),
                                            OutlinedButton(
                                              onPressed: () async {
                                                Navigator.of(context).pop();
                                                Util.instance.vibrate(
                                                    FeedbackType.warning);
                                                showCupertinoModalPopup(
                                                  context: context,
                                                  builder: (context) {
                                                    return Material(
                                                      color: Colors.transparent,
                                                      child: Card(
                                                        shape: RoundedRectangleBorder(
                                                            side: BorderSide(),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        5)),
                                                        child: SafeArea(
                                                          top: false,
                                                          child: Padding(
                                                            padding:
                                                                const EdgeInsets
                                                                    .all(8.0),
                                                            child: Column(
                                                              mainAxisSize:
                                                                  MainAxisSize
                                                                      .min,
                                                              children: <Widget>[
                                                                Text(
                                                                  "确认删除",
                                                                  style: TextStyle(
                                                                      fontSize:
                                                                          20,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w500),
                                                                ),
                                                                SizedBox(
                                                                  height: 12,
                                                                ),
                                                                Text(
                                                                  "确认要删除文件？",
                                                                  style: TextStyle(
                                                                      fontSize:
                                                                          20,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w400),
                                                                ),
                                                                SizedBox(
                                                                  height: 22,
                                                                ),
                                                                OutlinedButton(
                                                                  onPressed:
                                                                      () async {
                                                                    Navigator.of(
                                                                            context)
                                                                        .pop();
                                                                    await FlutterDownloader.remove(
                                                                        taskId: task
                                                                            .taskId,
                                                                        shouldDeleteContent:
                                                                            true);
                                                                    await _downloadStateNotifier!
                                                                        .runLoop();
                                                                  },
                                                                  child: Text(
                                                                    "同时删除已下载文件",
                                                                    style: TextStyle(
                                                                        fontSize:
                                                                            18,
                                                                        color: Colors
                                                                            .redAccent),
                                                                  ),
                                                                ),
                                                                SizedBox(
                                                                  height: 22,
                                                                ),
                                                                Row(
                                                                  children: [
                                                                    Expanded(
                                                                      child:
                                                                          OutlinedButton(
                                                                        onPressed:
                                                                            () async {
                                                                          Navigator.of(context)
                                                                              .pop();
                                                                          await FlutterDownloader.remove(
                                                                              taskId: task.taskId,
                                                                              shouldDeleteContent: false);
                                                                          await _downloadStateNotifier!
                                                                              .runLoop();
                                                                        },
                                                                        child:
                                                                            Text(
                                                                          "确认删除",
                                                                          style: TextStyle(
                                                                              fontSize: 18,
                                                                              color: Colors.redAccent),
                                                                        ),
                                                                      ),
                                                                    ),
                                                                    SizedBox(
                                                                      width: 20,
                                                                    ),
                                                                    Expanded(
                                                                      child:
                                                                          OutlinedButton(
                                                                        onPressed:
                                                                            () async {
                                                                          Navigator.of(context)
                                                                              .pop();
                                                                        },
                                                                        child:
                                                                            Text(
                                                                          "取消",
                                                                          style:
                                                                              TextStyle(fontSize: 18),
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
                                              },
                                              child: Text(
                                                "删除",
                                                style: TextStyle(
                                                    fontSize: 18,
                                                    color: Colors.redAccent),
                                              ),
                                            ),
                                            SizedBox(
                                              height: 16,
                                            ),
                                            OutlinedButton(
                                              onPressed: () async {
                                                Navigator.of(context).pop();
                                              },
                                              child: Text(
                                                "取消",
                                                style: TextStyle(fontSize: 18),
                                              ),
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
                          },
                          child: Icon(
                            CupertinoIcons.right_chevron,
                            size: 18,
                          ),
                        )),
              SizedBox(
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
          leading: ValueListenableBuilder(
              valueListenable: _downloadStateNotifier!.multiSelect,
              builder: (context, v, child) => v
                  ? GestureDetector(
                      onTap: () {
                        _downloadStateNotifier!.multiSelect.value = false;
                        _downloadStateNotifier!.resetSelectedTasks();
                      },
                      child: Icon(Icons.close),
                    )
                  : Container()),
          title: Column(
            children: [
              Text(
                "下载",
              ),
              if (Platform.isAndroid)
                ValueListenableBuilder(
                    valueListenable: _downloadStateNotifier!.downloadPath,
                    builder: (context, value, child) {
                      return Text(
                        value,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      );
                    })
            ],
          ),
          actions: [
            ValueListenableBuilder(
                valueListenable: _downloadStateNotifier!.multiSelect,
                builder: (context, v, child) => v
                    ? Padding(
                        padding: EdgeInsets.only(right: 10, top: 8, bottom: 8),
                        child: OutlinedButton(
                          onPressed: () {
                            _downloadStateNotifier!.resetSelectedTasks();
                            if (_downloadStateNotifier!
                                    .selectedTasks.value.length !=
                                _downloadStateNotifier!.tasks.value.length) {
                              _downloadStateNotifier!.addSelectedTasks(
                                  _downloadStateNotifier!.tasks.value);
                            }
                          },
                          child: Image.asset(
                            "assets/icons/select_all.png",
                            width: 20,
                            height: 20,
                          ),
                        ),
                      )
                    : Container()),
            if (Platform.isAndroid)
              Padding(
                padding: EdgeInsets.only(right: 10, top: 8, bottom: 8),
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      CupertinoPageRoute(
                        builder: (context) {
                          return DownloadSetting();
                        },
                        settings: RouteSettings(name: "download_setting"),
                      ),
                    );
                  },
                  child: Image.asset(
                    "assets/icons/setting.png",
                    width: 20,
                    height: 20,
                  ),
                ),
              ),
          ],
        ),
        body: ValueListenableBuilder(
            valueListenable: _downloadStateNotifier!.loading,
            builder: (context, loading, child) => loading
                ? Center(
                    child: CupertinoActivityIndicator(),
                  )
                : ValueListenableBuilder(
                    valueListenable: _downloadStateNotifier!.tasks,
                    builder: (context, tasks, child) => tasks.length > 0
                        ? Stack(
                            children: [
                              ListView.builder(
                                itemCount: tasks.length,
                                itemBuilder: (context, i) {
                                  return _buildTaskItem(
                                      tasks.reversed.toList()[i]);
                                },
                              ),
                              ValueListenableBuilder(
                                valueListenable:
                                    _downloadStateNotifier!.selectedTasks,
                                builder: (BuildContext context, value,
                                        Widget? child) =>
                                    AnimatedPositioned(
                                  bottom: value.length > 0 ? 0 : -100,
                                  duration: Duration(milliseconds: 200),
                                  child: Card(
                                    shape: RoundedRectangleBorder(
                                        side: BorderSide(),
                                        borderRadius:
                                            BorderRadius.circular(36)),
                                    margin: EdgeInsets.all(20),
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceAround,
                                        children: [
                                          GestureDetector(
                                            onTap: () async {
                                              Util.instance.vibrate(
                                                  FeedbackType.warning);
                                              showCupertinoModalPopup(
                                                context: context,
                                                builder: (context) {
                                                  return Material(
                                                    color: Colors.transparent,
                                                    child: Card(
                                                      shape:
                                                          RoundedRectangleBorder(
                                                              side:
                                                                  BorderSide(),
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          5)),
                                                      child: SafeArea(
                                                        top: false,
                                                        child: Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                  .all(8.0),
                                                          child: Column(
                                                            mainAxisSize:
                                                                MainAxisSize
                                                                    .min,
                                                            children: <Widget>[
                                                              Text(
                                                                "确认删除",
                                                                style: TextStyle(
                                                                    fontSize:
                                                                        20,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w500),
                                                              ),
                                                              SizedBox(
                                                                height: 12,
                                                              ),
                                                              Text(
                                                                "确认要删除${value.length}个下载任务？",
                                                                style: TextStyle(
                                                                    fontSize:
                                                                        20,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w400),
                                                              ),
                                                              SizedBox(
                                                                height: 22,
                                                              ),
                                                              Row(
                                                                children: [
                                                                  Expanded(
                                                                    child:
                                                                        OutlinedButton(
                                                                      onPressed:
                                                                          () async {
                                                                        Navigator.of(context)
                                                                            .pop();
                                                                        for (DownloadInfo task
                                                                            in value) {
                                                                          await FlutterDownloader.remove(
                                                                              taskId: task.taskId,
                                                                              shouldDeleteContent: true);
                                                                        }
                                                                        _downloadStateNotifier!
                                                                            .runLoop();
                                                                        _downloadStateNotifier!
                                                                            .resetSelectedTasks();
                                                                        _downloadStateNotifier!
                                                                            .multiSelect
                                                                            .value = false;
                                                                      },
                                                                      child:
                                                                          Text(
                                                                        "确认删除",
                                                                        style: TextStyle(
                                                                            fontSize:
                                                                                18,
                                                                            color:
                                                                                Colors.redAccent),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                  SizedBox(
                                                                    width: 20,
                                                                  ),
                                                                  Expanded(
                                                                    child:
                                                                        OutlinedButton(
                                                                      onPressed:
                                                                          () async {
                                                                        Navigator.of(context)
                                                                            .pop();
                                                                      },
                                                                      child:
                                                                          Text(
                                                                        "取消",
                                                                        style: TextStyle(
                                                                            fontSize:
                                                                                18),
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
                                            },
                                            child: Column(
                                              children: [
                                                Image.asset(
                                                  "assets/icons/delete.png",
                                                  width: 25,
                                                ),
                                                Text(
                                                  "删除",
                                                  style:
                                                      TextStyle(fontSize: 12),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  "暂无下载任务",
                                  style: TextStyle(
                                      color: AppTheme.of(context)
                                          .placeholderColor),
                                ),
                                SizedBox(
                                  height: 5,
                                ),
                                Text(
                                  "可在[文件]中点击文件右侧 > 将文件下载到手机",
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                  )));
  }
}
