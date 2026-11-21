part of 'dsm_api.dart';

/// {
///   "success": true,
///   "data": {
///     "total": 3,
///     "offset": 0,
///     "tasks": [
///       {
///         "taskid": "FileStation_CopyMove_12345",
///         "api": "SYNO.FileStation.CopyMove",
///         "method": "start",
///         "finished": false,
///         "progress": 45.5
///       }
///     ]
///   }
/// }
Future<Map> dsmFileStationBackgroundTaskList(
    {int? offset,
    int? limit,
    String? sortBy,
    String? sortDirection,
    String? apiFilter, // Filter by API (JSON array)
    bool? isListSharemove,
    bool? isVfs,
    bool? bkgInfo,
    CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.FileStation.BackgroundTask', method: 'list', version: 3);
  if (offset != null) data['offset'] = offset;
  if (limit != null) data['limit'] = limit;
  if (sortBy != null && sortBy.isNotEmpty) data['sort_by'] = sortBy;
  if (sortDirection != null && sortDirection.isNotEmpty) {
    data['sort_direction'] = sortDirection;
  }
  if (apiFilter != null && apiFilter.isNotEmpty) {
    data['api_filter'] = apiFilter;
  }
  if (isListSharemove != null) data['is_list_sharemove'] = isListSharemove;
  if (isVfs != null) data['is_vfs'] = isVfs;
  if (bkgInfo != null) data['bkg_info'] = bkgInfo;
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
//Log.info("dsmFileStationBackgroundTaskList: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

/// {
///   "success": true,
///   "data": {
///     "taskid": "FileStation_DirSize_12345"
///   }
/// }
Future<Map> dsmFileStationDirSizeStart(
    String path, // Directory path (JSON array for multiple)
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.FileStation.DirSize', method: 'start', version: 2);
  data['path'] = path;
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
//Log.info("dsmFileStationDirSizeStart: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

/// {
///   "success": true,
///   "data": {
///     "finished": true,
///     "total_size": 1073741824,
///     "num_dirs": 150,
///     "num_files": 2500
///   }
/// }
Future<Map> dsmFileStationDirSizeStatus(String taskid,
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.FileStation.DirSize', method: 'status', version: 2);
  data['taskid'] = taskid;
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
//Log.info("dsmFileStationDirSizeStatus: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

/// {
///   "success": true
/// }
Future<Map> dsmFileStationDirSizeStop(String taskid,
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.FileStation.DirSize', method: 'stop', version: 2);
  data['taskid'] = taskid;
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
//Log.info("dsmFileStationDirSizeStop: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

/// {
///   "success": true,
///   "data": {
///     "taskid": "FileStation_MD5_12345"
///   }
/// }
Future<Map> dsmFileStationMD5Start(String filePath, // File path
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.FileStation.MD5', method: 'start', version: 2);
  data['file_path'] = filePath;
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
//Log.info("dsmFileStationMD5Start: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

/// {
///   "success": true,
///   "data": {
///     "finished": true,
///     "md5": "5d41402abc4b2a76b9719d911017c592"
///   }
/// }
Future<Map> dsmFileStationMD5Status(String taskid,
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.FileStation.MD5', method: 'status', version: 2);
  data['taskid'] = taskid;
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
//Log.info("dsmFileStationMD5Status: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

/// {
///   "success": true
/// }
Future<Map> dsmFileStationMD5Stop(String taskid,
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.FileStation.MD5', method: 'stop', version: 2);
  data['taskid'] = taskid;
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
//Log.info("dsmFileStationMD5Stop: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}
