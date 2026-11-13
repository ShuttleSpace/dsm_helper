import 'package:background_downloader/background_downloader.dart';
import 'package:garden/stores/connection_store.dart';

/// DSM 认证头（Cookie + CSRF），供 background_downloader 的 task.headers 使用。
///
/// /fbdownload 与上传入口都靠 _SSID Cookie（`connectionStore.cookie`，登录后写入）鉴权；
/// 部分端点还需 X-SYNO-TOKEN。无凭据时返回空 map（公开资源场景）。
Map<String, String> authHeaders() {
  final headers = <String, String>{};
  final cookie = connectionStore.cookie.value;
  if (cookie.isNotEmpty) headers['Cookie'] = cookie;
  final token = connectionStore.synoToken.value;
  if (token.isNotEmpty) headers['X-SYNO-TOKEN'] = token;
  return headers;
}

/// 初始化后台传输引擎（app 启动时调用一次）。
///
/// - 运行态通知：含进度条，用户在后台也能看到/取消传输。
/// - Android 前台服务：移除系统 9 分钟超时，提升 app 退后台或被杀后传输存活概率。
///   （targetSdk 34+ 需在 AndroidManifest 声明 FOREGROUND_SERVICE_DATA_SYNC，
///   见 Task 3 原生配置。）
Future<void> initTransferEngine() async {
  FileDownloader().configureNotification(
    running: const TaskNotification('传输中', '文件: {filename}'),
    progressBar: true,
  );
  await FileDownloader().configure(
    androidConfig: const [
      (Config.runInForeground, Config.always),
    ],
  );
}
