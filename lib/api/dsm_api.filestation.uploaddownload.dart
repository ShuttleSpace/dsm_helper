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

/// 测试替身：非空时替代底层「带元数据的下载」，用于断言 206/200 分支与落盘位置
/// （生产恒为 null）。见 [dsmDownloadMetaForTesting] 与 [isResumablePartial]。
@visibleForTesting
Future<DsmDownloadResult> Function(
  String endpoint, {
  required String savePath,
  Map<String, dynamic>? headers,
  Map<String, dynamic>? queryParameters,
  CancelToken? cancelToken,
})?
    dsmDownloadMetaForTesting;

Future<DsmDownloadResult> _dsmDownloadMeta(
  String endpoint, {
  required String savePath,
  Map<String, dynamic>? headers,
  Map<String, dynamic>? queryParameters,
  CancelToken? cancelToken,
}) {
  final override = dsmDownloadMetaForTesting;
  if (override != null) {
    return override(endpoint,
        savePath: savePath,
        headers: headers,
        queryParameters: queryParameters,
        cancelToken: cancelToken);
  }
  return _httpDownloadWithMeta(endpoint,
      savePath: savePath,
      headers: headers,
      queryParameters: queryParameters,
      cancelToken: cancelToken);
}

/// 只有「确实是 206 Partial Content 且 Content-Range 起点等于 expectedOffset」
/// 才允许把字节追加到半成品文件。
///
/// 服务端忽略 Range 时会回 200 并把整文件写入 `.part`；若照单全收会造成
/// 重复/损坏（spec 明令禁止的静默损坏），故 200/未知/偏移不符一律返回 false。
bool isResumablePartial(DsmDownloadResult result, int expectedOffset) {
  if (result.statusCode != 206) return false;
  final range = result.contentRange;
  if (range == null) return false;
  final match = RegExp(r'^bytes\s+(\d+)-').firstMatch(range.trim());
  if (match == null) return false;
  return int.tryParse(match.group(1)!) == expectedOffset;
}

/// **Response:**
/// Binary file data (or ZIP archive for multiple files)
///
/// `resumeFrom` > 0 时对目标文件做字节级续写：带 `Range: bytes=N-` 拉取剩余字节，
/// **仅当确认 206 且 Content-Range 起点匹配时才追加**（见 [isResumablePartial]）；
/// 若服务端忽略 Range 回 200，则改为整文件重下覆盖 destPath，绝不追加。
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
  final partPath = '$destPath.part';
  final result = await _dsmDownloadMeta(_entryCGI,
      savePath: range == null ? destPath : partPath,
      headers: range,
      queryParameters: data,
      cancelToken: cancelToken);

  // 默认路径（resumeFrom=0）：与原实现一致，仅校验 JSON 信封后返回 data。
  if (range == null) {
    final res = result.data;
//Log.info("dsmFileStationDownload: $res");
    if (res['success'] != true) {
      throw DSMException.fromMap(res);
    }
    return res['data'] ?? {};
  }

  if (isResumablePartial(result, resumeFrom)) {
    appendPartAndCleanup(destPath, partPath);
    final res = result.data;
    return res is Map ? (res['data'] ?? {}) : {};
  }

  // 服务端忽略 Range（200/未知/Content-Range 偏移不符）：绝不追加，
  // 删除 .part 后整文件重下覆盖 destPath，避免重复/损坏。
  final part = File(partPath);
  if (part.existsSync()) part.deleteSync();
  final full = await _dsmDownloadMeta(_entryCGI,
      savePath: destPath,
      queryParameters: data,
      cancelToken: cancelToken);
  final res = full.data;
  if (res is Map && res['success'] == false) {
    throw DSMException.fromMap(res);
  }
  return res is Map ? (res['data'] ?? {}) : {};
}
