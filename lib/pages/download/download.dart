import 'package:android_intent_plus/android_intent.dart';
import 'package:garden/util/file_type_util.dart';
import 'package:garden/util/log.dart';
import 'package:garden/util/ui_util.dart';
import 'package:garden/util/storage_util.dart';
import 'package:background_downloader/background_downloader.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';
import 'package:garden/constants/app_constants.dart';
import 'package:garden/pages/common/image_preview.dart';
import 'package:garden/pages/common/video_player.dart';
import 'package:garden/pages/download/download_setting.dart';
import 'package:garden/pages/download/download_state.dart';
import 'package:garden/util/http_util.dart';
import 'package:garden/widgets/download/download_app_bar_widget.dart';
import 'package:garden/widgets/download/download_batch_action_widget.dart';
import 'package:garden/widgets/download/download_empty_state_widget.dart';
import 'package:garden/widgets/download/download_task_item_widget.dart';
import 'package:garden/widgets/transparent_router.dart';
// ignore: library_prefixes
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
  const Download({super.key});
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

  Widget _buildTaskItem(DownloadInfo info) {
    return DownloadTaskItemWidget(
      info: info,
      multiSelect: _downloadStateNotifier!.multiSelect,
      selectedTasks: _downloadStateNotifier!.selectedTasks,
      tasks: _downloadStateNotifier!.tasks,
      onLongPress: () {
        UiUtil.vibrate(FeedbackType.light);
        _downloadStateNotifier!
          ..multiSelect.value = true
          ..addSelectedTask(info);
      },
      onTap: () async {
        FileTypeEnum fileType = FileTypeUtil.toFileTypeEnum(
            FileTypeUtil.getFileType(info.task.filename));
        if (fileType == FileTypeEnum.image) {
          _handleImageTap(info);
        } else if (fileType == FileTypeEnum.movie) {
          await _handleVideoTap(info);
        } else {
          await _handleFileTap(info);
        }
      },
      onRetry: () async {
        await _downloadStateNotifier!.runLoop();
      },
      onPause: () async {
        await downloader.pause(info.task);
        await _downloadStateNotifier!.runLoop();
      },
      onResume: () async {
        Log.debug(info.task.taskId);
        var res = await downloader.resume(info.task);
        Log.debug("resume: $res");
        await _downloadStateNotifier!.runLoop();
      },
      onDelete: () {
        downloader.cancelTaskWithId(info.task.taskId);
        _downloadStateNotifier!.runLoop();
      },
    );
  }

  void _handleImageTap(DownloadInfo info) {
    List<String> images = [];
    int index = 0;
    for (int i = 0; i < _downloadStateNotifier!.tasks.value.length; i++) {
      if (info.status == TaskStatus.complete &&
          FileTypeUtil.toFileTypeEnum(
                  FileTypeUtil.getFileType(info.task.filename)) ==
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
      settings: const RouteSettings(name: "preview_image"),
    ));
  }

  Future<void> _handleVideoTap(DownloadInfo info) async {
    bool useEmbeedVideoPlayer =
        await StorageUtil.getBool("use_embeed_video_player") ?? true;
    Log.debug(useEmbeedVideoPlayer);
    if (!useEmbeedVideoPlayer) {
      AndroidIntent intent = AndroidIntent(
        action: 'action_view',
        data: await info.task.filePath(),
        arguments: {},
        type: "video/*",
      );
      await intent.launch();
    } else {
      if (context.mounted) {
        // ignore: use_build_context_synchronously
        Navigator.of(context).push(
          CupertinoPageRoute(
            builder: (context) {
              return FutureBuilder(
                future: info.task.filePath(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Text(snapshot.error.toString());
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator.adaptive();
                  }
                  if (snapshot.hasData) {
                    return VideoPlayerPage(
                      url: snapshot.data!,
                      name: info.task.filename,
                    );
                  } else {
                    return const Text('未知错误');
                  }
                },
              );
            },
            settings: const RouteSettings(name: "preview_image"),
          ),
        );
      }
    }
  }

  Future<void> _handleFileTap(DownloadInfo info) async {
    var result = await downloader.openFile(
      filePath: Path.join(info.task.directory, info.task.filename),
    );
    if (!result) {
      UiUtil.toast("不支持打开此文件");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: DownloadAppBarWidget(
          multiSelect: _downloadStateNotifier!.multiSelect,
          downloadPath: _downloadStateNotifier!.downloadPath,
          onExitMultiSelect: () {
            _downloadStateNotifier!.multiSelect.value = false;
            _downloadStateNotifier!.resetSelectedTasks();
          },
          onSelectAll: () {
            _downloadStateNotifier!.resetSelectedTasks();
            if (_downloadStateNotifier!.selectedTasks.value.length !=
                _downloadStateNotifier!.tasks.value.length) {
              _downloadStateNotifier!
                  .addSelectedTasks(_downloadStateNotifier!.tasks.value);
            }
          },
          onOpenSettings: () {
            Navigator.of(context).push(
              CupertinoPageRoute(
                builder: (context) {
                  return const DownloadSetting();
                },
                settings: const RouteSettings(name: "download_setting"),
              ),
            );
          },
        ),
        body: ValueListenableBuilder(
            valueListenable: _downloadStateNotifier!.loading,
            builder: (context, loading, child) => loading
                ? const Center(
                    child: CupertinoActivityIndicator(),
                  )
                : ValueListenableBuilder(
                    valueListenable: _downloadStateNotifier!.tasks,
                    builder: (context, tasks, child) => tasks.isNotEmpty
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
                                  bottom: value.isNotEmpty ? 0 : -100,
                                  duration: const Duration(milliseconds: 200),
                                  child: Card(
                                    shape: RoundedRectangleBorder(
                                        side: const BorderSide(),
                                        borderRadius:
                                            BorderRadius.circular(18)),
                                    margin: const EdgeInsets.all(20),
                                    child: Padding(
                                      padding: const EdgeInsets.all(
                                          AppConstants.paddingSmall),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceAround,
                                        children: [
                                          GestureDetector(
                                            onTap: () async {
                                              UiUtil.vibrate(
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
                                                const Text(
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
                        : const DownloadEmptyStateWidget(),
                  )));
  }

  Future<dynamic> _onDeleteActionDialog(
      BuildContext context, List<DownloadInfo> value) {
    return showCupertinoModalPopup(
      context: context,
      builder: (context) => DownloadBatchDeleteDialog(
        count: value.length,
        onConfirm: () async {
          for (DownloadInfo info in value) {
            await downloader.cancelTaskWithId(info.task.taskId);
          }
          _downloadStateNotifier!.runLoop();
          _downloadStateNotifier!.resetSelectedTasks();
          _downloadStateNotifier!.multiSelect.value = false;
        },
      ),
    );
  }
}
