part of 'dsm_api.dart';

/// {
///   "success": true,
///   "data": {
///     "total": 15,
///     "packages": [
///       {
///         "id": "Docker",
///         "name": "Docker",
///         "version": "20.10.23-1437",
///         "status": "running",
///         "description": "Docker container platform",
///         "distributor": "Synology Inc.",
///         "install_type": "package"
///       }
///     ]
///   }
/// }
Future<Map> dsmCorePackageList(
    {String?
        additional, // Additional fields (comma-separated): `description`, `dependent_packages`, `beta`, `distributor`, `maintainer`, `dsm_apps`, `install_type`, `autoupdate`

    CancelToken? cancelToken}) async {
  final data =
      _dsmApiRequestData(api: 'SYNO.Core.Package', method: 'list', version: 2);
  if (additional != null && additional.isNotEmpty) {
    data['additional'] = additional;
  }
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
  Log.info("dsmCorePackageList: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'];
}

/// {
///   "success": true,
///   "data": {
///     "package": {
///       "id": "Docker",
///       "name": "Docker",
///       "version": "20.10.23-1437",
///       "status": "running",
///       "description": "Docker container platform"
///     }
///   }
/// }
Future<Map> dsmCorePackageGet(String id, // Package ID
    {String?
        additional, // Additional fields (comma-separated): `description`, `dependent_packages`, `beta`, `distributor`, `maintainer`, `dsm_apps`, `install_type`, `autoupdate`

    CancelToken? cancelToken}) async {
  final data =
      _dsmApiRequestData(api: 'SYNO.Core.Package', method: 'get', version: 2);
  data["id"] = id;
  if (additional != null && additional.isNotEmpty) {
    data['additional'] = additional;
  }
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
  Log.info("dsmCorePackageGet: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'];
}

/// {
///   "success": true,
///   "data": {
///     "packages": [
///       {
///         "id": "ActiveBackup",
///         "name": "Active Backup for Business",
///         "version": "2.7.0-13164",
///         "available_version": "2.7.1-13200",
///         "category": "backup"
///       }
///     ]
///   }
/// }
Future<Map> dsmCorePackageServerList({CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.Core.Package.Server', method: 'list', version: 1);
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
  Log.info("dsmCorePackageServerList: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'];
}

/// {
///   "success": true,
///   "data": {
///     "task_id": "install_task_123"
///   }
/// }
Future<Map> dsmCorePackageServerInstallation(String id, // Package ID
    {String? volume, // Installation volume path
    CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.Core.Package.Installation', method: 'install', version: 1);
  data['id'] = id;
  if (volume != null && volume.isNotEmpty) {
    data['volume'] = volume;
  }
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.info("dsmCorePackageServerInstallation: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'];
}

/// {
///   "success": true
/// }
Future<Map> dsmCorePackageServerUnInstallation(String id, // Package ID
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.Core.Package.Installation', method: 'uninstall', version: 1);
  data['id'] = id;
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.info("dsmCorePackageServerUnInstallation: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'];
}

/// {
///   "success": true
/// }
Future<Map> dsmCorePackageControlStart(String id, // Package ID
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.Core.Package.Control', method: 'start', version: 1);
  data['id'] = id;
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.info("dsmCorePackageControlStart: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'];
}

/// {
///   "success": true
/// }
Future<Map> dsmCorePackageControlStop(String id, // Package ID
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.Core.Package.Control', method: 'stop', version: 1);
  data['id'] = id;
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.info("dsmCorePackageControlStop: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'];
}

/// {
///   "success": true
/// }
Future<Map> dsmCorePackageControlRestart(String id, // Package ID
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.Core.Package.Control', method: 'restart', version: 1);
  data['id'] = id;
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.info("dsmCorePackageControlRestart: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'];
}
