import 'dart:async';
import 'dart:isolate';
import 'dart:ui';

import 'package:dsm_helper/pages/download/download.dart';
import 'package:dsm_helper/util/function.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_downloader/flutter_downloader.dart';

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
    FlutterDownloader.registerCallback(downloadCallback, step: 1);
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
      DownloadTaskStatus status = DownloadTaskStatus.fromInt(data[1]);
      int progress = data[2];

      if (tasks.value.isNotEmpty) {
        tasks.value.forEach((task) {
          if (task.taskId == id) {
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
    List<DownloadTask> downloadTasks =
        await FlutterDownloader.loadTasks() ?? [];
    tasks.value = downloadTasks.map((e) => DownloadInfo.formTask(e)).toList();
    loading.value = false;
    debugPrint('runLoop: loading= ${loading.value}');
    // 如果存在下载中任务，每秒刷新一次
    if (tasks.value
            .where((task) =>
                task.status == DownloadTaskStatus.running ||
                task.status == DownloadTaskStatus.enqueued ||
                task.status == DownloadTaskStatus.undefined)
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

  static void downloadCallback(String id, int status, int progress) {
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
