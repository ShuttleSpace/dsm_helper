part of 'dsm_api.dart';

/// 文件页面级请求替身（测试用）：data 为 POST body，queryParameters 为 GET 查询参数。
@visibleForTesting
Future<dynamic> Function(String endpoint,
    {Map<String, dynamic>? data, Map<String, dynamic>? queryParameters})?
    dsmFileStationPageRequestForTesting;

Future<dynamic> _dsmFsPost(String endpoint,
    {required Map<String, dynamic> data, CancelToken? cancelToken}) async {
  final override = dsmFileStationPageRequestForTesting;
  if (override != null) {
    return await override(endpoint, data: data);
  }
  return await _httpPost(endpoint, data: data, cancelToken: cancelToken);
}

Future<dynamic> _dsmFsGet(String endpoint,
    {required Map<String, dynamic> queryParameters,
    CancelToken? cancelToken}) async {
  final override = dsmFileStationPageRequestForTesting;
  if (override != null) {
    return await override(endpoint, queryParameters: queryParameters);
  }
  return await _httpGet(endpoint,
      queryParameters: queryParameters, cancelToken: cancelToken);
}

Map<String, dynamic> _fsPageData(dynamic res) {
  if (res is! Map || res['success'] != true) {
    throw DSMException.fromMap(res is Map ? res : const {});
  }
  return res['data'] is Map
      ? Map<String, dynamic>.from(res['data'] as Map)
      : <String, dynamic>{};
}

/// 文件列表（保留旧层 POST + 引号字段的请求体）。
Future<Map<String, dynamic>> dsmFileStationListForPage(String path,
    {String sortBy = "name",
    String sortDirection = "asc",
    CancelToken? cancelToken}) async {
  return _fsPageData(await _dsmFsPost(_entryCGI,
      data: {
        "api": '"SYNO.FileStation.List"',
        "method": '"list"',
        "version": 2,
        "_sid": connectionStore.sid.value,
        "offset": 0,
        "folder_path": path,
        "filetype": '"all"',
        "limit": 5000,
        "sort_by": '"$sortBy"',
        "sort_direction": '"$sortDirection"',
        "additional": '["perm", "time", "size","mount_point_type","real_path"]',
      },
      cancelToken: cancelToken));
}

/// 共享文件夹列表。
Future<Map<String, dynamic>> dsmFileStationListShareForPage(
    {CancelToken? cancelToken}) async {
  return _fsPageData(await _dsmFsPost(_entryCGI,
      data: {
        "api": '"SYNO.FileStation.List"',
        "method": '"list_share"',
        "version": 2,
        "_sid": connectionStore.sid.value,
        "offset": 0,
        "limit": 1000,
        "sort_by": '"name"',
        "sort_direction": '"asc"',
        "additional": jsonEncode(["perm", "time", "size"]),
      },
      cancelToken: cancelToken));
}

/// SMB/NFS 虚拟文件夹（旧 smbFolder）。
Future<Map<String, dynamic>> dsmFileStationVirtualFolderSmbForPage(
    {CancelToken? cancelToken}) async {
  return _fsPageData(await _dsmFsPost(_entryCGI,
      data: {
        "api": '"SYNO.FileStation.VirtualFolder"',
        "method": '"list"',
        "version": 2,
        "_sid": connectionStore.sid.value,
        "node": "fm_rf_root",
        "type": '["cifs","nfs"]',
        "additional":
            '["real_path","owner","time","perm","mount_point_type","volume_status"]',
      },
      cancelToken: cancelToken));
}

/// FTP/SFTP/WebDAV 等远程连接列表（旧 remoteLink）。
Future<Map<String, dynamic>> dsmFileStationVirtualFolderForPage(String type,
    {CancelToken? cancelToken}) async {
  return _fsPageData(await _dsmFsPost(_entryCGI,
      data: {
        "api": 'SYNO.FileStation.VirtualFolder',
        "method": 'list',
        "version": 2,
        "_sid": connectionStore.sid.value,
        "node": '"$type"',
        "type": '"$type"',
        "sort_by": '"name"',
        "additional":
            '["real_path","owner","time","perm","mount_point_type","volume_status"]',
      },
      cancelToken: cancelToken));
}

/// 存储卷列表（旧 volumes）。
Future<Map<String, dynamic>> dsmCoreStorageVolumeListForPage(
    {CancelToken? cancelToken}) async {
  return _fsPageData(await _dsmFsPost(_entryCGI,
      data: {
        "limit": -1,
        "offset": 0,
        "location": '"internal"',
        "api": "SYNO.Core.Storage.Volume",
        "version": 1,
        "method": "list",
        "_sid": connectionStore.sid.value,
      },
      cancelToken: cancelToken));
}

/// 启动文件搜索任务。
Future<Map<String, dynamic>> dsmFileStationSearchStartForPage(
    List<String> paths, String pattern,
    {bool recursive = true,
    bool searchContent = false,
    String searchType = "simple",
    CancelToken? cancelToken}) async {
  return _fsPageData(await _dsmFsPost(_entryCGI,
      data: {
        "folder_path": jsonEncode(paths),
        "api": "SYNO.FileStation.Search",
        "method": '"start"',
        "pattern": '"$pattern"',
        "recursive": recursive,
        "search_content": searchContent,
        "search_type": '"$searchType"',
        "version": 2,
        "_sid": connectionStore.sid.value,
      },
      cancelToken: cancelToken));
}

/// 搜索结果列表。
Future<Map<String, dynamic>> dsmFileStationSearchListForPage(String taskId,
    {CancelToken? cancelToken}) async {
  return _fsPageData(await _dsmFsPost(_entryCGI,
      data: {
        "additional":
            jsonEncode(["real_path", "size", "owner", "time", "perm", "type"]),
        "taskid": taskId,
        "offset": 0,
        "limit": 1000,
        "filetype": "all",
        "api": '"SYNO.FileStation.Search"',
        "method": '"list"',
        "version": 2,
        "_sid": connectionStore.sid.value,
      },
      cancelToken: cancelToken));
}

/// 删除任务。
Future<Map<String, dynamic>> dsmFileStationDeleteStartForPage(List<String> path,
    {CancelToken? cancelToken}) async {
  return _fsPageData(await _dsmFsPost(_entryCGI,
      data: {
        "api": '"SYNO.FileStation.Delete"',
        "method": '"start"',
        "accurate_progress": "true",
        "version": 2,
        "_sid": connectionStore.sid.value,
        "path": jsonEncode(path),
      },
      cancelToken: cancelToken));
}

/// 压缩任务。
Future<Map<String, dynamic>> dsmFileStationCompressStartForPage(
    List<String> path, String destPath,
    {CancelToken? cancelToken}) async {
  return _fsPageData(await _dsmFsPost(_entryCGI,
      data: {
        "api": '"SYNO.FileStation.Compress"',
        "method": '"start"',
        "version": 3,
        "_sid": connectionStore.sid.value,
        "path": jsonEncode(path),
        "dest_file_path": destPath,
        "level": "normal",
        "mode": "replace",
        "format": "zip",
        "password": null,
        "codepage": null,
      },
      cancelToken: cancelToken));
}

/// 解压任务。
Future<Map<String, dynamic>> dsmFileStationExtractStartForPage(
    String filePath, String folderPath,
    {String? password, CancelToken? cancelToken}) async {
  return _fsPageData(await _dsmFsPost(_entryCGI,
      data: {
        "api": '"SYNO.FileStation.Extract"',
        "overwrite": "false",
        "method": '"start"',
        "version": 2,
        "_sid": connectionStore.sid.value,
        "file_path": filePath,
        "dest_folder_path": folderPath,
        "keep_dir": "true",
        "create_subfolder": "false",
        "password": '"$password"',
      },
      cancelToken: cancelToken));
}

/// 添加收藏。
Future<Map<String, dynamic>> dsmFileStationFavoriteAddForPage(
    String name, String path,
    {CancelToken? cancelToken}) async {
  return _fsPageData(await _dsmFsPost(_entryCGI,
      data: {
        "api": '"SYNO.FileStation.Favorite"',
        "method": '"add"',
        "version": 2,
        "_sid": connectionStore.sid.value,
        "name": name,
        "path": path,
        "index": -1,
      },
      cancelToken: cancelToken));
}

/// 收藏列表。
Future<Map<String, dynamic>> dsmFileStationFavoriteListForPage(
    {CancelToken? cancelToken}) async {
  return _fsPageData(await _dsmFsPost(_entryCGI,
      data: {
        "api": '"SYNO.FileStation.Favorite"',
        "method": '"list"',
        "version": 2,
        "_sid": connectionStore.sid.value,
        "offset": 0,
        "limit": 1000,
        "additional": '["perm", "time", "size","real_path"]',
      },
      cancelToken: cancelToken));
}

/// 卸载远程挂载点。
Future<Map<String, dynamic>> dsmFileStationMountUnmountForPage(String path,
    {CancelToken? cancelToken}) async {
  return _fsPageData(await _dsmFsPost(_entryCGI,
      data: {
        "api": '"SYNO.FileStation.Mount"',
        "method": '"unmount"',
        "version": 1,
        "_sid": connectionStore.sid.value,
        "mount_point": '"$path"',
        "is_mount_point": true,
        "mount_type": '"remote"',
      },
      cancelToken: cancelToken));
}

/// 断开远程连接。
Future<Map<String, dynamic>> dsmFileStationVFSConnectionDeleteForPage(String id,
    {CancelToken? cancelToken}) async {
  return _fsPageData(await _dsmFsPost(_entryCGI,
      data: {
        "api": '"SYNO.FileStation.VFS.Connection"',
        "method": '"delete"',
        "version": 1,
        "_sid": connectionStore.sid.value,
        "id": '"$id"',
      },
      cancelToken: cancelToken));
}

/// 创建文件夹（旧层用 GET）。
Future<Map<String, dynamic>> dsmFileStationCreateFolderForPage(
    String path, String name,
    {CancelToken? cancelToken}) async {
  return _fsPageData(await _dsmFsGet(_entryCGI,
      queryParameters: {
        "api": '"SYNO.FileStation.CreateFolder"',
        "method": '"create"',
        "version": 2,
        "force_parent": "false",
        "folder_path": '"$path"',
        "name": '"$name"',
        "_sid": connectionStore.sid.value,
      },
      cancelToken: cancelToken));
}

/// 复制/移动任务。
Future<Map<String, dynamic>> dsmFileStationCopyMoveStartForPage(
    List path, String destFolderPath, bool remove,
    {CancelToken? cancelToken}) async {
  return _fsPageData(await _dsmFsPost(_entryCGI,
      data: {
        "overwrite": "true",
        "dest_folder_path": destFolderPath,
        "api": '"SYNO.FileStation.CopyMove"',
        "remove_src": remove,
        "accurate_progress": "true",
        "method": '"start"',
        "version": 3,
        "_sid": connectionStore.sid.value,
        "path": jsonEncode(path),
      },
      cancelToken: cancelToken));
}

/// 重命名（旧层用 GET 且 path/name 带引号）。
Future<void> dsmFileStationRenameForPage(String path, String name,
    {CancelToken? cancelToken}) async {
  _fsPageData(await _dsmFsGet(_entryCGI,
      queryParameters: {
        "api": '"SYNO.FileStation.Rename"',
        "method": '"rename"',
        "version": 2,
        "path": '"$path"',
        "name": '"$name"',
        "_sid": connectionStore.sid.value,
      },
      cancelToken: cancelToken));
}

/// 测试替身：非空时替代上传请求。
@visibleForTesting
Future<dynamic> Function(String endpoint,
    {Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? data,
    CancelToken? cancelToken,
    Function(int, int)? onSendProgress})? dsmFileStationUploadPageForTesting;

/// 备份上传（旧 DsmApi.upload 的 multipart 语义，含 size/mtime 与进度回调）。
Future<Map<String, dynamic>> dsmFileStationUploadForPage(
    String uploadPath,
    String filePath,
    CancelToken? cancelToken,
    Function(int, int) onSendProgress) async {
  final file = File(filePath);
  final multipartFile = MultipartFile.fromFileSync(filePath,
      filename: filePath.split("/").last);
  final versions = availableApis
      .where((e) => e.name == 'SYNO.FileStation.Upload')
      .map((e) => (e.minVersion ?? 1).toInt())
      .toList();
  final minVersion = versions.isEmpty ? 1 : versions.reduce((a, b) => a < b ? a : b);
  final params = {
    "api": "SYNO.FileStation.Upload",
    "method": "upload",
    "version": minVersion < 3 ? minVersion : 3,
  };
  final data = {
    "path": uploadPath,
    "create_parents": true,
    "size": file.lengthSync(),
    "mtime": file.lastModifiedSync().millisecondsSinceEpoch,
    "overwrite": false,
    "file": multipartFile,
  };
  final override = dsmFileStationUploadPageForTesting;
  final res = override != null
      ? await override(_entryCGI,
          queryParameters: params,
          data: data,
          cancelToken: cancelToken,
          onSendProgress: onSendProgress)
      : await _httpUpload(_entryCGI,
          queryParameters: params,
          data: data,
          cancelToken: cancelToken,
          onSendProgress: onSendProgress);
  return _fsPageData(res);
}

/// 取消收藏。
Future<void> dsmFileStationFavoriteDeleteForPage(String path,
    {CancelToken? cancelToken}) async {
  _fsPageData(await _dsmFsPost(_entryCGI,
      data: {
        "api": '"SYNO.FileStation.Favorite"',
        "method": '"delete"',
        "version": 2,
        "_sid": connectionStore.sid.value,
        "path": path,
      },
      cancelToken: cancelToken));
}
