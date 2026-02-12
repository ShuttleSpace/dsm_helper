part of 'dsm_api.dart';

/// {
///   "success": true,
///   "data": {
///     "total": 25,
///     "images": [
///       {
///         "id": "sha256:abc123def456",
///         "repository": "nginxproxy/nginx-proxy",
///         "tag": "latest",
///         "size": 157286400,
///         "created": 1732752000,
///         "is_ddsm": false
///       }
///     ]
///   }
/// }
Future<Map> dsmDockerImageList(
    {int? offset, // Starting index (default: 0)
    int? limit, // Max results (default: -1 = all)
    bool? showDsm, // Show DSM images (default: false)
    CancelToken? cancelToken}) async {
  final data =
      _dsmApiRequestData(api: 'SYNO.Docker.Image', method: 'list', version: 1);
  if (offset != null) data['offset'] = offset;
  if (limit != null) data['limit'] = limit;
  if (showDsm != null) data['show_dsm'] = showDsm;
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
  Log.info("dsmDockerImageList: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

/// {
///   "success": true,
///   "data": {
///     "image": {
///       "id": "sha256:abc123def456",
///       "repository": "nginxproxy/nginx-proxy",
///       "tag": "latest",
///       "size": 157286400,
///       "created": 1732752000
///     }
///   }
/// }
Future<Map> dsmDockerImageGet(
    String repository, // Image repository
    String tag, // Image tag
    {CancelToken? cancelToken}) async {
  final data =
      _dsmApiRequestData(api: 'SYNO.Docker.Image', method: 'get', version: 1);
  data['repository'] = repository;
  data['tag'] = tag;
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
  Log.info("dsmDockerImageGet: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

/// {
///   "success": true,
///   "data": {
///     "task_id": "pull_task_123"
///   }
/// }
Future<Map> dsmDockerImagePull(String repository, // Image repository
    {String? tag, // Image tag (default: `latest`)
    String? registry, // Registry URL
    CancelToken? cancelToken}) async {
  final data =
      _dsmApiRequestData(api: 'SYNO.Docker.Image', method: 'pull', version: 1);
  data['repository'] = repository;
  if (tag != null && tag.isNotEmpty) data['tag'] = tag;
  if (registry != null && registry.isNotEmpty) data['registry'] = registry;
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.info("dsmDockerImagePull: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

/// {
///   "success": true
/// }
Future<Map> dsmDockerImageDelete(
    String repository, // Image repository
    String tag, // Image tag
    {bool? force, // Force delete (default: false)
    CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.Docker.Image', method: 'delete', version: 1);
  data['repository'] = repository;
  data['tag'] = tag;
  if (force != null) data['force'] = force;
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.info("dsmDockerImageDelete: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

/// {
///   "success": true,
///   "data": {
///     "images": [
///       {
///         "name": "nginx",
///         "description": "Official build of Nginx",
///         "star_count": 15000,
///         "is_official": true,
///         "is_automated": false
///       }
///     ]
///   }
/// }
Future<Map> dsmDockerImageSearch(String query, // Search query
    {String? registry, // Registry to search
    CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.Docker.Image.Search', method: 'search', version: 1);
  data['query'] = query;
  if (registry != null && registry.isNotEmpty) data['registry'] = registry;
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
  Log.info("dsmDockerImageSearch: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

/// {
///   "success": true,
///   "data": {
///     "registries": [
///       {
///         "name": "Docker Hub",
///         "url": "https://registry-1.docker.io",
///         "is_default": true
///       },
///       {
///         "name": "GitHub Container Registry",
///         "url": "https://ghcr.io",
///         "is_default": false
///       }
///     ]
///   }
/// }
Future<Map> dsmDockerImageRegistryList({CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.Docker.Image.Registry', method: 'list', version: 1);
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
  Log.info("dsmDockerImageRegistryList: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

/// {
///   "success": true
/// }
Future<Map> dsmDockerImageRegistryAdd(
    String name, // Registry name
    String url, // Registry URL
    {String? username, // Registry username
    String? password, // Registry password
    CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.Docker.Image.Registry', method: 'add', version: 1);
  data['name'] = name;
  data['url'] = url;
  if (username != null && username.isNotEmpty) data['username'] = username;
  if (password != null && password.isNotEmpty) data['password'] = password;
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.info("dsmDockerImageRegistryAdd: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}
