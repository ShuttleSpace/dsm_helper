part of 'dsm_api.dart';

Future<Map> dsmCoreOTPSaveMail(
    {required String mail, CancelToken? cancelToken}) async {
  final data =
      _dsmApiRequestData(api: 'SYNO.Core.OTP', method: 'save_mail', version: 2)
        ..addAll({'mail': mail});
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.info("dsmCoreOTPSaveMail: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

Future<Map> dsmCoreOTPGetQrcode(
    {required String account, CancelToken? cancelToken}) async {
  final data =
      _dsmApiRequestData(api: 'SYNO.Core.OTP', method: 'get_qrcode', version: 2)
        ..addAll({'account': account});
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.info("dsmCoreOTPGetQrcode: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

Future<Map> dsmCoreOTPAuthTmpCode(
    {required String code, CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.Core.OTP', method: 'auth_tmp_code', version: 2)
    ..addAll({'code': code});
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.info("dsmCoreOTPAuthTmpCode: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}
