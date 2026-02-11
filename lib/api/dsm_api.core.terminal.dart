part of 'dsm_api.dart';

Future<Map> dsmCoreTerminalGet({CancelToken? cancelToken}) async {
  final data =
      _dsmApiRequestData(api: 'SYNO.Core.Terminal', method: 'get', version: 3);
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.info("dsmCoreTerminalGet: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'];
}

Future<Map> dsmCoreTerminalSet(
    {required bool enableSsh,
    required bool enableTelnet,
    required String sshPort,
    CancelToken? cancelToken}) async {
  final data =
      _dsmApiRequestData(api: 'SYNO.Core.Terminal', method: 'set', version: 3)
        ..addAll({
          'enable_ssh': enableSsh,
          'enable_telnet': enableTelnet,
          'ssh_port': sshPort
        });
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.info("dsmCoreTerminalSet: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'];
}
