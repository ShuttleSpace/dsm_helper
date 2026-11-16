part of 'dsm_api.dart';

/// {
///   "success": true,
///   "data": {
///     "folders": [
///       {
///         "path": "/docker/new_folder",
///         "name": "new_folder",
///         "isdir": true
///       }
///     ]
///   }
/// }
Future<Map> dsmFileStationCreateFolder(
    String folderPath, // Parent folder path (JSON array for multiple)
    String name, // Folder name (JSON array for multiple)
    {bool? forceParent, // Create parent folders (default: false)
    String? additionial, // Additional fields
    CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.FileStation.CreateFolder', method: 'create', version: 2);
  data['folder_path'] = folderPath;
  data['name'] = name;
  if (forceParent != null) {
    data['force_parent'] = forceParent;
  }
  if (additionial != null && additionial.isNotEmpty) {
    data['additional'] = additionial;
  }
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
//Log.info("dsmFileStationCreateFolder: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

/// {
///   "success": true,
///   "data": {
///     "files": [
///       {
///         "path": "/docker/new_name.txt",
///         "name": "new_name.txt",
///         "isdir": false
///       }
///     ]
///   }
/// }
Future<Map> dsmFileStationRename(
    String path, // Source path (JSON array for multiple)
    String name, // New name (JSON array for multiple)
    {String? searchTaskid, // Search task ID
    String? additionial, // Additional fields
    CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.FileStation.Rename', method: 'rename', version: 2);
  data['path'] = path;
  data['name'] = name;
  if (searchTaskid != null && searchTaskid.isNotEmpty) {
    data['search_taskid'] = searchTaskid;
  }
  if (additionial != null && additionial.isNotEmpty) {
    data['additional'] = additionial;
  }
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
//Log.info("dsmFileStationRename: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

/// {
///   "success": true,
///   "data": {
///     "taskid": "FileStation_CopyMove_12345"
///   }
/// }
Future<Map> dsmFileStationCopyMoveStart(
    String path, // Source path (JSON array for multiple)
    String destFolderPath, // Destination folder
    {bool? overwrite, // Overwrite existing (default: false)
    bool? removeSrc, // Move instead of copy (default: false)
    bool? accurateProgress, // Accurate progress (default: false)
    String? searchTaskid, // Search task ID
    CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.FileStation.CopyMove', method: 'start', version: 3);
  data['path'] = path;
  data['dest_folder_path'] = destFolderPath;
  if (searchTaskid != null && searchTaskid.isNotEmpty) {
    data['search_taskid'] = searchTaskid;
  }
  if (overwrite != null) {
    data['overwrite'] = overwrite;
  }
  if (removeSrc != null) {
    data['remove_src'] = removeSrc;
  }
  if (accurateProgress != null) {
    data['accurate_progress'] = accurateProgress;
  }
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
//Log.info("dsmFileStationCopyMoveStart: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

/// {
///   "success": true,
///   "data": {
///     "finished": false,
///     "processing_path": "/docker/large_file.bin",
///     "progress": 45.5,
///     "total": 100,
///     "num_processed": 45
///   }
/// }
Future<Map> dsmFileStationCopyMoveStatus(String taskid, // Task ID
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.FileStation.CopyMove', method: 'status', version: 3);
  data['taskid'] = taskid;
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
//Log.info("dsmFileStationCopyMoveStatus: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

/// {
///   "success": true
/// }
Future<Map> dsmFileStationCopyMoveStop(String taskid, // Task ID
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.FileStation.CopyMove', method: 'stop', version: 3);
  data['taskid'] = taskid;
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
//Log.info("dsmFileStationCopyMoveStop: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

/// {
///   "success": true,
///   "data": {
///     "taskid": "FileStation_Delete_12345"
///   }
/// }
Future<Map> dsmFileStationDeleteStart(
    String path, // File/folder path (JSON array for multiple)
    {bool? accurateProgress, // Accurate progress (default: false)
    bool? recursive, // Delete recursively (default: false)
    String? searchTaskid, // Search task ID
    CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.FileStation.Delete', method: 'start', version: 2);
  data['path'] = path;
  if (searchTaskid != null && searchTaskid.isNotEmpty) {
    data['search_taskid'] = searchTaskid;
  }
  if (accurateProgress != null) {
    data['accurate_progress'] = accurateProgress;
  }
  if (recursive != null) {
    data['recursive'] = recursive;
  }
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
//Log.info("dsmFileStationDeleteStart: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

Map<String, dynamic> dsmFileStationDeleteStatusRequestData(
  String taskid, // Task ID
) {
  final data = _dsmApiRequestData(
      api: 'SYNO.FileStation.Delete', method: 'status', version: 2);
  data['taskid'] = taskid;
  return data;
}

/// {
///   "success": true,
///   "data": {
///     "finished": true,
///     "progress": 100,
///     "total": 2,
///     "num_processed": 2
///   }
/// }
Future<Map> dsmFileStationDeleteStatus(String taskid, // Task ID
    {CancelToken? cancelToken}) async {
  final data = dsmFileStationDeleteStatusRequestData(taskid);
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
//Log.info("dsmFileStationDeleteStatus: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

/// {
///   "success": true
/// }
Future<Map> dsmFileStationDeleteStop(String taskid, // Task ID
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.FileStation.Delete', method: 'stop', version: 2);
  data['taskid'] = taskid;
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
//Log.info("dsmFileStationDeleteStop: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}
