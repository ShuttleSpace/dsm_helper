part of 'dsm_api.dart';

Future<Map> dsmMomentsTimeline(
    {String? category = "Timeline", // Timeline、get
    String? type,
    CancelToken? cancelToken}) async {
  final api =
      '"SYNO.${connectionStore.dsmVersion.value >= 7 ? "Foto" : "Photo"}.Browse.$category"';
  final method = category == "Timeline" ? '"get"' : '"get_timeline"';
  final version = connectionStore.dsmVersion.value >= 7
      ? (category == "Timeline" ? 2 : 3)
      : 1;
  final data = _dsmApiRequestData(api: api, method: method, version: version)
    ..addAll({'timeline_group_unit': 'day'});
  if (type != null && type.isNotEmpty) {
    data['type'] = type;
  }
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.info("dsmFotoBrowseItemList: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

Future<Map> dsmMomentsPhotots(
    {int? year,
    int? month,
    int? day,
    int? albumId,
    String? category = "Item",
    String? type,
    int? limit = 5000,
    int? offset,
    CancelToken? cancelToken}) async {
  final api =
      '"SYNO.${connectionStore.dsmVersion.value >= 7 ? "Foto" : "Photo"}.Browse.$category"';
  final version = connectionStore.dsmVersion.value >= 7
      ? (category == "Timeline" ? 2 : 3)
      : 1;
  final data = _dsmApiRequestData(api: api, method: "list", version: version)
    ..addAll({
      'timeline_group_unit': 'day',
      'additional': jsonEncode([
        'thumbnail',
        'resolution',
        'orientation',
        'video_convert',
        'video_meta',
        'address'
      ])
    });
  if (type != null && type.isNotEmpty) {
    data['type'] = type;
  }
  if (year != null && month != null && day != null) {
    int start = DateTime(year, month, day, 8).secondsSinceEpoch;
    int end = start + 60 * 60 * 24;
    data['start_time'] = start;
    data['end_time'] = end;
  }
  if (albumId != null) {
    data['album_id'] = albumId;
  }
  if (limit != null) {
    data['limit'] = limit;
  }
  if (offset != null) {
    data['offset'] = offset;
  }
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.info("dsmMomentsPhotots: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

Future<Map> dsmMomentsAlbum(
    {int? offset = 0,
    int? limit = 5000,
    String? sortBy = "create_time",
    String? sortDirection = "desc",
    bool? shared = false,
    CancelToken? cancelToken}) async {
  final api =
      '"SYNO.${connectionStore.dsmVersion.value >= 7 ? "Foto" : "Photo"}.Browse.album"';
  final version = connectionStore.dsmVersion.value >= 7 ? 1 : 2;
  final data = _dsmApiRequestData(api: api, method: "list", version: version)
    ..addAll({
      'timeline_group_unit': 'day',
      'additional': jsonEncode([
        'thumbnail',
        'resolution',
        'orientation',
        'video_convert',
        'video_meta',
        'address'
      ])
    });
  if (sortBy != null && sortBy.isNotEmpty) {
    data['sort_by'] = sortBy;
  }
  if (sortDirection != null && sortDirection.isNotEmpty) {
    data['sort_direction'] = sortDirection;
  }
  if (shared != null) {
    data['shared'] = shared;
  }
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.info("dsmMomentsPhotots: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

Future<Map> dsmMomentsGeocodingList(
    {String? category = "Timeline", // Timeline、get
    String? type,
    CancelToken? cancelToken}) async {
  final api =
      '"SYNO.${connectionStore.dsmVersion.value >= 7 ? "Foto" : "Photo"}.Browse.Geocoding"';
  final method = category == "Timeline" ? '"get"' : '"get_timeline"';
  final version = connectionStore.dsmVersion.value >= 7
      ? (category == "Timeline" ? 2 : 3)
      : 1;
  final data = _dsmApiRequestData(api: api, method: method, version: version)
    ..addAll({'timeline_group_unit': 'day'});
  if (type != null && type.isNotEmpty) {
    data['type'] = type;
  }
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.info("dsmFotoBrowseItemList: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}
