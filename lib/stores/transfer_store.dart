import 'dart:convert';
import 'dart:io';

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

class TransferStep {
  const TransferStep({
    required this.id,
    required this.localPath,
    required this.remotePath,
    this.totalBytes = 0,
    this.transferredBytes = 0,
    this.state = TransferState.queued,
    this.modifyTime,
    this.errorMessage,
  });

  final String id;
  final String localPath;
  final String remotePath;
  final int totalBytes;
  final int transferredBytes;
  final TransferState state;
  final DateTime? modifyTime;
  final String? errorMessage;

  TransferStep copyWith({
    int? transferredBytes,
    int? totalBytes,
    TransferState? state,
    DateTime? modifyTime,
    String? errorMessage,
  }) =>
      TransferStep(
        id: id,
        localPath: localPath,
        remotePath: remotePath,
        totalBytes: totalBytes ?? this.totalBytes,
        transferredBytes: transferredBytes ?? this.transferredBytes,
        state: state ?? this.state,
        modifyTime: modifyTime ?? this.modifyTime,
        errorMessage: errorMessage ?? this.errorMessage,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'localPath': localPath,
        'remotePath': remotePath,
        'totalBytes': totalBytes,
        'transferredBytes': transferredBytes,
        'state': state.index,
        'modifyTime': modifyTime?.millisecondsSinceEpoch,
        'errorMessage': errorMessage,
      };

  factory TransferStep.fromJson(Map<String, dynamic> j) {
    final ms = j['modifyTime'] as num?;
    return TransferStep(
      id: j['id'] as String,
      localPath: j['localPath'] as String,
      remotePath: j['remotePath'] as String,
      totalBytes: j['totalBytes'] as int? ?? 0,
      transferredBytes: j['transferredBytes'] as int? ?? 0,
      state: TransferState.values[j['state'] as int? ?? 0],
      modifyTime: ms == null || ms <= 0
          ? null
          : DateTime.fromMillisecondsSinceEpoch(ms.toInt()),
      errorMessage: j['errorMessage'] as String?,
    );
  }
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
    this.steps,
    this.createdAt,
    this.updatedAt,
    this.speedBytesPerSecond,
    this.etaSeconds,
    this.errorMessage,
    this.statusCode,
    this.enqueueFailed = false,
  });

  final String id;
  final TransferType type;
  final String localPath;
  final String remotePath;
  final int totalBytes;
  final int transferredBytes;
  final TransferState state;
  final List<ChunkState>? chunks;
  final List<TransferStep>? steps;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final double? speedBytesPerSecond;
  final int? etaSeconds;
  final String? errorMessage;
  final int? statusCode;
  /// 入队阶段失败：后续子步骤回调不能再把父任务改成完成。
  final bool enqueueFailed;

  TransferTask copyWith({
    int? totalBytes,
    int? transferredBytes,
    TransferState? state,
    List<ChunkState>? chunks,
    List<TransferStep>? steps,
    DateTime? createdAt,
    DateTime? updatedAt,
    double? speedBytesPerSecond,
    int? etaSeconds,
    String? errorMessage,
    int? statusCode,
    bool? enqueueFailed,
    bool resetError = false,
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
        steps: steps ?? this.steps,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        speedBytesPerSecond:
            resetError ? null : speedBytesPerSecond ?? this.speedBytesPerSecond,
        etaSeconds: resetError ? null : etaSeconds ?? this.etaSeconds,
        errorMessage: resetError ? null : errorMessage ?? this.errorMessage,
        statusCode: resetError ? null : statusCode ?? this.statusCode,
        enqueueFailed: resetError ? false : enqueueFailed ?? this.enqueueFailed,
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
        if (steps != null) 'steps': steps!.map((s) => s.toJson()).toList(),
        'createdAt': createdAt?.millisecondsSinceEpoch,
        'updatedAt': updatedAt?.millisecondsSinceEpoch,
        'speedBytesPerSecond': speedBytesPerSecond,
        'etaSeconds': etaSeconds,
        'errorMessage': errorMessage,
        'statusCode': statusCode,
        'enqueueFailed': enqueueFailed,
      };

  factory TransferTask.fromJson(Map<String, dynamic> j) {
    DateTime? readTime(String key) {
      final ms = j[key] as num?;
      return ms == null || ms <= 0
          ? null
          : DateTime.fromMillisecondsSinceEpoch(ms.toInt());
    }

    return TransferTask(
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
      steps: (j['steps'] as List?)
          ?.cast<Map<String, dynamic>>()
          .map(TransferStep.fromJson)
          .toList(),
      createdAt: readTime('createdAt'),
      updatedAt: readTime('updatedAt'),
      speedBytesPerSecond: (j['speedBytesPerSecond'] as num?)?.toDouble(),
      etaSeconds: j['etaSeconds'] as int?,
      errorMessage: j['errorMessage'] as String?,
      statusCode: j['statusCode'] as int?,
      enqueueFailed: j['enqueueFailed'] as bool? ?? false,
    );
  }
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
    final now = DateTime.now();
    _tasks.value = [
      ..._tasks.value.where((e) => e.id != t.id),
      t.copyWith(createdAt: t.createdAt ?? now, updatedAt: now),
    ];
    persist();
  }

  /// 引擎回调可能带的是子步骤 id，先找到它所属的父任务。
  ({String groupId, TransferStep step})? findStepOwner(String stepId) {
    for (final t in _tasks.value) {
      final step = t.steps?.where((s) => s.id == stepId).firstOrNull;
      if (step != null) return (groupId: t.id, step: step);
    }
    return null;
  }

  void updateStep(
    String groupId,
    String stepId, {
    int? transferred,
    int? total,
    TransferState? state,
    String? errorMessage,
    double? speedBytesPerSecond,
    int? etaSeconds,
    bool forceActive = false,
    bool resetError = false,
  }) {
    final parent = _find(groupId);
    if (parent?.steps == null) return;
    final now = DateTime.now();
    final steps = parent!.steps!.map((s) {
      if (s.id != stepId) return s;
      final active = forceActive && s.state == TransferState.queued
          ? TransferState.active
          : null;
      return s.copyWith(
        transferredBytes: transferred ??
            (state == TransferState.done ? total ?? s.totalBytes : null),
        totalBytes: total,
        state: state ?? active,
        errorMessage: resetError ? null : errorMessage,
      );
    }).toList();
    _replace(_withSteps(parent, steps,
        stickyError: !resetError,
        speedBytesPerSecond: speedBytesPerSecond,
        etaSeconds: etaSeconds,
        errorMessage: errorMessage,
        updatedAt: now,
        resetError: resetError));
  }

  TransferTask _withSteps(
    TransferTask parent,
    List<TransferStep> steps, {
    // 入队失败等人工标记的错误不能被后续子步骤回调冲掉。
    bool stickyError = false,
    double? speedBytesPerSecond,
    int? etaSeconds,
    String? errorMessage,
    DateTime? updatedAt,
    bool resetError = false,
  }) {
    final total = steps.fold<int>(0, (sum, s) => sum + s.totalBytes);
    final transferred = steps.fold<int>(0, (sum, s) => sum + s.transferredBytes);
    TransferState state;
    if (steps.any((s) => s.state == TransferState.error)) {
      state = TransferState.error;
    } else if (steps.any((s) =>
        s.state == TransferState.queued || s.state == TransferState.active)) {
      state = TransferState.active;
    } else if (steps.every((s) => s.state == TransferState.done)) {
      state = TransferState.done;
    } else if (steps.every((s) => s.state == TransferState.canceled)) {
      state = TransferState.canceled;
    } else {
      state = TransferState.paused;
    }
    final errorStep = steps.where((s) => s.state == TransferState.error).firstOrNull;
    final effectiveError =
        (stickyError && parent.state == TransferState.error) ||
            (parent.enqueueFailed && !resetError);
    return parent.copyWith(
      steps: steps,
      totalBytes: total,
      transferredBytes: transferred,
      state: effectiveError ? TransferState.error : state,
      speedBytesPerSecond: speedBytesPerSecond,
      etaSeconds: etaSeconds,
      errorMessage: effectiveError
          ? (parent.errorMessage ?? errorMessage ?? errorStep?.errorMessage)
          : (errorMessage ?? (resetError ? null : errorStep?.errorMessage)),
      statusCode: effectiveError || errorStep != null ? parent.statusCode : null,
      updatedAt: updatedAt ?? DateTime.now(),
      resetError: resetError,
    );
  }

  void addStep(String groupId, TransferStep step, {bool stickyError = false}) {
    final parent = _find(groupId);
    if (parent?.steps == null) return;
    _replace(_withSteps(parent!, [...parent.steps!, step],
        stickyError: stickyError));
  }

  void removeStep(String groupId, String stepId) {
    final parent = _find(groupId);
    if (parent?.steps == null) return;
    _replace(_withSteps(
        parent!, parent.steps!.where((s) => s.id != stepId).toList(),
        stickyError: true));
  }

  void updateProgress(
    String id,
    int transferred,
    int total, {
    double? speedBytesPerSecond,
    int? etaSeconds,
  }) {
    final owner = findStepOwner(id);
    if (owner != null) {
      updateStep(owner.groupId, id,
          transferred: transferred,
          total: total,
          speedBytesPerSecond: speedBytesPerSecond,
          etaSeconds: etaSeconds,
          forceActive: true);
      return;
    }
    final t = _find(id);
    if (t == null) return;
    _replace(t.copyWith(
      transferredBytes: transferred,
      totalBytes: total,
      speedBytesPerSecond: speedBytesPerSecond,
      etaSeconds: etaSeconds,
      updatedAt: DateTime.now(),
    ));
  }

  void setState(String id, TransferState s) {
    final owner = findStepOwner(id);
    if (owner != null) {
      updateStep(owner.groupId, id, state: s);
      return;
    }
    final t = _find(id);
    if (t == null) return;
    _replace(t.copyWith(state: s, updatedAt: DateTime.now()));
  }

  /// 返回父任务中每个需要清理的引擎任务 id：有子步骤时是步骤 id。
  List<String> engineTaskIds(String id) {
    final t = _find(id);
    if (t?.steps != null) return t!.steps!.map((s) => s.id).toList();
    return [id];
  }

  void setError(String id, String message,
      {int? statusCode, bool manual = false}) {
    final owner = findStepOwner(id);
    if (owner != null) {
      updateStep(owner.groupId, id,
          state: TransferState.error, errorMessage: message);
      return;
    }
    final t = _find(id);
    if (t == null) return;
    _replace(t.copyWith(
      state: TransferState.error,
      errorMessage: message,
      statusCode: statusCode,
      enqueueFailed: manual ? true : null,
      updatedAt: DateTime.now(),
    ));
  }

  void clearTransferError(String id) {
    final owner = findStepOwner(id);
    if (owner != null) {
      updateStep(owner.groupId, id, resetError: true);
      return;
    }
    final t = _find(id);
    if (t == null) return;
    _replace(t.copyWith(resetError: true, updatedAt: DateTime.now()));
  }

  void _replace(TransferTask t) {
    _tasks.value = [..._tasks.value.where((e) => e.id != t.id), t];
    persist();
  }

  bool get hasDefaultControlHooks => true;

  ControlHook defaultControlFor(String kind) => (id) async {
    final downloader = FileDownloader();
    if (kind == 'cancel') {
      return downloader.cancelTaskWithId(id);
    }
    final task = await downloader.taskForId(id);
    if (task == null) return false;
    if (task is UploadTask) {
      // FileDownloader.pause 只收 DownloadTask；上传走底层 pause。
      return false;
    }
    return switch (kind) {
      'resume' => downloader.resume(task as DownloadTask),
      'pause' => downloader.pause(task as DownloadTask),
      _ => false,
    };
  };

  Future<bool> _control(
    String id,
    ControlHook? hook,
    ControlHook defaultHook,
  ) async {
    final t = _find(id);
    if (t?.steps != null) {
      final results = <bool>[];
      for (final step in t!.steps!) {
        results.add(await (hook ?? defaultHook).call(step.id));
      }
      return results.any((ok) => ok);
    }
    return (hook ?? defaultHook).call(id);
  }

  Future<bool> resumeTask(String id) async {
    final ok = await _control(id, onResume, defaultControlFor('resume'));
    if (ok) {
      clearTransferError(id);
      setState(id, TransferState.active);
    }
    return ok;
  }

  Future<bool> pauseTask(String id) async {
    // 引擎暂停对默认不允许暂停的上传任务会返回 false，但本地状态照常翻转，
    // 让 UI 反映用户意图；真正停止上传靠取消/重试。
    await _control(id, onPause, defaultControlFor('pause'));
    setState(id, TransferState.paused);
    return true;
  }

  Future<bool> cancelTask(String id) async {
    final ok = await _control(id, onCancel, defaultControlFor('cancel'));
    setState(id, TransferState.canceled);
    return ok;
  }

  /// 删除父任务所有子步骤的本地缓存文件。
  void deleteTransferCache(String groupId) {
    final parent = _find(groupId);
    if (parent?.steps == null) return;
    for (final step in parent!.steps!) {
      final file = File(step.localPath);
      if (file.existsSync()) {
        try {
          file.deleteSync();
        } catch (_) {}
      }
      final dir = file.parent;
      if (dir.existsSync()) {
        try {
          dir.deleteSync();
        } catch (_) {}
      }
    }
  }

  /// 一处完成引擎记录、缓存和本地记录的清理。
  Future<void> deleteTask(TransferTask t) async {
    for (final id in t.steps == null ? [t.id] : t.steps!.map((s) => s.id)) {
      await FileDownloader().cancelTaskWithId(id);
      await FileDownloader().database.deleteRecordWithId(id);
    }
    deleteTransferCache(t.id);
    remove(t.id);
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

  /// 备份父任务完成时推进 last_backup_time，只向前推进；app 生命周期内只需调用一次。
  void Function() startBackupTimeSync() {
    final subscription = tasks.toStream().listen((all) async {
      DateTime? latest;
      for (final t in all) {
        if (t.steps == null || t.state != TransferState.done) continue;
        for (final s in t.steps!) {
          final time = s.modifyTime;
          if (time != null && (latest == null || time.isAfter(latest))) {
            latest = time;
          }
        }
      }
      if (latest == null) return;
      final stored =
          int.tryParse(await StorageUtil.getString('last_backup_time') ?? '') ?? 0;
      if (latest.millisecondsSinceEpoch > stored) {
        await StorageUtil.setString(
            'last_backup_time', latest.millisecondsSinceEpoch.toString());
      }
    });
    return subscription.cancel;
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

  /// 由状态回调（UI isolate 汇总）写入任务状态。
  /// registerCallbacks 会屏蔽 updates 流，故不能只靠 [listenUpdates]。
  void applyTaskStatus(String id, TaskStatus status) {
    final s = _mapStatus(status);
    if (s != null) setState(id, s);
  }

  /// 状态回调带错误时保留可读原因；不展示响应体。
  void applyTaskStatusUpdate(TaskStatusUpdate update) {
    final exception = update.exception;
    if (exception != null && _mapStatus(update.status) == TransferState.error) {
      final statusCode = update.responseStatusCode ??
          (exception is TaskHttpException && exception.httpResponseCode > 0
              ? exception.httpResponseCode
              : null);
      setError(
        update.task.taskId,
        exception.description,
        statusCode: statusCode,
      );
      return;
    }
    applyTaskStatus(update.task.taskId, update.status);
  }

  /// 订阅 background_downloader 的进度/状态流，刷新本地任务状态。
  void listenUpdates() {
    FileDownloader().updates.listen((update) {
      if (update is TaskStatusUpdate) {
        applyTaskStatusUpdate(update);
      } else if (update is TaskProgressUpdate) {
        final total = update.hasExpectedFileSize ? update.expectedFileSize : -1;
        if (total > 0) {
          updateProgress(
            update.task.taskId,
            (update.progress * total).toInt(),
            total,
            speedBytesPerSecond:
                update.hasNetworkSpeed ? update.networkSpeed * 1024 * 1024 : null,
            etaSeconds:
                update.hasTimeRemaining ? update.timeRemaining.inSeconds : null,
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
