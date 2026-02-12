part of 'dsm_api.dart';

Future<Map> dsmFotoTeamBackgroundTaskFile({CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.FotoTeam.BackgroundTask.File', method: '', version: 1);
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.debug('dsmFotoTeamBackgroundTaskFile: $res');
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

Future<Map> dsmFotoTeamBrowseConcept({CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.FotoTeam.Browse.Concept', method: '', version: 2);
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.debug('dsmFotoTeamBrowseConcept: $res');
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

Future<Map> dsmFotoTeamBrowseDiff({CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.FotoTeam.Browse.Diff', method: '', version: 6);
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.debug('dsmFotoTeamBrowseDiff: $res');
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

Future<Map> dsmFotoTeamBrowseFolder({CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.FotoTeam.Browse.Folder', method: '', version: 2);
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.debug('dsmFotoTeamBrowseFolder: $res');
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

Future<Map> dsmFotoTeamBrowseGeneralTag({CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.FotoTeam.Browse.GeneralTag', method: '', version: 1);
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.debug('dsmFotoTeamBrowseGeneralTag: $res');
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

Future<Map> dsmFotoTeamBrowseGeocoding({CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.FotoTeam.Browse.Geocoding', method: '', version: 1);
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.debug('dsmFotoTeamBrowseGeocoding: $res');
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

Future<Map> dsmFotoTeamBrowseItem({CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.FotoTeam.Browse.Item', method: '', version: 6);
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.debug('dsmFotoTeamBrowseItem: $res');
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

Future<Map> dsmFotoTeamBrowsePerson({CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.FotoTeam.Browse.Person', method: '', version: 3);
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.debug('dsmFotoTeamBrowsePerson: $res');
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

Future<Map> dsmFotoTeamBrowseRecentlyAdded({CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.FotoTeam.Browse.RecentlyAdded', method: '', version: 5);
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.debug('dsmFotoTeamBrowseRecentlyAdded: $res');
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

Future<Map> dsmFotoTeamBrowseSimilar({CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.FotoTeam.Browse.Similar', method: '', version: 1);
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.debug('dsmFotoTeamBrowseSimilar: $res');
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

Future<Map> dsmFotoTeamBrowseSimilarItem({CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.FotoTeam.Browse.SimilarItem', method: '', version: 1);
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.debug('dsmFotoTeamBrowseSimilarItem: $res');
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

Future<Map> dsmFotoTeamBrowseSimilarTimeline({CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.FotoTeam.Browse.SimilarTimeline', method: '', version: 1);
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.debug('dsmFotoTeamBrowseSimilarTimeline: $res');
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

Future<Map> dsmFotoTeamBrowseTimeline({CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.FotoTeam.Browse.Timeline', method: '', version: 1);
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.debug('dsmFotoTeamBrowseTimeline: $res');
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

Future<Map> dsmFotoTeamBrowseUnit({CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.FotoTeam.Browse.Unit', method: '', version: 3);
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.debug('dsmFotoTeamBrowseUnit: $res');
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

Future<Map> dsmFotoTeamDownload({CancelToken? cancelToken}) async {
  final data =
      _dsmApiRequestData(api: 'SYNO.FotoTeam.Download', method: '', version: 2);
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.debug('dsmFotoTeamDownload: $res');
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

Future<Map> dsmFotoTeamIndex({CancelToken? cancelToken}) async {
  final data =
      _dsmApiRequestData(api: 'SYNO.FotoTeam.Index', method: '', version: 1);
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.debug('dsmFotoTeamIndex: $res');
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

Future<Map> dsmFotoTeamRegeneratePreview({CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.FotoTeam.RegeneratePreview', method: '', version: 1);
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.debug('dsmFotoTeamRegeneratePreview: $res');
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

Future<Map> dsmFotoTeamSearchFilter({CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.FotoTeam.Search.Filter', method: '', version: 3);
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.debug('dsmFotoTeamSearchFilter $res');
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

Future<Map> dsmFotoTeamSearchSearch({CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.FotoTeam.Search.Search', method: '', version: 6);
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.debug('dsmFotoTeamSearchSearch $res');
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

Future<Map> dsmFotoTeamSharingFolderBatchPermission(
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.FotoTeam.Sharing.FolderBatchPermission',
      method: '',
      version: 1);
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.debug('dsmFotoTeamSharingFolderBatchPermission $res');
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

Future<Map> dsmFotoTeamSharingFolderPermission(
    {CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.FotoTeam.Sharing.FolderPermission', method: '', version: 1);
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.debug('dsmFotoTeamSharingFolderPermission $res');
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

Future<Map> dsmFotoTeamSharingPassphrase({CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.FotoTeam.Sharing.Passphrase', method: '', version: 1);
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.debug('dsmFotoTeamSharingPassphrase $res');
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

Future<Map> dsmFotoTeamStreaming({CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.FotoTeam.Streaming', method: '', version: 2);
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.debug('dsmFotoTeamStreaming $res');
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

Future<Map> dsmFotoTeamThumbnail({CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.FotoTeam.Thumbnail', method: '', version: 2);
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.debug('dsmFotoTeamThumbnail $res');
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

Future<Map> dsmFotoTeamUploadConvertedFile({CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.FotoTeam.Upload.ConvertedFile', method: '', version: 5);
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.debug('dsmFotoTeamUploadConvertedFile $res');
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

Future<Map> dsmFotoTeamUploadFace({CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.FotoTeam.Upload.Face', method: '', version: 1);
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.debug('dsmFotoTeamUploadFace $res');
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

Future<Map> dsmFotoTeamUploadItem({CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.FotoTeam.Upload.Item', method: '', version: 7);
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
  Log.debug('dsmFotoTeamUploadItem $res');
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}
