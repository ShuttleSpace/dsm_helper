part of 'dsm_api.dart';

/// {
///   "success": true,
///   "data": {
///     "total": 10,
///     "containers": [
///       {
///         "id": "abc123def456",
///         "name": "nginx-proxy",
///         "image": "nginxproxy/nginx-proxy:latest",
///         "status": "running",
///         "state": "running",
///         "uptime": 86400,
///         "cpu_usage": 5,
///         "memory_usage": 104857600,
///         "network_rx": 1048576,
///         "network_tx": 524288
///       }
///     ]
///   }
/// }
Future<Map> dsmDockerContainerList(
    {int? offset, // Starting index (default: 0)
    int? limit, // Max results (default: -1 = all)
    String? type, // Container type (`all`, `running`, `stopped`)
    CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.Docker.Container', method: 'list', version: 1);
  if (offset != null) data['offset'] = offset;
  if (limit != null) data['limit'] = limit;
  if (type != null && type.isNotEmpty) data['type'] = type;
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
  Log.info("dsmDockerContainerList: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'];
}

/// {
///   "success": true,
///   "data": {
///     "container": {
///       "id": "abc123def456",
///       "name": "nginx-proxy",
///       "image": "nginxproxy/nginx-proxy:latest",
///       "status": "running",
///       "ports": [
///         {
///           "container_port": 80,
///           "host_port": 80,
///           "type": "tcp"
///         }
///       ],
///       "volumes": [
///         {
///           "host_path": "/volume1/docker/nginx-proxy",
///           "container_path": "/etc/nginx"
///         }
///       ],
///       "env": [
///         "DEFAULT_HOST=example.com"
///       ]
///     }
///   }
/// }
Future<Map> dsmDockerContainerGet(String name, // Container name
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.Docker.Container', method: 'get', version: 1);
  data['name'] = name;
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
  Log.info("dsmDockerContainerGet: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'];
}

/// {
///   "success": true
/// }
Future<Map> dsmDockerContainerStart(String name, // Container name
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.Docker.Container', method: 'start', version: 1);
  data['name'] = name;
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.info("dsmDockerContainerStart: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'];
}

/// {
///   "success": true
/// }
Future<Map> dsmDockerContainerStop(String name, // Container name
    {int? timeout, // Stop timeout in seconds (default: 10)
    CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.Docker.Container', method: 'stop', version: 1);
  data['name'] = name;
  if (timeout != null) data['timeout'] = timeout;
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.info("dsmDockerContainerStop: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'];
}

/// {
///   "success": true
/// }
Future<Map> dsmDockerContainerRestart(String name, // Container name
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.Docker.Container', method: 'restart', version: 1);
  data['name'] = name;
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.info("dsmDockerContainerRestart: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'];
}

/// {
///   "success": true
/// }
Future<Map> dsmDockerContainerDelete(
    String name, // Container name (comma-separated for multiple)
    {bool? force, // Force delete (default: false)
    CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.Docker.Container', method: 'delete', version: 1);
  data['name'] = name;
  if (force != null) data['force'] = force;
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.info("dsmDockerContainerDelete: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'];
}

Future<Map> dsmDockerContainerLogList(
    {required String name,
    String? method = 'list', // list, get
    String? sortDir,
    String? date,
    int? limit,
    int? offset,
    CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.Docker.Container.Log', method: method ?? 'list', version: 1)
    ..addAll({'name': name});
  if (method == 'get') {
    data['sort_dir'] = sortDir ?? 'ASC';
    data['date'] = date ?? '';
    data['limit'] = limit ?? 1000;
    data['offset'] = offset ?? 0;
  }
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.info("dsmDockerContainerLogList: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'];
}

/// {
///   "success": true,
///   "data": {
///     "containers": [
///       {
///         "name": "nginx-proxy",
///         "cpu_usage": 5,
///         "memory_usage": 104857600,
///         "memory_limit": 1073741824,
///         "network_rx": 1048576,
///         "network_tx": 524288
///       }
///     ]
///   }
/// }
Future<Map> dsmDockerContainerResourceGet({CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.Docker.Container.Resource', method: 'get', version: 1);
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
  Log.info("dsmDockerContainerResourceGet: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'];
}
