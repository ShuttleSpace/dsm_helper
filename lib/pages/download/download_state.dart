import 'dart:async';
import 'dart:isolate';
import 'dart:ui';

import 'package:background_downloader/background_downloader.dart';
import 'package:garden/pages/download/download.dart';
import 'package:garden/util/function.dart';
import 'package:flutter/widgets.dart';

class DownloadStateNotifier extends ChangeNotifier {
  ValueNotifier<List<DownloadInfo>> tasks = ValueNotifier([]);
  ValueNotifier<bool> loading = ValueNotifier(true);
  ValueNotifier<List<DownloadInfo>> selectedTasks = ValueNotifier([]);
  ValueNotifier<bool> multiSelect = ValueNotifier(false);
  ValueNotifier<String> downloadPath = ValueNotifier('');
  ReceivePort _receiverPort = ReceivePort();

  void addSelectedTask(DownloadInfo task) {
    selectedTasks.value.add(task);
    selectedTasks.notifyListeners();
  }

  void addSelectedTasks(List<DownloadInfo> tasks) {
    selectedTasks.value.addAll(tasks);
    selectedTasks.notifyListeners();
  }

  void removeSelectedTask(DownloadInfo task) {
    selectedTasks.value.remove(task);
    selectedTasks.notifyListeners();
  }

  void resetSelectedTasks() {
    selectedTasks.value = [];
  }

  void init() {
    Util.instance.getDownloadPath().then((value) {
      downloadPath.value = value;
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
      debugPrint('UI Isolate Callback: $data');
      String id = data[0];
      TaskStatus status = data[1] ?? TaskStatus.notFound;
      int progress = data[2] ?? 0;

      if (tasks.value.isNotEmpty) {
        tasks.value.forEach((task) {
          if (task.task.taskId == id) {
            task.status = status;
            task.progress = progress;
          }
        });
        tasks.notifyListeners();
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
    debugPrint('runLoop: loading= ${loading.value}');
    // 如果存在下载中任务，每秒刷新一次
    if (tasks.value
            .where((task) =>
                task.status == TaskStatus.running ||
                task.status == TaskStatus.enqueued ||
                task.status == TaskStatus.notFound)
            .length >
        0) {
    } else {}
  }

  Future<bool> onWillPop() {
    if (multiSelect.value) {
      multiSelect.value = false;
      selectedTasks.value = [];
    } else {
      debugPrint("可以返回");
      return Future.value(true);
    }

    return Future.value(false);
  }

  static void downloadCallback(String id,
      {TaskStatus? status, double? progress}) {
    debugPrint(
        'Background Isolate Callback: task ($id) is in status ($status) and process ($progress)');
    IsolateNameServer.lookupPortByName('downloader_send_port')
        ?.send([id, status, progress]);
  }
}

@immutable
class DownloadStateInherited extends InheritedWidget {
  final DownloadStateNotifier notifier;
  DownloadStateInherited({required this.notifier, required super.child});

  static DownloadStateInherited? of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<DownloadStateInherited>()!;
  }

  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) {
    return !(oldWidget is DownloadStateInherited) ||
        (oldWidget).notifier != this.notifier;
  }
}
