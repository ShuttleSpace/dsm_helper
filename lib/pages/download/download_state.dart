import 'dart:async';
import 'dart:isolate';
import 'dart:ui';

import 'package:background_downloader/background_downloader.dart';
import 'package:garden/pages/download/download.dart';
import 'package:garden/util/http_util.dart';
import 'package:flutter/widgets.dart';
import 'package:garden/util/log.dart';
import 'package:signals_flutter/signals_flutter.dart';

class DownloadStateNotifier {
  final tasks = signal<List<DownloadInfo>>([]);
  final loading = signal<bool>(true);
  final selectedTasks = signal<List<DownloadInfo>>([]);
  final multiSelect = signal<bool>(false);
  final downloadPath = signal<String>('');
  final ReceivePort _receiverPort = ReceivePort();

  void addSelectedTask(DownloadInfo task) {
    final currentTasks = [...selectedTasks.value];
    currentTasks.add(task);
    selectedTasks.value = currentTasks;
  }

  void addSelectedTasks(List<DownloadInfo> tasks) {
    final currentTasks = [...selectedTasks.value];
    currentTasks.addAll(tasks);
    selectedTasks.value = currentTasks;
  }

  void removeSelectedTask(DownloadInfo task) {
    final currentTasks = [...selectedTasks.value];
    currentTasks.remove(task);
    selectedTasks.value = currentTasks;
  }

  void resetSelectedTasks() {
    selectedTasks.value = [];
  }

  void init() {
    downloadTargetDir().then((v) => {
          // FIXME: use signals
          // downloadPath.value = v;
        });
    bindBackgroundIsolate();
    FileDownloader().registerCallbacks(
      taskStatusCallback: (update) =>
          downloadCallback(update.task.taskId, status: update.status),
      taskProgressCallback: (update) =>
          downloadCallback(update.task.taskId, progress: update.progress),
    );
    runLoop();
  }

  void bindBackgroundIsolate() {
    bool isSuccess = IsolateNameServer.registerPortWithName(
        _receiverPort.sendPort, 'downloader_send_port');
    if (!isSuccess) {
      unbindBackgroundIsolate();
      bindBackgroundIsolate();
      return;
    }
    _receiverPort.listen((dynamic data) {
      Log.debug('UI Isolate Callback: $data');
      String id = data[0];
      TaskStatus status = data[1] ?? TaskStatus.notFound;
      int progress = data[2] ?? 0;

      if (tasks.value.isNotEmpty) {
        final updatedTasks = tasks.value.map((task) {
          if (task.task.taskId == id) {
            task.status = status;
            task.progress = progress;
          }
          return task;
        }).toList();
        tasks.value = updatedTasks;
      }
    });
  }

  void unbindBackgroundIsolate() {
    IsolateNameServer.removePortNameMapping('downloader_send_port');
  }

  runLoop() async {
    List<Task> downloadTasks = await FileDownloader().allTasks();
    tasks.value = downloadTasks
        .takeWhile((t) => t is DownloadTask)
        .map((e) => DownloadInfo.formTask(e as DownloadTask))
        .toList();
    loading.value = false;
    Log.debug('runLoop: loading= ${loading.value}');
    // 如果存在下载中任务，每秒刷新一次
    if (tasks.value
        .where((task) =>
            task.status == TaskStatus.running ||
            task.status == TaskStatus.enqueued ||
            task.status == TaskStatus.notFound)
        .isNotEmpty) {
    } else {}
  }

  Future<bool> onWillPop() {
    if (multiSelect.value) {
      multiSelect.value = false;
      selectedTasks.value = [];
    } else {
      Log.debug("可以返回");
      return Future.value(true);
    }

    return Future.value(false);
  }

  static void downloadCallback(String id,
      {TaskStatus? status, double? progress}) {
    Log.debug(
        'Background Isolate Callback: task ($id) is in status ($status) and process ($progress)');
    IsolateNameServer.lookupPortByName('downloader_send_port')
        ?.send([id, status, progress]);
  }
}

@immutable
class DownloadStateInherited extends InheritedWidget {
  final DownloadStateNotifier notifier;
  const DownloadStateInherited(
      {super.key, required this.notifier, required super.child});

  static DownloadStateInherited? of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<DownloadStateInherited>()!;
  }

  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) {
    return oldWidget is! DownloadStateInherited ||
        (oldWidget).notifier != notifier;
  }
}
