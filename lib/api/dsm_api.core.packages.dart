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
        additional, // JSON Array, Additional fields (comma-separated): `description`, `dependent_packages`, `beta`, `distributor`, `maintainer`, `dsm_apps`, `install_type`, `autoupdate`, `status_sketch`, `dsm_apps`, `install_type` `status`,
    // additional=["status","dsm_apps","install_type"]
    bool? ignoreHidden,
    int? version,
    int? pollingInterval,
    CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.Core.Package', method: 'list', version: version ?? 2);
  if (additional != null && additional.isNotEmpty) {
    data['additional'] = additional;
  }
  if (pollingInterval != null) {
    data['polling_interval'] = pollingInterval;
  }
  if (ignoreHidden != null) {
    data['ignore_hidden'] = ignoreHidden;
  }
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
//Log.info("dsmCorePackageList: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
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
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
//Log.info("dsmCorePackageGet: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
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
Future<Map> dsmCorePackageServerList(
    {CancelToken? cancelToken,
    int? version,
    bool? updateSrpite,
    bool? blforcereload,
    bool? blloadothers = false}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.Core.Package.Server', method: 'list', version: version ?? 1);
  if (updateSrpite != null) {
    data['updateSrpite'] = true;
  }
  if (blforcereload != null) {
    data['blforcereload'] = true;
  }
  if (blloadothers != null) {
    data['blloadothers'] = true;
  }
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
  // Log.info("dsmCorePackageServerList: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

/// {"data":{"has_fail":false,"result":[{"api":"SYNO.Core.Upgrade.Server","data":{"available":false},"method":"check","success":true,"version":1},{"api":"SYNO.Core.Package.Server","data":{"action":"prepare","error":{"code":0},"stage":"prepare","success":true},"method":"check","success":true,"version":1}]},"success":true}
Future<Map> dsmCoreUpgradeCheck({CancelToken? cancelToken}) async {
  final compound = [
    {
      'api': 'SYNO.Core.Upgrade.Server',
      'method': 'check',
      'version': 1,
      'need_auto_smallupdate': true
    },
    {'api': 'SYNO.Core.Package.Server', 'method': 'check', 'version': 1}
  ];
  final res = await _dsmApiCall(jsonEncode(compound), cancelToken: cancelToken);
//Log.info("dsmCoreUpgradeCheck: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
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
//Log.info("dsmCorePackageServerInstallation: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
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
//Log.info("dsmCorePackageServerUnInstallation: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

/// {
///   "success": true
/// }
Future<Map> dsmCorePackageControlStart(
    String id, // Package ID
    String dsmApps, // json Encoded
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.Core.Package.Control', method: 'start', version: 1);
  data['id'] = id;
  data['dsm_apps'] = dsmApps;
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
//Log.info("dsmCorePackageControlStart: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
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
//Log.info("dsmCorePackageControlStop: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
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
//Log.info("dsmCorePackageControlRestart: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

/// get running app
Future<Map> dsmCorePollingData({CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.Core.Polling.Data', method: 'get', version: 1);
  data['action'] = 'load';
  data['load_disabled_port'] = true;
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
//Log.info("dsmCorePollingData: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

/// 套件页面级请求替身（测试用）。
@visibleForTesting
Future<dynamic> Function(String endpoint, {Map<String, dynamic>? data})?
    dsmCorePackagePagePostForTesting;

Future<dynamic> _dsmCorePackagePagePost(String endpoint,
    {required Map<String, dynamic> data, CancelToken? cancelToken}) async {
  final override = dsmCorePackagePagePostForTesting;
  if (override != null) return await override(endpoint, data: data);
  return await _httpPost(endpoint, data: data, cancelToken: cancelToken);
}

Map<String, dynamic> _corePackagePageData(dynamic res) {
  if (res is! Map || res['success'] != true) {
    throw DSMException.fromMap(res is Map ? res : const {});
  }
  return res['data'] is Map
      ? Map<String, dynamic>.from(res['data'] as Map)
      : <String, dynamic>{};
}

/// 安装套件（旧 installPackageTask 语义：name/blqinst/volume_path/...）。
Future<Map<String, dynamic>> dsmCorePackageInstallTaskForPage(
    String name, String path,
    {CancelToken? cancelToken}) async {
  return _corePackagePageData(await _dsmCorePackagePagePost(_entryCGI,
      data: {
        "name": name,
        "blqinst": true,
        "volume_path": path,
        "is_syno": true,
        "beta": false,
        "installrunpackage": true,
        "api": "SYNO.Core.Package.Installation",
        "version": 1,
        "method": "install",
        "_sid": connectionStore.sid.value,
      },
      cancelToken: cancelToken));
}

/// 安装进度查询。
Future<Map<String, dynamic>> dsmCorePackageInstallStatusForPage(String taskId,
    {CancelToken? cancelToken}) async {
  return _corePackagePageData(await _dsmCorePackagePagePost(_entryCGI,
      data: {
        "task_id": taskId,
        "api": "SYNO.Core.Package.Installation",
        "version": 1,
        "method": "status",
        "_sid": connectionStore.sid.value,
      },
      cancelToken: cancelToken));
}

/// 更新队列（旧 installPackageQueue 语义：pkgs 为手工拼的 JSON）。
Future<Map<String, dynamic>> dsmCorePackageInstallQueueForPage(String pkg,
    String version,
    {bool beta = false, CancelToken? cancelToken}) async {
  return _corePackagePageData(await _dsmCorePackagePagePost(_entryCGI,
      data: {
        "pkgs": '[{"pkg":"$pkg", "version": "$version","beta":$beta}]',
        "api": "SYNO.Core.Package.Installation",
        "version": 1,
        "method": "get_queue",
        "_sid": connectionStore.sid.value,
      },
      cancelToken: cancelToken));
}

/// 卸载套件（旧 uninstallPackageTask 语义：含双编码 extra_values）。
Future<Map<String, dynamic>> dsmCorePackageUninstallTaskForPage(String id,
    {Map? extra, CancelToken? cancelToken}) async {
  return _corePackagePageData(await _dsmCorePackagePagePost(_entryCGI,
      data: {
        "id": id,
        "api": "SYNO.Core.Package.Uninstallation",
        "version": 1,
        "method": "uninstall",
        "_sid": connectionStore.sid.value,
        "extra_values": jsonEncode(jsonEncode(extra)),
      },
      cancelToken: cancelToken));
}

/// 启动/停用套件（旧 launchPackage 语义：仅 start 带 dsm_apps）。
Future<void> dsmCorePackageControlForPage(String id, String app, String method,
    {CancelToken? cancelToken}) async {
  final data = <String, dynamic>{
    "id": id,
    "api": "SYNO.Core.Package.Control",
    "version": 1,
    "method": method,
    "_sid": connectionStore.sid.value,
  };
  if (method == "start") data["dsm_apps"] = jsonEncode([app]);
  _corePackagePageData(
      await _dsmCorePackagePagePost(_entryCGI,
          data: data, cancelToken: cancelToken));
}
