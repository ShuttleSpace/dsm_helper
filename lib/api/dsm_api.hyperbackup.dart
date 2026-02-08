part of 'dsm_api.dart';

/// {
///   "success": true,
///   "data": {
///     "tasks": [
///       {
///         "task_id": "1",
///         "name": "Daily System Backup",
///         "status": "idle",
///         "last_backup_time": 1732788000,
///         "next_backup_time": 1732874400,
///         "destination": "rsync://backup.example.com/backups"
///       }
///     ],
///     "total": 1
///   }
/// }
///
/// **Task Status:**
/// - `idle` - Not running
/// - `running` - Backup in progress
/// - `suspended` - Backup suspended
/// - `error` - Error occurred
Future<Map> dsmBackupTaskList({CancelToken? cancelToken}) async {
  final data =
      _dsmApiRequestData(api: 'SYNO.Backup.Task', method: 'List', version: 1);
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
  Log.info("dsmBackupTaskList: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'];
}

/// {
///   "success": true,
///   "data": {
///     "task_id": "1",
///     "name": "Daily System Backup",
///     "status": "idle",
///     "source_folders": ["/volume1/important"],
///     "destination": "rsync://backup.example.com/backups",
///     "schedule": {
///       "enabled": true,
///       "hour": 2,
///       "minute": 0
///     }
///   }
/// }
Future<Map> dsmBackupTaskGet(String taskId, // Task ID
    {CancelToken? cancelToken}) async {
  final data =
      _dsmApiRequestData(api: 'SYNO.Backup.Task', method: 'Get', version: 1);
  data['task_id'] = taskId;
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
  Log.info("dsmBackupTaskGet: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'];
}

/// {
///   "success": true,
///   "data": {
///     "status": "running",
///     "progress": 45,
///     "files_backed_up": 150,
///     "bytes_backed_up": 104857600,
///     "estimated_time_remaining": 1800
///   }
/// }
Future<Map> dsmBackupTaskGetStatus(String taskId, // Task ID
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.Backup.Task', method: 'GetStatus', version: 1);
  data['task_id'] = taskId;
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
  Log.info("dsmBackupTaskGetStatus: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'];
}

/// {
///   "success": true
/// }
///
/// **Notes:**
/// - Runs backup immediately regardless of schedule
/// - Task must not already be running
Future<Map> dsmBackupTaskRun(String taskId, // Task ID
    {CancelToken? cancelToken}) async {
  final data =
      _dsmApiRequestData(api: 'SYNO.Backup.Task', method: 'Run', version: 1);
  data['task_id'] = taskId;
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.info("dsmBackupTaskRun: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'];
}

/// {
///   "success": true
/// }
Future<Map> dsmBackupTaskCancel(String taskId, // Task ID
    {CancelToken? cancelToken}) async {
  final data =
      _dsmApiRequestData(api: 'SYNO.Backup.Task', method: 'Cancel', version: 1);
  data['task_id'] = taskId;
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.info("dsmBackupTaskCancel: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'];
}

/// {
///   "success": true
/// }
///
/// **Notes:**
/// - Suspends running backup
/// - Can be resumed later
/// - Partial backup data is preserved
Future<Map> dsmBackupTaskSuspend(String taskId, // Task ID
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.Backup.Task', method: 'Suspend', version: 1);
  data['task_id'] = taskId;
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.info("dsmBackupTaskSuspend: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'];
}

/// {
///   "success": true
/// }
///
/// **Notes:**
/// - Resumes suspended backup
/// - Continues from suspension point
Future<Map> dsmBackupTaskResume(String taskId, // Task ID
    {CancelToken? cancelToken}) async {
  final data =
      _dsmApiRequestData(api: 'SYNO.Backup.Task', method: 'Resume', version: 1);
  data['task_id'] = taskId;
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.info("dsmBackupTaskResume: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'];
}
