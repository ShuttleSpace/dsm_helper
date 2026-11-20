part of 'dsm_api.dart';

/// {
///   "success": true,
///   "data": {
///     "total": 5,
///     "shares": [
///       {
///         "name": "docker",
///         "path": "/volume1/docker",
///         "vol_path": "/volume1",
///         "description": "Docker shared folder",
///         "encryption": false,
///         "hidden": false,
///         "recyclebin": true,
///         "share_quota": 0
///       }
///     ]
///   }
/// }
Future<Map> dsmCoreShareList(
    {String? shareType, // Share type (`all`, `user`, `system`)
    String?
        additional, // Additional fields (comma-separated): `hidden`, `encryption`, `is_aclmode`, `recyclebin`, `share_quota`, `enable_share_compress`, `enable_share_cow`
    CancelToken? cancelToken}) async {
  final data =
      _dsmApiRequestData(api: 'SYNO.Core.Share', method: 'list', version: 1);
  if (additional != null && additional.isNotEmpty) {
    data['additional'] = additional;
  }
  if (shareType != null && shareType.isNotEmpty) {
    data['share_type'] = shareType;
  }
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
//Log.info("dsmCoreShareList: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

/// {
///   "success": true,
///   "data": {
///     "share": {
///       "name": "docker",
///       "path": "/volume1/docker",
///       "vol_path": "/volume1",
///       "description": "Docker shared folder"
///     }
///   }
/// }
Future<Map> dsmCoreShareGet(String name, // Share name
    {String?
        additional, // Additional fields (comma-separated): `hidden`, `encryption`, `is_aclmode`, `recyclebin`, `share_quota`, `enable_share_compress`, `enable_share_cow`
    CancelToken? cancelToken}) async {
  final data =
      _dsmApiRequestData(api: 'SYNO.Core.Share', method: 'get', version: 1);
  data['name'] = name;
  if (additional != null && additional.isNotEmpty) {
    data['additional'] = additional;
  }
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
//Log.info("dsmCoreShareGet: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

Map<String, dynamic> dsmCoreShareCreateRequestData(
  String name, // Share name
  String volPath, // Volume path (e.g., `/volume1`)
  {String? desc, // Description
  bool? encryption, // Enable encryption (default: false)
  bool? enableShareCompress, // Enable compression (default: false)
  bool? enableShareCow, // Enable Btrfs COW (default: false)
  bool? recyclebin, // Enable recycle bin (default: false)
}) {
  final data = _dsmApiRequestData(
      api: 'SYNO.Core.Share', method: 'create', version: 1);
  data['name'] = name;
  data['vol_path'] = volPath;
  if (desc != null && desc.isNotEmpty) {
    data['desc'] = desc;
  }
  if (encryption != null) {
    data['encryption'] = encryption;
  }
  if (enableShareCompress != null) {
    data['enable_share_compress'] = enableShareCompress;
  }
  if (enableShareCow != null) {
    data['enable_share_cow'] = enableShareCow;
  }
  if (recyclebin != null) {
    data['recyclebin'] = recyclebin;
  }
  return data;
}

/// {
///   "success": true
/// }
Future<Map> dsmCoreShareCreate(
    String name, // Share name
    String volPath, // Volume path (e.g., `/volume1`)
    {String? desc, // Description
    bool? encryption, // Enable encryption (default: false)
    bool? enableShareCompress, // Enable compression (default: false)
    bool? enableShareCow, // Enable Btrfs COW (default: false)
    bool? recyclebin, // Enable recycle bin (default: false)
    CancelToken? cancelToken}) async {
  final data = dsmCoreShareCreateRequestData(
    name,
    volPath,
    desc: desc,
    encryption: encryption,
    enableShareCompress: enableShareCompress,
    enableShareCow: enableShareCow,
    recyclebin: recyclebin,
  );
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
//Log.info("dsmCoreShareCreate: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

/// {
///   "success": true
/// }
Future<Map> dsmCoreShareSet(String name, // Share name
    {String? desc, // Description
    bool? encryption, // Enable encryption (default: false)
    bool? enableShareCompress, // Enable compression (default: false)
    bool? enableShareCow, // Enable Btrfs COW (default: false)
    bool? recyclebin, // Enable recycle bin (default: false)
    CancelToken? cancelToken}) async {
  final data =
      _dsmApiRequestData(api: 'SYNO.Core.Share', method: 'set', version: 1);
  data['name'] = name;
  if (desc != null && desc.isNotEmpty) {
    data['desc'] = desc;
  }
  if (encryption != null) {
    data['encryption'] = encryption;
  }
  if (enableShareCompress != null) {
    data['enable_share_compress'] = enableShareCompress;
  }
  if (enableShareCow != null) {
    data['enable_share_cow'] = enableShareCow;
  }
  if (recyclebin != null) {
    data['recyclebin'] = recyclebin;
  }
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
//Log.info("dsmCoreShareSet: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

/// {
///   "success": true
/// }
Future<Map> dsmCoreShareDelete(
    String name, // Share name (comma-separated for multiple)
    {CancelToken? cancelToken}) async {
  final data =
      _dsmApiRequestData(api: 'SYNO.Core.Share', method: 'delete', version: 1);
  data['name'] = name;
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
//Log.info("dsmCoreShareDelete: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

Future<Map> dsmCoreRecycleBinStart(
    {required String id, CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.Core.RecycleBin', method: 'start', version: 1)
    ..addAll({id: id});
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
//Log.info("dsmCoreRecycleBinStart: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

/// {
///   "success": true,
///   "data": {
///     "permissions": [
///       {
///         "name": "admin",
///         "is_group": false,
///         "permission": "RW"
///       },
///       {
///         "name": "users",
///         "is_group": true,
///         "permission": "RO"
///       }
///     ]
///   }
/// }
Future<Map> dsmCoreSharePermissionGet(String name, // Share name
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.Core.Share.Permission', method: 'get', version: 1);
  data['name'] = name;
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
//Log.info("dsmCoreSharePermissionGet: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

/// {
///   "success": true
/// }
Future<Map> dsmCoreSharePermissionSet(
    String name, // Share name
    String permissions, // JSON array of permissions
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.Core.Share.Permission', method: 'set', version: 1);
  data['name'] = name;
  data['permissions'] = permissions;
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
//Log.info("dsmCoreSharePermissionSet: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}
