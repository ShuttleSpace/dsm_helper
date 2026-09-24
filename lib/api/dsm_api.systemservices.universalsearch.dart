part of 'dsm_api.dart';

/// {
///   "success": true,
///   "data": {
///     "results": [
///       {
///         "path": "/volume1/Documents/report.pdf",
///         "name": "report.pdf",
///         "type": "file",
///         "size": 1048576,
///         "modified_time": 1732788000
///       },
///       {
///         "path": "/volume1/Photos/vacation",
///         "name": "vacation",
///         "type": "folder",
///         "modified_time": 1732788000
///       }
///     ],
///     "total": 2
///   }
/// }
///
/// **Response Fields:**
///
/// | Field | Type | Description |
/// |-------|------|-------------|
/// | `path` | string | Full file/folder path |
/// | `name` | string | File/folder name |
/// | `type` | string | Type (`file`, `folder`) |
/// | `size` | integer | File size (bytes, files only) |
/// | `modified_time` | integer | Last modified timestamp (Unix time) |
///
/// **Notes:**
/// - Universal Search indexes files across all shared folders
/// - Searches file names and metadata
/// - Indexing must be enabled in DSM settings
/// - Search results respect user permissions
/// - Supports wildcard searches with `*` and `?`
///
/// ---
Future<Map> dsmFinderFileIndexingSearch(String keyword, // Search keyword
    {int? offset,
    int? limit,
    CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.Finder.FileIndexing.Search', method: 'Search', version: 1);
  data['keyword'] = keyword;
  if (offset != null) data['offset'] = offset;
  if (limit != null) data['limit'] = limit;
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
//Log.info("dsmFinderFileIndexingSearch: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}
