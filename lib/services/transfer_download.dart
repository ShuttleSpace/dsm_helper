import 'package:background_downloader/background_downloader.dart';
import 'package:garden/api/dsm_api.filestation.transfer_url.dart';
import 'package:garden/services/transfer_engine.dart';
import 'package:garden/stores/connection_store.dart';

/// 下载并发分片数。
/// `/fbdownload` 是否认 `Range`（多线程）待 Task 8 真机确认；
/// 确认前保持 1（单连接，安全），确认后调高即可开启多线程。
int downloadConcurrency = 1;

/// 纯构造：把 URL + 目标目录 + 文件名 包成 background_downloader 下载任务。
///
/// 认证头来自 [authHeaders]（_SSID Cookie + X-SYNO-TOKEN）；
/// `allowPause` 开启断点续传（app 退后台/被杀后由系统 work-manager 续传）。
///
/// 绝对路径（以 `/` 开头）用 [BaseDirectory.root] 解析到真实位置；
/// 相对路径落在应用文档目录，避免 background_downloader 把绝对路径误判为相对。
/// 纯构造：把 URL + 目标目录 + 文件名 包成 background_downloader 下载任务。
///
/// 认证头来自 [authHeaders]（_SSID Cookie + X-SYNO-TOKEN）；
/// `allowPause` 开启断点续传（app 退后台/被杀后由系统 work-manager 续传）。
///
/// 单连接（[downloadConcurrency] <= 1）用普通 [DownloadTask]，只有真正多分片
/// 时才用 [ParallelDownloadTask]——后者原生 enqueue 在单 chunk 下更脆弱。
Task buildDownloadTask({
  required String url,
  required String directory,
  required String filename,
  int? chunks,
}) {
  final absolute = directory.startsWith('/');
  final baseDirectory =
      absolute ? BaseDirectory.root : BaseDirectory.applicationDocuments;
  final chunkCount = chunks ?? downloadConcurrency;
  if (chunkCount > 1) {
    return ParallelDownloadTask(
      url: url,
      filename: filename,
      directory: directory,
      baseDirectory: baseDirectory,
      headers: authHeaders(),
      chunks: chunkCount,
      allowPause: true,
      retries: 3,
    );
  }
  return DownloadTask(
    url: url,
    filename: filename,
    directory: directory,
    baseDirectory: baseDirectory,
    headers: authHeaders(),
    allowPause: true,
    retries: 3,
  );
}

/// 入队一个 DSM 文件下载，返回 taskId。
///
/// `remotePath` 为 NAS 侧绝对路径（如 `/Download/a.zip`），据此自构造
/// `/fbdownload` URL（见 [fbDownloadUrl]，抓包已证实 dlink 即路径 base64）。
Future<String> enqueueFileDownload({
  required String remotePath,
  required String destDir,
  String? destName,
}) async {
  final url = fbDownloadUrl(
    baseUri: connectionStore.baseUri.value,
    path: remotePath,
    synoToken: connectionStore.synoToken.value,
  );
  final task = buildDownloadTask(
    url: url,
    directory: destDir,
    filename: destName ?? remotePath.split('/').last,
  );
  final ok = await FileDownloader().enqueue(task);
  if (!ok) {
    throw Exception('enqueue download failed: ${task.taskId}');
  }
  return task.taskId;
}
