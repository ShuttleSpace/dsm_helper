part of 'dsm_api.dart';

/// # ActiveBackup for Business - Core APIs
///
/// **General Notes:**
/// - ActiveBackup for Business package must be installed
/// - Supports Windows, Linux, macOS physical devices
/// - Supports VMware, Hyper-V virtual machines
/// - All required parameters are marked in function signatures
/// - Missing required parameters will result in error code 120
/// - Some operations may take longer to respond

/// **Notes:**
/// - May take longer to respond
Future<Map> dsmActiveBackupDeviceList({CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.ActiveBackup.Device', method: 'list', version: 1);
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
  Log.info("dsmActiveBackupDeviceList: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

/// **Notes:**
/// - Requires parameter: `device_id`
/// - Error code 120 when parameter missing
Future<Map> dsmActiveBackupDeviceListRestorableVersion(
    String deviceId, // Device ID (required)
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.ActiveBackup.Device',
      method: 'list_restorable_version',
      version: 1);
  data['device_id'] = deviceId;
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
  Log.info("dsmActiveBackupDeviceListRestorableVersion: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

/// **Notes:**
/// - Requires parameter: `device_ids`
/// - Error code 120 when parameter missing
/// - May take longer to respond
Future<Map> dsmActiveBackupDeviceListTasks(
    String deviceIds, // Device IDs (comma-separated, required)
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.ActiveBackup.Device', method: 'list_tasks', version: 1);
  data['device_ids'] = deviceIds;
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
  Log.info("dsmActiveBackupDeviceListTasks: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

/// **Notes:**
/// - Requires parameter: `device_ids`
/// - Error code 120 when parameter missing
Future<Map> dsmActiveBackupDeviceRemove(
    String deviceIds, // Device IDs (comma-separated, required)
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.ActiveBackup.Device', method: 'remove', version: 1);
  data['device_ids'] = deviceIds;
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.info("dsmActiveBackupDeviceRemove: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

/// **Notes:**
/// - Requires parameter: `device_ids`
/// - Error code 120 when parameter missing
Future<Map> dsmActiveBackupDeviceSetCredential(
    String deviceIds, // Device IDs (comma-separated, required)
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.ActiveBackup.Device', method: 'set_credential', version: 1);
  data['device_ids'] = deviceIds;
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.info("dsmActiveBackupDeviceSetCredential: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

/// **Notes:**
/// - Requires parameter: `sessions`
/// - Error code 120 when parameter missing
Future<Map> dsmActiveBackupRestoreClear(
    String sessions, // Sessions (comma-separated, required)
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.ActiveBackup.Restore', method: 'clear', version: 1);
  data['sessions'] = sessions;
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.info("dsmActiveBackupRestoreClear: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

Future<Map> dsmActiveBackupRestoreList({CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.ActiveBackup.Restore', method: 'list', version: 1);
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
  Log.info("dsmActiveBackupRestoreList: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

Future<Map> dsmActiveBackupRestorePause(
    String jobIds, // Job IDs (comma-separated)
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.ActiveBackup.Restore', method: 'pause', version: 1);
  data['job_ids'] = jobIds;
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.info("dsmActiveBackupRestorePause: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

Future<Map> dsmActiveBackupRestoreResume(
    String jobIds, // Job IDs (comma-separated)
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.ActiveBackup.Restore', method: 'resume', version: 1);
  data['job_ids'] = jobIds;
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.info("dsmActiveBackupRestoreResume: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

Future<Map> dsmActiveBackupRestoreStatus(String jobId, // Job ID
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.ActiveBackup.Restore', method: 'status', version: 1);
  data['job_id'] = jobId;
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
  Log.info("dsmActiveBackupRestoreStatus: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

Future<Map> dsmActiveBackupRestoreStop({CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.ActiveBackup.Restore', method: 'stop', version: 1);
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
  Log.info("dsmActiveBackupRestoreStop: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

Future<Map> dsmActiveBackupSettingGetPhysMemsize(
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.ActiveBackup.Setting', method: 'get_phys_memsize', version: 1);
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
  Log.info("dsmActiveBackupSettingGetPhysMemsize: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

Future<Map> dsmActiveBackupSettingList({CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.ActiveBackup.Setting', method: 'list', version: 1);
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
  Log.info("dsmActiveBackupSettingList: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

Future<Map> dsmActiveBackupSettingSet(String settings, // Settings (JSON)
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.ActiveBackup.Setting', method: 'set', version: 1);
  data['settings'] = settings;
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.info("dsmActiveBackupSettingSet: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

Future<Map> dsmActiveBackupTaskBackup(
    String taskIds, // Task IDs (comma-separated)
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.ActiveBackup.Task', method: 'backup', version: 1);
  data['task_ids'] = taskIds;
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.info("dsmActiveBackupTaskBackup: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

Future<Map> dsmActiveBackupTaskCancel(
    String taskIds, // Task IDs (comma-separated)
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.ActiveBackup.Task', method: 'cancel', version: 1);
  data['task_ids'] = taskIds;
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.info("dsmActiveBackupTaskCancel: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

Future<Map> dsmActiveBackupTaskCancelWaitingBackup(
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.ActiveBackup.Task',
      method: 'cancel_waiting_backup',
      version: 1);
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
  Log.info("dsmActiveBackupTaskCancelWaitingBackup: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

Future<Map> dsmActiveBackupTaskCreateVmCheck({CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.ActiveBackup.Task', method: 'create_vm_check', version: 1);
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
  Log.info("dsmActiveBackupTaskCreateVmCheck: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

Future<Map> dsmActiveBackupTaskGetDefaultTaskName(
    String backupType, // Backup type
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.ActiveBackup.Task',
      method: 'get_default_task_name',
      version: 1);
  data['backup_type'] = backupType;
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
  Log.info("dsmActiveBackupTaskGetDefaultTaskName: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

Future<Map> dsmActiveBackupTaskList({CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.ActiveBackup.Task', method: 'list', version: 1);
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
  Log.info("dsmActiveBackupTaskList: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

Future<Map> dsmActiveBackupTaskListVmCheck({CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.ActiveBackup.Task', method: 'list_vm_check', version: 1);
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
  Log.info("dsmActiveBackupTaskListVmCheck: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

Future<Map> dsmActiveBackupTaskListWithDevice(
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.ActiveBackup.Task', method: 'list_with_device', version: 1);
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
  Log.info("dsmActiveBackupTaskListWithDevice: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

Future<Map> dsmActiveBackupTaskRemove(
    String taskIds, // Task IDs (comma-separated)
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.ActiveBackup.Task', method: 'remove', version: 1);
  data['task_ids'] = taskIds;
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.info("dsmActiveBackupTaskRemove: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

Future<Map> dsmActiveBackupTaskVmCheckCancel({CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.ActiveBackup.Task', method: 'vm_check_cancel', version: 1);
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
  Log.info("dsmActiveBackupTaskVmCheckCancel: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

Future<Map> dsmActiveBackupVersionDelete(String taskId, // Task ID
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.ActiveBackup.Version', method: 'delete', version: 1);
  data['task_id'] = taskId;
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.info("dsmActiveBackupVersionDelete: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

Future<dynamic> dsmActiveBackupVersionDownload(
    String deviceId, // Device ID
    String savePath, // Save path
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.ActiveBackup.Version', method: 'download', version: 1);
  data['device_id'] = deviceId;
  return await _httpDownload(_entryCGI,
      savePath: savePath, queryParameters: data, cancelToken: cancelToken);
}

Future<Map> dsmActiveBackupVersionList(String taskId, // Task ID
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.ActiveBackup.Version', method: 'list', version: 1);
  data['task_id'] = taskId;
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
  Log.info("dsmActiveBackupVersionList: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

Future<Map> dsmActiveBackupVersionListNode(String deviceId, // Device ID
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.ActiveBackup.Version', method: 'list_node', version: 1);
  data['device_id'] = deviceId;
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
  Log.info("dsmActiveBackupVersionListNode: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

Future<Map> dsmActiveBackupVersionLock(String taskId, // Task ID
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.ActiveBackup.Version', method: 'lock', version: 1);
  data['task_id'] = taskId;
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.info("dsmActiveBackupVersionLock: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

Future<Map> dsmActiveBackupVersionRestore(String deviceId, // Device ID
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.ActiveBackup.Version', method: 'restore', version: 1);
  data['device_id'] = deviceId;
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.info("dsmActiveBackupVersionRestore: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}
