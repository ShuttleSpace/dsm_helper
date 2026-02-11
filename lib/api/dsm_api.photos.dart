part of 'dsm_api.dart';

String _fotoApiName() {
  final dsmVersion = connectionStore.dsmVersion.value;
  return dsmVersion >= 7 ? "Foto" : "Photo";
}

/// Foto.Browse.Album-----------------------------------------------------------
Future<Map> dsmFotoBrowseAlbum(
    String
        method, // get_album_list_display(version 3), get_album_list_order(version 2)
    {Map<String, dynamic>? extra, // 注意要确保 key 和请求一致
    int version = 2,
    CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.${_fotoApiName()}Browse.Album',
      method: method,
      version: version);
  if (extra != null) data.addAll(extra);
  final res = await _httpGet(_entryCGI,
      queryParameters: data, cancelToken: cancelToken);
  Log.info("dsmFotoBrowseAlbumList: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'];
}

/// {"data":{"album_display_type":"all_album"},"success":true}
Future<Map> dsmFotoBrowseAlbumGetAlbumListDisplay(
    {CancelToken? cancelToken}) async {
  return dsmFotoBrowseAlbum('get_album_list_display',
      version: 3, cancelToken: cancelToken);
}

/// {"data":{"album_list_sort_by":"create_time","album_list_sort_direction":"desc","shared_with_me_sort_by":"share_modify_time","shared_with_me_sort_direction":"desc","shared_with_others_sort_by":"share_modify_time","shared_with_others_sort_direction":"desc"},"success":true}
Future<Map> dsmFotoBrowseAlbumGetAlbumListOrder(
    {CancelToken? cancelToken}) async {
  return dsmFotoBrowseAlbum('get_album_list_order',
      version: 2, cancelToken: cancelToken);
}

/// {"data":{"count":0},"success":true}
Future<Map> dsmFotoBrowseAlbumCount(
    {String? category, CancelToken? cancelToken}) async {
  return dsmFotoBrowseAlbum('count',
      version: 3,
      cancelToken: cancelToken,
      extra: {'category': '"${category ?? 'normal_share_with_me'}"'});
}

/// {"data":{"list":[{"additional":{"sharing_info":{"enable_password":false,"expiration":0,"is_expired":false,"mtime":1770795107,"owner":{"id":1,"name":"humphrey"},"passphrase":"KXU4ZxXkg","permission":[],"privacy_type":"public-view","sharing_link":"http://dang8080.myDS.me/photo/mo/sharing/KXU4ZxXkg","type":"album"},"thumbnail":{}},"cant_migrate_condition":{},"condition":{},"create_time":1770795096,"end_time":0,"freeze_album":false,"id":1,"item_count":0,"name":"2026-02-11","owner_user_id":1,"passphrase":"KXU4ZxXkg","shared":true,"sort_by":"default","sort_direction":"default","start_time":0,"temporary_shared":true,"type":"normal","version":81999}]},"success":true}
Future<Map> dsmFotoBrowseAlbumList(
    {int offset = 0,
    int limit = 50,
    List<String>? additional, // JSON Array, ["thumbnail","sharing_info"]
    String? category, // normal_share_with_me, 22shared
    String? sortBy, // from dsmFotoBrowseAlbumGetAlbumListOrder() return value.
    String? sortDirection, // asc desc
    CancelToken? cancelToken}) async {
  Map<String, dynamic> extra = {'offset': offset, 'limit': limit};
  if (category != null && category.isNotEmpty) {
    extra['category'] = '"$category"';
  }
  if (additional != null && additional.isNotEmpty) {
    extra['additional'] = jsonEncode(additional);
  }
  if (sortBy != null && sortBy.isNotEmpty) {
    extra['sort_by'] = '"$sortBy"';
  }
  if (sortDirection != null && sortDirection.isNotEmpty) {
    extra['sort_direction'] = '"$sortDirection"';
  }
  return dsmFotoBrowseAlbum('list',
      version: 4, cancelToken: cancelToken, extra: extra);
}

/// {"data":{"list":[{"additional":{"flex_section":[0],"provider_count":0,"sharing_info":{"enable_password":false,"expiration":0,"is_expired":false,"mtime":1770795107,"owner":{"id":1,"name":"humphrey"},"passphrase":"KXU4ZxXkg","permission":[],"privacy_type":"public-view","sharing_link":"http://dang8080.myDS.me/photo/mo/sharing/KXU4ZxXkg","type":"album"},"thumbnail":{}},"cant_migrate_condition":{},"condition":{"is_valid":true},"create_time":1770795096,"end_time":0,"freeze_album":false,"id":1,"item_count":0,"name":"2026-02-11","owner_user_id":1,"passphrase":"KXU4ZxXkg","shared":true,"sort_by":"default","sort_direction":"default","start_time":0,"temporary_shared":true,"type":"normal","version":81999}]},"success":true}
Future<Map> dsmFotoBrowseAlbumGet(List<num> id, // JSON Array, [1,2]
    {List<String>?
        additional, // Additional fields (comma-separated) ["sharing_info","flex_section","provider_count","thumbnail"]
    CancelToken? cancelToken}) async {
  return dsmFotoBrowseAlbum('get',
      version: 4,
      cancelToken: cancelToken,
      extra: {'id': jsonEncode(id), 'additional': jsonEncode(additional)});
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
      api: 'SYNO.${_fotoApiName()}Browse.Album', method: 'create', version: 1);
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
      api: 'SYNO.${_fotoApiName()}Browse.Album', method: 'delete', version: 1);
  data['id'] = id;
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.info("dsmFotoBrowseAlbumDelete: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'];
}

/// ----------------------------------------------------------------------------

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
      api: 'SYNO.${_fotoApiName()}Sharing.Passphrase',
      method: 'create',
      version: 1);
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
  final method = category == "Timeline" ? "get" : "get_timeline";
  final version = category == "Timeline"
      ? (dsmVersion >= 7 ? 2 : 1)
      : (dsmVersion >= 7 ? 3 : 1);

  final data = _dsmApiRequestData(
    api: 'SYNO.${_fotoApiName()}Browse.$category',
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
  final version = dsmVersion >= 7 ? 1 : 2;

  final data = _dsmApiRequestData(
    api: 'SYNO.${_fotoApiName()}Browse.$category',
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
  final data = _dsmApiRequestData(
    api: 'SYNO.${_fotoApiName()}Browse.Category',
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
  final version = dsmVersion >= 7 ? 1 : 2;

  final data = _dsmApiRequestData(
    api: 'SYNO.${_fotoApiName()}Browse.Album',
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
    api: 'SYNO.${_fotoApiName()}Browse.Geocoding',
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
  final data = _dsmApiRequestData(
    api: 'SYNO.${_fotoApiName()}Browse.GeneralTag',
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
  final start = DateTime(year, month, day, 8).millisecondsSinceEpoch ~/ 1000;
  final end = start + 60 * 60 * 24 - 1;

  final data = _dsmApiRequestData(
    api: 'SYNO.${_fotoApiName()}Browse.Timeline',
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
  final version = dsmVersion >= 7 ? 1 : 2;

  final data = _dsmApiRequestData(
    api: 'SYNO.${_fotoApiName()}Browse.RecentlyAdded',
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
  final version = dsmVersion >= 7 ? 3 : 1;

  final data = _dsmApiRequestData(
    api: 'SYNO.${_fotoApiName()}Browse.RecentlyAdded',
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
  final version = dsmVersion >= 7 ? 1 : 2;

  final data = _dsmApiRequestData(
    api: 'SYNO.${_fotoApiName()}Browse.RecentlyAdded',
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

// {"data":{"list":[]},"success":true}
Future<Map> dsmFotoBackgroundTaskInfo(String method, // list_user_task
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.$_fotoApiName().BackgroundTask.Info',
      method: method,
      version: 1);
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.info("dsmFotoBackgroundTaskInfo: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'];
}

/// {"data":{"task_info":{"completion":0,"create_time":1770795606143,"error":0,"extra_info":"","id":2,"operation":"delete","overwrite":0,"skip":0,"status":"waiting","total":1}},"success":true}
Future<Map> dsmFotoBackgroundTaskFile(
    String method, // delete
    String itemId,
    String folderId,
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.$_fotoApiName().BackgroundTask.File',
      method: method,
      version: 1)
    ..addAll({
      'item_id': itemId,
      'folder_id': folderId,
    });
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.info("dsmFotoBackgroundTaskFile: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'];
}
