part of 'dsm_api.dart';

/// {
///   "success": true,
///   "data": {
///     "list": [
///       {
///         "id": 123,
///         "name": "Vacation 2024",
///         "owner_user_id": 1,
///         "parent": 0,
///         "passphrase": "",
///         "shared": false,
///         "sort_by": "takentime",
///         "sort_direction": "desc"
///       }
///     ]
///   }
/// }
Future<Map> dsmFotoBrowseFolderList(
    int folderId, // Parent folder ID (0 for root)
    {int? offset, // Starting index (default: 0)
    int? limit, // Max results (default: 1000)
    String?
        additional, // Additional fields (comma-separated): `thumbnail`, `sharing_info`
    CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.Foto.Browse.Folder', method: 'list', version: 1);
  data['folder_id'] = folderId;
  if (offset != null) data['offset'] = offset;
  if (limit != null) data['limit'] = limit;
  if (additional != null && additional.isNotEmpty) {
    data['additional'] = additional;
  }
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
  Log.info("dsmFotoBrowseFolderList: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'];
}

/// {
///   "success": true,
///   "data": {
///     "folder": {
///       "id": 123,
///       "name": "Vacation 2024",
///       "owner_user_id": 1,
///       "parent": 0
///     }
///   }
/// }
Future<Map> dsmFotoBrowseFolderGet(int id, // Folder ID
    {String? additional, // Additional fields
    CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.Foto.Browse.Folder', method: 'get', version: 1);
  data['id'] = id;
  if (additional != null && additional.isNotEmpty) {
    data['additional'] = additional;
  }
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
  Log.info("dsmFotoBrowseFolderGet: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'];
}

/// {
///   "success": true,
///   "data": {
///     "count": 15
///   }
/// }
Future<Map> dsmFotoBrowseFolderCount(int folderId, // Parent folder ID
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.Foto.Browse.Folder', method: 'count', version: 1);
  data['folder_id'] = folderId;
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
  Log.info("dsmFotoBrowseFolderCount: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'];
}

/// {
///   "success": true,
///   "data": {
///     "list": [
///       {
///         "id": 456,
///         "name": "Company Events",
///         "owner_user_id": 1,
///         "parent": 0,
///         "shared": true
///       }
///     ]
///   }
/// }
///
/// **Notes:**
/// - Team Space folders are shared across team members
/// - Requires appropriate team permissions
///
/// ---
Future<Map> dsmFotoTeamBrowseFolderList(
    int folderId, // Parent folder ID (0 for root)
    {int? offset, // Starting index (default: 0)
    int? limit, // Max results (default: 2000)
    String? additional, // Additional fields
    CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.FotoTeam.Browse.Folder', method: 'list', version: 1);
  data['folder_id'] = folderId;
  if (offset != null) data['offset'] = offset;
  if (limit != null) data['limit'] = limit;
  if (additional != null && additional.isNotEmpty) {
    data['additional'] = additional;
  }
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
  Log.info("dsmFotoTeamBrowseFolderList: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'];
}
