part of 'dsm_api.dart';

/// Request data for SYNO.LogCenter.History list (v1) — legacy logHistory.
Map<String, dynamic> dsmLogCenterHistoryListRequestData() {
  final data = _dsmApiRequestData(
    api: 'SYNO.LogCenter.History',
    method: 'list',
    version: 1,
  )
    ..['offset'] = 0
    ..['limit'] = 50;
  return data;
}

/// SYNO.LogCenter.History list (v1) — gap for legacy logHistory.
Future<Map> dsmLogCenterHistoryList({CancelToken? cancelToken}) async {
  final data = dsmLogCenterHistoryListRequestData();
  final res =
      await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

/// Request data for SYNO.DownloadStation2.Task.List get (v2) — legacy downloadFileList.
Map<String, dynamic> dsmDownloadStation2TaskListGetRequestData(String listId) {
  final data = _dsmApiRequestData(
    api: 'SYNO.DownloadStation2.Task.List',
    method: 'get',
    version: 2,
  )..['list_id'] = listId;
  return data;
}

/// SYNO.DownloadStation2.Task.List get (v2) — gap for legacy downloadFileList.
Future<Map> dsmDownloadStation2TaskListGet(
  String listId, {
  CancelToken? cancelToken,
}) async {
  final data = dsmDownloadStation2TaskListGetRequestData(listId);
  final res =
      await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

/// Request data for SYNO.DownloadStation2.Task.List.Polling download (v2)
/// — legacy downloadCreate.
Map<String, dynamic> dsmDownloadStation2TaskListPollingDownloadRequestData(
  String listId,
  String destination,
  List selectedFile,
) {
  destination = destination.substring(1);
  final data = _dsmApiRequestData(
    api: 'SYNO.DownloadStation2.Task.List.Polling',
    method: 'download',
    version: 2,
  )
    ..['destination'] = '"$destination"'
    ..['list_id'] = '"$listId"'
    ..['selected'] = json.encode(selectedFile)
    ..['create_subfolder'] = true;
  return data;
}

/// SYNO.DownloadStation2.Task.List.Polling download (v2) — gap for legacy downloadCreate.
Future<Map> dsmDownloadStation2TaskListPollingDownload(
  String listId,
  String destination,
  List selectedFile, {
  CancelToken? cancelToken,
}) async {
  final data = dsmDownloadStation2TaskListPollingDownloadRequestData(
      listId, destination, selectedFile);
  final res =
      await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

/// Endpoint URL for GET /reward — legacy reward.
String dsmRewardUrl(String baseUri) {
  final base = baseUri.replaceFirst(RegExp(r'/+$'), '');
  return '$base/reward';
}

/// GET /reward — gap for legacy reward. Returns decoded value (not envelope).
Future<dynamic> dsmReward({CancelToken? cancelToken}) async {
  final url = dsmRewardUrl(connectionStore.baseUri.value);
  return await _httpGet(url, cancelToken: cancelToken);
}
