part of 'dsm_api.dart';

/// {
///   "success": true,
///   "data": {
///     "logs": [
///       {
///         "time": 1732788000,
///         "level": "info",
///         "user": "admin",
///         "event": "User logged in",
///         "ip": "192.168.1.100"
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
/// | `level` | string | Log level (`info`, `warning`, `error`) |
/// | `user` | string | Username |
/// | `event` | string | Event description |
/// | `ip` | string | Source IP address |
///
/// ---
Future<Map> dsmCoreSyslogClientLogList(
    {int? offset,
    int? limit,
    String? target, // LOCAL
    String?
        logtype, // String, comma separated, ftp,filestation,webdav,cifs,tftp,afp
    String? sortBy,
    String? sortDirection,
    CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.Core.SyslogClient.Log', method: 'List', version: 1);
  if (offset != null) data['offset'] = offset;
  if (limit != null) data['limit'] = limit;
  if (target != null && target.isNotEmpty) data['target'] = target;
  if (logtype != null && logtype.isNotEmpty) data['logtype'] = logtype;
  if (sortBy != null && sortBy.isNotEmpty) data['sort_by'] = sortBy;
  if (sortDirection != null && sortDirection.isNotEmpty) {
    data['sort_direction'] = sortDirection;
  }
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
  Log.info("dsmCoreSyslogClientLogList: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'];
}

/// {
///   "success": true,
///   "data": {
///     "total_logs": 12345,
///     "info_count": 10000,
///     "warning_count": 2000,
///     "error_count": 345
///   }
/// }
Future<Map> dsmCoreSyslogClientStatusGetCount(
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.Core.SyslogClient.Status', method: 'GetCount', version: 1);
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
  Log.info("dsmCoreSyslogClientStatusGetCount: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'];
}

/// {
///   "success": true,
///   "data": {
///     "events_per_second": 15.3,
///     "peak_eps": 120.5
///   }
/// }
///
/// **Notes:**
/// - EPS = Events Per Second
/// - Useful for monitoring log volume
///
/// ---
Future<Map> dsmCoreSyslogClientStatusGetEPS({CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.Core.SyslogClient.Status', method: 'GetEPS', version: 1);
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
  Log.info("dsmCoreSyslogClientStatusGetEPS: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'];
}

Future<Map> dsmCoreSyslogClientStatusLatestLogGet(
    {int? start = 0,
    int? limit = 50,
    bool? widget = true,
    String? dir = '"desc"',
    CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.Core.SyslogClient.Status',
      method: 'latestlog_get',
      version: 1);
  if (start != null) data['start'] = start;
  if (limit != null) data['limit'] = limit;
  if (widget != null) data['widget'] = widget;
  if (dir != null && dir.isNotEmpty) {
    data['dir'] = dir;
  }
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
  Log.info("dsmCoreSyslogClientStatusLatestLogGet: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'];
}

/// {
///   "success": true,
///   "data": {
///     "storage_path": "/volume1/logs",
///     "max_size": 10737418240,
///     "current_size": 5368709120,
///     "rotation_enabled": true
///   }
/// }
///
/// **Notes:**
/// - Log Center package must be installed
/// - Logs can be stored locally or sent to remote syslog server
/// - Log rotation prevents disk space exhaustion
/// - Supports filtering by time, level, user, event
///
/// ---
Future<Map> dsmCoreSyslogClientSettingStorageList(
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.Core.SyslogClient.Setting.Storage',
      method: 'List',
      version: 1);
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
  Log.info("dsmCoreSyslogClientSettingStorageList: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'];
}
