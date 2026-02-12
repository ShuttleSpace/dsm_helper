part of 'dsm_api.dart';

/// {
///   "success": true,
///   "data": {
///     "speed_download": 1048576,
///     "speed_upload": 52428,
///     "emule_speed_download": 0,
///     "emule_speed_upload": 0,
///     "nzb_speed_download": 0
///   }
/// }
///
/// **Response Fields:**
///
/// | Field | Type | Description |
/// |-------|------|-------------|
/// | `speed_download` | integer | Current download speed (bytes/s) |
/// | `speed_upload` | integer | Current upload speed (bytes/s) |
/// | `emule_speed_download` | integer | eMule download speed (bytes/s) |
/// | `emule_speed_upload` | integer | eMule upload speed (bytes/s) |
/// | `nzb_speed_download` | integer | NZB download speed (bytes/s) |
///
/// ---
Future<Map> dsmDownloadStationStatisticGetinfo(
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.DownloadStation.Statistic', method: 'getinfo', version: 1);
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
  Log.info("dsmDownloadStationStatisticGetinfo: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}
