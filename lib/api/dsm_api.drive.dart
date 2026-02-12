part of 'dsm_api.dart';

/// {
///   "success": true,
///   "data": {
///     "enabled": true,
///     "version": "3.4.0-15724",
///     "status": "running",
///     "total_users": 50,
///     "active_connections": 25
///   }
/// }
///
/// **Response Fields:**
///
/// | Field | Type | Description |
/// |-------|------|-------------|
/// | `enabled` | boolean | Drive enabled |
/// | `version` | string | Drive version |
/// | `status` | string | Service status |
/// | `total_users` | integer | Total Drive users |
/// | `active_connections` | integer | Active connections |
///
/// ---
Future<Map> dsmSynologyDriveInfoGetStatus({CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.SynologyDrive.Info', method: 'GetStatus', version: 1);
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
  Log.info("dsmSynologyDriveInfoGetStatus: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

/// {
///   "success": true,
///   "data": {
///     "max_file_size": 10737418240,
///     "enable_versioning": true,
///     "version_retention": 32,
///     "enable_team_folder": true
///   }
/// }
Future<Map> dsmSynologyDriveInfoGetConfig({CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.SynologyDrive.Info', method: 'GetConfig', version: 1);
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
  Log.info("dsmSynologyDriveInfoGetConfig: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

/// {
///   "success": true,
///   "data": {
///     "enable_link_sharing": true,
///     "enable_office_online": true,
///     "enable_mobile_access": true,
///     "max_upload_size": 10737418240
///   }
/// }
Future<Map> dsmSynologyDriveSettingsGet({CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.SynologyDrive.Settings', method: 'Get', version: 1);
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
  Log.info("dsmSynologyDriveSettingsGet: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

/// {
///   "success": true,
///   "data": {
///     "db_size": 524288000,
///     "total_files": 15000,
///     "total_folders": 2500,
///     "total_versions": 45000
///   }
/// }
///
/// **Response Fields:**
///
/// | Field | Type | Description |
/// |-------|------|-------------|
/// | `db_size` | integer | Database size (bytes) |
/// | `total_files` | integer | Total files tracked |
/// | `total_folders` | integer | Total folders tracked |
/// | `total_versions` | integer | Total file versions |
///
/// **Notes:**
/// - Database tracks all Drive files and versions
/// - Large databases may impact performance
/// - Regular cleanup recommended for old versions
///
/// ---
Future<Map> dsmSynologyDriveDBGetUsage({CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.SynologyDrive.DB', method: 'GetUsage', version: 1);
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
  Log.info("dsmSynologyDriveDBGetUsage: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

/// {
///   "success": true,
///   "data": {
///     "total_connections": 25,
///     "desktop_clients": 15,
///     "mobile_clients": 8,
///     "web_clients": 2
///   }
/// }
Future<Map> dsmSynologyDriveConnectionsGetSummary(
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.SynologyDrive.Connections', method: 'GetSummary', version: 1);
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
  Log.info("dsmSynologyDriveConnectionsGetSummary: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

/// {
///   "success": true,
///   "data": {
///     "connections": [
///       {
///         "user": "john.doe",
///         "client_type": "desktop",
///         "client_version": "3.4.0",
///         "ip_address": "192.168.1.100",
///         "connected_time": 1732788000
///       }
///     ],
///     "total": 1
///   }
/// }
///
/// **Response Fields:**
///
/// | Field | Type | Description |
/// |-------|------|-------------|
/// | `user` | string | Username |
/// | `client_type` | string | Client type (`desktop`, `mobile`, `web`) |
/// | `client_version` | string | Client version |
/// | `ip_address` | string | Client IP address |
/// | `connected_time` | integer | Connection timestamp (Unix time) |
///
/// ---
Future<Map> dsmSynologyDriveConnectionsList({CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.SynologyDrive.Connections', method: 'List', version: 1);
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
  Log.info("dsmSynologyDriveConnectionsList: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

/// {
///   "success": true,
///   "data": {
///     "connections": [
///       {
///         "user": "john.doe",
///         "device_name": "John's Laptop",
///         "sync_folder": "/home/john/Drive",
///         "status": "syncing",
///         "last_sync": 1732788000
///       }
///     ],
///     "total": 1
///   }
/// }
///
/// **Sync Status:**
/// - `idle` - Not syncing
/// - `syncing` - Currently syncing
/// - `paused` - Sync paused
/// - `error` - Sync error
///
/// ---
Future<Map> dsmSynologyDriveShareSyncListConnections(
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.SynologyDrive.ShareSync',
      method: 'ListConnections',
      version: 1);
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
  Log.info("dsmSynologyDriveShareSyncListConnections: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

/// {
///   "success": true,
///   "data": {
///     "logs": [
///       {
///         "time": 1732788000,
///         "user": "john.doe",
///         "action": "upload",
///         "file_path": "/Team Projects/report.pdf",
///         "ip_address": "192.168.1.100"
///       }
///     ],
///     "total": 1
///   }
/// }
///
/// **Response Fields:**
///
/// | Field | Type | Description |
/// |-------|------|-------------|
/// | `time` | integer | Log timestamp (Unix time) |
/// | `user` | string | Username |
/// | `action` | string | Action type |
/// | `file_path` | string | File path |
/// | `ip_address` | string | Client IP address |
///
/// **Action Types:**
/// - `upload` - File uploaded
/// - `download` - File downloaded
/// - `delete` - File deleted
/// - `rename` - File renamed
/// - `move` - File moved
/// - `share` - File shared
///
/// ---
Future<Map> dsmSynologyDriveLogList(
    {String? shareType, // Share type (`all`, `team_folder`, `personal`)
    int? offset,
    int? limit,
    CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.SynologyDrive.Log', method: 'List', version: 1);
  if (shareType != null && shareType.isNotEmpty) {
    data['share_type'] = shareType;
  }
  if (offset != null) data['offset'] = offset;
  if (limit != null) data['limit'] = limit;
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
  Log.info("dsmSynologyDriveLogList: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

/// {
///   "success": true,
///   "data": {
///     "shares": [
///       {
///         "name": "Team Projects",
///         "type": "team_folder",
///         "users": 10,
///         "size": 5368709120,
///         "file_count": 500
///       }
///     ],
///     "total": 1
///   }
/// }
Future<Map> dsmSynologyDriveShareListActive({CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.SynologyDrive.Share', method: 'ListActive', version: 1);
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
  Log.info("dsmSynologyDriveShareListActive: $res");
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
///         "id": "file_123",
///         "name": "deleted_document.docx",
///         "path": "/Team Projects/deleted_document.docx",
///         "deleted_by": "john.doe",
///         "deleted_time": 1732788000,
///         "size": 1048576
///       }
///     ],
///     "total": 1
///   }
/// }
///
/// {
///   "success": true,
///   "data": {
///     "pending_deletions": 25,
///     "deleted_size": 1073741824,
///     "retention_days": 30
///   }
/// }
///
/// **Response Fields:**
///
/// | Field | Type | Description |
/// |-------|------|-------------|
/// | `pending_deletions` | integer | Files pending permanent deletion |
/// | `deleted_size` | integer | Size of deleted files (bytes) |
/// | `retention_days` | integer | Days before permanent deletion |
///
/// **Notes:**
/// - Deleted files are retained for configured period
/// - Users can restore deleted files during retention
/// - Permanent deletion occurs after retention expires
/// - Admins can force immediate permanent deletion
///
/// ---
Future<Map> dsmSynologyDriveDeletionGetStatus(
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.SynologyDrive.Deletion', method: 'GetStatus', version: 1);
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
  Log.info("dsmSynologyDriveDeletionGetStatus: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

/// {
///   "success": true,
///   "data": {
///     "user": "john.doe",
///     "quota_used": 5368709120,
///     "quota_total": 107374182400,
///     "file_count": 500,
///     "folder_count": 50,
///     "last_sync_time": 1732788000
///   }
/// }
///
/// **Notes:**
/// - User profiles track quota and usage
/// - Quotas can be set per user
/// - Sync profiles show last sync activity
///
/// ---
Future<Map> dsmSynologyDriveUserProfileGet(String user, // Username
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.SynologyDrive.UserProfile', method: 'Get', version: 1);
  data['user'] = user;
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
  Log.info("dsmSynologyDriveUserProfileGet: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}
