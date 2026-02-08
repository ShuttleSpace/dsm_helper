part of 'dsm_api.dart';

/// # ActiveBackup for Business - AEM (Application-Aware) APIs
///
/// **General Notes:**
/// - Application-aware backup for Exchange, SQL Server
/// - All required parameters are marked in function signatures

Future<Map> dsmActiveBackupAEMActivityBackupStatus(
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.ActiveBackup.AEM.Activity',
      method: 'backup_status',
      version: 1);
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
  Log.info("dsmActiveBackupAEMActivityBackupStatus: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'];
}

Future<Map> dsmActiveBackupAEMActivityWriteVmmLog(String guestId, // Guest ID
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.ActiveBackup.AEM.Activity',
      method: 'write_vmm_log',
      version: 1);
  data['guest_id'] = guestId;
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.info("dsmActiveBackupAEMActivityWriteVmmLog: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'];
}

Future<Map> dsmActiveBackupAEMCheckKey(String key, // Key
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.ActiveBackup.AEM', method: 'check_key', version: 1);
  data['key'] = key;
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.info("dsmActiveBackupAEMCheckKey: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'];
}

Future<Map> dsmActiveBackupAEMCheckLeaderAddress(
    String leaderAddr, // Leader address
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.ActiveBackup.AEM', method: 'check_leader_address', version: 1);
  data['leader_addr'] = leaderAddr;
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.info("dsmActiveBackupAEMCheckLeaderAddress: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'];
}

Future<Map> dsmActiveBackupAEMEditConnection(String hostname, // Hostname
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.ActiveBackup.AEM', method: 'edit_connection', version: 1);
  data['hostname'] = hostname;
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.info("dsmActiveBackupAEMEditConnection: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'];
}

Future<Map> dsmActiveBackupAEMGetInfo({CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.ActiveBackup.AEM', method: 'get_info', version: 1);
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
  Log.info("dsmActiveBackupAEMGetInfo: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'];
}

Future<Map> dsmActiveBackupAEMNFSApplyState(
    String interfaces, // Interfaces (JSON)
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.ActiveBackup.AEM.NFS', method: 'apply_state', version: 1);
  data['interfaces'] = interfaces;
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.info("dsmActiveBackupAEMNFSApplyState: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'];
}

Future<Map> dsmActiveBackupAEMNFSCheckState(
    String interfaces, // Interfaces (JSON)
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.ActiveBackup.AEM.NFS', method: 'check_state', version: 1);
  data['interfaces'] = interfaces;
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.info("dsmActiveBackupAEMNFSCheckState: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'];
}

Future<Map> dsmActiveBackupAEMScriptDelete(String scriptId, // Script ID
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.ActiveBackup.AEM.Script', method: 'delete', version: 1);
  data['script_id'] = scriptId;
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.info("dsmActiveBackupAEMScriptDelete: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'];
}

Future<Map> dsmActiveBackupAEMScriptPrepareFileForJoin(
    String fileName, // File name
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.ActiveBackup.AEM.Script',
      method: 'prepare_file_for_join',
      version: 1);
  data['file_name'] = fileName;
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.info("dsmActiveBackupAEMScriptPrepareFileForJoin: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'];
}

Future<Map> dsmActiveBackupAEMScriptUpdate(String scriptId, // Script ID
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.ActiveBackup.AEM.Script', method: 'update', version: 1);
  data['script_id'] = scriptId;
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.info("dsmActiveBackupAEMScriptUpdate: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'];
}

Future<Map> dsmActiveBackupAEMTaskListAutoBackupRule(
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.ActiveBackup.AEM.Task',
      method: 'list_auto_backup_rule',
      version: 1);
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
  Log.info("dsmActiveBackupAEMTaskListAutoBackupRule: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'];
}

Future<Map> dsmActiveBackupAEMTaskListWithDevice(
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.ActiveBackup.AEM.Task',
      method: 'list_with_device',
      version: 1);
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
  Log.info("dsmActiveBackupAEMTaskListWithDevice: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'];
}

Future<Map> dsmActiveBackupAEMVersionList(String taskId, // Task ID
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.ActiveBackup.AEM.Version', method: 'list', version: 1);
  data['task_id'] = taskId;
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
  Log.info("dsmActiveBackupAEMVersionList: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'];
}
