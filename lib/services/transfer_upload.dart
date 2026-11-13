import 'dart:io';

import 'package:background_downloader/background_downloader.dart';
import 'package:garden/api/dsm_api.filestation.transfer_contract.dart';
import 'package:garden/api/dsm_api.filestation.transfer_url.dart';
import 'package:garden/services/transfer_engine.dart';
import 'package:garden/stores/connection_store.dart';

/// 一个上传分片（本地临时文件 + 字节范围）。
class TransferChunk {
  const TransferChunk({
    required this.index,
    required this.offset,
    required this.size,
    required this.tempPath,
  });
  final int index;
  final int offset;
  final int size;
  final String tempPath;
}

/// 把文件按字节范围切成临时分片（纯逻辑，可单测）。
/// 每个分片写成独立临时文件，便于 background_downloader 各自上传。
List<TransferChunk> splitFileIntoTempChunks(
  File file, {
  int chunkSize = kDefaultChunkSizeBytes,
}) {
  final length = file.lengthSync();
  if (length == 0) return const [];
  final dir = Directory.systemTemp.createTempSync('dsm_up_');
  final raf = file.openSync();
  final chunks = <TransferChunk>[];
  try {
    var offset = 0;
    var index = 0;
    while (offset < length) {
      final size =
          (offset + chunkSize < length) ? chunkSize : (length - offset);
      final bytes = raf.readSync(size);
      final temp = File('${dir.path}/part_$index');
      temp.writeAsBytesSync(bytes);
      chunks.add(TransferChunk(
        index: index,
        offset: offset,
        size: size,
        tempPath: temp.path,
      ));
      offset += size;
      index++;
    }
  } finally {
    raf.closeSync();
  }
  return chunks;
}

/// v2 单请求上传字段（multipart）。
Map<String, String> v2UploadFields({
  required String remotePath,
  required bool overwrite,
  int? mtime,
}) {
  return {
    'path': remotePath,
    'overwrite': overwrite ? 'true' : 'false',
    if (mtime != null) 'mtime': mtime.toString(),
  };
}

/// v3 分片上传字段（multipart）。首片（partNumber==1）不带 upload_id；
/// 其余片需带首片返回的 upload_id（此处按字段组装，握手协议待 Task 8 实测）。
Map<String, String> v3UploadFields({
  required String remotePath,
  required String filename,
  required int partNumber,
  required int totalParts,
  required int offset,
  required int offsetSize,
  required bool overwrite,
  required int mtime,
  String? uploadId,
}) {
  const f = UploadV3Fields();
  return {
    f.path: remotePath,
    f.filename: filename,
    if (uploadId != null) f.uploadId: uploadId,
    f.partNumber: partNumber.toString(),
    f.totalParts: totalParts.toString(),
    f.offset: offset.toString(),
    f.offsetSize: offsetSize.toString(),
    f.overwrite: overwrite ? 'true' : 'false',
    f.mtime: mtime.toString(),
  };
}

/// 入队一个文件上传，返回 taskId（v2）或 groupId（v3）。
///
/// `localPath` 为本地文件；`remoteDir` 为 NAS 侧目标目录。
/// v3 分片并发（[kUploadV3Supported]）未实测，默认走 v2 单请求。
Future<String> enqueueFileUpload({
  required String localPath,
  required String remoteDir,
  bool overwrite = false,
}) async {
  final file = File(localPath);
  if (!file.existsSync()) {
    throw ArgumentError('local file not found: $localPath');
  }
  if (kUploadV3Supported) {
    return enqueueV3Upload(file, remoteDir: remoteDir, overwrite: overwrite);
  }
  return enqueueV2Upload(file, remoteDir: remoteDir, overwrite: overwrite);
}

Future<String> enqueueV2Upload(
  File file, {
  required String remoteDir,
  required bool overwrite,
}) async {
  final filename = file.path.split('/').last;
  final dir = file.path.substring(0, file.path.length - filename.length - 1);
  final url = uploadEntryUrl(
    baseUri: connectionStore.baseUri.value,
    synoToken: connectionStore.synoToken.value,
    version: 2,
  );
  // shortcut: 上传本地文件用 root base 解析绝对路径，避免首部 '/' 被剥离
  final task = UploadTask(
    url: url,
    filename: filename,
    directory: dir,
    baseDirectory: BaseDirectory.root,
    fileField: 'file',
    fields: v2UploadFields(
      remotePath: '$remoteDir/$filename',
      overwrite: overwrite,
    ),
    headers: authHeaders(),
    retries: 3,
  );
  final ok = await FileDownloader().enqueue(task);
  if (!ok) throw Exception('enqueue upload failed: ${task.taskId}');
  return task.taskId;
}

/// v3 分片并发上传（**未实测**，待 Task 8 有效 SID 验证握手/拼合后启用）。
///
/// 当前按 `UploadV3Fields.assemblyOnFinalPart` 假设：末片上传即触发 NAS 拼合，
/// 不单独调用 complete。upload_id 握手协议未验证，故首片 upload_id 留空。
Future<String> enqueueV3Upload(
  File file, {
  required String remoteDir,
  required bool overwrite,
}) async {
  final filename = file.path.split('/').last;
  final remotePath = '$remoteDir/$filename';
  final mtime = file.lastModifiedSync().millisecondsSinceEpoch;
  final chunks = splitFileIntoTempChunks(file);
  final group = 'up_${DateTime.now().microsecondsSinceEpoch}';

  for (final chunk in chunks) {
    final tempDir =
        chunk.tempPath.substring(0, chunk.tempPath.length - 6); // 去掉 '/part_N'
    final url = uploadEntryUrl(
      baseUri: connectionStore.baseUri.value,
      synoToken: connectionStore.synoToken.value,
      version: 3,
    );
    final task = UploadTask(
      url: url,
      filename: filename,
      directory: tempDir,
      baseDirectory: BaseDirectory.root,
      fileField: 'file',
      group: group,
      fields: v3UploadFields(
        remotePath: remotePath,
        filename: filename,
        partNumber: chunk.index + 1,
        totalParts: chunks.length,
        offset: chunk.offset,
        offsetSize: chunk.size,
        overwrite: overwrite,
        mtime: mtime,
      ),
      headers: authHeaders(),
      retries: 3,
    );
    await FileDownloader().enqueue(task);
  }
  return group;
}
