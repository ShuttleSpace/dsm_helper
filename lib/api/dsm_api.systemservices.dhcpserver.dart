part of 'dsm_api.dart';

/// {
///   "success": true,
///   "data": {
///     "enabled": true,
///     "interface": "ovs_eth0",
///     "start_ip": "192.168.1.100",
///     "end_ip": "192.168.1.200",
///     "netmask": "255.255.255.0",
///     "gateway": "192.168.1.1",
///     "dns_server": "192.168.1.1",
///     "lease_time": 86400
///   }
/// }
///
/// **Response Fields:**
///
/// | Field | Type | Description |
/// |-------|------|-------------|
/// | `enabled` | boolean | DHCP server enabled |
/// | `interface` | string | Network interface |
/// | `start_ip` | string | DHCP range start IP |
/// | `end_ip` | string | DHCP range end IP |
/// | `netmask` | string | Subnet mask |
/// | `gateway` | string | Default gateway |
/// | `dns_server` | string | DNS server |
/// | `lease_time` | integer | Lease time (seconds) |
///
/// ---
Future<Map> dsmCoreNetworkDHCPServerGet(
    {String? ifname, // Interface name (default: `ovs_eth0`)
    CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.Core.Network.DHCPServer', method: 'Get', version: 1);
  if (ifname != null && ifname.isNotEmpty) data['ifname'] = ifname;
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
//Log.info("dsmCoreNetworkDHCPServerGet: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

/// {
///   "success": true,
///   "data": {
///     "clients": [
///       {
///         "hostname": "laptop",
///         "ip": "192.168.1.150",
///         "mac": "00:11:22:33:44:55",
///         "lease_time": 1732788000
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
/// | `hostname` | string | Client hostname |
/// | `ip` | string | Assigned IP address |
/// | `mac` | string | MAC address |
/// | `lease_time` | integer | Lease expiration (Unix time) |
///
/// ---
Future<Map> dsmCoreNetworkDHCPServerClientListList(
    {String? ifname, // Interface name (default: `bond0`)
    CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.Core.Network.DHCPServer.ClientList',
      method: 'List',
      version: 1);
  if (ifname != null && ifname.isNotEmpty) data['ifname'] = ifname;
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
//Log.info("dsmCoreNetworkDHCPServerClientListList: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

/// {
///   "success": true,
///   "data": {
///     "reservations": [
///       {
///         "hostname": "server",
///         "ip": "192.168.1.50",
///         "mac": "AA:BB:CC:DD:EE:FF"
///       }
///     ],
///     "total": 1
///   }
/// }
///
/// **Notes:**
/// - DHCP Server package must be installed
/// - Only one DHCP server per network interface
/// - Reservations ensure specific devices always get the same IP
/// - Common interface names: `ovs_eth0`, `bond0`, `eth0`
///
/// ---
Future<Map> dsmCoreNetworkDHCPServerReservationList(
    {String? ifname, // Interface name (default: `bond0`)
    CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.Core.Network.DHCPServer.Reservation',
      method: 'List',
      version: 1);
  if (ifname != null && ifname.isNotEmpty) data['ifname'] = ifname;
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
//Log.info("dsmCoreNetworkDHCPServerReservationList: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}
