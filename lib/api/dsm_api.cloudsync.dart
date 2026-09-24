part of 'dsm_api.dart';

/// {
///   "success": true,
///   "data": {
///     "connections": [
///       {
///         "conn_id": 1,
///         "cloud_type": "gdrive",
///         "display_name": "My Google Drive",
///         "status": "connected",
///         "account": "user@gmail.com"
///       }
///     ],
///     "total": 1
///   }
/// }
///
/// **Cloud Types:**
/// - `gdrive` - Google Drive
/// - `onedrive` - Microsoft OneDrive
/// - `dropbox` - Dropbox
/// - `s3` - Amazon S3
/// - `b2` - Backblaze B2
/// - `gcs` - Google Cloud Storage
/// - `azure` - Microsoft Azure
Future<Map> dsmCloudSyncConnectionList({CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.CloudSync.Connection', method: 'List', version: 1);
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
//Log.info("dsmCloudSyncConnectionList: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

/// {
///   "success": true,
///   "data": {
///     "conn_id": 1,
///     "cloud_type": "gdrive",
///     "display_name": "My Google Drive",
///     "status": "connected",
///     "account": "user@gmail.com",
///     "quota_total": 17179869184,
///     "quota_used": 5368709120
///   }
/// }
Future<Map> dsmCloudSyncConnectionGet(int connId, // Connection ID
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.CloudSync.Connection', method: 'Get', version: 1);
  data['conn_id'] = connId;
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
//Log.info("dsmCloudSyncConnectionGet: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

/// {
///   "success": true
/// }
///
/// **Notes:**
/// - Pauses all sync tasks for this connection
/// - Does not disconnect from cloud provider
Future<Map> dsmCloudSyncConnectionPause(int connId, // Connection ID
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.CloudSync.Connection', method: 'Pause', version: 1);
  data['conn_id'] = connId;
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
//Log.info("dsmCloudSyncConnectionPause: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

/// {
///   "success": true
/// }
Future<Map> dsmCloudSyncConnectionResume(int connId, // Connection ID
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.CloudSync.Connection', method: 'Resume', version: 1);
  data['conn_id'] = connId;
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
//Log.info("dsmCloudSyncConnectionResume: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

/// {
///   "success": true,
///   "data": {
///     "logs": [
///       {
///         "time": 1732788000,
///         "type": "info",
///         "message": "Sync completed successfully"
///       }
///     ],
///     "total": 1
///   }
/// }
///
/// **Log Types:**
/// - `info` - Information
/// - `warning` - Warning
/// - `error` - Error
///
/// **Notes:**
/// - Connection logs track sync activity and errors
/// - Useful for troubleshooting sync issues
/// - Logs are retained for limited time
Future<Map> dsmCloudSyncConnectionLogList(int connId, // Connection ID
    {int? offset, // Starting index (default: 0)
    int? limit, // Max results (default: 100)
    CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.CloudSync.Connection.Log', method: 'List', version: 1);
  data['conn_id'] = connId;
  if (offset != null) data['offset'] = offset;
  if (limit != null) data['limit'] = limit;
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
//Log.info("dsmCloudSyncConnectionLogList: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

/// {
///   "success": true,
///   "data": {
///     "tasks": [
///       {
///         "task_id": 1,
///         "conn_id": 1,
///         "name": "Documents Sync",
///         "local_path": "/volume1/Documents",
///         "remote_path": "/Documents",
///         "direction": "bidirectional",
///         "status": "syncing",
///         "progress": 45
///       }
///     ],
///     "total": 1
///   }
/// }
///
/// **Sync Directions:**
/// - `bidirectional` - Two-way sync
/// - `upload` - Local to cloud only
/// - `download` - Cloud to local only
///
/// **Task Status:**
/// - `idle` - Not syncing
/// - `syncing` - Currently syncing
/// - `paused` - Paused
/// - `error` - Error occurred
Future<Map> dsmCloudSyncTaskList(
    {int? connId, CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.CloudSync.Task', method: 'List', version: 1);
  if (connId != null) data['conn_id'] = connId;
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
//Log.info("dsmCloudSyncTaskList: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

/// {
///   "success": true,
///   "data": {
///     "task_id": 1,
///     "conn_id": 1,
///     "name": "Documents Sync",
///     "local_path": "/volume1/Documents",
///     "remote_path": "/Documents",
///     "direction": "bidirectional",
///     "status": "syncing",
///     "progress": 45,
///     "files_synced": 150,
///     "bytes_synced": 104857600,
///     "last_sync_time": 1732788000
///   }
/// }
Future<Map> dsmCloudSyncTaskGet(int taskId, // Task ID
    {CancelToken? cancelToken}) async {
  final data =
      _dsmApiRequestData(api: 'SYNO.CloudSync.Task', method: 'Get', version: 1);
  data['task_id'] = taskId;
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
//Log.info("dsmCloudSyncTaskGet: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

/// {
///   "success": true
/// }
Future<Map> dsmCloudSyncTaskPause(int taskId, // Task ID
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.CloudSync.Task', method: 'Pause', version: 1);
  data['task_id'] = taskId;
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
//Log.info("dsmCloudSyncTaskPause: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

/// {
///   "success": true
/// }
Future<Map> dsmCloudSyncTaskResume(int taskId, // Task ID
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.CloudSync.Task', method: 'Resume', version: 1);
  data['task_id'] = taskId;
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
//Log.info("dsmCloudSyncTaskResume: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

/// {
///   "success": true,
///   "data": {
///     "filters": [
///       {
///         "type": "exclude",
///         "pattern": "*.tmp"
///       },
///       {
///         "type": "exclude",
///         "pattern": ".DS_Store"
///       }
///     ]
///   }
/// }
///
/// **Filter Types:**
/// - `exclude` - Exclude matching files
/// - `include` - Include only matching files
///
/// **Notes:**
/// - Filters use wildcard patterns (`*`, `?`)
/// - Multiple filters can be applied
/// - Filters apply to both upload and download
/// - Common exclusions: temp files, system files, cache
Future<Map> dsmCloudSyncTaskFilterGet(int taskId, // Task ID
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.CloudSync.Task.Filter', method: 'Get', version: 1);
  data['task_id'] = taskId;
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
//Log.info("dsmCloudSyncTaskFilterGet: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}
