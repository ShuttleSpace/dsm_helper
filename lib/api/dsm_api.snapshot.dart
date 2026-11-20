part of 'dsm_api.dart';

/// {
///   "success": true,
///   "data": {
///     "luns": [
///       {
///         "uuid": "lun-uuid-1",
///         "name": "LUN1",
///         "type": "file",
///         "size": 10737418240,
///         "allocated": 5368709120,
///         "status": "normal"
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
/// | `uuid` | string | LUN UUID |
/// | `name` | string | LUN name |
/// | `type` | string | LUN type (`file`, `block`, `advanced`) |
/// | `size` | integer | LUN size (bytes) |
/// | `allocated` | integer | Allocated space (bytes) |
/// | `status` | string | LUN status |
///
/// ---
Future<Map> dsmCoreISCSILUNList(
    {String? types, // LUN types (comma-separated: `file`, `block`, `advanced`)
    int? offset, // Starting index (default: 0)
    int? limit, // Max results (default: 100)
    CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.Core.ISCSI.LUN', method: 'List', version: 1);
  if (types != null && types.isNotEmpty) data['types'] = types;
  if (offset != null) data['offset'] = offset;
  if (limit != null) data['limit'] = limit;
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
//Log.info("dsmCoreISCSILUNList: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

/// {
///   "success": true,
///   "data": {
///     "snapshots": [
///       {
///         "uuid": "snap-uuid-1",
///         "name": "LUN1-Snap1",
///         "src_lun_uuid": "lun-uuid-1",
///         "src_lun_name": "LUN1",
///         "taken_time": 1732788000,
///         "size": 5368709120,
///         "status": "healthy"
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
/// | `uuid` | string | Snapshot UUID |
/// | `name` | string | Snapshot name |
/// | `src_lun_uuid` | string | Source LUN UUID |
/// | `src_lun_name` | string | Source LUN name |
/// | `taken_time` | integer | Snapshot timestamp (Unix time) |
/// | `size` | integer | Snapshot size (bytes) |
/// | `status` | string | Snapshot status |
///
/// **Notes:**
/// - Snapshots are point-in-time copies of LUNs
/// - Multiple snapshots can be created per LUN
/// - Snapshots consume additional storage space
///
/// ---
Future<Map> dsmCoreISCSILUNSnapshotList(String srcLunUuid, // Source LUN UUID
    {int? offset, // Starting index (default: 0)
    int? limit, // Max results (default: 100)
    CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.Core.ISCSI.LUN.Snapshot', method: 'List', version: 1);
  data['src_lun_uuid'] = srcLunUuid;
  if (offset != null) data['offset'] = offset;
  if (limit != null) data['limit'] = limit;
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
//Log.info("dsmCoreISCSILUNSnapshotList: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

/// {
///   "success": true,
///   "data": {
///     "snapshot_uuid": "snapshot-uuid-2"
///   }
/// }
Future<Map> dsmCoreISCSILUNSnapshotCreate(String lunId, // LUN ID
    {String? description, // Snapshot description
    bool? isLocked, // Lock snapshot (default: false)
    CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.Core.ISCSI.LUN.Snapshot', method: 'Create', version: 1);
  data['lun_id'] = lunId;
  if (description != null && description.isNotEmpty) {
    data['description'] = description;
  }
  if (isLocked != null) data['is_locked'] = isLocked;
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
//Log.info("dsmCoreISCSILUNSnapshotCreate: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

/// {
///   "success": true
/// }
///
/// **Notes:**
/// - iSCSI Manager package required
/// - LUN snapshots are space-efficient
/// - Locked snapshots cannot be deleted
/// - Snapshots can be cloned to create new LUNs
///
/// ---
Future<Map> dsmCoreISCSILUNSnapshotDelete(
    String snapshotUuids, // Snapshot UUIDs (comma-separated)
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.Core.ISCSI.LUN.Snapshot', method: 'Delete', version: 1);
  data['snapshot_uuids'] = snapshotUuids;
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
//Log.info("dsmCoreISCSILUNSnapshotDelete: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

/// {
///   "success": true,
///   "data": {
///     "plans": [
///       {
///         "id": "plan_1",
///         "name": "Offsite Backup",
///         "source_share": "Documents",
///         "destination_host": "192.168.1.100",
///         "destination_share": "Documents_Backup",
///         "enabled": true,
///         "status": "normal",
///         "last_sync": 1732788000
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
/// | `id` | string | Replication plan ID |
/// | `name` | string | Plan name |
/// | `source_share` | string | Source shared folder |
/// | `destination_host` | string | Destination NAS IP/hostname |
/// | `destination_share` | string | Destination shared folder |
/// | `enabled` | boolean | Plan enabled |
/// | `status` | string | Replication status |
/// | `last_sync` | integer | Last sync timestamp (Unix time) |
///
/// ---
Future<Map> dsmCoreShareReplicationList(
    {String?
        additionalInfo, // Additional info fields (comma-separated: `status`, `last_sync`, `schedule`)
    int? offset, // Starting index (default: 0)
    int? limit, // Max results (default: 100)
    CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.Core.Share.Replication', method: 'List', version: 1);
  if (additionalInfo != null && additionalInfo.isNotEmpty) {
    data['additional_info'] = additionalInfo;
  }
  if (offset != null) data['offset'] = offset;
  if (limit != null) data['limit'] = limit;
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
//Log.info("dsmCoreShareReplicationList: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

/// {
///   "success": true,
///   "data": {
///     "task_id": "sync_task_123"
///   }
/// }
///
/// **Notes:**
/// - Replication requires Snapshot Replication package
/// - Source and destination must both support snapshots
/// - Replication is incremental (only changes are transferred)
/// - Use task_id to monitor sync progress
///
/// ---
Future<Map> dsmCoreShareReplicationSync(String planId, // Replication plan ID
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.Core.Share.Replication', method: 'Sync', version: 1);
  data['plan_id'] = planId;
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
//Log.info("dsmCoreShareReplicationSync: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

/// {
///   "success": true,
///   "data": {
///     "status": "running",
///     "progress": 45,
///     "transferred": 536870912,
///     "total": 1073741824
///   }
/// }
///
/// **Response Fields:**
///
/// | Field | Type | Description |
/// |-------|------|-------------|
/// | `status` | string | Task status (`running`, `completed`, `failed`) |
/// | `progress` | integer | Progress percentage (0-100) |
/// | `transferred` | integer | Bytes transferred |
/// | `total` | integer | Total bytes to transfer |
///
/// **Notes:**
/// - Replication status: `normal`, `syncing`, `error`, `paused`
/// - Failed replications can be retried
/// - Replication preserves snapshots on destination
///
/// ---
Future<Map> dsmCoreShareReplicationTaskStatus(String taskId, // Task ID
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.Core.Share.Replication.Task', method: 'Status', version: 1);
  data['task_id'] = taskId;
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
//Log.info("dsmCoreShareReplicationTaskStatus: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}
