part of 'dsm_api.dart';

/// {
///   "success": true,
///   "data": {
///     "enabled": true,
///     "auto_copy": true,
///     "destination": "/volume1/usbcopy"
///   }
/// }
Future<Map> dsmUSBCopyGetSettings({CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.USBCopy', method: 'GetSettings', version: 1);
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
//Log.info("dsmUSBCopyGetSettings: $res");
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
///         "name": "Photos Backup",
///         "enabled": true,
///         "source_filter": "*.jpg,*.png",
///         "destination": "/volume1/usbcopy/photos"
///       }
///     ],
///     "total": 1
///   }
/// }
///
/// **Response Fields:**
///
/// | Field | Type | Description |
/// |-------|------|-------------|
/// | `task_id` | integer | Task ID |
/// | `name` | string | Task name |
/// | `enabled` | boolean | Task enabled |
/// | `source_filter` | string | File filter pattern |
/// | `destination` | string | Destination path |
///
/// ---
Future<Map> dsmUSBCopyTaskList({CancelToken? cancelToken}) async {
  final data =
      _dsmApiRequestData(api: 'SYNO.USBCopy.Task', method: 'List', version: 1);
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
//Log.info("dsmUSBCopyTaskList: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

/// {
///   "success": true,
///   "data": {
///     "task_id": 1,
///     "name": "Photos Backup",
///     "enabled": true,
///     "source_filter": "*.jpg,*.png",
///     "destination": "/volume1/usbcopy/photos",
///     "overwrite": false,
///     "remove_source": false
///   }
/// }
Future<Map> dsmUSBCopyTaskGet(int taskId, // Task ID
    {CancelToken? cancelToken}) async {
  final data =
      _dsmApiRequestData(api: 'SYNO.USBCopy.Task', method: 'Get', version: 1);
  data['task_id'] = taskId;
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
//Log.info("dsmUSBCopyTaskGet: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

/// {
///   "success": true
/// }
Future<Map> dsmUSBCopyTaskEnable(
    int taskId, // Task ID
    bool enable, // Enable status (true/false)
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.USBCopy.Task', method: 'Enable', version: 1);
  data['task_id'] = taskId;
  data['enable'] = enable;
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
//Log.info("dsmUSBCopyTaskEnable: $res");
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
///         "task_id": 1,
///         "status": "success",
///         "files_copied": 25,
///         "bytes_copied": 104857600
///       }
///     ],
///     "total": 1
///   }
/// }
///
/// **Response Fields:**
///
/// | Field | Type | Description |
/// |-------|------|-------------|
/// | `time` | integer | Log timestamp (Unix time) |
/// | `task_id` | integer | Task ID |
/// | `status` | string | Copy status (`success`, `failed`, `partial`) |
/// | `files_copied` | integer | Number of files copied |
/// | `bytes_copied` | integer | Bytes copied |
///
/// **Notes:**
/// - USB Copy package must be installed
/// - Automatically copies files when USB device is connected
/// - Supports file filters and destination folders
/// - Can be triggered manually or automatically
/// - Logs track all copy operations
///
/// ---
Future<Map> dsmUSBCopyLogList(
    {int? offset, // Starting index (default: 0)
    int? limit, // Max results (default: 200)
    CancelToken? cancelToken}) async {
  final data =
      _dsmApiRequestData(api: 'SYNO.USBCopy.Log', method: 'List', version: 1);
  if (offset != null) data['offset'] = offset;
  if (limit != null) data['limit'] = limit;
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
//Log.info("dsmUSBCopyLogList: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}
