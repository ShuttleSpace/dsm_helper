part of 'dsm_api.dart';

/// {
///   "success": true,
///   "data": {
///     "total": 2,
///     "offset": 0,
///     "tasks": [
///       {
///         "id": "dbid_1",
///         "type": "bt",
///         "username": "admin",
///         "title": "ubuntu-22.04.iso",
///         "size": 3774873600,
///         "status": "downloading",
///         "additional": {
///           "detail": {
///             "destination": "/downloads",
///             "uri": "magnet:?xt=urn:btih:..."
///           },
///           "transfer": {
///             "size_downloaded": 1887436800,
///             "size_uploaded": 94371840,
///             "speed_download": 1048576,
///             "speed_upload": 52428
///           }
///         }
///       }
///     ]
///   }
/// }
Future<Map> dsmDownloadStationTaskList(
    {int? offset, // Starting index (default: 0)
    int? limit, // Max results (default: -1 = all)
    String?
        additional, // Additional fields (comma-separated): `detail`, `transfer`, `file`, `tracker`, `peer`
    CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.DownloadStation.Task', method: 'list', version: 1);
  if (offset != null) data['offset'] = offset;
  if (limit != null) data['limit'] = limit;
  if (additional != null && additional.isNotEmpty) {
    data['additional'] = additional;
  }
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
  Log.info("dsmDownloadStationTaskList: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'];
}

/// {
///   "success": true,
///   "data": {
///     "tasks": [
///       {
///         "id": "dbid_1",
///         "type": "bt",
///         "title": "ubuntu-22.04.iso",
///         "size": 3774873600,
///         "status": "downloading"
///       }
///     ]
///   }
/// }
Future<Map> dsmDownloadStationTaskGetinfo(
    String id, // Task ID (comma-separated for multiple)
    {String? additional, // Additional fields
    CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.DownloadStation.Task', method: 'getinfo', version: 1);
  data['id'] = id;
  if (additional != null && additional.isNotEmpty) {
    data['additional'] = additional;
  }
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
  Log.info("dsmDownloadStationTaskGetinfo: $res");
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
/// - Use either `uri` or `file`, not both
/// - Supports HTTP, HTTPS, FTP, magnet links, and torrent files
Future<Map> dsmDownloadStationTaskCreate(
    {String? uri, // Download URL (HTTP, FTP, magnet, etc.)
    MultipartFile? file, // Torrent file (multipart/form-data)
    String? destination, // Download destination path
    CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.DownloadStation.Task', method: 'create', version: 3);
  if (uri != null && uri.isNotEmpty) data['uri'] = uri;
  if (file != null) data['file'] = file;
  if (destination != null && destination.isNotEmpty) {
    data['destination'] = destination;
  }
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.info("dsmDownloadStationTaskCreate: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'];
}

/// {
///   "success": true
/// }
Future<Map> dsmDownloadStationTaskDelete(
    String id, // Task ID (comma-separated for multiple)
    {bool? forceComplete, // Force delete even if not complete
    CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.DownloadStation.Task', method: 'delete', version: 1);
  data['id'] = id;
  if (forceComplete != null) data['force_complete'] = forceComplete;
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.info("dsmDownloadStationTaskDelete: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'];
}

/// {
///   "success": true
/// }
Future<Map> dsmDownloadStationTaskPause(
    String id, // Task ID (comma-separated for multiple)
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.DownloadStation.Task', method: 'pause', version: 1);
  data['id'] = id;
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.info("dsmDownloadStationTaskPause: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'];
}

/// {
///   "success": true
/// }
Future<Map> dsmDownloadStationTaskResume(
    String id, // Task ID (comma-separated for multiple)
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.DownloadStation.Task', method: 'resume', version: 1);
  data['id'] = id;
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.info("dsmDownloadStationTaskResume: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'];
}

/// {
///   "success": true
/// }
Future<Map> dsmDownloadStationTaskEdit(
    String id, // Task ID (comma-separated for multiple)
    {String? destination, // New download destination
    CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.DownloadStation.Task', method: 'edit', version: 1);
  data['id'] = id;
  if (destination != null && destination.isNotEmpty) {
    data['destination'] = destination;
  }
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.info("dsmDownloadStationTaskEdit: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'];
}
