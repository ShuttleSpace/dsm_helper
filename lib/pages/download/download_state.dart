import 'dart:async';
import 'dart:isolate';
import 'dart:ui';

import 'package:background_downloader/background_downloader.dart';
import 'package:garden/pages/download/download.dart';
import 'package:garden/stores/transfer_store.dart';
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
      // 进度回调传来的是 0~1 的 double，转成百分比 int；状态回调为 null。
      final num? rawProgress = data[2] as num?;

      transferStore.applyTaskStatus(id, status);

      if (tasks.value.isNotEmpty) {
        final updatedTasks = tasks.value.map((task) {
          if (task.task.taskId == id) {
            task.status = status;
            if (rawProgress != null) {
              task.progress = (rawProgress * 100).round();
            }
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

  /// 合并「实时任务」(allTasks，进行中) 与「持久记录」(database，含已完成)。
  /// allTasks() 完成后即移除，已完成项只能从 database 取。
  void _applyTasks(List<Task> live, List<TaskRecord> records) {
    final byId = <String, DownloadInfo>{};
    for (final rec in records) {
      final t = rec.task;
      if (t is! DownloadTask) continue;
      byId[t.taskId] = DownloadInfo.formTask(t)
        ..status = rec.status
        ..progress = (rec.progress * 100).round();
    }
    for (final t in live) {
      if (t is! DownloadTask) continue;
      byId.putIfAbsent(t.taskId, () => DownloadInfo.formTask(t));
    }
    tasks.value = byId.values.toList();
  }

  /// 删除任务：取消活动任务并移除持久记录（已完成项只在 database 里）。
  Future<void> deleteTask(String id) async {
    await FileDownloader().cancelTaskWithId(id);
    await FileDownloader().database.deleteRecordWithId(id);
  }

  Future<void> runLoop() async {
    try {
      final live = await FileDownloader().allTasks();
      final records = await FileDownloader()
          .database
          .allRecords(group: FileDownloader.defaultGroup);
      _applyTasks(live, records);
    } finally {
      loading.value = false;
    }
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
