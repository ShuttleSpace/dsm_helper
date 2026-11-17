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
//Log.info("dsmDockerContainerList: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
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
//Log.info("dsmDockerContainerGet: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
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
//Log.info("dsmDockerContainerStart: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
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
//Log.info("dsmDockerContainerStop: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
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
//Log.info("dsmDockerContainerRestart: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
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
//Log.info("dsmDockerContainerDelete: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
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
//Log.info("dsmDockerContainerLogList: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
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
//Log.info("dsmDockerContainerResourceGet: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

/// 测试替身：非空时替代 Docker 模块的 POST，用于断言页面级复合请求的原始字段。
@visibleForTesting
Future<dynamic> Function(String endpoint, {Map<String, dynamic>? data})?
    dsmDockerPostForTesting;

Future<dynamic> _dsmDockerPost(String endpoint,
    {required Map<String, dynamic> data, CancelToken? cancelToken}) async {
  final override = dsmDockerPostForTesting;
  if (override != null) return await override(endpoint, data: data);
  return await _httpPost(endpoint, data: data, cancelToken: cancelToken);
}

/// 容器列表 + 资源 + 系统占用的一次性复合请求（页面总览用）。
///
/// 与旧 `DsmApi.dockerContainerInfo()` 的 compound 请求字段完全一致，
/// 成功返回 `data.result` 列表，失败抛 [DSMException]。
Future<List<dynamic>> dsmDockerContainerOverview(
    {CancelToken? cancelToken}) async {
  final compound = [
    {
      "api": "SYNO.Docker.Container",
      "method": "list",
      "version": 1,
      "limit": -1,
      "offset": 0,
      "type": "all"
    },
    {"api": "SYNO.Docker.Container.Resource", "method": "get", "version": 1},
    {"api": "SYNO.Core.System.Utilization", "method": "get", "version": 1},
  ];
  final res = await _dsmDockerPost(_entryCGI,
      data: {
        "api": 'SYNO.Entry.Request',
        "method": 'request',
        "mode": '"parallel"',
        "compound": jsonEncode(compound),
        "version": 1,
        "_sid": connectionStore.sid.value,
      },
      cancelToken: cancelToken);
  if (res is! Map || res['success'] != true) {
    throw DSMException.fromMap(res is Map ? res : const {});
  }
  final data = res['data'];
  final result = data is Map ? data['result'] : null;
  return result is List ? result : <dynamic>[];
}

/// 镜像列表 + 注册表的一次性复合请求（页面镜像/注册表用）。
Future<List<dynamic>> dsmDockerImageOverview({CancelToken? cancelToken}) async {
  final compound = [
    {
      "api": "SYNO.Docker.Image",
      "method": "list",
      "version": 1,
      "limit": -1,
      "offset": 0,
      "show_dsm": false
    },
    {
      "api": "SYNO.Docker.Registry",
      "method": "get",
      "version": 1,
      "limit": -1,
      "offset": 0
    }
  ];
  final res = await _dsmDockerPost(_entryCGI,
      data: {
        "api": 'SYNO.Entry.Request',
        "method": 'request',
        "mode": '"parallel"',
        "compound": jsonEncode(compound),
        "version": 1,
        "_sid": connectionStore.sid.value,
      },
      cancelToken: cancelToken);
  if (res is! Map || res['success'] != true) {
    throw DSMException.fromMap(res is Map ? res : const {});
  }
  final data = res['data'];
  final result = data is Map ? data['result'] : null;
  return result is List ? result : <dynamic>[];
}

/// 容器电源/删除操作；保留旧层的 `signal=9` 与 `preserve_profile` 语义。
Future<Map> dsmDockerContainerAction(String name, String action,
    {bool? preserveProfile, CancelToken? cancelToken}) async {
  final data = <String, dynamic>{
    "api": 'SYNO.Docker.Container',
    "method": action,
    "name": '"$name"',
    "version": 1,
    "_sid": connectionStore.sid.value,
  };
  if (action == "signal") {
    data['signal'] = 9;
  }
  if (action == "delete") {
    data['preserve_profile'] = preserveProfile ?? '';
  }
  final res = await _dsmDockerPost(_entryCGI,
      data: data, cancelToken: cancelToken);
  if (res is! Map || res['success'] != true) {
    throw DSMException.fromMap(res is Map ? res : const {});
  }
  return res['data'] is Map ? res['data'] as Map : <String, dynamic>{};
}

/// 容器详情/进程以外的扩展方法（`get`、`get_process` 等）。
Future<Map> dsmDockerContainerDetail(String name, String method,
    {CancelToken? cancelToken}) async {
  final res = await _dsmDockerPost(_entryCGI,
      data: {
        "api": 'SYNO.Docker.Container',
        "method": method,
        "name": '"$name"',
        "version": 1,
        "_sid": connectionStore.sid.value,
      },
      cancelToken: cancelToken);
  if (res is! Map || res['success'] != true) {
    throw DSMException.fromMap(res is Map ? res : const {});
  }
  return res['data'] is Map ? res['data'] as Map : <String, dynamic>{};
}

/// 容器进程列表（SYNO.Docker.Container/get_process）。
Future<Map> dsmDockerContainerProcesses(String name,
    {CancelToken? cancelToken}) async {
  return await dsmDockerContainerDetail(name, 'get_process',
      cancelToken: cancelToken);
}

/// 容器日志：`method=get` 带日期/排序/分页，`get_date_list` 只取日期列表。
Future<Map> dsmDockerContainerLog(String name, String method,
    {String? date, CancelToken? cancelToken}) async {
  final data = <String, dynamic>{
    "api": 'SYNO.Docker.Container.Log',
    "method": method,
    "name": '"$name"',
    "version": 1,
    "_sid": connectionStore.sid.value,
  };
  if (method == "get") {
    data['sort_dir'] = '"ASC"';
    data['date'] = '"$date"';
    data['limit'] = 1000;
    data['offset'] = 0;
  }
  final res = await _dsmDockerPost(_entryCGI,
      data: data, cancelToken: cancelToken);
  if (res is! Map || res['success'] != true) {
    throw DSMException.fromMap(res is Map ? res : const {});
  }
  return res['data'] is Map ? res['data'] as Map : <String, dynamic>{};
}
