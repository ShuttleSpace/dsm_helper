part of 'dsm_api.dart';

/// {
///   "success": true,
///   "data": {
///     "pptp_enabled": true,
///     "openvpn_enabled": true,
///     "l2tp_enabled": false,
///     "pptp_port": 1723,
///     "openvpn_port": 1194
///   }
/// }
Future<Map> dsmVPNCenterServerStatusLoad({CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.VPNCenter.Server.Status', method: 'status_load', version: 1);
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
//Log.info("dsmVPNCenterServerStatusLoad: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

/// {
///   "success": true,
///   "data": {
///     "connections": [
///       {
///         "id": "conn_123",
///         "username": "john",
///         "protocol": "openvpn",
///         "ip_address": "10.8.0.2",
///         "login_time": 1732752000,
///         "bytes_sent": 1048576,
///         "bytes_received": 2097152
///       }
///     ],
///     "total": 1
///   }
/// }
Future<Map> dsmVPNCenterServerConnectionEnum(
    {String? sort, // Sort field (default: `login_time`)
    String? dir, // Sort direction (`ASC`, `DESC`, default: `DESC`)
    int? start,
    int? limit,
    CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.VPNCenter.Server.Connection', method: 'enum', version: 1);
  if (sort != null && sort.isNotEmpty) data['sort'] = sort;
  if (dir != null && dir.isNotEmpty) data['dir'] = dir;
  if (start != null) data['start'] = start;
  if (limit != null) data['limit'] = limit;
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
//Log.info("dsmVPNCenterServerConnectionEnum: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

/// {
///   "success": true,
///   "data": {
///     "logs": [
///       {
///         "time": 1732752000,
///         "user": "john",
///         "protocol": "openvpn",
///         "event": "connected",
///         "ip_address": "192.168.1.100"
///       }
///     ],
///     "total": 1
///   }
/// }
///
/// **Response Fields:**
///
/// | Field | Type | Description |
/// |-------|------|-------------|
/// | `time` | integer | Event timestamp (Unix time) |
/// | `user` | string | Username |
/// | `protocol` | string | VPN protocol (pptp, openvpn, l2tp) |
/// | `event` | string | Event type (connected, disconnected, failed) |
/// | `ip_address` | string | Client IP address |
///
/// **Notes:**
/// - Logs are sorted by time (newest first)
/// - Protocol type filter: 0=all, 1=PPTP, 2=OpenVPN, 3=L2TP
///
/// ---
Future<Map> dsmVPNCenterServerLogLoad(
    {int? start,
    int? limit,
    int?
        prtltype, // Protocol type (0=all, 1=PPTP, 2=OpenVPN, 3=L2TP, default: 0)
    CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.VPNCenter.Server.Log', method: 'load', version: 1);
  if (start != null) data['start'] = start;
  if (limit != null) data['limit'] = limit;
  if (prtltype != null) data['prtltype'] = prtltype;
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
//Log.info("dsmVPNCenterServerLogLoad: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

/// {
///   "success": true,
///   "data": {
///     "interfaces": [
///       {
///         "name": "tun0",
///         "type": "openvpn",
///         "ip_address": "10.8.0.1",
///         "netmask": "255.255.255.0",
///         "status": "up"
///       }
///     ]
///   }
/// }
Future<Map> dsmVPNCenterServerNetworkInterfaceLoad(
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.VPNCenter.Server.NetworkInterface',
      method: 'load',
      version: 1);
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
//Log.info("dsmVPNCenterServerNetworkInterfaceLoad: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

/// {
///   "success": true,
///   "data": {
///     "enabled": true,
///     "login_attempt": 5,
///     "expire_min": 30,
///     "block_expire_min": 1440
///   }
/// }
///
/// **Response Fields:**
///
/// | Field | Type | Description |
/// |-------|------|-------------|
/// | `enabled` | boolean | Auto-block enabled |
/// | `login_attempt` | integer | Failed login attempts before block |
/// | `expire_min` | integer | Minutes to track failed attempts |
/// | `block_expire_min` | integer | Minutes to block IP address |
///
/// ---
Future<Map> dsmCoreSecurityAutoBlockGet({CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.Core.SecurityAutoBlock', method: 'get', version: 1);
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
//Log.info("dsmCoreSecurityAutoBlockGet: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

/// {
///   "success": true,
///   "data": {
///     "privileges": [
///       {
///         "name": "john",
///         "type": "user",
///         "pptp": true,
///         "openvpn": true,
///         "l2tp": false
///       },
///       {
///         "name": "vpn_users",
///         "type": "group",
///         "pptp": true,
///         "openvpn": true,
///         "l2tp": true
///       }
///     ],
///     "total": 2
///   }
/// }
///
/// **Response Fields:**
///
/// | Field | Type | Description |
/// |-------|------|-------------|
/// | `name` | string | User or group name |
/// | `type` | string | Type (`user`, `group`) |
/// | `pptp` | boolean | PPTP access allowed |
/// | `openvpn` | boolean | OpenVPN access allowed |
/// | `l2tp` | boolean | L2TP access allowed |
///
/// **Notes:**
/// - Permissions can be set per user or group
/// - At least one protocol must be enabled for access
///
/// ---
Future<Map> dsmVPNCenterServerPrivilegeLoad(String action, // enum
    {int? start,
    int? limit,
    CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.VPNCenter.Server.Privilege', method: 'load', version: 1);
  data['action'] = action;
  if (start != null) data['start'] = start;
  if (limit != null) data['limit'] = limit;
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
//Log.info("dsmVPNCenterServerPrivilegeLoad: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

/// {
///   "success": true,
///   "data": {
///     "enabled": true,
///     "port": 1723,
///     "max_connections": 10,
///     "authentication": "mschap_v2",
///     "encryption": "mppe_128"
///   }
/// }
Future<Map> dsmVPNCenterServerPPTPLoad({CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.VPNCenter.Server.PPTP', method: 'load', version: 1);
  data['serv_type'] = 'pptp';
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
//Log.info("dsmVPNCenterServerPPTPLoad: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

/// {
///   "success": true,
///   "data": {
///     "enabled": true,
///     "port": 1194,
///     "protocol": "udp",
///     "max_connections": 20,
///     "compression": true,
///     "cipher": "AES-256-CBC"
///   }
/// }
Future<Map> dsmVPNCenterServerOpenVPNLoad({CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.VPNCenter.Server.OpenVPN', method: 'load', version: 1);
  data['serv_type'] = 'openvpn';
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
//Log.info("dsmVPNCenterServerOpenVPNLoad: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

/// Binary ZIP file containing OpenVPN configuration files
///
/// **Notes:**
/// - Response is a ZIP file, not JSON
/// - Contains `.ovpn` configuration file and certificates
/// - Can be imported directly into OpenVPN clients
///
/// ---
Future<dynamic> dsmVPNCenterServerOpenVPNExportConfig(
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.VPNCenter.Server.OpenVPN',
      method: 'export_config',
      version: 1);
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
//Log.info("dsmVPNCenterServerOpenVPNExportConfig: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

/// {
///   "success": true,
///   "data": {
///     "enabled": false,
///     "port": 1701,
///     "max_connections": 10,
///     "authentication": "mschap_v2",
///     "ipsec_psk": "shared_secret_key"
///   }
/// }
///
/// **Response Fields:**
///
/// | Field | Type | Description |
/// |-------|------|-------------|
/// | `enabled` | boolean | Protocol enabled |
/// | `port` | integer | Listening port |
/// | `max_connections` | integer | Maximum concurrent connections |
/// | `authentication` | string | Authentication method |
/// | `ipsec_psk` | string | IPsec pre-shared key (L2TP only) |
/// | `protocol` | string | Transport protocol (OpenVPN only) |
/// | `cipher` | string | Encryption cipher (OpenVPN only) |
///
/// **Notes:**
/// - PPTP is considered insecure, use OpenVPN or L2TP instead
/// - L2TP requires IPsec for encryption
/// - OpenVPN supports both TCP and UDP protocols
///
/// ---
Future<Map> dsmVPNCenterServerL2TPLoad({CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.VPNCenter.Server.L2TP', method: 'load', version: 1);
  data['serv_type'] = 'l2tp';
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
//Log.info("dsmVPNCenterServerL2TPLoad: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}
