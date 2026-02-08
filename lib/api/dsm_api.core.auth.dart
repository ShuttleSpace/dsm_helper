part of 'dsm_api.dart';

/// **Notes:**
/// - Use `query=all` to get all available APIs
/// - Returns API paths and supported versions
/// - Useful for discovering available APIs

/// Success Response
/// {
///   "data": {
///     "sid": "AbCdEfGhIjKlMnOpQrStUvWxYz123456" // session id
///     "did": "device_id_1245", // device id
///     "is_portal_port": false, // use portal port
///     "synotoken": "AbCdEfGhIjKlMnOpQrStUvWxYz123456", // CSRF token
///   },
///   "success": true
/// }
///
/// - Sessions expire after 30 minutes of inactivity
/// - Each API call resets the inactivity timer
/// - Maximum session lifetime is typically 24 hours
Future<Map> dsmAuthLogin(
    {String? host, // DSM host address
    String? account, // Username
    String? passwd, // Password
    String? password, // Password (alias for passwd)
    String? otpCode, // 2FA code (if enabled)
    CancelToken? cancelToken,
    bool? rememberDevice, // Remember device
    String? deviceName, // Device name for trusted device
    String? deviceId, // Device ID for trusted device
    String? session =
        "FileStation", // Session name (e.g., `FileStation`, `DownloadStation`, `DSM`)
    String? cookie}) async {
  final data = _dsmApiRequestData(
    api: "SYNO.API.Auth",
    method: "login",
    version: 6,
  )..addAll({
      "account": account,
      "passwd": passwd ?? password,
      "otp_code": otpCode,
      "session": session,
      "enable_device_token": rememberDevice == true ? 'yes' : 'no',
      "format": "sid", // sid or cookie(default)
    });
  if (deviceName != null) {
    data["device_name"] = deviceName;
  }
  if (deviceId != null) {
    data["device_id"] = deviceId;
  }

  final res = await _httpGet(_authCGI,
      queryParameters: data,
      host: host,
      cancelToken: cancelToken,
      cookie: cookie);
  Log.info("login: $res");
  if (res["success"] == true) {
    final sid = res["data"]["sid"];
    connectionStore.setSid(sid);
  } else {
    throw DSMException.fromMap(res);
  }
  return res;
}

Future<Map> dsmAuthLogout({CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
    api: "SYNO.API.Auth",
    method: "logout",
    version: 6,
  )..addAll({
      "sesssion": "FileStation",
    });
  final res =
      await _httpGet(_authCGI, queryParameters: data, cancelToken: cancelToken);
  Log.info("logout: $res");
  if (res["success"] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'];
}

/// {
///     "command": "get_server_info",
///     "env": {
///         "control_host": "cnc.quickconnect.cn",
///         "relay_region": "cn"
///     },
///     "errno": 0,
///     "server": {
///         "ca_fingerprints": [
///             "xxx",
///             "xxxx",
///             "xxxxx"
///         ],
///         "ddns": "NULL",
///         "ds_state": "CONNECTED",
///         "external": {
///             "ip": "00.00.00.000",
///             "ipv6": "::"
///         },
///         "fqdn": "NULL",
///         "gateway": "192.168.00.1",
///         "interface": [
///             {
///                 "ip": "192.168.00.5",
///                 "ipv6": [
///                     {
///                         "addr_type": 0,
///                         "address": /// "xxxx:15b0:xxxx:4246:xxxx:d0ff:xx/// xx:db15",
///                         "prefix_length": 64,
///                         "scope": "global"
///                     },
///                     {
///                         "addr_type": 32,
///                         "address": /// "fe80::xxxx:d0ff:xxxx:db15",
///                         "prefix_length": 64,
///                         "scope": "link"
///                     }
///                 ],
///                 "mask": "255.255.255.0",
///                 "name": "eth0"
///             }
///         ],
///         "ipv6_tunnel": [],
///         "is_bsm": false,
///         "pingpong_path": "",
///         "redirect_prefix": "",
///         "serverID": "0000000",
///         "tcp_punch_port": 0,
///         "udp_punch_port": 45785
///     },
///     "service": {
///         "port": 5000,
///         "ext_port": 0,
///         "pingpong": "UNKNOWN",
///         "pingpong_desc": []
///     },
///     "smartdns": {
///         "host": "xxxx.direct.quickconnect.cn",
///         "lan": [
///             "192-168-00-5.xxxx.direct.quickconnect.cn"
///         ],
///         "lanv6": [
///             "syn6-xxxx.xxxx.direct.quickconnect.cn",
///             "syn6-xxxxxx.xxxx.direct.quickconnect.cn"
///         ],
///         "hole_punch": "127-0-0-1.xxxx.direct./// quickconnect.cn"
///     },
///     "version": 1
/// }
///
/// server, service, env 字段可能不存在，不存在时表示此节点未保存当前 quickconnect ID 的信息，需要通过 sites 字段保存的其他节点列表重新调用此接口查询。
///
/// dsm connect address https://kb.synology.cn/zh-cn/DSM/tutorial/What_websites_does_Synology_NAS_connect_to_when_running_services_or_updating_software
/// https://www.qunhuinas.com/news/jishuziliao/Synology_NAS_DSM_7_x_6_2_x.html
Future<Map> dsmAuthQuickConnectLogin(String quickConnectID,
    {String baseUri = 'quickconnect.to', CancelToken? cancelToken}) async {
  final data = {
    "version": 1,
    "serverID": quickConnectID,
    "command": 'get_server_info',
    "id": "dsm",
    "get_ca_fingerprints": true
  };
  final res = await _httpPost('https://$baseUri/Serv.php',
      data: data,
      cancelToken: cancelToken,
      // FIXME: text/plain???
      headers: {'Content-Type': 'application/json'});
  Log.info("dsmAuthQuickConnectLogin: $res");
  if (res["success"] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'];
}

/// {
///     "command": "request_tunnel",
///     "env": {
///         "control_host": "cnc.quickconnect.cn",
///         "relay_region": "xxx"
///     },
///     "errno": 0,
///     "server": {
///         "ddns": "NULL",
///         "ds_state": "CONNECTED",
///         "external": {
///             "ip": "00.00.00.000",
///             "ipv6": "::"
///         },
///         "fqdn": "NULL",
///         "gateway": "192.168.00.5",
///         "interface": [
///             {
///                 "ip": "192.168.00.00",
///                 "ipv6": [
///                     {
///                         "addr_type": 0,
///                         "address": "xxxx:xxxx:xxxx:xxxx:xxxx:xxxx:xxxx:db15",
///                         "prefix_length": 64,
///                         "scope": "global"
///                     },
///                     {
///                         "addr_type": 32,
///                         "address": "fe80::xxxx:xxxx:xxxx:db15",
///                         "prefix_length": 64,
///                         "scope": "link"
///                     }
///                 ],
///                 "mask": "255.255.255.0",
///                 "name": "eth0"
///             }
///         ],
///         "ipv6_tunnel": [],
///         "is_bsm": false,
///         "pingpong_path": "",
///         "redirect_prefix": "",
///         "serverID": "0000",
///         "tcp_punch_port": 0,
///         "udp_punch_port": 45785
///     },
///     "service": {
///         "port": 5000,
///         "ext_port": 0,
///         "pingpong": "UNKNOWN",
///         "pingpong_desc": [],
///         "relay_ip": "xx.xx.xxx.xx",
///         "relay_dn": "synr-xxx.xxxx.direct.quickconnect.cn",
///         "relay_port": 39833,
///         "vpn_ip": "xxx.xxx.xxx.xxx",
///         "https_ip": "xxx.xxx.xxx.xxx",
///         "https_port": 443
///     },
///     "smartdns": {
///         "host": "xxxx.direct.quickconnect.cn",
///         "lan": [
///             "192-168-00-00.xxxx.direct.quickconnect.cn"
///         ],
///         "lanv6": [
///             "syn6-xxxx.xx.direct.quickconnect.cn",
///             "syn6-xxxx.xx.direct.quickconnect.cn"
///         ],
///         "hole_punch": "127-0-0-1.xxxx.direct.quickconnect.cn"
///     },
///     "version": 1
/// }
/// optional method
Future<Map> dsmAuthControlHostRequestTunnel(
    String quickConnectID,
    String
        controlHost, // get from dsmAuthQuickConnectLogin response's env.control_host. if dsmAuthQuickConnectLogin response's service.relay_ip is empty, then use this open tunnel
    {CancelToken? cancelToken}) async {
  final data = {
    "version": 1,
    "serverID": quickConnectID,
    "command": 'request_tunnel',
    "id": "dsm",
    "get_ca_fingerprints": true,
    "platform": kIsWasm || kIsWeb
        ? 'Web'
        : Platform.isAndroid
            ? 'Android'
            : Platform.isIOS
                ? 'iOS'
                : Platform.isMacOS
                    ? "MacOSX"
                    : Platform.isWindows
                        ? "Windows"
                        : Platform.isLinux
                            ? "Linux"
                            : "Unknown",
  };
  final res = await _httpPost('https://$controlHost/Serv.php',
      data: data,
      headers: {'Content-Type': 'application/json'},
      cancelToken: cancelToken);
  Log.info("dsmAuthQuickConnectLogin: $res");
  if (res["success"] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'];
}

/// 通过以上两步可以获取到包括内网地址，外网地址以及代理地址，通过此接口是否超时判断地址是否可用，程序中按自定义的优先级使用即可。
Future<void> dsmPingpong({String? host, CancelToken? cancelToken}) async {
  await _httpGet('webman/pingpong.cgi',
      queryParameters: {'quickconnect': true},
      cancelToken: cancelToken,
      host: host);
}

Future<List<DsmApiInfo>> dsmInfoQuery({CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
    api: "SYNO.API.Info",
    method: "query",
    version: 1,
  )..addAll({
      "query": "all", // API names (comma-separated or all)
    });
  final res =
      await _httpGet(_authCGI, queryParameters: data, cancelToken: cancelToken);
  Log.info("query: $res");
  if (res["success"] != true) {
    throw DSMException.fromMap(res);
  }
  return (res["data"] as Map)
      .entries
      .map((e) => DsmApiInfo.fromJson(e.key, e.value))
      .toList();
}

/// {
///   "success": true,
///   "data": {
///     "SynoToken": "SYNOTOKEN_STRING",
///     "isAdmin": true,
///     "user": "admin"
///   }
/// }
Future<Map> dsmDesktopSessionDataGetjs({CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
    api: "SYNO.Core.Desktop.SessionData",
    method: "getjs",
    version: 1,
  );
  final res =
      await _httpGet(_authCGI, queryParameters: data, cancelToken: cancelToken);
  Log.info("getjs: $res");
  if (res["success"] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'];
}
