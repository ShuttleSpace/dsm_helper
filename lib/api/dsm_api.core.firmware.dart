part of 'dsm_api.dart';

Future<Map> dsmCoreSystemInfoFirmware({CancelToken? cancelToken}) async {
  final data =
      _dsmApiRequestData(api: 'SYNO.Core.System', method: 'info', version: 3)
        ..addAll({'type': 'firmware'});
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
//Log.info("dsmCoreSystemInfoFirmware: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

Future<Map> dsmCoreUpgradeServerCheck({CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.Core.Upgrade.Server', method: 'check', version: 2)
    ..addAll({
      'user_reading': true,
      'need_auto_smallupdate': true,
      'need_promotion': true
    });
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
//Log.info("dsmCoreUpgradeServerCheck: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}
