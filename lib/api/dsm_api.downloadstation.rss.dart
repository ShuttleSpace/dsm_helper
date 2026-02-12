part of 'dsm_api.dart';

/// {
///   "success": true,
///   "data": {
///     "total": 2,
///     "offset": 0,
///     "sites": [
///       {
///         "id": "rss_1",
///         "title": "Ubuntu Releases",
///         "url": "https://releases.ubuntu.com/rss",
///         "is_updating": false,
///         "last_update": 1732752000
///       }
///     ]
///   }
/// }
Future<Map> dsmDownloadStationRSSSiteList(
    {int? offset, int? limit, CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.DownloadStation.RSS.Site', method: 'list', version: 1);
  if (offset != null) data['offset'] = offset;
  if (limit != null) data['limit'] = limit;
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
  Log.info("dsmDownloadStationRSSSiteList: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

/// {
///   "success": true
/// }
Future<Map> dsmDownloadStationRSSSiteRefresh(String id, // RSS site ID
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.DownloadStation.RSS.Site', method: 'refresh', version: 1);
  data['id'] = id;
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.info("dsmDownloadStationRSSSiteRefresh: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

/// {
///   "success": true,
///   "data": {
///     "total": 10,
///     "offset": 0,
///     "feeds": [
///       {
///         "id": "feed_1",
///         "title": "Ubuntu 22.04 LTS",
///         "url": "https://releases.ubuntu.com/22.04/ubuntu-22.04-desktop-amd64.iso.torrent",
///         "download_uri": "https://releases.ubuntu.com/22.04/ubuntu-22.04-desktop-amd64.iso.torrent",
///         "publish_date": 1732752000
///       }
///     ]
///   }
/// }
Future<Map> dsmDownloadStationRSSFeedList(String id, // RSS site ID
    {int? offset,
    int? limit,
    CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.DownloadStation.RSS.Feed', method: 'list', version: 1);
  data['id'] = id;
  if (offset != null) data['offset'] = offset;
  if (limit != null) data['limit'] = limit;
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
  Log.info("dsmDownloadStationRSSFeedList: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}
