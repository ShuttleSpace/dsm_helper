part of 'dsm_api.dart';

Future<Map> dsmStorageCGIStorageLoadInfo({CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.Storage.CGI.Storage', method: 'load_info', version: 1);
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.info('dsmStorageCGIStorageLoadInfo: $res');
  if (res['success'] != true) {
    throw DSMException.fromMap(res, module: 'SYNO.Storage.CGI.Storage');
  }
  return res['data'] ?? {};
}

Future<Map> dsmStorageCGISmartGetHealthInfo(String device,
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.Storage.CGI.Smart', method: 'get_health_info', version: 1);
  data['device'] = device;
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.info('dsmStorageCGISmartGetHealthInfo: $res');
  if (res['success'] != true) {
    throw DSMException.fromMap(res, module: 'SYNO.Storage.CGI.Storage');
  }
  return res['data'] ?? {};
}
