part of 'dsm_api.dart';

/// # ActiveBackup for Business - Agent APIs
///
/// **General Notes:**
/// - All required parameters are marked in function signatures
/// - Missing required parameters will result in error code 120

Future<Map> dsmActiveBackupAgentDeviceDuplicateWorkload(
    String workloadUuid, // Workload UUID
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.ActiveBackup.Agent.Device',
      method: 'duplicate_workload',
      version: 1);
  data['workload_uuid'] = workloadUuid;
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.info("dsmActiveBackupAgentDeviceDuplicateWorkload: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'];
}

Future<Map> dsmActiveBackupAgentDeviceListNodes(String deviceId, // Device ID
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.ActiveBackup.Agent.Device', method: 'list_nodes', version: 1);
  data['device_id'] = deviceId;
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
  Log.info("dsmActiveBackupAgentDeviceListNodes: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'];
}

Future<Map> dsmActiveBackupAgentDeviceSetUpdatePolicy(
    String autoUpdate, // Auto update policy
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.ActiveBackup.Agent.Device',
      method: 'set_update_policy',
      version: 1);
  data['auto_update'] = autoUpdate;
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.info("dsmActiveBackupAgentDeviceSetUpdatePolicy: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'];
}

Future<Map> dsmActiveBackupAgentDeviceUpdateAgent(
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.ActiveBackup.Agent.Device',
      method: 'update_agent',
      version: 1);
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
  Log.info("dsmActiveBackupAgentDeviceUpdateAgent: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'];
}

Future<Map> dsmActiveBackupAgentDeviceUpgrade(
    String deviceIds, // Device IDs (comma-separated)
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.ActiveBackup.Agent.Device', method: 'upgrade', version: 1);
  data['device_ids'] = deviceIds;
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.info("dsmActiveBackupAgentDeviceUpgrade: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'];
}

Future<Map> dsmActiveBackupAgentlessCreateDevice(
    String remoteConnectionInfo, // Remote connection info (JSON)
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.ActiveBackup.Agentless', method: 'create_device', version: 1);
  data['remote_connection_info'] = remoteConnectionInfo;
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.info("dsmActiveBackupAgentlessCreateDevice: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'];
}

Future<Map> dsmActiveBackupAgentlessGetDatapathOnStorage(
    String shareName, // Share name
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.ActiveBackup.Agentless',
      method: 'get_datapath_on_storage',
      version: 1);
  data['share_name'] = shareName;
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
  Log.info("dsmActiveBackupAgentlessGetDatapathOnStorage: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'];
}

Future<Map> dsmActiveBackupAgentlessGetTaskSetting(String taskId, // Task ID
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.ActiveBackup.Agentless',
      method: 'get_task_setting',
      version: 1);
  data['task_id'] = taskId;
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
  Log.info("dsmActiveBackupAgentlessGetTaskSetting: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'];
}

Future<Map> dsmActiveBackupAgentlessListDeviceFolder(
    String remoteConnectionInfo, // Remote connection info (JSON)
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.ActiveBackup.Agentless',
      method: 'list_device_folder',
      version: 1);
  data['remote_connection_info'] = remoteConnectionInfo;
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
  Log.info("dsmActiveBackupAgentlessListDeviceFolder: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'];
}

Future<Map> dsmActiveBackupAgentlessRemoveSshKeyTmpFile(
    String sshKeyFile, // SSH key file path
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.ActiveBackup.Agentless',
      method: 'remove_ssh_key_tmp_file',
      version: 1);
  data['ssh_key_file'] = sshKeyFile;
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.info("dsmActiveBackupAgentlessRemoveSshKeyTmpFile: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'];
}

Future<Map> dsmActiveBackupAgentlessSetDevice(
    String remoteConnectionInfo, // Remote connection info (JSON)
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.ActiveBackup.Agentless', method: 'set_device', version: 1);
  data['remote_connection_info'] = remoteConnectionInfo;
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.info("dsmActiveBackupAgentlessSetDevice: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'];
}

Future<Map> dsmActiveBackupAgentlessSmbListRemoteFolder(
    String hostIp, // Host IP address
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.ActiveBackup.Agentless',
      method: 'smb_list_remote_folder',
      version: 1);
  data['host_ip'] = hostIp;
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
  Log.info("dsmActiveBackupAgentlessSmbListRemoteFolder: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'];
}

Future<Map> dsmActiveBackupAgentlessTestConnection(
    String remoteConnectionInfo, // Remote connection info (JSON)
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.ActiveBackup.Agentless',
      method: 'test_connection',
      version: 1);
  data['remote_connection_info'] = remoteConnectionInfo;
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.info("dsmActiveBackupAgentlessTestConnection: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'];
}

Future<Map> dsmActiveBackupAgentlessTestRsyncModuleConnection(
    String remoteConnectionInfo, // Remote connection info (JSON)
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.ActiveBackup.Agentless',
      method: 'test_rsync_module_connection',
      version: 1);
  data['remote_connection_info'] = remoteConnectionInfo;
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.info("dsmActiveBackupAgentlessTestRsyncModuleConnection: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'];
}

Future<Map> dsmActiveBackupAgentlessTestSshKey(
    String sshKeyFilePath, // SSH key file path
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.ActiveBackup.Agentless', method: 'test_ssh_key', version: 1);
  data['ssh_key_file_path'] = sshKeyFilePath;
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.info("dsmActiveBackupAgentlessTestSshKey: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'];
}

Future<Map> dsmActiveBackupAgentlessTestTaskSettings(
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.ActiveBackup.Agentless',
      method: 'test_task_settings',
      version: 1);
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
  Log.info("dsmActiveBackupAgentlessTestTaskSettings: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'];
}
