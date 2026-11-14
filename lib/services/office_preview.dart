import 'package:dio/dio.dart';
import 'package:garden/extensions/string.dart';
import 'package:garden/stores/connection_store.dart';

/// vue-office js-preview-lib 能本地渲染的扩展名（纯前端，见 assets/preview/office.html）。
/// doc(旧二进制)/ppt/csv 等该库不支持，走系统"打开方式"。
const kWebPreviewExtensions = {'docx', 'xlsx', 'xls'};

bool canWebPreview(String name) =>
    kWebPreviewExtensions.contains(fileExtension(name));

String fileExtension(String name) =>
    name.contains('.') ? name.split('.').last.toLowerCase() : '';

/// 文件内容 URL。dlink 用文件页预览一直在用的格式，并带 _sid —— 抓包证实
/// 外部应用（MIUI 下载器）可凭此 URL 直接取到文件，无需 Cookie。
String fileContentUrl(Map file) {
  final name = Uri.encodeComponent(file['name'] as String);
  final dlink = (file['path'] as String).utf8();
  // 沿用文件页图片/视频预览一直在用的 dlink 格式（带 _sid，外部应用可访问）
  final base = connectionStore.baseUri.value.replaceFirst(RegExp(r'/+$'), '');
  return '$base/fbdownload/$name'
      '?dlink=%22$dlink%22&_sid=%22${connectionStore.sid.value}%22&mode=open';
}

/// 取文件字节，供 WebView 里的 JS 预览器渲染。
/// shortcut: 整文件读入内存再 base64 注入，超大文件（>20MB）会吃内存，
/// 到时改为分块 JS channel 或本地 HTTP 服务流式喂给 WebView。
Future<List<int>> fetchFileBytes(String url) async {
  final res = await Dio().get<List<int>>(
    url,
    options: Options(
      responseType: ResponseType.bytes,
      receiveTimeout: const Duration(seconds: 60),
    ),
  );
  return res.data ?? <int>[];
}

const kMaxWebPreviewBytes = 20 * 1024 * 1024;
