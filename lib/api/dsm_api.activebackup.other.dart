part of 'dsm_api.dart';

/// # ActiveBackup for Business - Other APIs
///
/// **General Notes:**
/// - Delegation, task templates, and workload management
/// - All required parameters are marked in function signatures

Future<Map> dsmActiveBackupIntegrationWrapperDomainGet(
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.ActiveBackup.Wrapper.Domain', method: 'get', version: 1);
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
  Log.info("dsmActiveBackupIntegrationWrapperDomainGet: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

Future<Map> dsmActiveBackupIntegrationWrapperDomainGetDomainList(
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.ActiveBackup.Wrapper.Domain',
      method: 'get_domain_list',
      version: 1);
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
  Log.info("dsmActiveBackupIntegrationWrapperDomainGetDomainList: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

Future<Map> dsmActiveBackupIntegrationWrapperDomainTestDc(
    String dcAddress, // DC address
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.ActiveBackup.Wrapper.Domain', method: 'test_dc', version: 1);
  data['dc_address'] = dcAddress;
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.info("dsmActiveBackupIntegrationWrapperDomainTestDc: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

Future<Map> dsmActiveBackupIntegrationWrapperLdapGet(
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.ActiveBackup.Wrapper.LDAP', method: 'get', version: 1);
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
  Log.info("dsmActiveBackupIntegrationWrapperLdapGet: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

Future<Map> dsmActiveBackupIntegrationWrapperNfsGet(
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.ActiveBackup.Wrapper.NFS', method: 'get', version: 1);
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
  Log.info("dsmActiveBackupIntegrationWrapperNfsGet: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

Future<Map> dsmActiveBackupIntegrationWrapperNfsSet(
    String settings, // Settings (JSON)
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.ActiveBackup.Wrapper.NFS', method: 'set', version: 1);
  data['settings'] = settings;
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.info("dsmActiveBackupIntegrationWrapperNfsSet: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

Future<Map> dsmActiveBackupIntegrationWrapperNfsPrivilegeLoad(
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.ActiveBackup.Wrapper.NFSPrivilege',
      method: 'load',
      version: 1);
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
  Log.info("dsmActiveBackupIntegrationWrapperNfsPrivilegeLoad: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

Future<Map> dsmActiveBackupIntegrationWrapperNfsPrivilegeSave(
    String privileges, // Privileges (JSON)
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.ActiveBackup.Wrapper.NFSPrivilege',
      method: 'save',
      version: 1);
  data['privileges'] = privileges;
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.info("dsmActiveBackupIntegrationWrapperNfsPrivilegeSave: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

Future<Map> dsmActiveBackupOtherDelegationCreateOrUpdate(
    String delegation, // Delegation (JSON)
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.ActiveBackup.Delegation',
      method: 'create_or_update',
      version: 1);
  data['delegation'] = delegation;
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.info("dsmActiveBackupOtherDelegationCreateOrUpdate: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

Future<Map> dsmActiveBackupOtherDelegationDelete(
    String delegationId, // Delegation ID
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.ActiveBackup.Delegation', method: 'delete', version: 1);
  data['delegation_id'] = delegationId;
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.info("dsmActiveBackupOtherDelegationDelete: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

Future<Map> dsmActiveBackupOtherDelegationList(
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.ActiveBackup.Delegation', method: 'list', version: 1);
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
  Log.info("dsmActiveBackupOtherDelegationList: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

Future<Map> dsmActiveBackupOtherTaskTemplateCreate(
    String templateName, // Template name
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.ActiveBackup.TaskTemplate', method: 'create', version: 1);
  data['template_name'] = templateName;
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.info("dsmActiveBackupOtherTaskTemplateCreate: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

Future<Map> dsmActiveBackupOtherTaskTemplateList(
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.ActiveBackup.TaskTemplate', method: 'list', version: 1);
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
  Log.info("dsmActiveBackupOtherTaskTemplateList: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

Future<Map> dsmActiveBackupOtherTaskTemplateRemove(
    String templateId, // Template ID
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.ActiveBackup.TaskTemplate', method: 'remove', version: 1);
  data['template_id'] = templateId;
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.info("dsmActiveBackupOtherTaskTemplateRemove: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

Future<Map> dsmActiveBackupOtherTaskTemplateSet(
    String templateId, // Template ID
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.ActiveBackup.TaskTemplate', method: 'set', version: 1);
  data['template_id'] = templateId;
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.info("dsmActiveBackupOtherTaskTemplateSet: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

Future<Map> dsmActiveBackupOtherTaskTemplateSetPriority(
    String templateId, // Template ID
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.ActiveBackup.TaskTemplate',
      method: 'set_priority',
      version: 1);
  data['template_id'] = templateId;
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.info("dsmActiveBackupOtherTaskTemplateSetPriority: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

Future<Map> dsmActiveBackupOtherTaskTemplateTranslateTargetId(
    String targetId, // Target ID
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.ActiveBackup.TaskTemplate',
      method: 'translate_target_id',
      version: 1);
  data['target_id'] = targetId;
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
  Log.info("dsmActiveBackupOtherTaskTemplateTranslateTargetId: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

Future<Map> dsmActiveBackupOtherWorkloadBackup(
    String workloadUuid, // Workload UUID
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.ActiveBackup.Workload', method: 'backup', version: 1);
  data['workload_uuid'] = workloadUuid;
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.info("dsmActiveBackupOtherWorkloadBackup: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

Future<Map> dsmActiveBackupOtherWorkloadCancel(
    String workloadUuid, // Workload UUID
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.ActiveBackup.Workload', method: 'cancel', version: 1);
  data['workload_uuid'] = workloadUuid;
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.info("dsmActiveBackupOtherWorkloadCancel: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

Future<Map> dsmActiveBackupOtherWorkloadCancelByActivityUid(
    String activityUid, // Activity UID
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.ActiveBackup.Workload',
      method: 'cancel_by_activity_uid',
      version: 1);
  data['activity_uid'] = activityUid;
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.info("dsmActiveBackupOtherWorkloadCancelByActivityUid: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

Future<Map> dsmActiveBackupOtherWorkloadCancelThenDelete(
    String workloadUuid, // Workload UUID
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.ActiveBackup.Workload',
      method: 'cancel_then_delete',
      version: 1);
  data['workload_uuid'] = workloadUuid;
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.info("dsmActiveBackupOtherWorkloadCancelThenDelete: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

Future<Map> dsmActiveBackupOtherWorkloadCreate(
    String workloadName, // Workload name
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.ActiveBackup.Workload', method: 'create', version: 1);
  data['workload_name'] = workloadName;
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.info("dsmActiveBackupOtherWorkloadCreate: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

Future<Map> dsmActiveBackupOtherWorkloadDelete(
    String workloadUuid, // Workload UUID
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.ActiveBackup.Workload', method: 'delete', version: 1);
  data['workload_uuid'] = workloadUuid;
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.info("dsmActiveBackupOtherWorkloadDelete: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

Future<Map> dsmActiveBackupOtherWorkloadDeleteWithoutDedup(
    String workloadUuid, // Workload UUID
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.ActiveBackup.Workload',
      method: 'delete_without_dedup',
      version: 1);
  data['workload_uuid'] = workloadUuid;
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.info("dsmActiveBackupOtherWorkloadDeleteWithoutDedup: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

Future<Map> dsmActiveBackupOtherWorkloadGetPlan(
    String workloadUuid, // Workload UUID
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.ActiveBackup.Workload', method: 'get_plan', version: 1);
  data['workload_uuid'] = workloadUuid;
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
  Log.info("dsmActiveBackupOtherWorkloadGetPlan: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

Future<Map> dsmActiveBackupOtherWorkloadGetStatus(
    String workloadUuid, // Workload UUID
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.ActiveBackup.Workload', method: 'get_status', version: 1);
  data['workload_uuid'] = workloadUuid;
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
  Log.info("dsmActiveBackupOtherWorkloadGetStatus: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

Future<Map> dsmActiveBackupOtherWorkloadUpdate(
    String workloadUuid, // Workload UUID
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.ActiveBackup.Workload', method: 'update', version: 1);
  data['workload_uuid'] = workloadUuid;
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.info("dsmActiveBackupOtherWorkloadUpdate: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}
