import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:garden/api/dsm_api.dart' show DSMException;
import 'package:garden/api/dsm_api.filestation.transfer_url.dart';
import 'package:garden/stores/connection_store.dart';

/// vue-office js-preview-lib 能本地渲染的扩展名（纯前端，见 assets/preview/office.html）。
/// doc(旧二进制)/ppt/csv 等该库不支持，走系统"打开方式"。
const kWebPreviewExtensions = {'docx', 'xlsx', 'xls'};

bool canWebPreview(String name) =>
    kWebPreviewExtensions.contains(fileExtension(name));

String fileExtension(String name) =>
    name.contains('.') ? name.split('.').last.toLowerCase() : '';

/// 预览取流地址：统一走新层的官方下载直链（带 `_sid`，mode=open 内联）。
String fileContentUrl(Map file) => fbDownloadUrl(
      baseUri: connectionStore.baseUri.value,
      path: file['path'] as String,
      sid: connectionStore.sid.value,
      mode: 'open',
    );

/// DSM 下载失败时服务端返回的是 JSON 错误信封而非文件字节。
/// 识别出来才能把 code/message 变成可读错误，而不是把错误 JSON 当文件渲染。
/// shortcut: 用 UTF-8 解码探测，二进制文件恰好以合法 JSON 信封开头才会误判。
Map? dsmErrorMapFromBytes(List<int> bytes) {
  if (bytes.isEmpty) return null;
  try {
    final decoded = jsonDecode(utf8.decode(bytes));
    if (decoded is Map && decoded['success'] == false) return decoded;
  } catch (_) {
    // 真文件字节不是 JSON，正常返回 null。
  }
  return null;
}

/// 取文件字节，供 WebView 里的 JS 预览器渲染，也供文本预览复用。
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
  final bytes = res.data ?? <int>[];
  final error = dsmErrorMapFromBytes(bytes);
  if (error != null) throw DSMException.fromMap(error);
  return bytes;
}

const kMaxWebPreviewBytes = 20 * 1024 * 1024;
