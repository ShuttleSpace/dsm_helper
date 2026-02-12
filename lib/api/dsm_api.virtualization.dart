part of 'dsm_api.dart';

/// {
///   "success": true,
///   "data": {
///     "images": [
///       {
///         "image_id": "img-1",
///         "image_name": "ubuntu-22.04-server.iso",
///         "size": 1073741824,
///         "type": "iso",
///         "create_time": 1732788000
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
/// | `image_id` | string | Image ID |
/// | `image_name` | string | Image filename |
/// | `size` | integer | Image size (bytes) |
/// | `type` | string | Image type (`iso`, `vdisk`) |
/// | `create_time` | integer | Creation timestamp (Unix time) |
Future<Map> dsmVirtualizationImageList(
    {int? offset, // Starting index (default: 0)
    int? limit, // Max results (default: 100)
    CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.Virtualization.Image', method: 'List', version: 1);
  if (offset != null) data['offset'] = offset;
  if (limit != null) data['limit'] = limit;
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
  Log.info("dsmVirtualizationImageList: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

/// {
///   "success": true,
///   "data": {
///     "task_id": "task_126",
///     "image_id": "img-2"
///   }
/// }
Future<Map> dsmVirtualizationImageCreate(String imageName, // Image filename
    {bool? autoCleanTask, // Auto-clean task after completion (default: true)
    String? guestId, // Source VM ID (for VM-to-image)
    CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.Virtualization.Image', method: 'Create', version: 1);
  data['image_name'] = imageName;
  if (autoCleanTask != null) data['auto_clean_task'] = autoCleanTask;
  if (guestId != null && guestId.isNotEmpty) data['guest_id'] = guestId;
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.info("dsmVirtualizationImageCreate: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

/// {
///   "success": true
/// }
Future<Map> dsmVirtualizationImageDelete(String imageId, // Image ID
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.Virtualization.Image', method: 'Delete', version: 1);
  data['image_id'] = imageId;
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.info("dsmVirtualizationImageDelete: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

/// **Notes:**
/// - Tasks are created for asynchronous operations
/// - Completed tasks can be cleared to free resources
/// - Failed tasks contain error information
/// - Task status: `running`, `completed`, `failed`, `cancelled`

/// {
///   "success": true,
///   "data": {
///     "tasks": [
///       "task_123",
///       "task_124",
///       "task_125"
///     ]
///   }
/// }
Future<Map> dsmVirtualizationTaskList({CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.Virtualization.Task', method: 'List', version: 1);
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
  Log.info("dsmVirtualizationTaskList: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

/// {
///   "success": true,
///   "data": {
///     "task_id": "task_123",
///     "status": "running",
///     "progress": 65,
///     "operation": "power_on",
///     "guest_id": "vm-1"
///   }
/// }
///
/// **Response Fields:**
///
/// | Field | Type | Description |
/// |-------|------|-------------|
/// | `task_id` | string | Task ID |
/// | `status` | string | Task status (`running`, `completed`, `failed`) |
/// | `progress` | integer | Progress percentage (0-100) |
/// | `operation` | string | Operation type |
/// | `guest_id` | string | Associated VM ID |
Future<Map> dsmVirtualizationTaskGet(String taskid, // Task ID
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.Virtualization.Task', method: 'Get', version: 1);
  data['taskid'] = taskid;
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
  Log.info("dsmVirtualizationTaskGet: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

/// {
///   "success": true
/// }
Future<Map> dsmVirtualizationTaskClear(String taskid, // Task ID
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.Virtualization.Task', method: 'Clear', version: 1);
  data['taskid'] = taskid;
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.info("dsmVirtualizationTaskClear: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

/// {
///   "success": true,
///   "data": {
///     "guests": [
///       {
///         "guest_id": "vm-1",
///         "guest_name": "Ubuntu Server",
///         "status": "running",
///         "vcpu_num": 2,
///         "vram_size": 4096,
///         "storage_size": 53687091200,
///         "autorun": 1
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
/// | `guest_id` | string | VM ID |
/// | `guest_name` | string | VM name |
/// | `status` | string | VM status (`running`, `stopped`, `paused`) |
/// | `vcpu_num` | integer | Number of virtual CPUs |
/// | `vram_size` | integer | RAM size (MB) |
/// | `storage_size` | integer | Storage size (bytes) |
/// | `autorun` | integer | Auto-start on boot (0=disabled, 1=enabled) |
Future<Map> dsmVirtualizationGuestList(
    {bool? additional, // Include additional info (default: false)
    int? offset, // Starting index (default: 0)
    int? limit, // Max results (default: 100)
    CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.Virtualization.Guest', method: 'List', version: 1);
  if (additional != null) data['additional'] = additional;
  if (offset != null) data['offset'] = offset;
  if (limit != null) data['limit'] = limit;
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
  Log.info("dsmVirtualizationGuestList: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

/// {
///   "success": true,
///   "data": {
///     "guest_id": "vm-1",
///     "guest_name": "Ubuntu Server",
///     "status": "running",
///     "vcpu_num": 2,
///     "vram_size": 4096,
///     "storage_size": 53687091200,
///     "autorun": 1，
///     "network": [
///      {
///        "mac": "00:11:32:AB:CD:EF",
///        "network_name": "default"
///      }
///    ]
///   }
/// }
/// **Notes:**
/// - Use either `guest_id` or `guest_name` parameter
/// - Additional info fields: `network`, `storage`, `snapshot`
///
/// ---

Future<Map> dsmVirtualizationGuestGet(
    {String? guestId, // VM ID
    String? guestName, // VM name
    String? additional, // Additional info fields (comma-separated)
    CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.Virtualization.Guest', method: 'Get', version: 1);
  if (guestId != null && guestId.isNotEmpty) data['guest_id'] = guestId;
  if (guestName != null && guestName.isNotEmpty) data['guest_name'] = guestName;
  if (additional != null && additional.isNotEmpty) {
    data['additional'] = additional;
  }
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
  Log.info("dsmVirtualizationGuestGet: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

/// {
///   "success": true,
///   "data": {
///     "task_id": "task_123"
///   }
/// }
Future<Map> dsmVirtualizationGuestPowerOn(
    {String? guestId, // VM ID
    String? guestName, // VM name
    CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.Virtualization.Guest', method: 'PowerOn', version: 1);
  if (guestId != null && guestId.isNotEmpty) data['guest_id'] = guestId;
  if (guestName != null && guestName.isNotEmpty) data['guest_name'] = guestName;
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.info("dsmVirtualizationGuestPowerOn: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

/// {
///   "success": true,
///   "data": {
///     "task_id": "task_124"
///   }
/// }
Future<Map> dsmVirtualizationGuestPowerOff(
    {String? guestId, // VM ID
    String? guestName, // VM name
    bool? force, // Force power off (default: false)
    CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.Virtualization.Guest', method: 'PowerOff', version: 1);
  if (guestId != null && guestId.isNotEmpty) data['guest_id'] = guestId;
  if (guestName != null && guestName.isNotEmpty) data['guest_name'] = guestName;
  if (force != null) data['force'] = force;
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.info("dsmVirtualizationGuestPowerOff: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

/// {
///   "success": true,
///   "data": {
///     "task_id": "task_125"
///   }
/// }
///
/// **Notes:**
/// - `Shutdown` sends ACPI shutdown signal (graceful)
/// - `PowerOff` with `force=true` immediately stops VM (ungraceful)
/// - Use task_id to monitor operation progress
///
/// ---
Future<Map> dsmVirtualizationGuestShutdown(
    {String? guestId, // VM ID
    String? guestName, // VM name
    CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.Virtualization.Guest', method: 'Shutdown', version: 1);
  if (guestId != null && guestId.isNotEmpty) data['guest_id'] = guestId;
  if (guestName != null && guestName.isNotEmpty) data['guest_name'] = guestName;
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.info("dsmVirtualizationGuestShutdown: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

Future<Map> dsmVirtualizationGuestActionCheckPoweron(
    {required String guestId, CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.Virtualization.Guest.Action',
      method: 'check_poweron',
      version: 1)
    ..addAll({'guest_id': guestId});
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.info("dsmVirtualizationGuestActionCheckPoweron: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

Future<Map> dsmVirtualizationGuestActionPwrCtl(
    {required String guestId,
    required String action, // poweron, poweroff, reset, shutdown
    CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.Virtualization.Guest.Action', method: 'pwr_ctl', version: 1)
    ..addAll({'guest_id': guestId, 'action': action});
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.info("dsmVirtualizationGuestActionPwrCtl: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

/// {
///   "success": true
/// }
Future<Map> dsmVirtualizationGuestDelete(
    {String? guestId, // VM ID
    String? guestName, // VM name
    CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.Virtualization.Guest', method: 'Delete', version: 1);
  if (guestId != null && guestId.isNotEmpty) data['guest_id'] = guestId;
  if (guestName != null && guestName.isNotEmpty) data['guest_name'] = guestName;
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.info("dsmVirtualizationGuestDelete: $res");
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
/// - VM must be stopped to change CPU/RAM configuration
/// - Auto-run setting can be changed while VM is running
/// - Use either `guest_id` or `guest_name` parameter
Future<Map> dsmVirtualizationGuestSet(
    {String? guestId, // VM ID
    String? guestName, // VM name
    int? vcpuNum, // Number of virtual CPUs
    int? vramSize, // RAM size (MB)
    int? autorun, // Auto-start on boot (0=disabled, 1=enabled)
    CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.Virtualization.Guest', method: 'Set', version: 1);
  if (guestId != null && guestId.isNotEmpty) data['guest_id'] = guestId;
  if (guestName != null && guestName.isNotEmpty) data['guest_name'] = guestName;
  if (vcpuNum != null) data['vcpu_num'] = vcpuNum;
  if (vramSize != null) data['vram_size'] = vramSize;
  if (autorun != null) data['autorun'] = autorun;
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.info("dsmVirtualizationGuestSet: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}
