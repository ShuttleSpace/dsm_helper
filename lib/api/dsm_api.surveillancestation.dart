part of 'dsm_api.dart';

/// {
///   "success": true,
///   "data": {
///     "version": "9.2.0-9289",
///     "camera_number": 4,
///     "license_number": 4,
///     "recording_enabled": true
///   }
/// }
Future<Map> dsmSurveillanceStationInfoGetInfo(
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.SurveillanceStation.Info', method: 'GetInfo', version: 1);
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
  Log.info("dsmSurveillanceStationInfoGetInfo: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'];
}

/// {
///   "success": true,
///   "data": {
///     "cameras": [
///       {
///         "id": 1,
///         "name": "Front Door",
///         "model": "DS-2CD2142FWD-I",
///         "vendor": "Hikvision",
///         "ip": "192.168.1.100",
///         "port": 80,
///         "enabled": true,
///         "status": 1,
///         "recording_status": 1,
///         "ptz_capable": false
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
/// | `id` | integer | Camera ID |
/// | `name` | string | Camera name |
/// | `model` | string | Camera model |
/// | `vendor` | string | Camera vendor |
/// | `ip` | string | Camera IP address |
/// | `port` | integer | Camera port |
/// | `enabled` | boolean | Camera enabled |
/// | `status` | integer | Camera status (1=normal, 2=disconnected) |
/// | `recording_status` | integer | Recording status (1=recording, 2=not recording) |
/// | `ptz_capable` | boolean | PTZ capability |
///
/// ---
Future<Map> dsmSurveillanceStationCameraList(
    {int? offset, // Starting index (default: 0)
    int? limit, // Max results (default: 100)
    bool? blIncludeDeletedCam, // Include deleted cameras (default: false)
    CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.SurveillanceStation.Camera', method: 'List', version: 9);
  if (offset != null) data['offset'] = offset;
  if (limit != null) data['limit'] = limit;
  if (blIncludeDeletedCam != null) {
    data['blIncludeDeletedCam'] = blIncludeDeletedCam;
  }
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
  Log.info("dsmSurveillanceStationCameraList: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'];
}

/// {
///   "success": true,
///   "data": {
///     "id": 1,
///     "name": "Front Door",
///     "model": "DS-2CD2142FWD-I",
///     "vendor": "Hikvision",
///     "ip": "192.168.1.100",
///     "port": 80,
///     "enabled": true,
///     "status": 1,
///     "recording_status": 1,
///     "ptz_capable": false
///   }
/// }
Future<Map> dsmSurveillanceStationCameraGetInfo(
    String cameraIds, // Camera ID (comma-separated for multiple)
    {bool? basic, // Include basic info (default: true)
    bool? streamInfo, // Include stream info (default: false)
    bool? optimize, // Include optimization info (default: false)
    CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.SurveillanceStation.Camera', method: 'GetInfo', version: 9);
  data['cameraIds'] = cameraIds;
  if (basic != null) data['basic'] = basic;
  if (streamInfo != null) data['streamInfo'] = streamInfo;
  if (optimize != null) data['optimize'] = optimize;
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
  Log.info("dsmSurveillanceStationCameraGetInfo: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'];
}

/// {
///   "success": true
/// }
Future<Map> dsmSurveillanceStationCameraEnable(int id, // Camera ID
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.SurveillanceStation.Camera', method: 'Enable', version: 9);
  data['id'] = id;
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.info("dsmSurveillanceStationCameraEnable: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'];
}

/// {
///   "success": true
/// }
Future<Map> dsmSurveillanceStationCameraDisable(int id, // Camera ID
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.SurveillanceStation.Camera', method: 'Disable', version: 9);
  data['id'] = id;
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.info("dsmSurveillanceStationCameraDisable: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'];
}

/// Binary JPEG image data
///
/// **Notes:**
/// - Response is a JPEG image, not JSON
/// - Use either `id` or `name` parameter
/// - Profile type affects image quality and size
///
/// ---
Future<dynamic> dsmSurveillanceStationCameraGetSnapshot(
    {int? id,
    String? name,
    int?
        profileType, // Profile type (0=high quality, 1=balanced, 2=low bandwidth, default: 1)
    CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.SurveillanceStation.Camera',
      method: 'GetSnapshot',
      version: 9);
  if (id != null) data['id'] = id;
  if (name != null && name.isNotEmpty) data['name'] = name;
  if (profileType != null) data['profileType'] = profileType;
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
  Log.info("dsmSurveillanceStationCameraGetSnapshot: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'];
}

/// {
///   "success": true,
///   "data": {
///     "cameras": [
///       {
///         "id": 1,
///         "mjpeg_path": "/webapi/entry.cgi?api=SYNO.SurveillanceStation.VideoStream&version=1&method=Stream&cameraId=1&format=mjpeg",
///         "rtsp_path": "rtsp://192.168.1.1:554/live/1",
///         "multicast_path": ""
///       }
///     ]
///   }
/// }
///
/// **Response Fields:**
///
/// | Field | Type | Description |
/// |-------|------|-------------|
/// | `id` | integer | Camera ID |
/// | `mjpeg_path` | string | MJPEG stream path |
/// | `rtsp_path` | string | RTSP stream URL |
/// | `multicast_path` | string | Multicast stream path (if enabled) |
///
/// **Notes:**
/// - Response is a JPEG image, not JSON
/// - Use either `id` or `name` parameter
/// - Profile type affects image quality and size
///
/// ---
/// {
///   "success": true,
///   "data": {
///     "cameras": [
///       {
///         "id": 1,
///         "mjpeg_path": "/webapi/entry.cgi?api=SYNO.SurveillanceStation.VideoStream&version=1&method=Stream&cameraId=1&format=mjpeg",
///         "rtsp_path": "rtsp://192.168.1.1:554/live/1",
///         "multicast_path": ""
///       }
///     ]
///   }
/// }
///
/// **Response Fields:**
///
/// | Field | Type | Description |
/// |-------|------|-------------|
/// | `id` | integer | Camera ID |
/// | `mjpeg_path` | string | MJPEG stream path |
/// | `rtsp_path` | string | RTSP stream URL |
/// | `multicast_path` | string | Multicast stream path (if enabled) |
///
/// **Notes:**
/// - Response is a continuous MJPEG stream
/// - Use `multipart` format for HTTP multipart stream
/// - Stream continues until connection is closed
///
/// ---
Future<Map> dsmSurveillanceStationCameraGetLiveViewPath(
    String idList, // Camera IDs (comma-separated)
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.SurveillanceStation.Camera',
      method: 'GetLiveViewPath',
      version: 9);
  data['idList'] = idList;
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
  Log.info("dsmSurveillanceStationCameraGetLiveViewPath: $res");
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
/// - Response is a continuous MJPEG stream
/// - Use `multipart` format for HTTP multipart stream
/// - Stream continues until connection is closed
///
/// ---
Future<Map> dsmSurveillanceStationVideoStreamStream(
    int cameraId, // Camera ID
    String format, // Stream format (`mjpeg`, `multipart`)
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.SurveillanceStation.VideoStream',
      method: 'Stream',
      version: 1);
  data['cameraId'] = cameraId;
  data['format'] = format;
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
  Log.info("dsmSurveillanceStationVideoStreamStream: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'];
}

/// {
///   "success": true,
///   "data": {
///     "groups": [
///       {
///         "id": 1,
///         "name": "Front Cameras",
///         "camera_ids": [1, 2, 3]
///       },
///       {
///         "id": 2,
///         "name": "Back Cameras",
///         "camera_ids": [4, 5]
///       }
///     ]
///   }
/// }
///
/// **Notes:**
/// - Camera groups organize cameras for easier management
/// - Groups can be used for batch operations
/// - Live view can display multiple cameras from a group
///
/// ---
Future<Map> dsmSurveillanceStationCameraGroupEnum(
    {int? privCamType, // Camera type filter (default: 1)
    CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.SurveillanceStation.Camera.Group', method: 'Enum', version: 1);
  if (privCamType != null) data['privCamType'] = privCamType;
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
  Log.info("dsmSurveillanceStationCameraGroupEnum: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'];
}

/// {
///   "success": true,
///   "data": {
///     "events": [
///       {
///         "id": 54321,
///         "camera_id": 1,
///         "camera_name": "Front Door",
///         "time": 1732752000,
///         "reason": "motion",
///         "locked": false,
///         "has_snapshot": true
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
/// | `id` | integer | Event ID |
/// | `camera_id` | integer | Camera ID |
/// | `camera_name` | string | Camera name |
/// | `time` | integer | Event timestamp (Unix time) |
/// | `reason` | string | Event reason (motion, manual, alarm, etc.) |
/// | `locked` | boolean | Event locked (protected from deletion) |
/// | `has_snapshot` | boolean | Snapshot available |
///
/// ---
Future<Map> dsmSurveillanceStationEventQuery(
    {String? cameraIds, // Camera IDs (comma-separated)
    int? fromTime, // Start timestamp (Unix time)
    int? toTime, // End timestamp (Unix time)
    String? reason, // Event reason filter (comma-separated)
    int? locked, // Locked status (0=unlocked, 1=locked)
    int? offset,
    int? limit,
    CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.SurveillanceStation.Event', method: 'Query', version: 4);
  if (cameraIds != null && cameraIds.isNotEmpty) data['cameraIds'] = cameraIds;
  if (fromTime != null) data['fromTime'] = fromTime;
  if (toTime != null) data['toTime'] = toTime;
  if (reason != null && reason.isNotEmpty) data['reason'] = reason;
  if (locked != null) data['locked'] = locked;
  if (offset != null) data['offset'] = offset;
  if (limit != null) data['limit'] = limit;
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
  Log.info("dsmSurveillanceStationEventQuery: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'];
}

/// {
///   "success": true
/// }
Future<Map> dsmSurveillanceStationEventDelete(
    {String? reason, // Event reason filter
    String? cameraIds, // Camera IDs (comma-separated)
    int? fromTime, // Start timestamp
    int? toTime, // End timestamp
    int? locked, // Locked status filter
    CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.SurveillanceStation.Event', method: 'Delete', version: 4);
  if (reason != null && reason.isNotEmpty) data['reason'] = reason;
  if (cameraIds != null && cameraIds.isNotEmpty) data['cameraIds'] = cameraIds;
  if (fromTime != null) data['fromTime'] = fromTime;
  if (toTime != null) data['toTime'] = toTime;
  if (locked != null) data['locked'] = locked;
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.info("dsmSurveillanceStationEventDelete: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'];
}

/// {
///   "success": true
/// }
Future<Map> dsmSurveillanceStationEventLock(
    {String? reason, // Event reason filter
    String? cameraIds, // Camera IDs (comma-separated)
    int? fromTime, // Start timestamp
    int? toTime, // End timestamp
    CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.SurveillanceStation.Event', method: 'Lock', version: 4);
  if (reason != null && reason.isNotEmpty) data['reason'] = reason;
  if (cameraIds != null && cameraIds.isNotEmpty) data['cameraIds'] = cameraIds;
  if (fromTime != null) data['fromTime'] = fromTime;
  if (toTime != null) data['toTime'] = toTime;
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.info("dsmSurveillanceStationEventLock: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'];
}

/// {
///   "success": true
/// }
Future<Map> dsmSurveillanceStationEventUnlock(
    String idList, // Event IDs (comma-separated)
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.SurveillanceStation.Event', method: 'Unlock', version: 4);
  data['idList'] = idList;
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.info("dsmSurveillanceStationEventUnlock: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'];
}

/// {
///   "success": true,
///   "data": {
///     "motion_detection": {
///       "enabled": true,
///       "sensitivity": 80,
///       "threshold": 10,
///       "object_size": 5
///     }
///   }
/// }
///
/// **Notes:**
/// - Event reasons: `motion`, `manual`, `alarm`, `continuous`
/// - Locked events cannot be deleted
/// - Motion detection settings are camera-specific
/// - Events can be filtered by multiple criteria
///
/// ---
Future<Map> dsmSurveillanceStationEventDetectionMotionEnum(
    int camId, // Camera ID
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.SurveillanceStation.Event.Detection',
      method: 'MotionEnum',
      version: 1);
  data['camId'] = camId;
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
  Log.info("dsmSurveillanceStationEventDetectionMotionEnum: $res");
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
/// - Direction values: `up`, `down`, `left`, `right`, `upleft`, `upright`, `downleft`, `downright`, `home`, `stop`
/// - Speed range: 1 (slowest) to 5 (fastest)
/// - `home` moves camera to home position
/// - `stop` stops current movement
///
/// ---
Future<Map> dsmSurveillanceStationPTZMove(
    int cameraId, // Camera ID
    String
        direction, // Direction (`up`, `down`, `left`, `right`, `home`, `stop`)
    {int? speed, // Movement speed (1-5, default: 3)
    CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.SurveillanceStation.PTZ', method: 'Move', version: 5);
  data['cameraId'] = cameraId;
  data['direction'] = direction;
  if (speed != null) data['speed'] = speed;
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.info("dsmSurveillanceStationPTZMove: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'];
}

/// {
///   "success": true
/// }
Future<Map> dsmSurveillanceStationPTZZoom(
    int cameraId, // Camera ID
    String control, // Zoom control (`in`, `out`, `stop`)
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.SurveillanceStation.PTZ', method: 'Zoom', version: 5);
  data['cameraId'] = cameraId;
  data['control'] = control;
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.info("dsmSurveillanceStationPTZZoom: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'];
}

/// {
///   "success": true
/// }
Future<Map> dsmSurveillanceStationPTZFocus(
    int cameraId, // Camera ID
    String control, // Focus control (`in`, `out`, `auto`, `stop`)
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.SurveillanceStation.PTZ', method: 'Focus', version: 5);
  data['cameraId'] = cameraId;
  data['control'] = control;
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.info("dsmSurveillanceStationPTZFocus: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'];
}

/// {
///   "success": true,
///   "data": {
///     "presets": [
///       {
///         "id": 1,
///         "name": "Front Gate",
///         "position": 1
///       },
///       {
///         "id": 2,
///         "name": "Parking Lot",
///         "position": 2
///       }
///     ]
///   }
/// }
///
/// **Notes:**
/// - Use either `presetId` or `position` parameter
/// - Presets must be configured in Surveillance Station first
///
/// ---
Future<Map> dsmSurveillanceStationPTZPresetList(int cameraId, // Camera ID
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.SurveillanceStation.PTZ.Preset', method: 'List', version: 1);
  data['cameraId'] = cameraId;
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
  Log.info("dsmSurveillanceStationPTZPresetList: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'];
}

/// {
///   "success": true
/// }
Future<Map> dsmSurveillanceStationPTZGotoPreset(int cameraId, // Camera ID
    {int? presetId, // Preset ID
    int? position, // Preset position number
    int? speed, // Movement speed (1-5)
    CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.SurveillanceStation.PTZ.Preset',
      method: 'GoPreset',
      version: 1);
  data['cameraId'] = cameraId;
  if (presetId != null) data['presetId'] = presetId;
  if (position != null) data['position'] = position;
  if (speed != null) data['speed'] = speed;
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.info("dsmSurveillanceStationPTZGotoPreset: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'];
}

/// {
///   "success": true,
///   "data": {
///     "patrols": [
///       {
///         "id": 1,
///         "name": "Perimeter Scan",
///         "preset_count": 4
///       }
///     ]
///   }
/// }
///
/// **Notes:**
/// - Patrols are sequences of preset positions
/// - Camera automatically moves through patrol points
/// - Patrol continues until stopped or interrupted
///
/// ---
Future<Map> dsmSurveillanceStationPTZPatrolList(int cameraId, // Camera ID
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.SurveillanceStation.PTZ.Patrol', method: 'List', version: 1);
  data['cameraId'] = cameraId;
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
  Log.info("dsmSurveillanceStationPTZPatrolList: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'];
}

/// {
///   "success": true
/// }
Future<Map> dsmSurveillanceStationPTZPatrolRunPatrol(
    int cameraId, // Camera ID
    int patrolId, // Patrol ID
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.SurveillanceStation.PTZ.Patrol',
      method: 'RunPatrol',
      version: 1);
  data['cameraId'] = cameraId;
  data['patrolId'] = patrolId;
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.info("dsmSurveillanceStationPTZPatrolRunPatrol: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'];
}

/// {
///   "success": true,
///   "data": {
///     "recordings": [
///       {
///         "id": 12345,
///         "camera_id": 1,
///         "start_time": 1732752000,
///         "end_time": 1732755600,
///         "size": 104857600,
///         "locked": false,
///         "type": "continuous"
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
/// | `id` | integer | Recording ID |
/// | `camera_id` | integer | Camera ID |
/// | `start_time` | integer | Recording start time (Unix time) |
/// | `end_time` | integer | Recording end time (Unix time) |
/// | `size` | integer | Recording size (bytes) |
/// | `locked` | boolean | Recording locked (protected from deletion) |
/// | `type` | string | Recording type (`continuous`, `motion`, `manual`) |
///
/// ---
Future<Map> dsmSurveillanceStationRecordingQuery(
    String cameraIds, // Camera IDs (comma-separated)
    int fromTime, // Start timestamp (Unix time)
    int toTime, // End timestamp (Unix time)
    {int? offset,
    int? limit,
    CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.SurveillanceStation.Recording', method: 'Query', version: 5);
  data['cameraIds'] = cameraIds;
  data['fromTime'] = fromTime;
  data['toTime'] = toTime;
  if (offset != null) data['offset'] = offset;
  if (limit != null) data['limit'] = limit;
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
  Log.info("dsmSurveillanceStationRecordingQuery: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'];
}

/// {
///   "success": true
/// }
Future<Map> dsmSurveillanceStationRecordingDelete(
    String idList, // Recording IDs (comma-separated)
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.SurveillanceStation.Recording', method: 'Delete', version: 5);
  data['idList'] = idList;
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.info("dsmSurveillanceStationRecordingDelete: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'];
}

/// {
///   "success": true
/// }
Future<Map> dsmSurveillanceStationRecordingLock(
    String idList, // Recording IDs (comma-separated)
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.SurveillanceStation.Recording', method: 'Lock', version: 5);
  data['idList'] = idList;
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.info("dsmSurveillanceStationRecordingLock: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'];
}

/// {
///   "success": true
/// }
Future<Map> dsmSurveillanceStationRecordingUnlock(
    String idList, // Recording IDs (comma-separated)
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.SurveillanceStation.Recording', method: 'Unlock', version: 5);
  data['idList'] = idList;
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.info("dsmSurveillanceStationRecordingUnlock: $res");
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
/// - Response is a video file, not JSON
/// - Large recordings may take time to download
/// - Locked recordings cannot be deleted
///
/// ---
Future<Map> dsmSurveillanceStationRecordingDownload(String id, // Recording ID
    {String? mountId, // Mount ID (for external storage)
    CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.SurveillanceStation.Recording',
      method: 'Download',
      version: 5);
  data['id'] = id;
  if (mountId != null && mountId.isNotEmpty) data['mountId'] = mountId;
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
  Log.info("dsmSurveillanceStationRecordingDownload: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'];
}

/// {
///   "success": true,
///   "data": {
///     "task_id": "export_123"
///   }
/// }
///
/// **Notes:**
/// - Creates an export task for downloading recordings
/// - Use task_id to check export progress
/// - Exported files are saved to designated folder
///
/// ---
Future<Map> dsmSurveillanceStationRecordingExportSave(
    int camId, // Camera ID
    int fromTime, // Start timestamp (Unix time)
    int toTime, // End timestamp (Unix time)
    {String? fileName, // Export filename
    CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.SurveillanceStation.Recording.Export',
      method: 'Save',
      version: 2);
  data['camId'] = camId;
  data['fromTime'] = fromTime;
  data['toTime'] = toTime;
  if (fileName != null && fileName.isNotEmpty) data['fileName'] = fileName;
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.info("dsmSurveillanceStationRecordingExportSave: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'];
}

/// {
///   "success": true,
///   "data": {
///     "enabled": true,
///     "motion": true,
///     "manual": false,
///     "alarm": false,
///     "continuous": true
///   }
/// }
Future<Map> dsmSurveillanceStationRecordingGetConfig(
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.SurveillanceStation.Recording',
      method: 'GetConfig',
      version: 5);
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
  Log.info("dsmSurveillanceStationRecordingGetConfig: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'];
}

/// {
///   "success": true
/// }
Future<Map> dsmSurveillanceStationRecordingStart(int cameraId, // Camera ID
    {String? type, // Recording type (motion, manual, continuous)
    CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.SurveillanceStation.Recording', method: 'Start', version: 5);
  data['cameraId'] = cameraId;
  if (type != null && type.isNotEmpty) data['type'] = type;
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.info("dsmSurveillanceStationRecordingStart: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'];
}

/// {
///   "success": true
/// }
Future<Map> dsmSurveillanceStationRecordingStop(int cameraId, // Camera ID
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.SurveillanceStation.Recording', method: 'Stop', version: 5);
  data['cameraId'] = cameraId;
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.info("dsmSurveillanceStationRecordingStop: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'];
}

/// {
///   "success": true
/// }
Future<Map> dsmSurveillanceStationRecordingPause(int cameraId, // Camera ID
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.SurveillanceStation.Recording', method: 'Pause', version: 5);
  data['cameraId'] = cameraId;
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.info("dsmSurveillanceStationRecordingPause: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'];
}

/// {
///   "success": true
/// }
Future<Map> dsmSurveillanceStationRecordingResume(int cameraId, // Camera ID
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.SurveillanceStation.Recording', method: 'Resume', version: 5);
  data['cameraId'] = cameraId;
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.info("dsmSurveillanceStationRecordingResume: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'];
}
