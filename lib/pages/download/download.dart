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
import 'package:garden/widgets/transfer_list.dart';
// ignore: library_prefixes
import 'package:path/path.dart' as Path;
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:signals_hooks/signals_hooks.dart';

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

class Download extends HookWidget {
  const Download({super.key});

  @override
  Widget build(BuildContext context) {
    final notifier = DownloadStateInherited.of(context)!.notifier;
    final downloader = useMemoized(() => FileDownloader(), const []);
    // The notifier owns these signals; subscribing to them rebuilds this page
    // exactly like the ValueListenableBuilders they replaced.
    final loading = useExistingSignal(notifier.loading);
    final tasks = useExistingSignal(notifier.tasks);
    final selectedTasks = useExistingSignal(notifier.selectedTasks);

    Future<void> handleFileTap(DownloadInfo info) async {
      var result = await downloader.openFile(
        filePath: Path.join(info.task.directory, info.task.filename),
      );
      if (!result) {
        UiUtil.toast("不支持打开此文件");
      }
    }

    Future<void> handleVideoTap(DownloadInfo info) async {
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

    void handleImageTap(DownloadInfo info) {
      List<String> images = [];
      int index = 0;
      for (int i = 0; i < notifier.tasks.value.length; i++) {
        if (info.status == TaskStatus.complete &&
            FileTypeUtil.toFileTypeEnum(
                    FileTypeUtil.getFileType(info.task.filename)) ==
                FileTypeEnum.image) {
          images.add(Path.join(notifier.tasks.value[i].task.directory,
              notifier.tasks.value[i].task.filename));
          if (notifier.tasks.value[i] == info) {
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

    Widget buildTaskItem(DownloadInfo info) {
      return DownloadTaskItemWidget(
        info: info,
        multiSelect: notifier.multiSelect,
        selectedTasks: notifier.selectedTasks,
        tasks: notifier.tasks,
        onLongPress: () {
          UiUtil.vibrate(FeedbackType.light);
          notifier
            ..multiSelect.value = true
            ..addSelectedTask(info);
        },
        onTap: () async {
          FileTypeEnum fileType = FileTypeUtil.toFileTypeEnum(
              FileTypeUtil.getFileType(info.task.filename));
          if (fileType == FileTypeEnum.image) {
            handleImageTap(info);
          } else if (fileType == FileTypeEnum.movie) {
            await handleVideoTap(info);
          } else {
            await handleFileTap(info);
          }
        },
        onRetry: () async {
          await notifier.runLoop();
        },
        onPause: () async {
          await downloader.pause(info.task);
          await notifier.runLoop();
        },
        onResume: () async {
          Log.debug(info.task.taskId);
          var res = await downloader.resume(info.task);
          Log.debug("resume: $res");
          await notifier.runLoop();
        },
        onDelete: () async {
          await notifier.deleteTask(info.task.taskId);
          await notifier.runLoop();
        },
      );
    }

    Future<dynamic> onDeleteActionDialog(
        BuildContext context, List<DownloadInfo> value) {
      return showCupertinoModalPopup(
        context: context,
        builder: (context) => DownloadBatchDeleteDialog(
          count: value.length,
          onConfirm: () async {
            for (DownloadInfo info in value) {
              await notifier.deleteTask(info.task.taskId);
            }
            await notifier.runLoop();
            notifier.resetSelectedTasks();
            notifier.multiSelect.value = false;
          },
        ),
      );
    }

    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifier.init();
      });
      return notifier.unbindBackgroundIsolate;
    }, const []);

    bool isInProgress(DownloadInfo t) =>
        t.status == TaskStatus.enqueued ||
        t.status == TaskStatus.running ||
        t.status == TaskStatus.paused;

    Widget buildTaskList(List<DownloadInfo> items) {
      if (items.isEmpty) return const DownloadEmptyStateWidget();
      final reversed = items.reversed.toList();
      return ListView.builder(
        itemCount: reversed.length,
        itemBuilder: (context, i) => buildTaskItem(reversed[i]),
      );
    }

    return Scaffold(
      appBar: DownloadAppBarWidget(
        multiSelect: notifier.multiSelect,
        downloadPath: notifier.downloadPath,
        onExitMultiSelect: () {
          notifier.multiSelect.value = false;
          notifier.resetSelectedTasks();
        },
        onSelectAll: () {
          notifier.resetSelectedTasks();
          if (notifier.selectedTasks.value.length !=
              notifier.tasks.value.length) {
            notifier.addSelectedTasks(notifier.tasks.value);
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
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 上传/下载统一在「传输」 tab 呈现，避免上传进度混入文件列表。
          const TransferList(),
          Expanded(
            child: loading.value
                ? const Center(
                    child: CupertinoActivityIndicator(),
                  )
                : DefaultTabController(
                    length: 3,
                    child: Stack(
                      children: [
                        Column(
                          children: [
                            const TabBar(
                              tabs: [
                                Tab(text: "全部"),
                                Tab(text: "下载中"),
                                Tab(text: "已完成"),
                              ],
                            ),
                            Expanded(
                              child: TabBarView(
                                children: [
                                  buildTaskList(tasks.value),
                                  buildTaskList(
                                      tasks.value.where(isInProgress).toList()),
                                  buildTaskList(tasks.value
                                      .where((t) =>
                                          t.status == TaskStatus.complete)
                                      .toList()),
                                ],
                              ),
                            ),
                          ],
                        ),
                        AnimatedPositioned(
                          bottom: selectedTasks.value.isNotEmpty ? 0 : -100,
                          duration: const Duration(milliseconds: 200),
                          child: Card(
                            shape: RoundedRectangleBorder(
                                side: const BorderSide(),
                                borderRadius: BorderRadius.circular(18)),
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
                                      UiUtil.vibrate(FeedbackType.warning);
                                      onDeleteActionDialog(
                                          context, selectedTasks.value);
                                    },
                                    child: Column(
                                      children: [
                                        Image.asset(
                                          "assets/icons/delete.png",
                                          width: 25,
                                        ),
                                        const Text(
                                          "删除",
                                          style: TextStyle(fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
