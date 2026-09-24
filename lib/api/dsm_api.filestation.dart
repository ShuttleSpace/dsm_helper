part of 'dsm_api.dart';

/// ## Error Codes

/// | Code | Description |
/// |------|-------------|
/// | 400 | Invalid parameter |
/// | 401 | No such file or directory |
/// | 402 | System is too busy |
/// | 403 | Invalid user |
/// | 404 | Invalid group |
/// | 405 | Invalid user and group |
/// | 406 | Can't get user/group information from the account server |
/// | 407 | Operation not permitted |
/// | 408 | No such task of the file operation |
/// | 409 | Non-supported file system |
/// | 410 | Failed to connect internet-based file system (ex: CIFS) |
/// | 411 | Read-only file system |
/// | 412 | Filename too long in the non-encrypted file system |
/// | 413 | Filename too long in the encrypted file system |
/// | 414 | File already exists |
/// | 415 | Disk quota exceeded |
/// | 416 | No space left on device |
/// | 417 | Input/output error |
/// | 418 | Illegal name or path |
/// | 419 | Illegal file name |
/// | 420 | Illegal file name on FAT file system |
/// | 421 | Device or resource busy |///

/// ---

/// {
///   "success": true,
///   "data": {
///     "is_manager": true,
///     "support_virtual_protocol": ["cifs", "nfs"],
///     "support_sharing": true,
///     "hostname": "MyNAS",
///     "enable_list_usergrp": true,
///     "items": [
///       {
///         "path": "/volume1/homes/admin",
///         "name": "home"
///       }
///     ]
///   }
/// }
///
/// **Response Fields:**
///
/// | Field | Type | Description |
/// |-------|------|-------------|
/// | `is_manager` | boolean | User has manager privileges |
/// | `support_virtual_protocol` | array | Supported virtual protocols |
/// | `support_sharing` | boolean | Sharing feature supported |
/// | `hostname` | string | NAS hostname |
/// | `enable_list_usergrp` | boolean | Can list users/groups |
///
/// ---
Future<Map> dsmFileStationInfoGet({CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.FileStation.Info', method: 'get', version: 2);
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
//Log.info("dsmFileStationInfoGet: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

/// {
///   "success": true,
///   "data": {
///     "total": 3,
///     "offset": 0,
///     "shares": [
///       {
///         "path": "/docker",
///         "name": "docker",
///         "isdir": true,
///         "additional": {
///           "real_path": "/volume1/docker",
///           "owner": {
///             "user": "admin",
///             "group": "administrators",
///             "uid": 1024,
///             "gid": 100
///           },
///           "time": {
///             "atime": 1732752000,
///             "mtime": 1732752000,
///             "ctime": 1732752000,
///             "crtime": 1732752000
///           },
///           "perm": {
///             "posix": 755,
///             "is_acl_mode": false,
///             "acl": {
///               "append": false,
///               "del": false,
///               "exec": true,
///               "read": true,
///               "write": false
///             }
///           }
///         }
///       }
///     ]
///   }
/// }
///
/// **Response Fields:**
///
/// | Field | Type | Description |
/// |-------|------|-------------|
/// | `total` | integer | Total number of shares |
/// | `offset` | integer | Current offset |
/// | `shares` | array | Array of share objects |
/// | `path` | string | Share path |
/// | `name` | string | Share name |
/// | `isdir` | boolean | Is directory |
///
/// ---
Future<Map> dsmFileStationListListShare(
    {int? offset, // Starting index (default: 0)
    int? limit, // Max results (default: 0 = all)
    String?
        sortBy, // Sort field: `name`, `user`, `group`, `mtime`, `atime`, `ctime`, `crtime`, `posix`
    String? sortDirection, // `asc` or `desc`
    bool? onlywritable, // Only writable shares
    List<String>?
        additional, // Additional fields: `real_path`, `owner`, `time`, `perm`, `mount_point_type`, `volume_status`
    CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.FileStation.List', method: 'list_share', version: 2);
  if (offset != null) data['offset'] = offset;
  if (limit != null) data['limit'] = limit;
  if (sortBy != null && sortBy.isNotEmpty) data['sort_by'] = sortBy;
  if (sortDirection != null && sortDirection.isNotEmpty) {
    data['sort_direction'] = sortDirection;
  }
  if (onlywritable != null) data['onlywritable'] = onlywritable;
  if (additional != null && additional.isNotEmpty) {
    data['additional'] = jsonEncode(additional);
  }
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
  // Log.info("dsmFileStationListListShare: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

/// {
///   "success": true,
///   "data": {
///     "total": 15,
///     "offset": 0,
///     "files": [
///       {
///         "path": "/docker/compose",
///         "name": "compose",
///         "isdir": true,
///         "additional": {
///           "size": 4096,
///           "time": {
///             "atime": 1732752000,
///             "mtime": 1732752000,
///             "ctime": 1732752000,
///             "crtime": 1732752000
///           }
///         }
///       }
///     ]
///   }
/// }
Future<Map> dsmFileStationListList(String folderPath, // Folder path
    {int? offset, // Starting index
    int? limit, // Max results
    String?
        sortBy, // Sort field: `name`, `size`, `user`, `group`, `mtime`, `atime`, `ctime`, `crtime`, `posix`, `type`
    String? sortDirection, // `asc` or `desc`
    String? pattern, // File name pattern
    String? filetype, // `file`, `dir`, `all`
    String? gotoPath, // Jump to specific path
    String?
        additional, // Additional fields: `real_path`, `size`, `owner`, `time`, `perm`, `mount_point_type`, `type`
    CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.FileStation.List', method: 'list', version: 2);
  data['folder_path'] = folderPath;
  if (offset != null) data['offset'] = offset;
  if (limit != null) data['limit'] = limit;
  if (sortBy != null && sortBy.isNotEmpty) data['sort_by'] = sortBy;
  if (sortDirection != null && sortDirection.isNotEmpty) {
    data['sort_direction'] = sortDirection;
  }
  if (pattern != null && pattern.isNotEmpty) data['pattern'] = pattern;
  if (filetype != null && filetype.isNotEmpty) data['filetype'] = filetype;
  if (gotoPath != null && gotoPath.isNotEmpty) data['goto_path'] = gotoPath;
  if (additional != null && additional.isNotEmpty) {
    data['additional'] = additional;
  }
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
//Log.info("dsmFileStationListList: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

/// {
///   "success": true,
///   "data": {
///     "files": [
///       {
///         "path": "/docker/README.md",
///         "name": "README.md",
///         "isdir": false,
///         "additional": {
///           "size": 2048,
///           "time": {
///             "atime": 1732752000,
///             "mtime": 1732752000,
///             "ctime": 1732752000,
///             "crtime": 1732752000
///           }
///         }
///       }
///     ]
///   }
/// }
Future<Map> dsmFileStationListGetinfo(
    String path, // File/folder path (JSON array for multiple)
    {String? additional, // Additional fields
    CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.FileStation.List', method: 'getinfo', version: 2);
  data['path'] = path;
  if (additional != null && additional.isNotEmpty) {
    data['additional'] = additional;
  }
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
//Log.info("dsmFileStationListGetinfo: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

Future<Map> dsmFileStationVirtualFolderList(
    {required String node,
    required String type,
    String? sortBy,
    String? additional,
    CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.FileStation.VirtualFolder', method: 'list', version: 2)
    ..addAll({'node': node, 'type': type});
  if (sortBy != null) {
    data['sort_by'] = sortBy;
  }
  if (additional != null) {
    data['additional'] = additional;
  }
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
//Log.info("dsmFileStationVirtualFolderList: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

Future<Map> dsmFileStationVFSConnectionDelete(
    {required String id, CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.FileStation.VFS.Connection', method: 'delete', version: 1)
    ..addAll({'id': id});
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
//Log.info("dsmFileStationVFSConnectionDelete: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

/// {
///   "success": true,
///   "data": {
///     "result": true
///   }
/// }
Future<Map> dsmFileStationCheckPermissionWrite(
    String path, // Destination folder path
    String filename, // Filename to check
    {int? size,
    bool? overwrite,
    bool? createOnly, // File must not exist (default: false)
    CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.FileStation.CheckPermission', method: 'write', version: 3);
  data['path'] = path;
  data['filename'] = filename;
  if (overwrite != null) data['overwrite'] = overwrite;
  if (size != null) data['size'] = size;
  if (createOnly != null) data['create_only'] = createOnly;
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
//Log.info("dsmFileStationCheckPermissionWrite: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}
