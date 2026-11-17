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
