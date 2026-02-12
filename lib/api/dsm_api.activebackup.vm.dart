part of 'dsm_api.dart';

/// # ActiveBackup for Business - VM APIs
///
/// **General Notes:**
/// - All required parameters are marked in function signatures
/// - Missing required parameters will result in error code 120
/// - Some operations may take longer to respond

Future<Map> dsmActiveBackupInventoryCancelCheckJob(String session, // Session ID
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.ActiveBackup.Inventory',
      method: 'cancel_check_job',
      version: 1);
  data['session'] = session;
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.info("dsmActiveBackupInventoryCancelCheckJob: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

Future<Map> dsmActiveBackupInventoryCheckIdentity(
    String inventoryId, // Inventory ID
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.ActiveBackup.Inventory', method: 'check_identity', version: 1);
  data['inventory_id'] = inventoryId;
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.info("dsmActiveBackupInventoryCheckIdentity: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

Future<Map> dsmActiveBackupInventoryCheckIscsi(
    String inventoryId, // Inventory ID
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.ActiveBackup.Inventory', method: 'check_iscsi', version: 1);
  data['inventory_id'] = inventoryId;
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.info("dsmActiveBackupInventoryCheckIscsi: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

Future<Map> dsmActiveBackupInventoryCreate(String hostName, // Host name
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.ActiveBackup.Inventory', method: 'create', version: 1);
  data['host_name'] = hostName;
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.info("dsmActiveBackupInventoryCreate: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

Future<Map> dsmActiveBackupInventoryCreateCheckJob(String session, // Session ID
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.ActiveBackup.Inventory',
      method: 'create_check_job',
      version: 1);
  data['session'] = session;
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.info("dsmActiveBackupInventoryCreateCheckJob: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

Future<Map> dsmActiveBackupInventoryGetCheckStatus(String session, // Session ID
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.ActiveBackup.Inventory',
      method: 'get_check_status',
      version: 1);
  data['session'] = session;
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
  Log.info("dsmActiveBackupInventoryGetCheckStatus: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

Future<Map> dsmActiveBackupInventoryGetHostInterface(
    String inventoryId, // Inventory ID
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.ActiveBackup.Inventory',
      method: 'get_host_interface',
      version: 1);
  data['inventory_id'] = inventoryId;
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
  Log.info("dsmActiveBackupInventoryGetHostInterface: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

Future<Map> dsmActiveBackupInventoryGetNodeInfos(
    String ids, // Node IDs (comma-separated)
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.ActiveBackup.Inventory', method: 'get_node_infos', version: 1);
  data['ids'] = ids;
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
  Log.info("dsmActiveBackupInventoryGetNodeInfos: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

Future<Map> dsmActiveBackupInventoryGetNodePath(
    String nodePathList, // Node path list (JSON)
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.ActiveBackup.Inventory', method: 'get_node_path', version: 1);
  data['node_path_list'] = nodePathList;
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
  Log.info("dsmActiveBackupInventoryGetNodePath: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

Future<Map> dsmActiveBackupInventoryGetServerCache(
    String inventoryId, // Inventory ID
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.ActiveBackup.Inventory',
      method: 'get_server_cache',
      version: 1);
  data['inventory_id'] = inventoryId;
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
  Log.info("dsmActiveBackupInventoryGetServerCache: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

Future<Map> dsmActiveBackupInventoryGetServerInfo(
    String inventoryId, // Inventory ID
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.ActiveBackup.Inventory',
      method: 'get_server_info',
      version: 1);
  data['inventory_id'] = inventoryId;
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
  Log.info("dsmActiveBackupInventoryGetServerInfo: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

Future<Map> dsmActiveBackupInventoryList({CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.ActiveBackup.Inventory', method: 'list', version: 1);
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
  Log.info("dsmActiveBackupInventoryList: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

Future<Map> dsmActiveBackupInventoryListClusterSharedVolume(
    String inventoryId, // Inventory ID
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.ActiveBackup.Inventory',
      method: 'list_cluster_shared_volume',
      version: 1);
  data['inventory_id'] = inventoryId;
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
  Log.info("dsmActiveBackupInventoryListClusterSharedVolume: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

Future<Map> dsmActiveBackupInventoryListGuestNode(
    String inventoryId, // Inventory ID
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.ActiveBackup.Inventory',
      method: 'list_guest_node',
      version: 1);
  data['inventory_id'] = inventoryId;
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
  Log.info("dsmActiveBackupInventoryListGuestNode: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

Future<Map> dsmActiveBackupInventoryListNode(String parentId, // Parent ID
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.ActiveBackup.Inventory', method: 'list_node', version: 1);
  data['parent_id'] = parentId;
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
  Log.info("dsmActiveBackupInventoryListNode: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

Future<Map> dsmActiveBackupInventoryMergeAutoBackupRule(
    String aemUuid, // AEM UUID
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.ActiveBackup.Inventory',
      method: 'merge_auto_backup_rule',
      version: 1);
  data['aem_uuid'] = aemUuid;
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.info("dsmActiveBackupInventoryMergeAutoBackupRule: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

Future<Map> dsmActiveBackupInventoryRemove({CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.ActiveBackup.Inventory', method: 'remove', version: 1);
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
  Log.info("dsmActiveBackupInventoryRemove: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

Future<Map> dsmActiveBackupInventoryUpdate(String authUser, // Auth user
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.ActiveBackup.Inventory', method: 'update', version: 1);
  data['auth_user'] = authUser;
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.info("dsmActiveBackupInventoryUpdate: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

Future<Map> dsmActiveBackupInventoryUpdateCache(
    String inventoryId, // Inventory ID
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.ActiveBackup.Inventory', method: 'update_cache', version: 1);
  data['inventory_id'] = inventoryId;
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.info("dsmActiveBackupInventoryUpdateCache: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

Future<Map> dsmActiveBackupRestoreVMAbeCancel(
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.ActiveBackup.RestoreVM', method: 'abe_cancel', version: 1);
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
  Log.info("dsmActiveBackupRestoreVMAbeCancel: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

Future<Map> dsmActiveBackupRestoreVMAbeVerify(
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.ActiveBackup.RestoreVM', method: 'abe_verify', version: 1);
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
  Log.info("dsmActiveBackupRestoreVMAbeVerify: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

Future<Map> dsmActiveBackupRestoreVMCheckSpec(
    String deviceList, // Device list (JSON)
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.ActiveBackup.RestoreVM', method: 'check_spec', version: 1);
  data['device_list'] = deviceList;
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.info("dsmActiveBackupRestoreVMCheckSpec: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

Future<Map> dsmActiveBackupRestoreVMCheckSupportTcmu(
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.ActiveBackup.RestoreVM',
      method: 'check_support_tcmu',
      version: 1);
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
  Log.info("dsmActiveBackupRestoreVMCheckSupportTcmu: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

Future<Map> dsmActiveBackupRestoreVMCheckVmm({CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.ActiveBackup.RestoreVM', method: 'check_vmm', version: 1);
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
  Log.info("dsmActiveBackupRestoreVMCheckVmm: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

Future<Map> dsmActiveBackupRestoreVMCloneEncCmpImage(
    String filePath, // File path
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.ActiveBackup.RestoreVM',
      method: 'clone_enc_cmp_image',
      version: 1);
  data['file_path'] = filePath;
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.info("dsmActiveBackupRestoreVMCloneEncCmpImage: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

Future<Map> dsmActiveBackupRestoreVMCreateImage(String taskId, // Task ID
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.ActiveBackup.RestoreVM', method: 'create_image', version: 1);
  data['task_id'] = taskId;
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.info("dsmActiveBackupRestoreVMCreateImage: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

Future<Map> dsmActiveBackupRestoreVMGetAvailableMem(
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.ActiveBackup.RestoreVM',
      method: 'get_available_mem',
      version: 1);
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
  Log.info("dsmActiveBackupRestoreVMGetAvailableMem: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

Future<Map> dsmActiveBackupRestoreVMGetVmmMeta(
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.ActiveBackup.RestoreVM', method: 'get_vmm_meta', version: 1);
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
  Log.info("dsmActiveBackupRestoreVMGetVmmMeta: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

Future<Map> dsmActiveBackupRestoreVMJobCheck({CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.ActiveBackup.RestoreVM', method: 'job_check', version: 1);
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
  Log.info("dsmActiveBackupRestoreVMJobCheck: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

Future<Map> dsmActiveBackupRestoreVMListLatestVersion(
    String singleMode, // Single mode
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.ActiveBackup.RestoreVM',
      method: 'list_latest_version',
      version: 1);
  data['single_mode'] = singleMode;
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
  Log.info("dsmActiveBackupRestoreVMListLatestVersion: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

Future<Map> dsmActiveBackupRestoreVMListSpec(
    String deviceList, // Device list (JSON)
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.ActiveBackup.RestoreVM', method: 'list_spec', version: 1);
  data['device_list'] = deviceList;
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
  Log.info("dsmActiveBackupRestoreVMListSpec: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

Future<Map> dsmActiveBackupRestoreVMMigrate(
    String deviceList, // Device list (JSON)
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.ActiveBackup.RestoreVM', method: 'migrate', version: 1);
  data['device_list'] = deviceList;
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.info("dsmActiveBackupRestoreVMMigrate: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

Future<Map> dsmActiveBackupRestoreVMRemoveImage(String taskId, // Task ID
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.ActiveBackup.RestoreVM', method: 'remove_image', version: 1);
  data['task_id'] = taskId;
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.info("dsmActiveBackupRestoreVMRemoveImage: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

Future<Map> dsmActiveBackupRestoreVMRemoveVmmMeta(
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.ActiveBackup.RestoreVM',
      method: 'remove_vmm_meta',
      version: 1);
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
  Log.info("dsmActiveBackupRestoreVMRemoveVmmMeta: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

Future<Map> dsmActiveBackupRestoreVMRestore(
    String deviceList, // Device list (JSON)
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.ActiveBackup.RestoreVM', method: 'restore', version: 1);
  data['device_list'] = deviceList;
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.info("dsmActiveBackupRestoreVMRestore: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

Future<Map> dsmActiveBackupRestoreVMSetVmmMeta(
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.ActiveBackup.RestoreVM', method: 'set_vmm_meta', version: 1);
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
  Log.info("dsmActiveBackupRestoreVMSetVmmMeta: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

Future<Map> dsmActiveBackupRestoreVMStatusImage(String serialId, // Serial ID
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.ActiveBackup.RestoreVM', method: 'status_image', version: 1);
  data['serial_id'] = serialId;
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
  Log.info("dsmActiveBackupRestoreVMStatusImage: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}
