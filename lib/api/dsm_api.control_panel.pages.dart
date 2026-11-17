part of 'dsm_api.dart';

/// 控制面板页面级通用请求桥：保留旧层 POST/GET + 原始 body/query 的语义，
/// 页面只需替换 `DsmApi.xxx()` 调用，不依赖 compat 信封。
@visibleForTesting
Future<dynamic> Function(String endpoint,
    {Map<String, dynamic>? data, Map<String, dynamic>? queryParameters})?
    dsmControlPanelRequestForTesting;

Future<dynamic> _dsmCpRequest(String endpoint,
    {Map<String, dynamic>? data,
    Map<String, dynamic>? queryParameters,
    bool get = false,
    CancelToken? cancelToken}) async {
  final override = dsmControlPanelRequestForTesting;
  if (override != null) {
    return await override(endpoint,
        data: data, queryParameters: queryParameters);
  }
  return get
      ? await _httpGet(endpoint,
          queryParameters: queryParameters, cancelToken: cancelToken)
      : await _httpPost(endpoint, data: data, cancelToken: cancelToken);
}

/// 成功返回 `data` 字段（自动补 `_sid`），失败抛 [DSMException]。
Future<Map<String, dynamic>> dsmControlPanelPost(Map<String, dynamic> body,
    {CancelToken? cancelToken}) async {
  final data = <String, dynamic>{'_sid': connectionStore.sid.value}..addAll(body);
  final res = await _dsmCpRequest(_entryCGI,
      data: data, cancelToken: cancelToken);
  if (res is! Map || res['success'] != true) {
    throw DSMException.fromMap(res is Map ? res : const {});
  }
  return res['data'] is Map
      ? Map<String, dynamic>.from(res['data'] as Map)
      : <String, dynamic>{};
}

/// GET 变体（少量旧接口用 GET，如 mediaIndexStatus）。
Future<Map<String, dynamic>> dsmControlPanelGet(Map<String, dynamic> query,
    {CancelToken? cancelToken}) async {
  final data = <String, dynamic>{'_sid': connectionStore.sid.value}..addAll(query);
  final res = await _dsmCpRequest(_entryCGI,
      queryParameters: data, get: true, cancelToken: cancelToken);
  if (res is! Map || res['success'] != true) {
    throw DSMException.fromMap(res is Map ? res : const {});
  }
  return res['data'] is Map
      ? Map<String, dynamic>.from(res['data'] as Map)
      : <String, dynamic>{};
}

// 从旧方法逐字迁移的页面级请求（body 未改动，仅换成新层 HTTP 与异常）。
Map<String, dynamic> _cpPageData(dynamic res) {
  if (res is! Map || res['success'] != true) {
    throw DSMException.fromMap(res is Map ? res : const {});
  }
  return res['data'] is Map
      ? Map<String, dynamic>.from(res['data'] as Map)
      : <String, dynamic>{};
}

Future<Map<String, dynamic>> dsmCoreTerminalInfoForPage() async {
    var data = {
      "api": "SYNO.Core.Terminal",
      "version": 3,
      "method": "get",
      "_sid": connectionStore.sid.value,
    };
    return _cpPageData(await _dsmCpRequest(_entryCGI, data: data));
}

Future<Map<String, dynamic>> dsmCoreTerminalSetForPage(bool ssh, bool telnet, String sshPort) async {
    var data = {
      "api": '"SYNO.Core.Terminal"',
      "enable_telnet": telnet,
      "enable_ssh": ssh,
      "ssh_port": sshPort,
      "version": 3,
      "method": "set",
      "_sid": connectionStore.sid.value,
    };
    Log.info(data);
    return _cpPageData(await _dsmCpRequest(_entryCGI, data: data));
}

Future<Map<String, dynamic>> dsmCoreSystemPowerForPage(String method, bool force) async {
    var data = {
      "api": '"SYNO.Core.System"',
      "force": force,
      "local": true,
      "version": 1,
      "method": method,
      "_sid": connectionStore.sid.value,
    };
    return _cpPageData(await _dsmCpRequest(_entryCGI, data: data));
}

Future<Map<String, dynamic>> dsmCoreUserGroupsForPage() async {
    var data = {
      "api": "SYNO.Core.Group",
      "offset": 0,
      "limit": -1,
      "name_only": false,
      "version": 1,
      "method": "list",
      "_sid": connectionStore.sid.value,
    };
    return _cpPageData(await _dsmCpRequest(_entryCGI, data: data));
}

Future<Map<String, dynamic>> dsmCoreUserSettingsApplyForPage(Map save) async {
    String dataStr = jsonEncode(jsonEncode(save));
    var data = {
      "api": "SYNO.Core.UserSettings",
      "data":
          dataStr, //r'"{\"SYNO.SDS._Widget.Instance\":{\"modulelist\":[\"SYNO.SDS.SystemInfoApp.SystemHealthWidget\",\"SYNO.SDS.SystemInfoApp.ConnectionLogWidget\",\"SYNO.SDS.ResourceMonitor.Widget\"]}}"',
      "method": "apply",
      "version": 1,
      "_sid": connectionStore.sid.value,
    };
    return _cpPageData(await _dsmCpRequest(_entryCGI, data: data));
}

Future<Map<String, dynamic>> dsmCoreUserDetailForPage(String name) async {
    List apis = [
      {
        "api": "SYNO.Core.User",
        "method": "get",
        "version": 1,
        "name": name,
        "additional": [
          "description",
          "email",
          "expired",
          "cannot_chg_passwd",
          "passwd_never_expire"
        ]
      },
      {"api": "SYNO.Core.User.PasswordExpiry", "method": "get", "version": 1},
      {
        "api": "SYNO.Core.Share.Permission",
        "method": "list_by_user",
        "version": 1,
        "name": name,
        "user_group_type": "local_user",
        "share_type": [
          "dec",
          "local",
          "usb",
          "sata",
          "cluster",
          "cold_storage"
        ],
        "additional": ["hidden", "encryption", "is_aclmode"]
      },
      {
        "api": "SYNO.Core.Storage.Volume",
        "method": "list",
        "version": 1,
        "offset": 0,
        "limit": -1,
        "location": "internal"
      },
      {
        "api": "SYNO.Core.BandwidthControl",
        "method": "get",
        "version": 2,
        "name": name,
        "owner_type": "local_user"
      },
      {
        "api": "SYNO.Core.OTP.Admin",
        "method": "get",
        "version": 1,
        "name": name
      },
      {"api": "SYNO.Core.FileServ.SMB", "method": "get", "version": 1},
      {
        "api": "SYNO.Core.Quota",
        "method": "get",
        "version": 1,
        "name": name,
        "support_share_quota": true
      }
    ];
    var result = await _compatPost(_entryCGI, data: {
      "api": 'SYNO.Entry.Request',
      "method": 'request',
      "mode": '"sequential"',
      "compound": jsonEncode(apis),
      "version": 1,
      "_sid": connectionStore.sid.value,
    });
    return result;
}

Future<Map<String, dynamic>> dsmCoreUserSaveForPage(
    Map userInfo,
    List addGroup,
    List removeGroup,
  ) async {
    Map userInfoApi = {
      "api": "SYNO.Core.User",
      "method": "set",
      "version": 1,
      "name": userInfo['name'],
      "description": userInfo['description'],
      "email": userInfo['email'],
      "cannot_chg_passwd": userInfo['cannot_chg_passwd'],
      "expired": userInfo['expired'],
      "new_name": userInfo['new_name'],
    };
    if (userInfo['password'] != null && userInfo['password'].length > 0) {
      userInfoApi['password'] = userInfo['password'];
    }
    List apis = [userInfoApi];

    for (int i = 0; i < addGroup.length; i++) {
      apis.add({
        "api": "SYNO.Core.Group.Member",
        "method": "add",
        "version": 1,
        "group": addGroup[i],
        "name": userInfo['name']
      });
    }
    for (int i = 0; i < removeGroup.length; i++) {
      apis.add({
        "api": "SYNO.Core.Group.Member",
        "method": "remove",
        "version": 1,
        "group": removeGroup[i],
        "name": userInfo['name']
      });
    }
    var result = await _compatPost(_entryCGI, data: {
      "stop_when_error": false,
      "api": 'SYNO.Entry.Request',
      "method": 'request',
      "mode": '"sequential"',
      "compound": jsonEncode(apis),
      "version": 1,
      "_sid": connectionStore.sid.value,
    });
    return result;
}

Future<Map<String, dynamic>> dsmCoreTaskRecordForPage(int task) async {
    var data = {
      "api": "SYNO.Core.TaskScheduler",
      "version": 1,
      "offset": 0,
      "limit": 2,
      "method": "view",
      "id": task,
      "_sid": connectionStore.sid.value,
    };
    return _cpPageData(await _dsmCpRequest(_entryCGI, data: data));
}

Future<Map<String, dynamic>> dsmCoreFirmwareVersionForPage() async {
    var result = await _compatPost(_entryCGI, data: {
      "type": '"firmware"',
      "api": 'SYNO.Core.System',
      "method": 'info',
      "version": 3,
      "_sid": connectionStore.sid.value,
    });
    return result;
}

Future<Map<String, dynamic>> dsmCoreFirmwareUpgradeForPage() async {
    var result = await _compatPost(_entryCGI, data: {
      "api": 'SYNO.Core.Upgrade.Server',
      "method": 'check',
      "version": 2,
      "user_reading": true,
      "need_auto_smallupdate": true,
      "need_promotion": true,
      "_sid": connectionStore.sid.value,
    });
    return result;
}

Future<Map<String, dynamic>> dsmCoreFileServiceForPage() async {
    List apis = [
      {"api": "SYNO.Core.FileServ.SMB", "method": "get", "version": 3},
      {"api": "SYNO.Core.FileServ.AFP", "method": "get", "version": 1},
      {"api": "SYNO.Core.FileServ.NFS", "method": "get", "version": 2},
      {"api": "SYNO.Core.FileServ.FTP", "method": "get", "version": 3},
      {"api": "SYNO.Core.FileServ.FTP.SFTP", "method": "get", "version": 1},
      // {"api": "SYNO.Core.BandwidthControl.Protocol", "method": "get", "version": 1, "protocol": "FTP"},
      // {"api": "SYNO.Core.TFTP", "method": "get", "version": 1},
      // {"api": "SYNO.Backup.Service.NetworkBackup", "method": "get", "version": 1},
      // {"api": "SYNO.Core.BandwidthControl.Protocol", "method": "get", "version": 1, "protocol": "NetworkBackup"},
      // {"api": "SYNO.Core.Directory.Domain", "method": "get", "version": 1},
      // {
      //   "api": "SYNO.Core.Share",
      //   "method": "list",
      //   "version": 1,
      //   "additional": ["is_service_share"],
      //   "shareType": ["dec", "local", "usb", "sata", "cluster"]
      // },
      // {"api": "SYNO.Core.Service", "method": "get", "version": 1, "service_id": "pgsql"},
      {
        "api": "SYNO.Core.SyslogClient.FileTransfer",
        "method": "get",
        "version": 1
      },
      // {"api": "SYNO.Core.Network", "method": "get", "version": 1},
      // {"api": "SYNO.Core.FileServ.ReflinkCopy", "method": "get", "version": 1},
      // {"api": "SYNO.Core.Web.DSM", "method": "get", "version": 2},
      // {"api": "SYNO.Core.ExternalDevice.Printer.BonjourSharing", "method": "get", "version": 1},
      // {"api": "SYNO.Core.FileServ.ServiceDiscovery", "method": "get", "version": 1},
      // {"api": "SYNO.Core.FileServ.ServiceDiscovery.WSTransfer", "method": "get", "version": 1}
    ];
    var result = await _compatPost(_entryCGI, data: {
      "api": 'SYNO.Entry.Request',
      "method": 'request',
      "mode": '"sequential"',
      "compound": jsonEncode(apis),
      "version": 1,
      "_sid": connectionStore.sid.value,
    });
    return result;
}

Future<Map<String, dynamic>> dsmCoreFileServiceLogForPage(String protocol) async {
    var data = {
      "protocol": '"$protocol"',
      "api": "SYNO.Core.SyslogClient.FileTransfer",
      "method": "get_level",
      "version": 1,
    };
    return _cpPageData(await _dsmCpRequest(_entryCGI, data: data));
}

Future<Map<String, dynamic>> dsmCoreFileServiceLogSaveForPage(String protocol, Map logLevel) async {
    var data = {
      "protocol": '"$protocol"',
      "loglevel": json.encode(logLevel),
      "api": "SYNO.Core.SyslogClient.FileTransfer",
      "method": "set_level",
      "version": 1,
    };
    return _cpPageData(await _dsmCpRequest(_entryCGI, data: data));
}

Future<Map<String, dynamic>> dsmCoreFileServiceSaveForPage(
      Map smb, Map syslogClient, Map afp, Map nfs, Map ftp, Map sftp) async {
    List apis = [
      {
        "api": "SYNO.Core.FileServ.SMB",
        "method": "set",
        "version": 3,
        "enable_samba": smb['enable_samba'],
        "workgroup": smb['workgroup'],
        "disable_shadow_copy": smb['disable_shadow_copy'],
        "smb_transfer_log_enable": syslogClient['cifs']
      },
      {
        "api": "SYNO.Core.FileServ.AFP",
        "method": "set",
        "version": 1,
        "enable_afp": afp['enable_afp'],
        "afp_transfer_log_enable": syslogClient['afp']
      },
      {
        "api": "SYNO.Core.FileServ.NFS",
        "method": "set",
        "version": 2,
        "enable_nfs": nfs['enable_nfs'],
        "enable_nfs_v4": nfs['enable_nfs_v4'],
        "enable_nfs_v4_1": nfs['enable_nfs_v4'],
        "nfs_v4_domain": nfs['nfs_v4_domain']
      },
      {
        "api": "SYNO.Core.SyslogClient.FileTransfer",
        "method": "set",
        "version": 1,
        "cifs": syslogClient['cifs'],
        "afp": syslogClient['afp']
      },
      {
        "api": "SYNO.Core.FileServ.FTP",
        "method": "set",
        "version": "3",
        "enable_ftp": ftp['enable_ftp'],
        "enable_ftps": ftp['enable_ftps'],
        "timeout": ftp['timeout'],
        "portnum": ftp['portnum'],
        "custom_port_range": ftp['custom_port_range'],
        "use_ext_ip": ftp['use_ext_ip'],
        "enable_fxp": ftp['enable_fxp'],
        "enable_fips": ftp['enable_fips'],
        "enable_ascii": ftp['enable_ascii'],
        "utf8_mode": ftp['utf8_mode']
      },
      {
        "api": "SYNO.Core.FileServ.FTP.SFTP",
        "method": "set",
        "version": "1",
        "enable": sftp['enable'],
        "sftp_portnum": sftp['portnum'],
        "portnum": sftp['portnum']
      }
    ];
    var result = await _compatPost(_entryCGI, data: {
      "api": 'SYNO.Entry.Request',
      "method": 'request',
      "mode": '"sequential"',
      "compound": jsonEncode(apis),
      "version": 1,
      "_sid": connectionStore.sid.value,
    });
    return result;
}

Future<Map<String, dynamic>> dsmCoreNetworkStatusForPage() async {
    List apis = [
      {
        "api": "SYNO.Core.Network",
        "method": "get",
        "version": 2,
      },
      {"api": "SYNO.Core.Network.Ethernet", "method": "list", "version": 2},
      {"api": "SYNO.Core.Network.PPPoE", "method": "list", "version": 1},
      {"api": "SYNO.Core.Network.Proxy", "method": "get", "version": 1},
      {
        "api": "SYNO.Core.Network.Router.Gateway.List",
        "method": "get",
        "version": 1,
        "iptype": "ipv4",
        "type": "wan"
      },
      {"api": "SYNO.Core.Web.DSM", "method": "get", "version": 2}
    ];
    var result = await _compatPost(_entryCGI, data: {
      "stop_when_error": false,
      "api": 'SYNO.Entry.Request',
      "method": 'request',
      "mode": '"sequential"',
      "compound": jsonEncode(apis),
      "version": 1,
      "_sid": connectionStore.sid.value,
    });
    return result;
}

Future<Map<String, dynamic>> dsmCoreShareDetailForPage(String name) async {
    // [
    //   {"api": "SYNO.Core.Storage.Volume", "method": "list", "version": 1, "limit": -1, "offset": 0, "location": "internal", "option": "include_cold_storage"},
    //   {
    //     "api": "SYNO.Core.Share",
    //     "method": "get",
    //     "version": 1,
    //     "name": "test1",
    //     "additional": ["hidden", "recyclebin", "advance_setting", "encryption", "is_cluster_share", "is_cold_storage_share", "enable_snapshot_browsing", "share_quota", "enable_share_cow", "enable_share_compress"]
    //   }
    // ];
    var data = {
      "api": '"SYNO.Core.Share"',
      "method": '"get"',
      "version": 1,
      "_sid": connectionStore.sid.value,
      "name": '"$name"',
      "additional": jsonEncode([
        "hidden",
        "recyclebin",
        "advance_setting",
        "encryption",
        "is_cluster_share",
        "is_cold_storage_share",
        "enable_snapshot_browsing",
        "share_quota",
        "enable_share_cow",
        "enable_share_compress",
      ]),
    };
    return _cpPageData(await _dsmCpRequest(_entryCGI, data: data));
}

Future<Map<String, dynamic>> dsmCoreShareAddForPage(
    String name,
    String volPath,
    String desc, {
    String? oldName,
    bool encryption = false,
    String password = "",
    bool recycleBin = false,
    bool recycleBinAdminOnly = false,
    bool hidden = false,
    bool hideUnreadable = false,
    bool enableShareCow = false,
    bool enableShareCompress = false,
    bool enableShareQuota = false,
    String shareQuota = "",
    String method = "create",
  }) async {
    //"{"name":"test","vol_path":"/volume3","desc":"test","hidden":true,"enable_recycle_bin":true,"recycle_bin_admin_only":true,"hide_unreadable":true,"enable_share_cow":true,"enable_share_compress":true,"share_quota":1024,"name_org":""}"
    Map shareInfo = {
      "name": name,
      "vol_path": volPath,
      "desc": desc,
      "name_org": "",
      "enable_recycle_bin": recycleBin,
      "recycle_bin_admin_only": recycleBinAdminOnly,
      "encryption": encryption,
      "hidden": hidden,
      "hide_unreadable": hideUnreadable,
      "enable_share_cow": enableShareCow,
      "enable_share_compress": enableShareCow && enableShareCompress,
    };
    if (encryption) {
      shareInfo['enc_passwd'] = password;
    }
    if (enableShareQuota) {
      shareInfo['share_quota'] = num.parse(shareQuota);
    } else {
      shareInfo['share_quota'] = 0;
    }
    //"{"name":"testc","vol_path":"/volume3","desc":"bjxjbddb","enable_share_cow":true,"enable_share_compress":true,"share_quota":1024,"encryption":true,"enc_passwd":""}"
    var data = {
      "api": '"SYNO.Core.Share"',
      "method": '"$method"',
      "version": 1,
      "_sid": connectionStore.sid.value,
      "name": oldName ?? name,
      "shareinfo": jsonEncode(shareInfo),
    };
    return _cpPageData(await _dsmCpRequest(_entryCGI, data: data));
}

/// 用户所属组列表（旧 userGroup 语义）。
Future<Map<String, dynamic>> dsmCoreUserGroupsForUserForPage(String name) async {
  final res = await _dsmCpRequest(_entryCGI,
      data: {
        "name_only": false,
        "user": '"$name"',
        "type": '"local"',
        "api": 'SYNO.Core.Group',
        "method": 'list',
        "version": 1,
        "_sid": connectionStore.sid.value,
      });
  return _cpPageData(res);
}
