import 'dart:convert';

import 'package:background_downloader/background_downloader.dart';
import 'package:garden/util/storage_util.dart';
import 'package:signals_flutter/signals_flutter.dart';

enum TransferType { download, upload }

enum TransferState { queued, active, paused, done, error, canceled }

class ChunkState {
  const ChunkState({
    required this.index,
    required this.transferred,
    required this.total,
    required this.state,
  });
  final int index;
  final int transferred;
  final int total;
  final TransferState state;

  Map<String, dynamic> toJson() => {
        'index': index,
        'transferred': transferred,
        'total': total,
        'state': state.index,
      };

  factory ChunkState.fromJson(Map<String, dynamic> j) => ChunkState(
        index: j['index'] as int,
        transferred: j['transferred'] as int,
        total: j['total'] as int,
        state: TransferState.values[j['state'] as int],
      );
}

class TransferTask {
  const TransferTask({
    required this.id,
    required this.type,
    required this.localPath,
    required this.remotePath,
    this.totalBytes = 0,
    this.transferredBytes = 0,
    this.state = TransferState.queued,
    this.chunks,
  });

  final String id;
  final TransferType type;
  final String localPath;
  final String remotePath;
  final int totalBytes;
  final int transferredBytes;
  final TransferState state;
  final List<ChunkState>? chunks;

  TransferTask copyWith({
    int? totalBytes,
    int? transferredBytes,
    TransferState? state,
    List<ChunkState>? chunks,
  }) =>
      TransferTask(
        id: id,
        type: type,
        localPath: localPath,
        remotePath: remotePath,
        totalBytes: totalBytes ?? this.totalBytes,
        transferredBytes: transferredBytes ?? this.transferredBytes,
        state: state ?? this.state,
        chunks: chunks ?? this.chunks,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.index,
        'localPath': localPath,
        'remotePath': remotePath,
        'totalBytes': totalBytes,
        'transferredBytes': transferredBytes,
        'state': state.index,
        'chunks': chunks?.map((c) => c.toJson()).toList(),
      };

  factory TransferTask.fromJson(Map<String, dynamic> j) => TransferTask(
        id: j['id'] as String,
        type: TransferType.values[j['type'] as int],
        localPath: j['localPath'] as String,
        remotePath: j['remotePath'] as String,
        totalBytes: j['totalBytes'] as int? ?? 0,
        transferredBytes: j['transferredBytes'] as int? ?? 0,
        state: TransferState.values[j['state'] as int],
        chunks: (j['chunks'] as List?)
            ?.cast<Map<String, dynamic>>()
            .map(ChunkState.fromJson)
            .toList(),
      );
}

/// 引擎控制钩子（便于测试注入；默认走 background_downloader 单例）。
typedef ControlHook = Future<bool> Function(String taskId);

class TransferStore {
  TransferStore({this.onResume, this.onPause, this.onCancel});

  final ControlHook? onResume;
  final ControlHook? onPause;
  final ControlHook? onCancel;

  final _tasks = signal<List<TransferTask>>([]);
  ReadonlySignal<List<TransferTask>> get tasks => _tasks;

  TransferTask? _find(String id) =>
      _tasks.value.where((t) => t.id == id).firstOrNull;

  void add(TransferTask t) {
    _tasks.value = [..._tasks.value.where((e) => e.id != t.id), t];
    persist();
  }

  void updateProgress(String id, int transferred, int total) {
    final t = _find(id);
    if (t == null) return;
    _replace(t.copyWith(transferredBytes: transferred, totalBytes: total));
  }

  void setState(String id, TransferState s) {
    final t = _find(id);
    if (t == null) return;
    _replace(t.copyWith(state: s));
  }

  void _replace(TransferTask t) {
    _tasks.value = [..._tasks.value.where((e) => e.id != t.id), t];
    persist();
  }

  Future<bool> resumeTask(String id) async {
    final ok = await (onResume?.call(id) ?? Future.value(false));
    if (ok) setState(id, TransferState.active);
    return ok;
  }

  Future<bool> pauseTask(String id) async {
    // 包内暂停需 Task 对象（下载靠通知按钮原生暂停）；本地状态先翻转，
    // 让 UI 反映意图。
    await onPause?.call(id);
    setState(id, TransferState.paused);
    return true;
  }

  Future<bool> cancelTask(String id) async {
    final ok = await (onCancel?.call(id) ?? Future.value(false));
    setState(id, TransferState.canceled);
    return ok;
  }

  void remove(String id) {
    _tasks.value = _tasks.value.where((e) => e.id != id).toList();
    persist();
  }

  Future<void> persist() async {
    await StorageUtil.setString(
      'transfer_tasks',
      jsonEncode(_tasks.value.map((t) => t.toJson()).toList()),
    );
  }

  Future<void> load() async {
    final raw = await StorageUtil.getString('transfer_tasks');
    if (raw == null || raw.isEmpty) {
      _tasks.value = const [];
      return;
    }
    final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    _tasks.value = list.map(TransferTask.fromJson).toList();
  }

  /// app 启动时恢复未完成传输（依赖引擎自身的持久化队列续传）。
  Future<void> resumeUnfinishedOnStartup() async {
    await load();
    for (final t in _tasks.value) {
      if (t.state == TransferState.queued ||
          t.state == TransferState.active ||
          t.state == TransferState.paused) {
        await resumeTask(t.id);
      }
    }
  }

  /// 订阅 background_downloader 的进度/状态流，刷新本地任务状态。
  void listenUpdates() {
    FileDownloader().updates.listen((update) {
      if (update is TaskStatusUpdate) {
        final s = _mapStatus(update.status);
        if (s != null) setState(update.task.taskId, s);
      } else if (update is TaskProgressUpdate) {
        final total = update.expectedFileSize;
        if (total > 0) {
          updateProgress(
            update.task.taskId,
            (update.progress * total).toInt(),
            total,
          );
        }
      }
    });
  }

  static TransferState? _mapStatus(TaskStatus s) {
    switch (s) {
      case TaskStatus.enqueued:
      case TaskStatus.running:
      case TaskStatus.waitingToRetry:
        return TransferState.active;
      case TaskStatus.paused:
        return TransferState.paused;
      case TaskStatus.complete:
        return TransferState.done;
      case TaskStatus.failed:
      case TaskStatus.notFound:
        return TransferState.error;
      case TaskStatus.canceled:
        return TransferState.canceled;
    }
  }
}

final transferStore = TransferStore();
