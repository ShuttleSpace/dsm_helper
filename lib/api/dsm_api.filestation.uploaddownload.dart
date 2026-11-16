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

/// 断点续写 Range 头：已有字节为 0（或已 >= total）时返回 null（整文件下载）。
///
/// 前置验证结论见 docs/superpowers/specs/2026-11-16-transfer-capability-probe.md：
/// 下载端点需有效 FileStation SID，206 未实测，故不启用并行分片；单连接续写
/// 由本助手 + [appendPartAndCleanup] 在自管下载路径上提供。
Map<String, String>? downloadResumeRangeHeader(
  int existingBytes, {
  int? totalBytes,
}) {
  if (existingBytes <= 0) return null;
  if (totalBytes != null && existingBytes >= totalBytes) return null;
  return {'Range': 'bytes=$existingBytes-'};
}

/// 从本地半成品文件推导续写偏移；不存在或已完整返回 0。
int downloadResumeOffset(String destPath, {int? totalBytes}) {
  final file = File(destPath);
  if (!file.existsSync()) return 0;
  final length = file.lengthSync();
  if (totalBytes != null && length >= totalBytes) return 0;
  return length;
}

/// 把 Range 拉回的分片字节追加到目标文件，随后删除临时分片。
/// 先落 `.part` 再追加，避免失败时污染已有的半成品文件。
void appendPartAndCleanup(String destPath, String partPath) {
  final part = File(partPath);
  if (!part.existsSync()) return;
  final raf = File(destPath).openSync(mode: FileMode.append);
  try {
    raf.writeFromSync(part.readAsBytesSync());
  } finally {
    raf.closeSync();
    part.deleteSync();
  }
}

/// **Response:**
/// Binary file data (or ZIP archive for multiple files)
///
/// `resumeFrom` > 0 时对目标文件做字节级续写：带 `Range: bytes=N-` 拉取剩余字节，
/// 先落 `.part` 再追加到目标文件（见 [downloadResumeRangeHeader]/[appendPartAndCleanup]）。
/// 传 0（默认）时行为与原先完全一致。
Future<dynamic> dsmFileStationDownload(
    String path, // File path (JSON array for multiple - creates ZIP)
    String destPath,
    {String? mode, // `open` or `download`
    CancelToken? cancelToken,
    int resumeFrom = 0}) async {
  final data = _dsmApiRequestData(
      api: 'SYNO.FileStation.Download', method: 'download', version: 2);
  data['path'] = path;
  if (mode != null) data['mode'] = mode;

  final range = downloadResumeRangeHeader(resumeFrom);
  if (range == null) {
    final res = await _httpDownload(_entryCGI,
        savePath: destPath, queryParameters: data, cancelToken: cancelToken);
//Log.info("dsmFileStationDownload: $res");
    if (res['success'] != true) {
      throw DSMException.fromMap(res);
    }
    return res['data'] ?? {};
  }

  final partPath = '$destPath.part';
  final res = await _httpDownload(_entryCGI,
      savePath: partPath,
      headers: range,
      queryParameters: data,
      cancelToken: cancelToken);
  if (res is Map && res['success'] == false) {
    throw DSMException.fromMap(res);
  }
  appendPartAndCleanup(destPath, partPath);
  return res is Map ? (res['data'] ?? {}) : {};
}
