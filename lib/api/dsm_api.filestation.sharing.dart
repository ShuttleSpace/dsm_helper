part of 'dsm_api.dart';

/// {
///   "success": true,
///   "data": {
///     "links": [
///       {
///         "id": "SHARE_LINK_ID",
///         "url": "https://nas.example.com/sharing/SHARE_LINK_ID",
///         "link_owner": "admin",
///         "path": "/docker/document.pdf",
///         "date_expired": 0,
///         "date_available": 0,
///         "status": "valid",
///         "has_password": false,
///         "expire_times": 0,
///         "access_time": 5,
///         "isFolder": false
///       }
///     ]
///   }
/// }
Future<dynamic> dsmFileStationSharingGetinfo(String id, // Shared link ID
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.FileStation.Sharing', method: 'getinfo', version: 3);
  data['id'] = id;
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
//Log.info("dsmFileStationSharingGetinfo: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

/// {
///   "success": true,
///   "data": {
///     "total": 3,
///     "offset": 0,
///     "links": [
///       {
///         "id": "LINK_001",
///         "url": "https://nas.example.com/sharing/LINK_001",
///         "link_owner": "admin",
///         "path": "/docker/README.md",
///         "date_expired": 0,
///         "status": "valid",
///         "has_password": false,
///         "access_time": 12,
///         "isFolder": false
///       }
///     ]
///   }
/// }
Future<dynamic> dsmFileStationSharingList(
    {int? offset,
    int? limit,
    String?
        sortBy, // Sort field: `name`, `user`, `access_time`, `mtime`, `expire_time`, `status`
    String? sortDirection, // `asc` or `desc`
    bool? forceClean, // Clean invalid links first (default: false)
    CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.FileStation.Sharing', method: 'list', version: 3);
  if (offset != null) data['offset'] = offset;
  if (limit != null) data['limit'] = limit;
  if (sortBy != null && sortBy.isNotEmpty) data['sort_by'] = sortBy;
  if (sortDirection != null && sortDirection.isNotEmpty) {
    data['sort_direction'] = sortDirection;
  }
  if (forceClean != null) data['force_clean'] = forceClean;
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
//Log.info("dsmFileStationSharingList: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

/// {
///   "success": true,
///   "data": {
///     "links": [
///       {
///         "id": "NEW_LINK_ID",
///         "url": "https://nas.example.com/sharing/NEW_LINK_ID",
///         "link_owner": "admin",
///         "path": "/docker/document.pdf",
///         "date_expired": 1735689600,
///         "status": "valid",
///         "has_password": true,
///         "expire_times": 10,
///         "isFolder": false
///       }
///     ]
///   }
/// }
Future<dynamic> dsmFileStationSharingCreate(
    String path, // File/folder path to share
    {String? password, // Password protectio
    int? dateExpired, //  Expiration date (Unix timestamp, 0 = never)
    int? dateAvailable, // Available from date (Unix timestamp, 0 = immediate)
    int? expireTimes, // Max accesses (0 = unlimited)
    CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.FileStation.Sharing', method: 'create', version: 3);
  data['path'] = path;
  if (password != null && password.isNotEmpty) data['password'] = password;
  if (dateExpired != null) data['date_expired'] = dateExpired;
  if (dateAvailable != null) data['date_available'] = dateAvailable;
  if (expireTimes != null) data['expire_times'] = expireTimes;
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
//Log.info("dsmFileStationSharingCreate: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

/// {
///   "success": true
/// }
Future<dynamic> dsmFileStationSharingDelete(
    String id, //  Link ID (comma-separated for multiple)
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.FileStation.Sharing', method: 'delete', version: 3);
  data['id'] = id;
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
//Log.info("dsmFileStationSharingDelete: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

/// {
///   "success": true
/// }
Future<dynamic> dsmFileStationSharingClearInvalid(
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.FileStation.Sharing', method: 'clear_invalid', version: 3);
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
//Log.info("dsmFileStationSharingClearInvalid: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

/// {
///   "success": true,
///   "data": {
///     "links": [
///       {
///         "id": "LINK_ID",
///         "url": "https://nas.example.com/sharing/LINK_ID",
///         "link_owner": "admin",
///         "path": "/docker/document.pdf",
///         "date_expired": 1767225600,
///         "has_password": true
///       }
///     ]
///   }
/// }

Future<dynamic> dsmFileStationSharingEdit(String id, // Session ID
    {String? password, // New password (empty to remove)
    int? dateExpired, //  New expiration date
    int? dateAvailable, // New available from date
    int? expireTimes, // New max accesses
    CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.FileStation.Sharing', method: 'edit', version: 3);
  data['id'] = id;
  if (password != null && password.isNotEmpty) data['password'] = password;
  if (dateExpired != null) data['date_expired'] = dateExpired;
  if (dateAvailable != null) data['date_available'] = dateAvailable;
  if (expireTimes != null) data['expire_times'] = expireTimes;
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
//Log.info("dsmFileStationSharingEdit: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}
