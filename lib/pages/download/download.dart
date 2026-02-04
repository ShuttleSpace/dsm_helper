import 'dart:io';
import 'package:android_intent_plus/android_intent.dart';
import 'package:background_downloader/background_downloader.dart';
import 'package:garden/pages/common/video_player.dart';
import 'package:garden/pages/download/download_setting.dart';
import 'package:garden/pages/download/download_state.dart';
import 'package:garden/themes/app_theme.dart';
import 'package:garden/widgets/transparent_router.dart';
import 'package:garden/pages/common/image_preview.dart';
import 'package:garden/util/function.dart';
import 'package:garden/widgets/file_icon.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';
import 'package:path/path.dart' as Path;

class DownloadInfo {
  DownloadTask task;
  TaskStatus? status;
  int? progress;

  DownloadInfo({
    required this.task,
  });
  factory DownloadInfo.formTask(DownloadTask task) {
    return DownloadInfo(task: task);
  }
  @override
  String toString() =>
      "DownloadInfo(taskId: ${task.taskId}, status: $status, progress: $progress, url: ${task.taskId}, filename: ${task.filename}, savedDir: ${task.directory}, timeCreated: ${task.creationTime.toIso8601String()})";
}

class Download extends StatefulWidget {
  Download({key}) : super(key: key);
  @override
  DownloadState createState() => DownloadState();
}

class DownloadState extends State<Download> {
  DownloadStateNotifier? _downloadStateNotifier;
  var downloader = FileDownloader();

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

  Widget _buildDownloadStatus(TaskStatus status, int progress) {
    if (status == TaskStatus.complete) {
      return Card(
        shape: RoundedRectangleBorder(
            side: BorderSide(), borderRadius: BorderRadius.circular(18)),
        margin: EdgeInsets.only(bottom: 3),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            "下载完成",
            style: TextStyle(fontSize: 10, color: Colors.white),
          ),
        ),
      );
    } else if (status == TaskStatus.failed) {
      return Card(
        shape: RoundedRectangleBorder(
            side: BorderSide(), borderRadius: BorderRadius.circular(18)),
        margin: EdgeInsets.only(bottom: 3),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            "下载失败",
            style: TextStyle(fontSize: 10, color: Colors.white),
          ),
        ),
      );
    } else if (status == TaskStatus.canceled) {
      return Card(
        shape: RoundedRectangleBorder(
            side: BorderSide(), borderRadius: BorderRadius.circular(18)),
        margin: EdgeInsets.only(bottom: 3),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            "取消下载",
            style: TextStyle(fontSize: 10, color: Colors.white),
          ),
        ),
      );
    } else if (status == TaskStatus.paused) {
      return Card(
        shape: RoundedRectangleBorder(
            side: BorderSide(), borderRadius: BorderRadius.circular(18)),
        margin: EdgeInsets.only(bottom: 3),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            "暂停下载",
            style: TextStyle(fontSize: 10, color: Colors.white),
          ),
        ),
      );
    } else if (status == TaskStatus.running) {
      return Card(
        shape: RoundedRectangleBorder(
            side: BorderSide(), borderRadius: BorderRadius.circular(18)),
        margin: EdgeInsets.only(bottom: 3),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            "$progress%",
            style: TextStyle(fontSize: 10, color: Colors.white),
          ),
        ),
      );
    } else if (status == TaskStatus.enqueued) {
      return Card(
        shape: RoundedRectangleBorder(
            side: BorderSide(), borderRadius: BorderRadius.circular(18)),
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

  Widget _buildTaskItem(DownloadInfo info) {
    FileTypeEnum fileType = Util.instance.fileType(info.task.filename);
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
              ..addSelectedTask(info);
          },
          onPressed: () async {
            // print(task.savedDir + "/" + task.filename);
            // return;
            if (value) {
              if (_downloadStateNotifier!.selectedTasks.value.contains(info)) {
                _downloadStateNotifier!.removeSelectedTask(info);
              } else {
                _downloadStateNotifier!.addSelectedTask(info);
              }
            } else {
              if (fileType == FileTypeEnum.image) {
                //获取当前目录全部图片文件
                List<String> images = [];
                int index = 0;
                for (int i = 0;
                    i < _downloadStateNotifier!.tasks.value.length;
                    i++) {
                  if (info.status == TaskStatus.complete &&
                      Util.instance.fileType(info.task.filename) ==
                          FileTypeEnum.image) {
                    images.add(Path.join(
                        _downloadStateNotifier!.tasks.value[i].task.directory,
                        _downloadStateNotifier!.tasks.value[i].task.filename));
                    if (_downloadStateNotifier!.tasks.value[i] == info) {
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
                    data: await info.task.filePath(),
                    arguments: {},
                    type: "video/*",
                  );
                  await intent.launch();
                } else {
                  Navigator.of(context).push(
                    CupertinoPageRoute(
                        builder: (context) {
                          return FutureBuilder(
                              future: info.task.filePath(),
                              builder: (context, snapshot) {
                                if (snapshot.hasError) {
                                  return Text(snapshot.error.toString());
                                }
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return CircularProgressIndicator.adaptive();
                                }
                                if (snapshot.hasData) {
                                  return VideoPlayerPage(
                                    url: snapshot.data!,
                                    name: info.task.filename,
                                  );
                                } else {
                                  return Text('未知错误');
                                }
                              });
                        },
                        settings: RouteSettings(name: "preview_image")),
                  );
                }
              } else {
                var result = await downloader.openFile(
                    filePath:
                        Path.join(info.task.directory, info.task.filename));
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
                tag: Path.join(info.task.directory, info.task.filename),
                child: FileIcon(
                  fileType,
                  thumb: fileType == FileTypeEnum.image &&
                          info.status == TaskStatus.complete
                      ? Path.join(info.task.directory, info.task.filename)
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
                      info.task.filename,
                      style: TextStyle(
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(
                      height: 5,
                    ),
                    Text(
                      DateTime.fromMillisecondsSinceEpoch(
                              info.task.creationTime.secondsSinceEpoch)
                          .format("Y/m/d H:i:s"),
                      style: TextStyle(
                          fontSize: 12,
                          color:
                              Theme.of(context).textTheme.headlineSmall?.color),
                    ),
                    SizedBox(
                      height: 5,
                    ),
                    _buildDownloadStatus(
                        info.status ?? TaskStatus.notFound, info.progress ?? 0),
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
                              borderRadius: BorderRadius.circular(18)),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: ValueListenableBuilder(
                                valueListenable:
                                    _downloadStateNotifier!.selectedTasks,
                                builder: (context, selectedTasks, chidl) =>
                                    selectedTasks.contains(info)
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
                                            BorderRadius.circular(18)),
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
                                            if (info.status ==
                                                TaskStatus.failed)
                                              OutlinedButton(
                                                onPressed: () async {
                                                  Navigator.of(context).pop();
                                                  // TODO: retry
                                                  // await downloader.retry(
                                                  //     taskId: info.taskId);
                                                  await _downloadStateNotifier!
                                                      .runLoop();
                                                },
                                                child: Text(
                                                  "重试",
                                                  style:
                                                      TextStyle(fontSize: 18),
                                                ),
                                              ),
                                            if (info.status ==
                                                TaskStatus.running)
                                              OutlinedButton(
                                                onPressed: () async {
                                                  Navigator.of(context).pop();
                                                  await downloader
                                                      .pause(info.task);
                                                  await _downloadStateNotifier!
                                                      .runLoop();
                                                },
                                                child: Text(
                                                  "暂停",
                                                  style:
                                                      TextStyle(fontSize: 18),
                                                ),
                                              ),
                                            if (info.status ==
                                                TaskStatus.paused)
                                              OutlinedButton(
                                                onPressed: () async {
                                                  Navigator.of(context).pop();
                                                  debugPrint(info.task.taskId);
                                                  var res = await downloader
                                                      .resume(info.task);
                                                  debugPrint("resume: $res");
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
                                              TaskStatus.paused,
                                              TaskStatus.running,
                                              TaskStatus.failed
                                            ].contains(info.status))
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
                                                                    await downloader
                                                                        .cancelTaskWithId(
                                                                      info.task
                                                                          .taskId,
                                                                    );
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
                                                                          await downloader.cancelTaskWithId(info
                                                                              .task
                                                                              .taskId);
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
                                            BorderRadius.circular(18)),
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
                                              _onDeleteActionDialog(
                                                  context, value);
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

  Future<dynamic> _onDeleteActionDialog(
      BuildContext context, List<DownloadInfo> value) {
    return showCupertinoModalPopup(
      context: context,
      builder: (context) {
        return Material(
          color: Colors.transparent,
          child: Card(
            shape: RoundedRectangleBorder(
                side: BorderSide(), borderRadius: BorderRadius.circular(5)),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      "确认删除",
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                    ),
                    SizedBox(
                      height: 12,
                    ),
                    Text(
                      "确认要删除${value.length}个下载任务？",
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.w400),
                    ),
                    SizedBox(
                      height: 22,
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () async {
                              Navigator.of(context).pop();
                              for (DownloadInfo info in value) {
                                await downloader
                                    .cancelTaskWithId(info.task.taskId);
                              }
                              _downloadStateNotifier!.runLoop();
                              _downloadStateNotifier!.resetSelectedTasks();
                              _downloadStateNotifier!.multiSelect.value = false;
                            },
                            child: Text(
                              "确认删除",
                              style: TextStyle(
                                  fontSize: 18, color: Colors.redAccent),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 20,
                        ),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () async {
                              Navigator.of(context).pop();
                            },
                            child: Text(
                              "取消",
                              style: TextStyle(fontSize: 18),
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
  }
}
