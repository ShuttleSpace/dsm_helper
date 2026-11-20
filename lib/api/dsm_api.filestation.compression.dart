part of 'dsm_api.dart';

/// {
///   "success": true,
///   "data": {
///     "taskid": "FileStation_Compress_12345"
///   }
/// }
Future<Map> dsmFileStationCompressStart(
    String path, // File/folder path (JSON array for multiple)
    String destFilePath, // Destination archive path
    {String? level,
    String? mode,
    String? format,
    String? password,
    CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.FileStation.Compress', method: 'start', version: 3);
  data['path'] = path;
  data['dest_file_path'] = destFilePath;
  if (level != null && level.isNotEmpty) data['level'] = level;
  if (mode != null && mode.isNotEmpty) data['mode'] = mode;
  if (format != null && format.isNotEmpty) data['format'] = format;
  if (password != null && password.isNotEmpty) data['_password'] = password;
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
//Log.info("dsmFileStationCompressStart: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

/// {
///   "success": true,
///   "data": {
///     "finished": false,
///     "progress": 45.5,
///     "total": 100,
///     "num_processed": 45
///   }
/// }
Future<Map> dsmFileStationCompressStatus(String taskid,
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.FileStation.Compress', method: 'status', version: 3);
  data['taskid'] = taskid;
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
//Log.info("dsmFileStationCompressStatus: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

/// {
///   "success": true
/// }
Future<Map> dsmFileStationCompressStop(String taskid,
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.FileStation.Compress', method: 'stop', version: 3);
  data['taskid'] = taskid;
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
//Log.info("dsmFileStationCompressStop: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

/// {
///   "success": true,
///   "data": {
///     "taskid": "FileStation_Extract_12345"
///   }
/// }
Future<Map> dsmFileStationExtractStart(
    String filePath, // Archive file path
    String destFolderPath, // Destination folder
    {bool? overwrite,
    bool? keepDir,
    bool? createSubfolder,
    String? codepage,
    String? password,
    String? itemId,
    CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.FileStation.Extract', method: 'start', version: 2);
  data['file_path'] = filePath;
  data['dest_folder_path'] = destFolderPath;
  if (overwrite != null) data['overwrite'] = overwrite;
  if (keepDir != null) data['keep_dir'] = keepDir;
  if (createSubfolder != null) data['create_subfolder'] = createSubfolder;
  if (codepage != null && codepage.isNotEmpty) data['codepage'] = codepage;
  if (password != null && password.isNotEmpty) data['password'] = password;
  if (itemId != null && itemId.isNotEmpty) data['item_id'] = itemId;
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
//Log.info("dsmFileStationExtractStart: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

/// {
///   "success": true,
///   "data": {
///     "finished": false,
///     "progress": 65.0,
///     "total": 100,
///     "num_processed": 65
///   }
/// }
Future<Map> dsmFileStationExtractStatus(String taskid,
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.FileStation.Extract', method: 'status', version: 2);
  data['taskid'] = taskid;
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
//Log.info("dsmFileStationExtractStatus: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

/// {
///   "success": true
/// }
Future<Map> dsmFileStationExtractStop(String taskid,
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.FileStation.Extract', method: 'stop', version: 2);
  data['taskid'] = taskid;
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
//Log.info("dsmFileStationExtractStop: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}
