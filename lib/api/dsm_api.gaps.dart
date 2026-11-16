part of 'dsm_api.dart';

/// SYNO.LogCenter.History list (v1) — gap for legacy logHistory.
Future<Map> dsmLogCenterHistoryList({CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
    api: 'SYNO.LogCenter.History',
    method: 'list',
    version: 1,
  )
    ..['offset'] = 0
    ..['limit'] = 50;
  final res =
      await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

/// SYNO.DownloadStation2.Task.List get (v2) — gap for legacy downloadFileList.
Future<Map> dsmDownloadStation2TaskListGet(
  String listId, {
  CancelToken? cancelToken,
}) async {
  final data = _dsmApiRequestData(
    api: 'SYNO.DownloadStation2.Task.List',
    method: 'get',
    version: 2,
  )..['list_id'] = listId;
  final res =
      await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

/// SYNO.DownloadStation2.Task.List.Polling download (v2) — gap for legacy downloadCreate.
Future<Map> dsmDownloadStation2TaskListPollingDownload(
  String listId,
  String destination,
  List selectedFile, {
  CancelToken? cancelToken,
}) async {
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
  final res =
      await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

/// GET /reward — gap for legacy reward. Returns decoded value (not envelope).
Future<dynamic> dsmReward({CancelToken? cancelToken}) async {
  final baseUri = connectionStore.baseUri.value;
  final url = '${baseUri}reward';
  return await _httpGet(url, cancelToken: cancelToken);
}
