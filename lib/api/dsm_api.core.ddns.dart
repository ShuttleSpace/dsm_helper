part of 'dsm_api.dart';

Future<Map> dsmCoreDDNSRecordSet(
    {required String id,
    required bool enable,
    required String provider,
    required String hostname,
    required String username,
    String? passwd,
    required String net,
    required String ip,
    required String ipv6,
    required bool heartbeat,
    CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.Core.DDNS.Record', method: 'set', version: 1)
    ..addAll({
      'id': id.replaceAll('USER_', '*'),
      'enable': enable,
      'provider': provider,
      'hostname': hostname,
      'username': username,
      'net': net,
      'ip': ip,
      'ipv6': ipv6,
      'heartbeat': heartbeat
    });
  if (passwd != null) {
    data['passwd'] = passwd;
  }
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
//Log.info("dsmCoreDDNSRecordSet: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

Future<Map> dsmCoreDDNSRecordUpdateIpAddress(
    {required String id, CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.Core.DDNS.Record', method: 'update_ip_address', version: 1)
    ..addAll({'id': id});
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
//Log.info("dsmCoreDDNSRecordUpdateIpAddress: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

Future<Map> dsmCoreDDNSRecordDelete(
    {required List<String> id, CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.Core.DDNS.Record', method: 'delete', version: 1)
    ..addAll({'id': jsonEncode(id)});
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
//Log.info("dsmCoreDDNSRecordDelete: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

Future<Map> dsmCoreDDNSRecordTest(
    {required String provider,
    required String hostname,
    required String username,
    String? passwd,
    required String net,
    required String ip,
    required String ipv6,
    required bool heartbeat,
    CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.Core.DDNS.Record', method: 'test', version: 1)
    ..addAll({
      'enable': true,
      'provider': provider.replaceAll('*', 'USER_'),
      'hostname': hostname,
      'username': username,
      'net': net,
      'ip': ip,
      'ipv6': ipv6,
      'heartbeat': heartbeat
    });
  if (passwd != null) {
    data['passwd'] = passwd;
  }
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
//Log.info("dsmCoreDDNSRecordTest: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}
