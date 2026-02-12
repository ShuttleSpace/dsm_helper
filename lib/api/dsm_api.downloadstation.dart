part of 'dsm_api.dart';

/// {
///   "success": true,
///   "data": {
///     "is_manager": true,
///     "version": "3.8.16-3566",
///     "version_string": "3.8.16-3566"
///   }
/// }
Future<Map> dsmDownloadStationInfoGetinfo({CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.DownloadStation.Info', method: 'getinfo', version: 2);
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
  Log.info("dsmDownloadStationInfoGetinfo: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

/// {
///   "success": true,
///   "data": {
///     "bt_max_download": 0,
///     "bt_max_upload": 0,
///     "emule_max_download": 0,
///     "emule_max_upload": 0,
///     "nzb_max_download": 0,
///     "http_max_download": 0,
///     "ftp_max_download": 0,
///     "emule_enabled": false,
///     "unzip_service_enabled": true,
///     "default_destination": "/downloads",
///     "emule_default_destination": "/emule"
///   }
/// }
Future<Map> dsmDownloadStationInfoGetconfig({CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.DownloadStation.Info', method: 'getconfig', version: 2);
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
  Log.info("dsmDownloadStationInfoGetconfig: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

/// {
///   "success": true
/// }
Future<Map> dsmDownloadStationInfoSetconfig(
    {int? btMaxDownload, // Max BT download speed (KB/s, 0 = unlimited)
    int? btMaxUpload, // Max BT upload speed (KB/s, 0 = unlimited)
    int? emuleMaxDownload, // Max eMule download speed (KB/s)
    int? emuleMaxUpload, // Max eMule upload speed (KB/s)
    int? nzbMaxDownload, // Max NZB download speed (KB/s)
    int? httpMaxDownload, // Max HTTP download speed (KB/s)
    int? ftpMaxDownload, // Max FTP download speed (KB/s)
    bool? emuleEnabled, // Enable eMule
    bool? unzipServiceEnabled, // Enable auto-unzip
    String? defaultDestination, // Default download destination
    String? emuleDefaultDestination, // eMule download destination
    CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.DownloadStation.Info', method: 'setconfig', version: 2);
  if (btMaxDownload != null) data['bt_max_download'] = btMaxDownload;
  if (btMaxUpload != null) data['bt_max_upload'] = btMaxUpload;
  if (emuleMaxDownload != null) data['emule_max_download'] = emuleMaxDownload;
  if (emuleMaxUpload != null) data['emule_max_upload'] = emuleMaxUpload;
  if (nzbMaxDownload != null) data['nzb_max_download'] = nzbMaxDownload;
  if (httpMaxDownload != null) data['http_max_download'] = httpMaxDownload;
  if (ftpMaxDownload != null) data['ftp_max_download'] = ftpMaxDownload;
  if (emuleEnabled != null) data['emule_enabled'] = emuleEnabled;
  if (unzipServiceEnabled != null) {
    data['unzip_service_enabled'] = unzipServiceEnabled;
  }
  if (defaultDestination != null && defaultDestination.isNotEmpty) {
    data['default_destination'] = defaultDestination;
  }
  if (emuleDefaultDestination != null && emuleDefaultDestination.isNotEmpty) {
    data['emule_default_destination'] = emuleDefaultDestination;
  }
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.info("dsmDownloadStationInfoSetconfig: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

/// {
///   "success": true,
///   "data": {
///     "enabled": false,
///     "emule_enabled": false
///   }
/// }
Future<Map> dsmDownloadStationScheduleGetconfig(
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.DownloadStation.Schedule', method: 'getconfig', version: 1);
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
  Log.info("dsmDownloadStationScheduleGetconfig: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

/// {
///   "success": true
/// }
Future<Map> dsmDownloadStationScheduleSetconfig(
    bool enabled, // Enable schedule
    bool emuleEnabled, // Enable eMule schedule
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.DownloadStation.Schedule', method: 'setconfig', version: 1);
  data['enabled'] = enabled;
  data['emule_enabled'] = emuleEnabled;
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.info("dsmDownloadStationScheduleSetconfig: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

Future<Map> dsmDownloadStation2SettingsLocationGet(
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.DownloadStation2.Settings.Location',
      method: 'get',
      version: 1);
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.info("dsmDownloadStation2SettingsLocationGet: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

Future<Map> dsmDownloadStation2TaskBTTrackerList(
    {required String taskId, CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.DownloadStation2.Task.BT.Tracker', method: 'list', version: 2)
    ..addAll({'task_id': taskId});
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.info("dsmDownloadStation2TaskBTTrackerList: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

Future<Map> dsmDownloadStation2TaskBTTrackerAdd(
    {required String taskId,
    required List<String> tracker,
    CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.DownloadStation2.Task.BT.Tracker', method: 'add', version: 2)
    ..addAll({'task_id': taskId, 'tracker': jsonEncode(tracker)});
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.info("dsmDownloadStation2TaskBTTrackerAdd: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

Future<Map> dsmDownloadStation2TaskBTPeerList(
    {required String taskId, CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.DownloadStation2.Task.BT.Peer', method: 'list', version: 2)
    ..addAll({'task_id': taskId});
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.info("dsmDownloadStation2TaskBTPeerList: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

Future<Map> dsmDownloadStation2TaskBTFileList(
    {required String taskId,
    int? offset = 0,
    int? limit = 50,
    String? sortBy = 'name',
    String? order = 'ASC',
    String? query,
    CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.DownloadStation2.Task.BT.File', method: 'list', version: 2)
    ..addAll({
      'task_id': taskId,
      'offset': offset,
      'limit': limit,
      'sort_by': sortBy,
      'order': order,
      'query': query ?? ''
    });
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.info("dsmDownloadStation2TaskBTFileList: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}
