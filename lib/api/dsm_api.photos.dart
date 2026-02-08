part of 'dsm_api.dart';

/// {
///   "success": true,
///   "data": {
///     "list": [
///       {
///         "id": "album_123",
///         "name": "Best Photos 2024",
///         "create_time": 1732752000,
///         "item_count": 50,
///         "shared": false,
///         "type": "normal"
///       }
///     ]
///   }
/// }
Future<Map> dsmFotoBrowseAlbumList(
    {int? offset, // Starting index (default: 0)
    int? limit, // Max results (default: 1000)
    String? sortBy, // Sort field (`album_name`, `create_time`)
    String? sortDirection, // Sort direction: `asc` or `desc`
    CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.Foto.Browse.Album', method: 'list', version: 1);
  if (offset != null) data['offset'] = offset;
  if (limit != null) data['limit'] = limit;
  if (sortBy != null && sortBy.isNotEmpty) data['sort_by'] = sortBy;
  if (sortDirection != null && sortDirection.isNotEmpty) {
    data['sort_direction'] = sortDirection;
  }
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
  Log.info("dsmFotoBrowseAlbumList: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'];
}

/// {
///   "success": true,
///   "data": {
///     "album": {
///       "id": "album_123",
///       "name": "Best Photos 2024",
///       "create_time": 1732752000,
///       "item_count": 50,
///       "condition": []
///     }
///   }
/// }
Future<Map> dsmFotoBrowseAlbumGet(String id, // Album ID
    {String?
        additional, // Additional fields (comma-separated) `sharing_info`, `thumbnail`
    CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.Foto.Browse.Album', method: 'get', version: 1);
  data['id'] = id;
  if (additional != null && additional.isNotEmpty) {
    data['additional'] = additional;
  }
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
  Log.info("dsmFotoBrowseAlbumGet: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'];
}

/// {
///   "success": true,
///   "data": {
///     "id": "album_124"
///   }
/// }
Future<Map> dsmFotoBrowseAlbumCreate(String name, // Album name
    {String? condition, //  Album condition (JSON array)
    CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.Foto.Browse.Album', method: 'create', version: 1);
  data['name'] = name;
  if (condition != null && condition.isNotEmpty) data['condition'] = condition;
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.info("dsmFotoBrowseAlbumCreate: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'];
}

/// {
///   "success": true
/// }
Future<Map> dsmFotoBrowseAlbumDelete(
    String id, // Album ID (comma-separated for multiple)
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.Foto.Browse.Album', method: 'delete', version: 1);
  data['id'] = id;
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.info("dsmFotoBrowseAlbumDelete: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'];
}

/// {
///   "success": true,
///   "data": {
///     "passphrase": "abc123xyz",
///     "sharing_link": "https://photos.example.com/mo/sharing/abc123xyz"
///   }
/// }
Future<Map> dsmFotoSharingPassphraseCreate(String id, // Album or folder ID
    {bool? enabled, // Enable sharing (default: true)
    String? permission, // Sharing permission: `read` or `write`
    int? expiration, // Expiration timestamp (0 for never)
    CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.Foto.Sharing.Passphrase', method: 'create', version: 1);
  data['id'] = id;
  if (enabled != null) data['enabled'] = enabled;
  if (permission != null && permission.isNotEmpty) {
    data['permission'] = permission;
  }
  if (expiration != null) data['expiration'] = expiration;
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.info("dsmFotoSharingPassphraseCreate: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'];
}

/// Timeline API - 获取时间线数据
/// 兼容 DSM 6 (Photo) 和 DSM 7 (Foto)
Future<Map> dsmFotoBrowseTimeline({
  String? category = "Timeline",
  String? type,
  CancelToken? cancelToken,
}) async {
  final dsmVersion = connectionStore.dsmVersion.value;
  final apiName = dsmVersion >= 7 ? "Foto" : "Photo";
  final method = category == "Timeline" ? "get" : "get_timeline";
  final version = category == "Timeline"
      ? (dsmVersion >= 7 ? 2 : 1)
      : (dsmVersion >= 7 ? 3 : 1);

  final data = _dsmApiRequestData(
    api: 'SYNO.$apiName.Browse.$category',
    method: method,
    version: version,
  );
  data['timeline_group_unit'] = 'day';
  if (type != null) data['type'] = type;

  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.info("dsmFotoBrowseTimeline: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'];
}

/// Photos API - 获取照片列表
/// 兼容 DSM 6 (Photo) 和 DSM 7 (Foto)
Future<Map> dsmFotoBrowsePhotoList({
  int? year,
  int? month,
  int? day,
  int? albumId,
  String? category = "Item",
  String? type,
  int? limit = 5000,
  CancelToken? cancelToken,
}) async {
  final dsmVersion = connectionStore.dsmVersion.value;
  final apiName = dsmVersion >= 7 ? "Foto" : "Photo";
  final version = dsmVersion >= 7 ? 1 : 2;

  final data = _dsmApiRequestData(
    api: 'SYNO.$apiName.Browse.$category',
    method: 'list',
    version: version,
  );
  data['offset'] = 0;
  data['limit'] = limit ?? 5000;
  data['additional'] =
      '["thumbnail","resolution","orientation","video_convert","video_meta","address"]';
  if (type != null) data['type'] = type;
  if (year != null && month != null && day != null) {
    final start = DateTime(year, month, day, 8).millisecondsSinceEpoch ~/ 1000;
    final end = start + 60 * 60 * 24;
    data['start_time'] = start;
    data['end_time'] = end;
  }
  if (albumId != null) data['album_id'] = albumId;

  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.info("dsmFotoBrowsePhotoList: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'];
}

/// Category API - 获取分类数据
/// 兼容 DSM 6 (Photo) 和 DSM 7 (Foto)
Future<Map> dsmFotoBrowseCategory({
  CancelToken? cancelToken,
}) async {
  final dsmVersion = connectionStore.dsmVersion.value;
  final apiName = dsmVersion >= 7 ? "Foto" : "Photo";

  final data = _dsmApiRequestData(
    api: 'SYNO.$apiName.Browse.Category',
    method: 'get',
    version: 1,
  );

  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.info("dsmFotoBrowseCategory: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'];
}

/// Album API - 获取相册列表
/// 兼容 DSM 6 (Photo) 和 DSM 7 (Foto)
Future<Map> dsmFotoBrowseAlbumListMoments({
  int? offset = 0,
  int? limit = 5000,
  String? sortBy = "create_time",
  String? sortDirection = "desc",
  bool? shared = false,
  CancelToken? cancelToken,
}) async {
  final dsmVersion = connectionStore.dsmVersion.value;
  final apiName = dsmVersion >= 7 ? "Foto" : "Photo";
  final version = dsmVersion >= 7 ? 1 : 2;

  final data = _dsmApiRequestData(
    api: 'SYNO.$apiName.Browse.Album',
    method: 'list',
    version: version,
  );
  data['offset'] = offset;
  data['limit'] = limit;
  data['additional'] = '["thumbnail"]';
  data['shared'] = shared;
  data['sort_by'] = sortBy;
  data['sort_direction'] = sortDirection;

  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.info("dsmFotoBrowseAlbumListMoments: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'];
}

/// Geocoding API - 获取地理编码数据
/// 仅支持 DSM 7 (Foto)
Future<Map> dsmFotoBrowseGeocoding({
  int? offset = 0,
  int? limit = 5000,
  CancelToken? cancelToken,
}) async {
  final data = _dsmApiRequestData(
    api: 'SYNO.Foto.Browse.Geocoding',
    method: 'list',
    version: 1,
  );
  data['offset'] = offset;
  data['limit'] = limit;
  data['additional'] = '["thumbnail"]';

  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.info("dsmFotoBrowseGeocoding: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'];
}

/// General Tag API - 获取通用标签
/// 支持 DSM 7 (Foto) 和 FotoTeam
Future<Map> dsmFotoBrowseGeneral({
  int? offset = 0,
  int? limit = 5000,
  bool isTeam = false,
  CancelToken? cancelToken,
}) async {
  final apiName = isTeam ? 'FotoTeam' : 'Foto';
  final data = _dsmApiRequestData(
    api: 'SYNO.$apiName.Browse.GeneralTag',
    method: 'list',
    version: 1,
  );
  data['offset'] = offset;
  data['limit'] = limit;
  data['additional'] = '["thumbnail"]';

  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.info("dsmFotoBrowseGeneral: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'];
}

/// Location API - 获取特定日期的地理位置数据
/// 兼容 DSM 6 (Photo) 和 DSM 7 (Foto)
Future<Map> dsmFotoBrowseTimelineLocation(
  int year,
  int month,
  int day, {
  CancelToken? cancelToken,
}) async {
  final dsmVersion = connectionStore.dsmVersion.value;
  final apiName = dsmVersion >= 7 ? "Foto" : "Photo";

  final start = DateTime(year, month, day, 8).millisecondsSinceEpoch ~/ 1000;
  final end = start + 60 * 60 * 24 - 1;

  final data = _dsmApiRequestData(
    api: 'SYNO.$apiName.Browse.Timeline',
    method: 'get_geocoding',
    version: 1,
  );
  data['start_time'] = start;
  data['end_time'] = end;

  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.info("dsmFotoBrowseTimelineLocation: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'];
}

/// Recently Added API - 获取最近添加的项目
/// 兼容 DSM 6 (Photo) 和 DSM 7 (Foto)
Future<Map> dsmFotoBrowseRecentlyAdded({
  CancelToken? cancelToken,
}) async {
  final dsmVersion = connectionStore.dsmVersion.value;
  final apiName = dsmVersion >= 7 ? "Foto" : "Photo";
  final version = dsmVersion >= 7 ? 1 : 2;

  final data = _dsmApiRequestData(
    api: 'SYNO.$apiName.Browse.RecentlyAdded',
    method: 'list',
    version: version,
  );
  data['offset'] = 0;
  data['limit'] = 4;
  data['additional'] = '["thumbnail"]';

  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.info("dsmFotoBrowseRecentlyAdded: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'];
}

/// Recently Timeline API - 获取最近添加的时间线
/// 兼容 DSM 6 (Photo) 和 DSM 7 (Foto)
Future<Map> dsmFotoBrowseRecentlyTimeline({
  CancelToken? cancelToken,
}) async {
  final dsmVersion = connectionStore.dsmVersion.value;
  final apiName = dsmVersion >= 7 ? "Foto" : "Photo";
  final version = dsmVersion >= 7 ? 3 : 1;

  final data = _dsmApiRequestData(
    api: 'SYNO.$apiName.Browse.RecentlyAdded',
    method: 'get_timeline',
    version: version,
  );
  data['timeline_group_unit'] = 'day';

  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.info("dsmFotoBrowseRecentlyTimeline: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'];
}

/// Recently Photos API - 获取最近添加的照片
/// 兼容 DSM 6 (Photo) 和 DSM 7 (Foto)
Future<Map> dsmFotoBrowseRecentlyPhotos({
  int? year,
  int? month,
  int? day,
  int? albumId,
  CancelToken? cancelToken,
}) async {
  final dsmVersion = connectionStore.dsmVersion.value;
  final apiName = dsmVersion >= 7 ? "Foto" : "Photo";
  final version = dsmVersion >= 7 ? 1 : 2;

  final data = _dsmApiRequestData(
    api: 'SYNO.$apiName.Browse.RecentlyAdded',
    method: 'list',
    version: version,
  );
  data['offset'] = 0;
  data['limit'] = 5000;
  data['additional'] =
      '["thumbnail","resolution","orientation","video_convert","video_meta","address"]';
  if (year != null && month != null && day != null) {
    final start = DateTime(year, month, day, 8).millisecondsSinceEpoch ~/ 1000;
    final end = start + 60 * 60 * 24;
    data['start_time'] = start;
    data['end_time'] = end;
  }
  if (albumId != null) data['album_id'] = albumId;

  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.info("dsmFotoBrowseRecentlyPhotos: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'];
}
