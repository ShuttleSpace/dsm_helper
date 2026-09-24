part of 'dsm_api.dart';

/// {
///   "success": true
/// }
Future<Map> dsmFileStationUpload(
    String path, // Destination folder path
    MultipartFile file, // File to upload
    {bool? createParents, // Create parent folders (default: true)
    bool? overwrite, // Overwrite existing files (default: false)
    int? mtime,
    int? crtime,
    int? atime,
    CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.FileStation.Upload', method: 'upload', version: 2);
  data['path'] = path;
  data['file'] = file;
  if (createParents != null) data['create_parents'] = createParents;
  if (overwrite != null) data['overwrite'] = overwrite;
  if (mtime != null) data['mtime'] = mtime;
  if (crtime != null) data['crtime'] = crtime;
  if (atime != null) data['atime'] = atime;
  final res = await _httpPost(_entryCGI, data: data, cancelToken: cancelToken);
//Log.info("dsmFileStationUpload: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}

/// **Response:**
/// Binary file data (or ZIP archive for multiple files)
Future<dynamic> dsmFileStationDownload(
    String path, // File path (JSON array for multiple - creates ZIP)
    String destPath,
    {String? mode, // `open` or `download`
    CancelToken? cancelToken}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.FileStation.Download', method: 'download', version: 2);
  data['path'] = path;
  if (mode != null) data['mode'] = mode;
  final res = await _httpDownload(_entryCGI,
      savePath: destPath, queryParameters: data, cancelToken: cancelToken);
//Log.info("dsmFileStationDownload: $res");
  if (res['success'] != true) {
    throw DSMException.fromMap(res);
  }
  return res['data'] ?? {};
}
