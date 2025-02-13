import 'dart:async';
import 'dart:isolate';
import 'dart:ui';

import 'package:dsm_helper/pages/download/download.dart';
import 'package:dsm_helper/util/function.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_downloader/flutter_downloader.dart';

class DownloadStateNotifier extends ChangeNotifier {
  ValueNotifier<List<DownloadInfo>> _tasks = ValueNotifier([]);
  ValueNotifier<bool> _loading = ValueNotifier(true);
  ValueNotifier<List<DownloadInfo>> _selectedTasks = ValueNotifier([]);
  ValueNotifier<bool> _multiSelect = ValueNotifier(false);
  ValueNotifier<String> downloadPath = ValueNotifier('');
  ReceivePort _receiverPort = ReceivePort();

  void set loading(bool v) {
    _loading.value = v;
    _loading.notifyListeners();
  }

  void set multiSelectVaule(bool v) {
    _multiSelect.value = v;
    _multiSelect.notifyListeners();
  }

  bool get multiSelectVaule => _multiSelect.value;
  List<DownloadInfo> get tasks => _tasks.value;
  bool get loading => _loading.value;

  List<DownloadInfo> get selectedTasks => _selectedTasks.value;

  void addSelectedTask(DownloadInfo task) {
    _selectedTasks.value.add(task);
    _selectedTasks.notifyListeners();
  }

  void addSelectedTasks(List<DownloadInfo> tasks) {
    _selectedTasks.value.addAll(tasks);
    _selectedTasks.notifyListeners();
  }

  void removeSelectedTask(DownloadInfo task) {
    _selectedTasks.value.remove(task);
    _selectedTasks.notifyListeners();
  }

  void resetSelectedTasks() {
    _selectedTasks.value = [];
    _selectedTasks.notifyListeners();
  }

  void init() {
    Util.instance.getDownloadPath().then((value) {
      downloadPath.value = value;
      downloadPath.notifyListeners();
    });
    bindBackgroundIsolate();
    FlutterDownloader.registerCallback(downloadCallback as DownloadCallback,
        step: 1);
    getData();
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

      if (_tasks.value.isNotEmpty) {
        _tasks.value.forEach((task) {
          if (task.taskId == id) {
            task.status = status;
            task.progress = progress;
          }
        });
      }
    });
  }

  void unbindBackgroundIsolate() {
    IsolateNameServer.removePortNameMapping('downloader_send_port');
  }

  getData() async {
    List<DownloadTask> downloadTasks =
        await FlutterDownloader.loadTasks() ?? [];
    _tasks = ValueNotifier(
        downloadTasks.map((e) => DownloadInfo.formTask(e)).toList());
    _loading = ValueNotifier(false);
    // 如果存在下载中任务，每秒刷新一次
    if (_tasks.value
            .where((task) =>
                task.status == DownloadTaskStatus.running ||
                task.status == DownloadTaskStatus.enqueued ||
                task.status == DownloadTaskStatus.undefined)
            .length >
        0) {
    } else {}
  }

  Future<bool> onWillPop() {
    if (_multiSelect.value) {
      _multiSelect.value = false;
      _selectedTasks = ValueNotifier([]);
    } else {
      debugPrint("可以返回");
      return Future.value(true);
    }

    return Future.value(false);
  }

  void downloadCallback(String id, DownloadTaskStatus status, int progress) {
    debugPrint(
        'Background Isolate Callback: task ($id) is in status ($status) and process ($progress)');
    IsolateNameServer.lookupPortByName('downloader_send_port')
        ?.send([id, status.index, progress]);
  }
}

@immutable
class DownloadStateInherited extends InheritedWidget {
  final DownloadStateNotifier notifier;
  DownloadStateInherited({required this.notifier, required super.child});

  static DownloadStateInherited of(BuildContext context) {
    DownloadStateInherited? instance =
        context.dependOnInheritedWidgetOfExactType<DownloadStateInherited>();
    assert(instance != null, "not found DownloadStateInherited in tree!");
    return instance!;
  }

  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) {
    return !(oldWidget is DownloadStateInherited) ||
        (oldWidget).notifier != this.notifier;
  }
}
