part of 'dsm_api.dart';

Future<Map> dsmCoreNormalUser(String method, // get, set
    {Map<String, dynamic>? changedData,
    CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.Core.NormalUser',
      method: method,
      version: method == 'get' ? 1 : 2);
  if (changedData != null) {
    data.addAll(changedData);
  }
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.info("dsmCoreNormalUser: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

Future<Map> dsmCorePersonalSettingsQuota({CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.Core.PersonalSettings', method: 'quota', version: 1);
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.info("dsmCorePersonalSettingsQuota: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

Future<Map> dsmCoreUserSettingsApply(
    {required Map data, CancelToken? cancelToken}) async {
  final requestData = _dsmApiRequestData(
      api: 'SYNO.Core.UserSettings', method: 'apply', version: 1)
    ..addAll({'data': jsonEncode(jsonEncode(data))});
  final res =
      await _httpPost(_entryCGI, data: requestData, cancelToken: cancelToken);
  Log.info("dsmCoreUserSettingsApply: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}
