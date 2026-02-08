part of 'dsm_api.dart';

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
  Log.info("dsmCoreSystemInfo: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'];
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
    String resource, // Resource type (`cpu`, `memory`, `disk`, `network`)
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.Core.System.Utilization', method: 'get', version: 1)
    ..addAll({"resource": resource});
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
  Log.info("dsmCoreSystemUtilization: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'];
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
Future<Map> dsmCoreSystemHealth({CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.Core.System.SystemHealth', method: 'get', version: 1);
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
  Log.info("dsmCoreSystemHealth: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'];
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
  Log.info("dsmCoreFileServSMB: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'];
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
  Log.info("dsmCoreFileServAFP: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'];
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
  Log.info("dsmCoreFileServNFS: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'];
}

Future<String> pingpong(String host, {CancelToken? cancelToken}) async {
  final res = await _httpGet("$host/webman/pingpong.cgi");
  Log.info("pingpong: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return host;
}
