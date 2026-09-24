part of 'dsm_api.dart';

Future<Map> dsmCoreSecurityScanStatusRuleGet(
    {String? items = 'ALL', CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.Core.SecurityScan.Status', method: 'rule_get', version: 1);
  if (items != null) {
    data['items'] = items;
  }
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
//Log.info("dsmCoreSecurityScanStatusRuleGet: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

Future<Map> dsmCoreSecurityScanStatusSystemGet(
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.Core.SecurityScan.Status', method: 'system_get', version: 1);
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
//Log.info("dsmCoreSecurityScanStatusSystemGet: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}
