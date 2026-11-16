part of 'dsm_api.dart';

Future<List<DsmApiInfo>> dsmInfoQuery({CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
    api: "SYNO.API.Info",
    method: "query",
    version: 1,
  )..addAll({
      "query": "all", // API names (comma-separated or all)
    });
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
//Log.info("query: $res");
  if (res["success"] != true) {
    throw DSMException.fromMap(res);
  }
  return (res["data"] as Map)
      .entries
      .map((e) => DsmApiInfo.fromJson(e.key, e.value))
      .toList();
}

/// ## Notes
///
/// - All DSM Core APIs require authentication except login
/// - Session IDs expire after inactivity (default: 15 minutes)
/// - Use appropriate session names for different applications
/// - 2FA codes are required if enabled on the account

/// {
///   "success": true,
///   "data": {
///     "codepage": "enu",
///     "model": "DS920+",
///     "ram_size": 4096,
///     "serial": "20C0SQN123456",
///     "temperature": 42,
///     "temperature_warn": false,
///     "time": "Thu Nov 28 01:30:00 2024",
///     "time_zone": "America/New_York",
///     "time_zone_desc": "EST",
///     "up_time": 86400,
///     "usb_dev": [],
///     "version": "7.2-64570",
///     "version_string": "DSM 7.2-64570"
///   }
/// }
Future<Map> dsmCoreSystemInfo(
    {String? type, // Info type (`storage`, `network`, `service`)
    CancelToken? cancelToken}) async {
  final data =
      _dsmApiRequestData(api: 'SYNO.Core.System', method: 'info', version: 3);
  if (type != null) {
    data['type'] = type;
  }
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
//Log.info("dsmCoreSystemInfo: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

/// {
///   "success": true,
///   "data": {
///     "cpu": {
///       "other_load": 5,
///       "system_load": 10,
///       "user_load": 15
///     },
///     "memory": {
///       "real_usage": 2048,
///       "si_disk": 0,
///       "so_disk": 0,
///       "swap_usage": 0
///     },
///     "disk": {
///       "disk": [
///         {
///           "device": "sda",
///           "display_name": "Drive 1",
///           "read_access": 100,
///           "type": "internal",
///           "utilization": 50,
///           "write_access": 50
///         }
///       ]
///     },
///     "network": [
///       {
///         "device": "eth0",
///         "rx": 1048576,
///         "tx": 524288
///       }
///     ]
///   }
/// }
Future<Map> dsmCoreSystemUtilization(
    List<String> resource, // Resource type (`cpu`, `memory`, `disk`, `network`)
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.Core.System.Utilization', method: 'get', version: 1)
    ..addAll({"resource": jsonEncode(resource)});
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
  // Log.info("dsmCoreSystemUtilization: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

/// {
///   "success": true,
///   "data": {
///     "cpu_temperature": 42,
///     "disk_temperature": [38, 40, 39, 41],
///     "fan_status": "normal",
///     "power_status": "normal",
///     "system_status": "normal",
///     "temperature_warning": false
///   }
/// }
/// {"data":{"hostname":"HumphreyBay","interfaces":[{"id":"ovs_eth0","ip":"192.168.8.40","type":"ovseth"},{"id":"ovs_eth1","ip":"169.254.112.21","type":"ovseth"}],"rule":{"description":{"description_format":"{0}","description_params":["widget:system_ok"],"description_use_formatted":false},"id":"system_health","priority":40,"type":2},"uptime":"107:56:50"},"success":true}
Future<Map> dsmCoreSystemHealth({CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.Core.System.SystemHealth', method: 'get', version: 1);
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
//Log.info("dsmCoreSystemHealth: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

/// {
///   "success": true,
///   "data": {
///     "enable": true,
///     "workgroup": "WORKGROUP",
///     "wins_server": "",
///     "local_master": true
///   }
/// }
Future<Map> dsmCoreFileServSMB({CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.Core.FileServ.SMB', method: 'get', version: 1);
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
//Log.info("dsmCoreFileServSMB: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

/// {
///   "success": true,
///   "data": {
///     "enable": true,
///     "enable_bonjour": true
///   }
/// }
Future<Map> dsmCoreFileServAFP({CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.Core.FileServ.AFP', method: 'get', version: 1);
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
//Log.info("dsmCoreFileServAFP: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

/// {
///   "success": true,
///   "data": {
///     "enable": true,
///     "enable_nfsv4": true
///   }
/// }
Future<Map> dsmCoreFileServNFS({CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.Core.FileServ.NFS', method: 'get', version: 1);
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
//Log.info("dsmCoreFileServNFS: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

Future<String> pingpong(String host, {CancelToken? cancelToken}) async {
  final res = await _httpGet("$host/webman/pingpong.cgi");
//Log.info("pingpong: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return host;
}

/// action = "external_ip"
/// {"data":{"ddns_hostname":"dang8080.myDS.me","external_ip":"112.96.231.219"},"success":true}
///
Future<Map> dsmCoreDesktopInitdata(
    {String? action, // get_module_string
    String? jsconfig, // json string
    // {"texts":"texts","jsBaseURL":"webman/3rdparty/CloudSync"}
    // {"texts":"texts","jsBaseURL":"webman/3rdparty/SynologyDrive"}
    // {"texts":"texts","jsBaseURL":"webman/3rdparty/SynologyDrive-ShareSync"}
    String? launchApp,
    CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.Core.Desktop.Initdata', method: 'get', version: 1);
  if (action != null && action.isNotEmpty) {
    data['action'] = action;
  }
  if (launchApp != null && launchApp.isNotEmpty) {
    data['launch_app'] = launchApp;
  }
  if (action != null &&
      action == "get_module_string" &&
      jsconfig != null &&
      jsconfig.isNotEmpty) {
    data['jsconfig'] = jsconfig;
  }

  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
  // Log.info("dsmCoreDesktopInitdata: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res, module: 'Core.Desktop');
  }
  return res['data'] ?? {};
}

Future<Map> dsmCoreDesktopInitdataGetUserService(
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.Core.Desktop.Initdata', method: 'get_user_service', version: 1)
    ..addAll({'launch_app': 'null'});
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
  // Log.info("dsmCoreDesktopInitdata: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res, module: 'Core.Desktop');
  }
  return res['data'] ?? {};
}

Future<Map> dsmCoreDesktopInitdataGetUiConfig(
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.Core.Desktop.Initdata', method: 'get_ui_config', version: 1)
    ..addAll({
      'launch_app': null,
      'lang': '"chs"',
      'debug': null,
    });
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
  // Log.info("dsmCoreDesktopInitdata: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res, module: 'Core.Desktop');
  }
  return res['data'] ?? {};
}

// {"data":{"need_update":false},"success":true}
Future<Map> dsmCoreDesktopPersonalUpdater({CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.Core.Desktop.PersonalUpdater',
      method: 'need_update',
      version: 1);
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
//Log.info("dsmCoreDesktopPersonalUpdater: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res, module: 'Core.Desktop');
  }
  return res['data'] ?? {};
}

Future<Map> dsmCoreMediaIndexingMediaConverter(
    String method, // start, stop, status, pause, resume
    {int? delayHours,
    CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.Core.MediaIndexing.MediaConverter', method: method, version: 1)
    ..addAll({'delay_hours': delayHours ?? ''});
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
//Log.info("dsmCoreMediaIndexingMediaConverter: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res, module: 'Core.Media.Indexing');
  }
  return res['data'] ?? {};
}

Future<Map> dsmCoreDSMNotifyStringsGet(
    {String? lang, String? pkgname, CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.Core.DSMNotify.Strings', method: 'get', version: 1);
  if (lang != null && lang.isNotEmpty) {
    data['lang'] = '"$lang"';
  }
  if (pkgname != null && pkgname.isNotEmpty) {
    data['pkgname'] = '"$pkgname"';
  }
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
//Log.info("dsmCoreDSMNotifyStringsGet: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res, module: 'Core.DSM.Notify');
  }
  return res['data'] ?? {};
}

Future<Map> dsmCoreDSMNotify(String action, // apply, load
    {String? lang,
    String? pkgname,
    bool? cleanAll,
    CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.Core.DSMNotify', method: 'notify', version: 1);
  if (action == 'load') {
    data.addAll({
      'lastRead': DateTime.now().secondsSinceEpoch,
      'lastSeen': DateTime.now().secondsSinceEpoch,
      'action': 'load'
    });
  } else if (action == 'apply') {
    data['action'] = 'apply';
    if (cleanAll != null && cleanAll) {
      data['clean'] = 'all';
    }
  }
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
//Log.info("dsmCoreDSMNotify: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res, module: 'Core.DSM.Notify');
  }
  return res['data'] ?? {};
}

Future<Map> dsmCoreCurrentConnectionList(
    {String? sortBy = 'time',
    String? sortDirection = 'DESC',
    CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.Core.CurrentConnection', method: 'list', version: 1);
  if (sortBy != null && sortBy.isNotEmpty) {
    data['sort_by'] = sortBy;
  }
  if (sortDirection != null && sortDirection.isNotEmpty) {
    data['sort_direction'] = sortDirection;
  }
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  // Log.info("dsmCoreCurrentConnectionList: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

Map<String, dynamic> dsmCoreCurrentConnectionGetRequestData(
  String action, // enum
  {int? offset,
  int? limit,
  int? start, // FIXME:???
  String? sortBy = 'time',
  String? sortDirection = 'DESC',
}) {
  final data = _dsmApiRequestData(
      api: 'SYNO.Core.CurrentConnection', method: 'get', version: 1);
  data['action'] = action;
  if (sortBy != null && sortBy.isNotEmpty) {
    data['sort_by'] = sortBy;
  }
  if (sortDirection != null && sortDirection.isNotEmpty) {
    data['sort_direction'] = sortDirection;
  }
  if (limit != null) {
    data['limit'] = limit;
  }
  if (offset != null) {
    data['offset'] = offset;
  }
  if (start != null) {
    data['start'] = start;
  }
  return data;
}

Future<Map> dsmCoreCurrentConnectionGet(String action, // enum
    {int? offset,
    int? limit,
    int? start, // FIXME:???
    String? sortBy = 'time',
    String? sortDirection = 'DESC',
    CancelToken? cancelToken}) async {
  final data = dsmCoreCurrentConnectionGetRequestData(
    action,
    offset: offset,
    limit: limit,
    start: start,
    sortBy: sortBy,
    sortDirection: sortDirection,
  );
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
//Log.info("dsmCoreCurrentConnectionGet: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

Future<Map> dsmCoreCurrentConnectionKickConnection(Map connection,
    {String? serviceConn, // JSON Array
    CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.Core.CurrentConnection',
      method: 'kick_connection',
      version: 1);
  data['http_conn'] = jsonEncode(connection);
  if (serviceConn != null && serviceConn.isNotEmpty) {
    data['service_conn'] = serviceConn;
  }
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
//Log.info("dsmCoreCurrentConnectionKickConnection: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

Future<Map> dsmCoreSystemProcess({CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.Core.System.Process', method: 'list', version: 1);
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
//Log.info("dsmCoreSystemProcess: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

Future<Map> dsmCoreSystemProcessGroup({CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.Core.System.ProcessGroup',
      method: connectionStore.dsmVersion.value >= 7 ? 'list' : 'service_info',
      version: 1);
  if (connectionStore.dsmVersion.value == 7) {
    data['node'] = 'xnode-2572';
  }
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
//Log.info("dsmCoreSystemProcessGroup: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

Future<Map> dsmSDSWidgetModuleListDetail(List widgets,
    {CancelToken? cancelToken}) async {
  final apis = [];
  if (widgets.contains("SYNO.SDS.ResourceMonitor.Widget")) {
    apis.add({
      "api": "SYNO.Core.System.Utilization",
      "method": "get",
      "version": 1,
      "type": "current",
      "resource": ["cpu", "memory", "network", "disk"]
    });
  }
  if (widgets.contains("SYNO.SDS.SystemInfoApp.StorageUsageWidget")) {
    apis.add({
      "api": "SYNO.Storage.CGI.Storage",
      "method": "load_info",
      "version": 1,
    });
  }
  if (widgets.contains("SYNO.SDS.SystemInfoApp.ConnectionLogWidget")) {
    apis.add({
      "api": "SYNO.Core.CurrentConnection",
      "method": "list",
      "sort_direction": "DESC",
      "sort_by": "time",
      "version": 1,
    });
  }
  if (widgets.contains("SYNO.SDS.TaskScheduler.TaskSchedulerWidget")) {
    apis.add({
      "api": "SYNO.Core.TaskScheduler",
      "sort_by": "next_trigger_time",
      "sort_direction": "ASC",
      "start": 0,
      "limit": 50,
      "method": "list",
      "version": 1,
    });
  }
  if (widgets.contains("SYNO.SDS.SystemInfoApp.RecentLogWidget")) {
    apis.add({
      "api": "SYNO.Core.SyslogClient.Status",
      "start": 0,
      "limit": 50,
      "widget": true,
      "dir": '"desc"',
      "method": "latestlog_get",
      "version": 1,
    });
    if (widgets.contains("SYNO.SDS.SystemInfoApp.FileChangeLogWidget")) {
      apis.add({
        "start": 0,
        "limit": 50,
        "target": "LOCAL",
        "logtype": "ftp,filestation,webdav,cifs,tftp,afp",
        "dir": "desc",
        "api": "SYNO.Core.SyslogClient.Log",
        "method": "list",
        "version": 1,
      });
    }
  }
  apis.add({
    "api": "SYNO.Core.System",
    "method": "info",
    "version": 1,
  });
  apis.add({
    "action": "load",
    "lastRead": DateTime.now().secondsSinceEpoch,
    "lastSeen": DateTime.now().secondsSinceEpoch,
    "api": "SYNO.Core.DSMNotify",
    "method": "notify",
    "version": 1,
  });
  apis.add({
    "api": "SYNO.Core.AppNotify",
    "method": "get",
    "version": 1,
  });
  final res = await _dsmApiCall(jsonEncode(apis),
      mod: '"parallel"', cancelToken: cancelToken);
  // Log.info("dsmSDSWidgetModuleListDetail: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

/// {"data":{"admin_configured":true,"ew20_website_url":"https://account.synology.com/","first_admin_login":true,"privacy_agreement":"skip","promote_ew":false,"udc_check_state":"","udc_enabled":"no","welcome_hide":true,"welcome_upgrade_step":false},"success":true}
Future<Map> dsmCoreQuickStartInfo(String method, // load_ds_info
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
    api: 'SYNO.Core.QuickStart.Info',
    method: method,
    version: 3,
  );
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
//Log.info("dsmCoreQuickStartInfo: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

/// response 见 mock/dsm/api=SYNO.Core.BackgroundTask&method=get&query=all.curl
Future<Map> dsmCoreBackgroundTask(
    {String? method, CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.Core.BackgroundTask', method: method ?? 'get', version: 1);
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
//Log.info("dsmCoreBackgroundTask: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

/// {"success":true}
Future<bool> dsmCoreDesktopTimeoutCheck({CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.Core.Desktop.Timeout', method: 'Check', version: 1);
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
//Log.info("dsmCoreDesktopTimeoutCheck: $res");
  return res['success'] == true;
}

/// {"data":{"never_show":"yes"},"success":true}
Future<Map> dsmCorePromotionPreInstall(String method, // get_never_show
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.Core.Promotion.PreInstall', method: method, version: 1);
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
//Log.info("dsmCorePromotionPreInstall: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

/// {"data":{"background_color":"#FFFFFF","background_position":"fill","background_seq":2,"enable_background_customize":true,"enable_logo_customize":false,"from_dsm":true,"login_footer_enable_html":false,"login_footer_msg":"","login_title":"HumphreyIO","login_version_logo":false,"login_welcome_msg":"My Hero!","login_welcome_title":"Welcome Home","logo_position":"center","logo_seq":0,"only_background_color":false,"weather_info":"display"},"success":true}
/// SYNO.SDS.AudioStation.Application, SYNO.Cal.Application ...
Future<Map> dsmCoreThemeAppPortalLogin(String app,
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.Core.Theme.AppPortalLogin', method: 'get', version: 1);
  data['app'] = '"$app"';
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
//Log.info("dsmCoreThemeAppPortalLogin: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

Future<Map> dsmCoreThemeAppPortalLoginBatch(List<String> apps,
    {CancelToken? cancelToken}) async {
  final compound = apps.map((e) => {
        'api': 'SYNO.Core.Theme.AppPortalLogin',
        'method': 'get',
        'version': 1,
        'app': '"$e"',
      });
  final res = await _dsmApiCall(jsonEncode(compound), cancelToken: cancelToken);
//Log.info("dsmCoreThemeAppPortalLoginBatch: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}
