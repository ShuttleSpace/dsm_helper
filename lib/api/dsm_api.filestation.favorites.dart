part of 'dsm_api.dart';

/// {
///   "success": true,
///   "data": {
///     "total": 5,
///     "offset": 0,
///     "favorites": [
///       {
///         "path": "/docker",
///         "name": "Docker Files",
///         "status": "valid"
///       }
///     ]
///   }
/// }
Future<Map> dsmFileStationFavoriteList(String taskid,
    {int? offset,
    int? limit,
    String? sortBy,
    String? statusFilter,
    String? additional,
    CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.FileStation.Favorite', method: 'list', version: 2);
  data['taskid'] = taskid;
  if (offset != null) data['offset'] = offset;
  if (limit != null) data['limit'] = limit;
  if (sortBy != null && sortBy.isNotEmpty) data['sort_by'] = sortBy;
  if (statusFilter != null && statusFilter.isNotEmpty) {
    data['status_filter'] = statusFilter;
  }
  if (additional != null && additional.isNotEmpty) {
    data['additional'] = additional;
  }
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
//Log.info("dsmFileStationFavoriteList: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

/// {
///   "success": true
/// }
Future<Map> dsmFileStationFavoriteAdd(String path, // File/folder path
    {String? name, // Favorite name
    String? index, // Position index
    CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.FileStation.Favorite', method: 'add', version: 2);
  data['path'] = path;
  if (name != null && name.isNotEmpty) data['name'] = name;
  if (index != null && index.isNotEmpty) data['index'] = index;
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
//Log.info("dsmFileStationFavoriteAdd: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

/// {
///   "success": true
/// }
Future<Map> dsmFileStationFavoriteDelete(String path, // File/folder path
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.FileStation.Favorite', method: 'delete', version: 2);
  data['path'] = path;
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
//Log.info("dsmFileStationFavoriteDelete: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

/// {
///   "success": true
/// }
Future<Map> dsmFileStationFavoriteClearBroken(
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.FileStation.Favorite', method: 'clear_broken', version: 2);
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
//Log.info("dsmFileStationFavoriteClearBroken: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

/// {
///   "success": true
/// }
Future<Map> dsmFileStationFavoriteEdit(String path, String name,
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.FileStation.Favorite', method: 'edit', version: 2);
  data['path'] = path;
  data['name'] = name;
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
//Log.info("dsmFileStationFavoriteEdit: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

/// {
///   "success": true
/// }
Future<Map> dsmFileStationFavoriteReplaceAll(
    String path, // Path or paths (JSON array)
    String name, // Name or names (JSON array)
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.FileStation.Favorite', method: 'replace_all', version: 2);
  data['path'] = path;
  data['name'] = name;
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
//Log.info("dsmFileStationFavoriteReplaceAll: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}
