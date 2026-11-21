part of 'dsm_api.dart';

/// {
///   "success": true,
///   "data": {
///     "volumes": [
///       {
///         "name": "nginx-data",
///         "driver": "local",
///         "mountpoint": "/volume1/@docker/volumes/nginx-data/_data",
///         "scope": "local",
///         "created": 1732752000
///       }
///     ]
///   }
/// }
Future<Map> dsmDockerVolumeList({CancelToken? cancelToken}) async {
  final data =
      _dsmApiRequestData(api: 'SYNO.Docker.Volume', method: 'list', version: 1);
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
//Log.info("dsmDockerVolumeList: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

/// {
///   "success": true,
///   "data": {
///     "name": "nginx-data"
///   }
/// }
Future<Map> dsmDockerVolumeCreate(String name, // Volume name
    {String? driver, // Volume driver (default: `local`)
    CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.Docker.Volume', method: 'create', version: 1);
  data['name'] = name;
  if (driver != null && driver.isNotEmpty) data['driver'] = driver;
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
//Log.info("dsmDockerVolumeCreate: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

/// {
///   "success": true
/// }
Future<Map> dsmDockerVolumeDelete(String name, // Volume name
    {bool? force, // Force delete (default: false)
    CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.Docker.Volume', method: 'delete', version: 1);
  data['name'] = name;
  if (force != null) data['force'] = force;
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
//Log.info("dsmDockerVolumeDelete: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}
