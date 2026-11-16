import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:garden/services/office_preview.dart';
import 'package:garden/widgets/neu_back_button.dart';

/// 用内嵌的 vue-office JS 预览 docx/xlsx/xls。
/// 文件内容由 Dart 侧带凭据下载后注入，避免 WebView 里的跨域/鉴权问题。
class OfficePreviewPage extends StatefulWidget {
  const OfficePreviewPage({
    super.key,
    required this.file,
    required this.url,
  });

  final Map file;
  final String url;

  @override
  State<OfficePreviewPage> createState() => _OfficePreviewPageState();
}

class _OfficePreviewPageState extends State<OfficePreviewPage> {
  late final WebViewController _controller;
  String? _error;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (_) => _render(),
        onWebResourceError: (e) {
          if (e.isForMainFrame ?? false) {
            setState(() => _error = '页面加载失败：${e.description}');
          }
        },
      ))
      ..loadFlutterAsset('assets/preview/office.html');
  }

  Future<void> _render() async {
    if (_ready) return;
    try {
      final bytes = await fetchFileBytes(widget.url);
      if (bytes.isEmpty) throw StateError('文件内容为空');
      if (bytes.length > kMaxWebPreviewBytes) {
        throw StateError('文件过大，请下载后使用其他应用打开');
      }
      final b64 = base64Encode(bytes);
      final ext = fileExtension(widget.file['name'] as String);
      // renderOffice 返回 Promise，取不到解析值；失败由 HTML 的 #status 自行显示
      await _controller.runJavaScript(
        'renderOffice(${jsonEncode(b64)}, ${jsonEncode(ext)})',
      );
      setState(() => _ready = true);
    } catch (e) {
      // DSMException 的 toString 已含 code/message，直接展示且留在页面内不崩溃。
      setState(() => _error = '预览失败：$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: AppBackButton(context),
        title: Text(widget.file['name'] as String),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_error != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            )
          else if (!_ready)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
