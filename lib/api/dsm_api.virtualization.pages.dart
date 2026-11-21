part of 'dsm_api.dart';

/// 虚拟化页面级请求替身（测试用）。
@visibleForTesting
Future<dynamic> Function(String endpoint, {Map<String, dynamic>? data})?
    dsmVirtualizationPagePostForTesting;

Future<dynamic> _dsmVmPost(String endpoint,
    {required Map<String, dynamic> data, CancelToken? cancelToken}) async {
  final override = dsmVirtualizationPagePostForTesting;
  if (override != null) return await override(endpoint, data: data);
  return await _httpPost(endpoint, data: data, cancelToken: cancelToken);
}

Map<String, dynamic> _vmPageData(dynamic res) {
  if (res is! Map || res['success'] != true) {
    throw DSMException.fromMap(res is Map ? res : const {});
  }
  return res['data'] is Map
      ? Map<String, dynamic>.from(res['data'] as Map)
      : <String, dynamic>{};
}

/// 虚拟化集群信息（旧 `DsmApi.cluster(method)` 的 POST v1 语义）。
Future<Map<String, dynamic>> dsmVirtualizationClusterForPage(String method,
    {CancelToken? cancelToken}) async {
  return _vmPageData(await _dsmVmPost(_entryCGI,
      data: {
        "api": "SYNO.Virtualization.Cluster",
        "method": method,
        "version": 1,
        "_sid": connectionStore.sid.value,
      },
      cancelToken: cancelToken));
}

/// 是否可开机（guest_id 带引号，保留旧请求体）。
Future<void> dsmVirtualizationGuestCheckPowerOnForPage(String guestId,
    {CancelToken? cancelToken}) async {
  _vmPageData(await _dsmVmPost(_entryCGI,
      data: {
        "api": '"SYNO.Virtualization.Guest.Action"',
        "method": '"check_poweron"',
        "guest_id": '"$guestId"',
        "version": 1,
        "_sid": connectionStore.sid.value,
      },
      cancelToken: cancelToken));
}

/// 虚拟机电源操作（guest_id/action 带引号，保留旧请求体）。
Future<void> dsmVirtualizationGuestPowerActionForPage(
    String guestId, String action,
    {CancelToken? cancelToken}) async {
  _vmPageData(await _dsmVmPost(_entryCGI,
      data: {
        "api": '"SYNO.Virtualization.Guest.Action"',
        "method": '"pwr_ctl"',
        "guest_id": '"$guestId"',
        "action": action,
        "version": 1,
        "_sid": connectionStore.sid.value,
      },
      cancelToken: cancelToken));
}
