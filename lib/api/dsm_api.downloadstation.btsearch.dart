part of 'dsm_api.dart';

/// {
///   "success": true,
///   "data": {
///     "taskid": "btsearch_1"
///   }
/// }
Future<Map> dsmDownloadStationBTSearchStart(String keyword, // Search keyword
    {String? module, // Search module (default: `all`)
    CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.DownloadStation.BTSearch', method: 'start', version: 1);
  data['keyword'] = keyword;
  if (module != null && module.isNotEmpty) data['module'] = module;
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
//Log.info("dsmDownloadStationBTSearchStart: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

/// {
///   "success": true,
///   "data": {
///     "total": 50,
///     "offset": 0,
///     "finished": true,
///     "items": [
///       {
///         "title": "Ubuntu 22.04 LTS Desktop",
///         "download": "magnet:?xt=urn:btih:...",
///         "size": 3774873600,
///         "date": "2023-04-21",
///         "peers": 150,
///         "seeds": 500,
///         "leechs": 50,
///         "category": "Software"
///       }
///     ]
///   }
/// }
Future<Map> dsmDownloadStationBTSearchList(String taskid, // Search task ID
    {int? offset,
    int? limit,
    String?
        sortBy, // Sort field: `title`, `size`, `date`, `peers`, `seeds`, `leechs`
    String? sortDirection,
    String? filterCategory,
    String? filterTitle,
    CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.DownloadStation.BTSearch', method: 'list', version: 1);
  data['taskid'] = taskid;
  if (offset != null) data['offset'] = offset;
  if (limit != null) data['limit'] = limit;
  if (sortBy != null && sortBy.isNotEmpty) data['sort_by'] = sortBy;
  if (sortDirection != null && sortDirection.isNotEmpty) {
    data['sort_direction'] = sortDirection;
  }
  if (filterCategory != null && filterCategory.isNotEmpty) {
    data['filter_category'] = filterCategory;
  }
  if (filterTitle != null && filterTitle.isNotEmpty) {
    data['filter_title'] = filterTitle;
  }
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
//Log.info("dsmDownloadStationBTSearchList: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

/// {
///   "success": true,
///   "data": {
///     "categories": [
///       "All",
///       "Movie",
///       "TV",
///       "Music",
///       "Software",
///       "Game",
///       "Book",
///       "Other"
///     ]
///   }
/// }
Future<Map> dsmDownloadStationBTSearchGetCategory(
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.DownloadStation.BTSearch', method: 'getCategory', version: 1);
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
//Log.info("dsmDownloadStationBTSearchGetCategory: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

/// {
///   "success": true,
///   "data": {
///     "modules": [
///       {
///         "name": "all",
///         "displayname": "All"
///       },
///       {
///         "name": "piratebay",
///         "displayname": "The Pirate Bay"
///       }
///     ]
///   }
/// }
Future<Map> dsmDownloadStationBTSearchGetModule(
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.DownloadStation.BTSearch', method: 'getModule', version: 1);
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
//Log.info("dsmDownloadStationBTSearchGetModule: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

/// {
///   "success": true
/// }
Future<Map> dsmDownloadStationBTSearchClean(
    String taskid, // Task ID (comma-separated for multiple)
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.DownloadStation.BTSearch', method: 'clean', version: 1);
  data['taskid'] = taskid;
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
//Log.info("dsmDownloadStationBTSearchClean: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}
