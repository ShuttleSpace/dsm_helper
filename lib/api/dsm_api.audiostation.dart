part of 'dsm_api.dart';

/// {
///   "success": true,
///   "data": {
///     "is_manager": true,
///     "version": "6.5.5-3374",
///     "version_string": "6.5.5-3374"
///   }
/// }
Future<Map> dsmAudioStationInfoGetinfo({CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.AudioStation.Info', method: 'getinfo', version: 1);
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
//Log.info("dsmAudioStationInfoGetinfo: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

/// {
///   "success": true,
///   "data": {
///     "playlists": [
///       {
///         "id": "playlist_123",
///         "name": "My Favorites",
///         "type": "normal",
///         "library": "personal",
///         "sharing_status": "private"
///       }
///     ],
///     "total": 1
///   }
/// }
///
/// **Notes:**
/// - Library filter options: `all`, `personal`, `shared`
Future<Map> dsmAudioStationPlaylistList(
    String library, // Library filter (`all`, `personal`, `shared`)
    {int? limit, // Max results (default: 100000)
    CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.AudioStation.Playlist', method: 'list', version: 1);
  data['library'] = library;
  if (limit != null) data['limit'] = limit;
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
//Log.info("dsmAudioStationPlaylistList: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

/// {
///   "success": true,
///   "data": {
///     "songs": [
///       {
///         "id": "music_456",
///         "title": "Song Title",
///         "artist": "Artist Name",
///         "album": "Album Name"
///       }
///     ]
///   }
/// }
///
/// **Notes:**
/// - Pinned songs are user-specific favorites
/// - Requires AudioStation 6.0 or later
Future<Map> dsmAudioStationPinList({CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.AudioStation.Pin', method: 'list', version: 1);
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
//Log.info("dsmAudioStationPinList: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

/// {
///   "success": true,
///   "data": {
///     "players": [
///       {
///         "id": "player_123",
///         "name": "Living Room Speaker",
///         "type": "airplay",
///         "connected": true,
///         "playing": false
///       }
///     ]
///   }
/// }
///
/// **Notes:**
/// - Player type options: `all`, `airplay`, `chromecast`
/// - Additional fields: `subplayer_list`
Future<Map> dsmAudioStationRemotePlayerList(
    String type, // Player type (`all`, `airplay`, `chromecast`)
    {String? additional, // Additional fields (`subplayer_list`)
    CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.AudioStation.RemotePlayer', method: 'list', version: 1);
  data['type'] = type;
  if (additional != null && additional.isNotEmpty) {
    data['additional'] = additional;
  }
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
//Log.info("dsmAudioStationRemotePlayerList: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

/// {
///   "success": true,
///   "data": {
///     "playlist": [
///       {
///         "id": "song_456",
///         "title": "Song Title",
///         "artist": "Artist Name"
///       }
///     ]
///   }
/// }
Future<Map> dsmAudioStationRemotePlayerGetplaylist(String id, // Player ID
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.AudioStation.RemotePlayer', method: 'getplaylist', version: 1);
  data['id'] = id;
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
//Log.info("dsmAudioStationRemotePlayerGetplaylist: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

/// {
///   "success": true
/// }
///
/// **Notes:**
/// - Player ID must be obtained from `list` method first
/// - Supported actions: `play`, `stop`, `pause`, `next`, `prev`
/// - Requires compatible AirPlay or Chromecast devices
Future<Map> dsmAudioStationRemotePlayerControl(
    String id, // Player ID
    String action, // Player action (`play`, `stop`, `pause`, `next`, `prev`)
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.AudioStation.RemotePlayer', method: 'control', version: 1);
  data['id'] = id;
  data['action'] = action;
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
//Log.info("dsmAudioStationRemotePlayerControl: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

/// 歌曲列表：NAS 已经把整库的 ID3 标签索引好了（`song_tag` / `song_audio`），
/// 比自己拉文件解析标签省事得多，代价是 NAS 上得装 Audio Station。
Future<Map> dsmAudioStationSongList(
    {String library = 'shared',
    int limit = 5000,
    int offset = 0,
    String sortBy = 'title',
    String sortDirection = 'asc',
    CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.AudioStation.Song', method: 'list', version: 3)
    ..addAll({
      'library': library,
      'limit': limit,
      'offset': offset,
      'sort_by': sortBy,
      'sort_direction': sortDirection,
      'additional': '["song_tag","song_audio"]',
    });
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}
