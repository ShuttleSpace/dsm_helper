part of 'dsm_api.dart';

/// {
///   "success": true,
///   "data": {
///     "taskid": "FileStation_12345"
///   }
/// }
/// **Response Fields:**
///
/// | Field | Type | Description |
/// |-------|------|-------------|
/// | `taskid` | string | Search task ID |
///
/// ---
Future<Map> dsmFileStationSearchStart(String folderPath, // Starting folder path
    {bool? recursive, // Search recursively (default: true)
    String? pattern, // File name pattern (wildcards: `*`, `?`)
    String? extension, // File extensions (comma-separated)
    String? filetype, // `file`, `dir`, `all`
    int? sizeFrom, // Minimum file size (bytes)
    int? sizeTo, // Maximum file size (bytes)
    int? mtimeFrom, // Modified after (Unix timestamp)
    int? mtimeTo, // Modified before (Unix timestamp)
    int? crtimeFrom, // Created after (Unix timestamp)
    int? crtimeTo, // Created before (Unix timestamp)
    int? atimeFrom, // Accessed after (Unix timestamp)
    int? atimeTo, // Accessed before (Unix timestamp)
    String? owener, // Owner username
    String? group, // Group name
    CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.FileStation.Search', method: 'start', version: 2);
  data['folder_path'] = folderPath;
  if (recursive != null) data['recursive'] = recursive;
  if (pattern != null && pattern.isNotEmpty) data['pattern'] = pattern;
  if (extension != null && extension.isNotEmpty) data['extension'] = extension;
  if (filetype != null && filetype.isNotEmpty) data['filetype'] = filetype;
  if (sizeFrom != null) data['size_from'] = sizeFrom;
  if (sizeTo != null) data['size_to'] = sizeTo;
  if (mtimeFrom != null) data['mtime_from'] = mtimeFrom;
  if (mtimeTo != null) data['mtime_to'] = mtimeTo;
  if (crtimeFrom != null) data['crtime_from'] = crtimeFrom;
  if (crtimeTo != null) data['crtime_to'] = crtimeTo;
  if (atimeFrom != null) data['atime_from'] = atimeFrom;
  if (atimeTo != null) data['atime_to'] = atimeTo;
  if (owener != null && owener.isNotEmpty) data['owener'] = owener;
  if (group != null && group.isNotEmpty) data['group'] = group;
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
//Log.info("dsmFileStationSearchStart: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

/// {
///   "success": true,
///   "data": {
///     "total": 5,
///     "offset": 0,
///     "finished": true,
///     "files": [
///       {
///         "path": "/docker/README.md",
///         "name": "README.md",
///         "isdir": false,
///         "additional": {
///           "size": 2048,
///           "time": {
///             "mtime": 1732752000
///           }
///         }
///       }
///     ]
///   }
/// }
///
/// **Response Fields:**
///
/// | Field | Type | Description |
/// |-------|------|-------------|
/// | `finished` | boolean | Search complete |
/// | `total` | integer | Total results found |
/// | `files` | array | Matching files |
///
/// ---
Future<Map> dsmFileStationSearchList(String taskid, // Task ID from start
    {int? offset, // Starting index
    int? limit, // Max results
    String?
        sortBy, // Sort field: `name`, `size`, `user`, `group`, `mtime`, `atime`, `ctime`, `crtime`, `posix`, `type`
    String? sortDirection, // Sort direction: `asc` or `desc`
    String? pattern, // Additional pattern filter
    String? filetype, // `file`, `dir`, `all`
    String? additional, // Additional fields
    CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.FileStation.Search', method: 'list', version: 2);
  data['taskid'] = taskid;
  if (pattern != null && pattern.isNotEmpty) data['pattern'] = pattern;
  if (filetype != null && filetype.isNotEmpty) data['filetype'] = filetype;
  if (additional != null && additional.isNotEmpty) {
    data['additional'] = additional;
  }
  if (offset != null) data['offset'] = offset;
  if (limit != null) data['limit'] = limit;
  if (sortBy != null && sortBy.isNotEmpty) data['sort_by'] = sortBy;
  if (sortDirection != null && sortDirection.isNotEmpty) {
    data['sort_direction'] = sortDirection;
  }
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
//Log.info("dsmFileStationSearchList: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

/// {
///   "success": true,
///   "data": {
///     "finished": false,
///     "total": 3,
///     "num_found": 3
///   }
/// }
Future<Map> dsmFileStationSearchStatus(String taskid, // Task ID
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.FileStation.Search', method: 'status', version: 2);
  data['taskid'] = taskid;
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
//Log.info("dsmFileStationSearchStatus: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

/// {
///   "success": true
/// }
Future<Map> dsmFileStationSearchStop(String taskid, // Task ID
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.FileStation.Search', method: 'stop', version: 2);
  data['taskid'] = taskid;
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
//Log.info("dsmFileStationSearchStop: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

/// {
///   "success": true
/// }
Future<Map> dsmFileStationSearchClean(
    String taskid, // Task ID (use `all` for all completed tasks)
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.FileStation.Search', method: 'clean', version: 2);
  data['taskid'] = taskid;
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
//Log.info("dsmFileStationSearchClean: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}
