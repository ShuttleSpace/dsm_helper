part of 'dsm_api.dart';

/// {
///   "success": true,
///   "data": {
///     "networks": [
///       {
///         "id": "abc123def456",
///         "name": "bridge",
///         "driver": "bridge",
///         "scope": "local",
///         "ipam": {
///           "driver": "default",
///           "config": [
///             {
///               "subnet": "172.17.0.0/16",
///               "gateway": "172.17.0.1"
///             }
///           ]
///         }
///       }
///     ]
///   }
/// }
Future<Map> dsmDockerNetworkList({CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.Docker.Network', method: 'list', version: 1);
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
  Log.info("dsmDockerNetworkList: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'];
}

/// {
///   "success": true,
///   "data": {
///     "id": "network_id_123"
///   }
/// }
Future<Map> dsmDockerNetworkCreate(String name, // Network name
    {String? driver, // Network driver (`bridge`, `host`, `overlay`, `macvlan`)
    String? subnet, // Subnet (e.g., `172.18.0.0/16`)
    String? gateway,
    String? ipRange,
    CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.Docker.Network', method: 'create', version: 1);
  data['name'] = name;
  if (driver != null && driver.isNotEmpty) data['driver'] = driver;
  if (subnet != null && subnet.isNotEmpty) data['subnet'] = subnet;
  if (gateway != null && gateway.isNotEmpty) data['gateway'] = gateway;
  if (ipRange != null && ipRange.isNotEmpty) data['ip_range'] = ipRange;
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.info("dsmDockerNetworkCreate: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'];
}

/// {
///   "success": true
/// }
Future<Map> dsmDockerNetworkDelete(String name, // Network name
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.Docker.Network', method: 'delete', version: 1);
  data['name'] = name;
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.info("dsmDockerNetworkDelete: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'];
}
