part of 'dsm_api.dart';

/// {
///   "success": true,
///   "data": {
///     "snapshots": [
///       {
///         "id": "snapshot_1",
///         "name": "@GMT-2025.11.28-10.00.00",
///         "time_create": 1732788000,
///         "description": "Daily backup",
///         "is_locked": false,
///         "size": 1073741824
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
/// | `id` | string | Snapshot ID |
/// | `name` | string | Snapshot name (GMT format) |
/// | `time_create` | integer | Creation timestamp (Unix time) |
/// | `description` | string | Snapshot description |
/// | `is_locked` | boolean | Locked status (protected from deletion) |
/// | `size` | integer | Snapshot size (bytes) |
///
/// ---
Future<Map> dsmCoreShareSnapshotList(String shareName, // Shared folder name
    {int? offset, // Starting index (default: 0)
    int? limit, // Max results (default: 100)
    CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.Core.Share.Snapshot', method: 'List', version: 1);
  data['share_name'] = shareName;
  if (offset != null) data['offset'] = offset;
  if (limit != null) data['limit'] = limit;
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
  Log.info("dsmCoreShareSnapshotList: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

/// {
///   "success": true,
///   "data": {
///     "snapshot_id": "snapshot_2"
///   }
/// }
Future<Map> dsmCoreShareSnapshotCreate(String shareName, // Shared folder name
    {String? description, // Snapshot description
    bool? isLocked, // Lock snapshot (default: false)
    CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.Core.Share.Snapshot', method: 'Create', version: 1);
  data['share_name'] = shareName;
  if (description != null && description.isNotEmpty) {
    data['description'] = description;
  }
  if (isLocked != null) data['is_locked'] = isLocked;
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.info("dsmCoreShareSnapshotCreate: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

/// {
///   "success": true
/// }
Future<Map> dsmCoreShareSnapshotDelete(
    String shareName, // Shared folder name
    String snapshotIds, // Snapshot IDs (comma-separated)
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.Core.Share.Snapshot', method: 'Delete', version: 1);
  data['share_name'] = shareName;
  data['snapshot_ids'] = snapshotIds;
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.info("dsmCoreShareSnapshotDelete: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

/// {
///   "success": true
/// }
Future<Map> dsmCoreShareSnapshotSetAttr(
    String shareName, // Shared folder name
    String snapshotId, // Snapshot ID
    {String? description, // New description
    bool? isLocked, // Lock status
    CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.Core.Share.Snapshot', method: 'SetAttr', version: 1);
  data['share_name'] = shareName;
  data['snapshot_id'] = snapshotId;
  if (description != null && description.isNotEmpty) {
    data['description'] = description;
  }
  if (isLocked != null) data['is_locked'] = isLocked;
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.info("dsmCoreShareSnapshotSetAttr: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}
